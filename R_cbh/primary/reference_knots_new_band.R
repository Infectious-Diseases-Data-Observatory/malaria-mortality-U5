#!/usr/bin/env Rscript
# Reference knots of the age bands added after the original fits: 5-9 years (60-119 months), 10-14 years (120-179) and
# 15 years and over (180+) (author requests, 20 November 2026). The knots of the seven under-five bands in
# R_cbh/primary/reference_knots.csv are a snapshot of the original fits. A band with no rows in that file gets the knots
# mgcv places by its default rule on the band's own
# records: the model is set up on the prepared dataset with the primary formula and the settings of the fit
# (R_cbh/primary/01_fit.R), without being fitted, and the knots of the PfPR and calendar-time splines are appended to
# the file. Bands already in the file are left as they are.
# Run by hand, once, after R_cbh/primary/00_prepare.R and before R_cbh/primary/01_fit.R:
#   CBH_PRIMARY_VERSION=gadm Rscript R_cbh/primary/reference_knots_new_band.R
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/primary/specification.R")
library(mgcv)
settings <- cbh_primary_settings()
form <- cbh_primary_regional_formula(settings)
knot_table <- cbh_read_csv(settings$knots)
ages <- cbh_config()$age_bands$age_band
new <- setdiff(ages, knot_table$age_band)
if (!length(new)) { message("Every age band has reference knots; nothing to add."); quit(save = "no", status = 0) }
input <- readRDS(settings$data)$data
input <- input[unique(c(all.vars(form), "age_band"))]
basis <- c(pfpr_pct = 5L, calendar_year = 6L)
for (a in new) {
  d <- droplevels(input[input$age_band == a, , drop = FALSE])
  stopifnot(nrow(d) > 0, !anyNA(d))
  set.seed(20260907L)
  G <- bam(form, data = d, family = binomial(link = "cloglog"), method = "fREML", discrete = TRUE, gamma = 2, select = FALSE,
           nthreads = 2, na.action = na.fail, fit = FALSE)
  labels <- vapply(G$smooth, `[[`, "", "label")
  for (v in names(basis)) {
    s <- G$smooth[[match(paste0("s(", v, ")"), labels)]]
    stopifnot(inherits(s, "cr.smooth"), length(s$xp) == basis[[v]], !is.unsorted(s$xp, strictly = TRUE),
              s$xp[1] >= min(d[[v]]) - 1e-9, s$xp[basis[[v]]] <= max(d[[v]]) + 1e-9)
    knot_table <- rbind(knot_table, data.frame(age_band = a, variable = v, index = seq_along(s$xp), value = s$xp))
    message(a, " ", v, ": ", paste(signif(s$xp, 6), collapse = ", "))
  }
}
cbh_atomic_csv(knot_table, settings$knots)
message("Reference knots added for ", paste(new, collapse = ", "), ": ", settings$knots)
