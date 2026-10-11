#!/usr/bin/env Rscript
# Distinct answer labels of the DHS items used for the recode covariates, over the DHS surveys of the variant
# (ported from the analysis project's R_cbh/snow_units/04_label_inventory.R): BR h3/h5/h7/h9 (DTP doses, measles),
# m15 (place of delivery), and PR hv201 (water), hv205 (toilet), hv206 (electricity), hv103 (slept last night),
# hc70/hc72 non-numeric codes. Counts only. Labels are classified by R_cbh/snow/R/label_rules.R; 09_covariates_dhs.R
# stops on any unclassified label, and this inventory is where to look when it does.
# Output: <out>/labels/{br,pr}_labels.csv
suppressPackageStartupMessages(library(data.table))
source("R_cbh/snow/R/settings.R"); source("R_cbh/snow/R/dhs_files.R")
S <- snow_dirs(snow_settings(), "labels"); out <- file.path(S$out, "labels")
dhs <- setdiff(snow_surveys(S), grep("^MC_", snow_surveys(S), value = TRUE))
registry <- fread("data/derived_dhs/survey_registry.csv")[svkey %in% dhs]
stopifnot(nrow(registry) == length(dhs))
tab <- function(survey, file, x, vars) rbindlist(lapply(intersect(vars, names(x)), function(v) {
  y <- tolower(trimws(as.character(x[[v]])))
  if (v %in% c("hc70", "hc72")) y <- y[!grepl("^-?[0-9.]+$", y)]   # numeric z-scores are not labels
  t <- table(y, useNA = "ifany")
  data.table(survey = survey, file = file, variable = v, label = names(t), n = as.integer(t))
}))
br <- rbindlist(lapply(seq_len(nrow(registry)), function(i) {
  x <- readRDS(registry$local_recode[i]); r <- tab(registry$svkey[i], "BR", x, c("h3", "h5", "h7", "h9", "m15")); rm(x); invisible(gc()); r }))
fwrite(br, file.path(out, "br_labels.csv"))
pr <- rbindlist(lapply(registry$svkey, function(s) {
  x <- readRDS(snow_pr_path(s)); names(x) <- tolower(names(x))
  r <- tab(s, "PR", x, c("hv201", "hv205", "hv206", "hv103", "hc70", "hc72")); rm(x); invisible(gc()); r }))
fwrite(pr, file.path(out, "pr_labels.csv"))
cat(sprintf("%s: BR %d surveys, %d distinct (variable, label); PR %d surveys, %d distinct\n", S$variant, uniqueN(br$survey),
            nrow(unique(br[, .(variable, label)])), uniqueN(pr$survey), nrow(unique(pr[, .(variable, label)]))))
