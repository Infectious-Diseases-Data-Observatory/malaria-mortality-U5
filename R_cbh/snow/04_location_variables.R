#!/usr/bin/env Rscript
# Inventory of location variables finer than the survey-region, for every survey of the feasibility overlay (ported
# from the analysis project's R_cbh/snow_units/02_location_variables.R). DHS: the Births Recode used by the child-band
# builder; candidates are v023/v024/v101 and any country-specific (s...) variable whose label names an
# administrative unit. MICS: geographic variables of bh.sav and hh.sav (HH7, HH7A, ...). Only variable names, labels,
# counts of distinct values and up to 12 example values are written (no records); the file stays in ignored results/.
# Output: <out>/feasibility/location_variables.csv
suppressPackageStartupMessages({ library(data.table); library(haven) })
source("R_cbh/snow/R/settings.R")
S <- snow_settings(); out <- file.path(S$out, "feasibility")
surveys <- fread(file.path(out, "survey_feasibility.csv"))
registry <- fread("data/derived_dhs/survey_registry.csv")
setup <- fread("data/derived_mics/survey_setup.csv")
geo_label <- "state|region|zone|district|lga|province|county|depart|prefect|commune|cercle|woreda|division|municip|governorate|wilaya|moughataa|parish|constituency|chiefdom|ward|locality|sub-?county|kebele|arrondissement|canton|circonscription"
describe <- function(survey, file, v, x) {
  vals <- if (is.labelled(x)) as.character(as_factor(x)) else as.character(x)
  tab <- sort(table(vals[!is.na(vals) & nzchar(vals)]), decreasing = TRUE)
  lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  data.table(survey = survey, file = file, variable = v, label = lab, n_values = length(tab),
             examples = paste(head(names(tab), 12), collapse = " | "))
}
rows <- list()
for (s in surveys$survey) {
  if (startsWith(s, "MC_")) {
    folder <- setup[svkey == s, folder]
    for (f in c("bh.sav", "hh.sav")) {
      p <- file.path("data/raw/MICS_extracted", folder, f); if (!file.exists(p)) next
      h <- read_sav(p, n_max = 0)
      labs <- vapply(h, function(z) { l <- attr(z, "label"); if (is.null(l)) "" else l }, "")
      cand <- names(h)[grepl("^HH7|^HH6$|^HH1$|^REGION|^DISTRICT|^PROV|^ZONE", names(h), ignore.case = TRUE) |
                         grepl(geo_label, labs, ignore.case = TRUE)]
      if (!length(cand)) next
      d <- read_sav(p, col_select = all_of(cand))
      rows[[length(rows) + 1]] <- rbindlist(lapply(cand, function(v) describe(s, f, v, d[[v]])))
    }
  } else {
    x <- readRDS(registry[svkey == s, local_recode][1])
    labs <- vapply(x, function(z) { l <- attr(z, "label"); if (is.null(l)) "" else l }, "")
    cand <- names(x)[names(x) %in% c("v023", "v024", "v101") |
                       (grepl("^s", names(x)) & grepl(geo_label, labs, ignore.case = TRUE))]
    rows[[length(rows) + 1]] <- rbindlist(lapply(cand, function(v) describe(s, "BR", v, x[[v]])))
    rm(x); invisible(gc())
  }
}
inv <- rbindlist(rows)
inv <- merge(surveys[, .(survey, programme, country, in_v9, survey_regions, pct_records_split)], inv, by = "survey")
fwrite(inv[order(country, survey, -n_values)], file.path(out, "location_variables.csv"))
cat(S$variant, ":", nrow(inv), "candidate variables in", uniqueN(inv$survey), "surveys\n")
