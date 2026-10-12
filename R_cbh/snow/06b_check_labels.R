#!/usr/bin/env Rscript
# Classifies every label of the label inventory (06_label_inventory.R) with R_cbh/snow/R/label_rules.R before the
# covariates are computed, so that unclassified labels are listed at once (09_covariates_dhs.R stops at the first).
# Survey-specific decisions in R_cbh/snow/config/label_overrides.csv are applied first, as in 09.
# Output: <out>/labels/unclassified_labels.csv (empty when every label is classified); exits with an error otherwise.
suppressPackageStartupMessages(library(data.table))
source("R_cbh/snow/R/settings.R"); source("R_cbh/snow/R/label_rules.R")
S <- snow_settings(); out <- file.path(S$out, "labels")
lab <- rbind(fread(file.path(out, "br_labels.csv"), na.strings = NULL), fread(file.path(out, "pr_labels.csv"), na.strings = NULL))
lab[is.na(label), label := ""]
# Labels as 09_covariates_dhs.R reads them (single quotes); the CSV-escaped quotes of the files are undone.
lab[, label := gsub('""', '"', label, fixed = TRUE)]
ov <- fread("R_cbh/snow/config/label_overrides.csv")[, label := gsub('""', '"', label, fixed = TRUE)]
classify <- function(v, x) switch(v,
  h3 = , h5 = , h7 = , h9 = snow_vacc(x), m15 = snow_facility(x), hv201 = snow_water(x), hv205 = snow_sanitation(x),
  hv206 = snow_yesno(x, "electricity"), hv103 = snow_yesno(x, "de facto"), hc70 = , hc72 = rep(0, length(x)))
bad <- lab[, {
  x <- label; o <- ov[survey == .BY$survey & variable == .BY$variable]
  r <- tryCatch({ y <- classify(.BY$variable, x[!x %in% o$label]); character() }, error = function(e) conditionMessage(e))
  .(problem = if (length(r)) r else NA_character_)
}, by = .(survey, file, variable)][!is.na(problem)]
fwrite(bad, file.path(out, "unclassified_labels.csv"))
if (nrow(bad)) { print(bad); stop(nrow(bad), " (survey, variable) pairs with unclassified labels; see ", file.path(out, "unclassified_labels.csv")) }
cat(S$variant, ": every label of", uniqueN(lab$survey), "surveys is classified\n")
