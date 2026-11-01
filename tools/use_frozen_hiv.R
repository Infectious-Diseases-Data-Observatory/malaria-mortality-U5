#!/usr/bin/env Rscript
# Use the paper's child HIV incidence panels (stage hiv_panels of run_pipeline.R).
# The model can be refitted as a check (stage hiv, optional: --only=hiv). After a refit, this script records how it
# differs from the frozen panels (results/cbh/hiv_incidence/refit_vs_frozen.csv), keeps the refit outputs in
# */hiv_incidence/refit_check/, and restores the frozen base and extended panels and draws, from which
# R_cbh/hiv/03_add_liberia_aidsinfo.R then rebuilds the Liberia panels used by the models.
suppressPackageStartupMessages(library(data.table))
priv <- "data/derived_cbh/hiv_incidence"; out <- "results/cbh/hiv_incidence"
m <- fread("data/INPUTS_MANIFEST.csv")[role == "frozen_hiv"]
stopifnot(nrow(m) == 4L)
panels <- c("child_incidence_country_year.csv", "child_incidence_country_year_extended.csv")
draws <- c("child_incidence_draws.rds", "child_incidence_draws_extended.rds")
for (d in file.path(c(priv, out), "refit_check")) dir.create(d, recursive = TRUE, showWarnings = FALSE)
cmp <- list()
# A file identical to its frozen copy was restored by an earlier run, not refitted (stage hiv is optional).
refitted <- function(f) file.exists(file.path(priv, f)) &&
  !identical(unname(tools::md5sum(file.path(priv, f))), unname(tools::md5sum(file.path("data/frozen", priv, f))))
for (f in panels) {
  refit <- file.path(priv, f)
  if (refitted(f)) {
    file.copy(refit, file.path(priv, "refit_check", f), overwrite = TRUE, copy.date = TRUE)
    file.copy(refit, file.path(out, "refit_check", f), overwrite = TRUE, copy.date = TRUE)
    a <- fread(refit); b <- fread(file.path("data/frozen", priv, f))
    z <- merge(a[, .(iso3, year, status = hiv_incidence_status, refit = hiv_incidence_per1000)],
               b[, .(iso3, year, frozen = hiv_incidence_per1000)], by = c("iso3", "year"))
    z[, log_ratio := log(refit / frozen)]
    cmp[[f]] <- z[, .(panel = f, country_years = .N, identical = sum(refit == frozen),
      differ_over_5pct = sum(abs(log_ratio) > log(1.05), na.rm = TRUE),
      median_abs_log_ratio = median(abs(log_ratio), na.rm = TRUE), max_abs_log_ratio = max(abs(log_ratio), na.rm = TRUE)), by = status]
  }
}
for (f in draws) if (refitted(f)) file.copy(file.path(priv, f), file.path(priv, "refit_check", f), overwrite = TRUE, copy.date = TRUE)
if (length(cmp)) fwrite(rbindlist(cmp), file.path(out, "refit_vs_frozen.csv"))
for (i in seq_len(nrow(m))) {
  to <- sub("^data/frozen/", "", m$file[i])
  stopifnot(file.copy(m$file[i], to, overwrite = TRUE, copy.date = TRUE), identical(unname(tools::md5sum(to)), m$md5[i]))
  if (grepl("[.]csv$", to)) file.copy(to, file.path(out, basename(to)), overwrite = TRUE, copy.date = TRUE)
}
if (length(cmp)) print(rbindlist(cmp))
cat("Frozen HIV panels and draws restored\n")
