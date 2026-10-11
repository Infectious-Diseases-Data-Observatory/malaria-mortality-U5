#!/usr/bin/env Rscript
# One-off: writes R_cbh/snow/config/dhs_pr_hw_files.csv, the DHS Household Member Recode (PR) and WHO height/weight
# recode (HW) file names that the Snow-unit pipeline reads for each DHS survey of the MAP-eligible sample (120
# surveys). Run from the repository root with the analysis project as argument:
#   Rscript tools/freeze_pr_hw_table.R "<path to analysis project>"
# Inputs (read only): the analysis project's results/cbh/snow_units/feasibility/dhs_file_needs.csv (which surveys
# need an HW file because their BR lacks WHO z-scores), the rdhs dataset catalogue and the local rdhs cache.
# Rules (as the analysis project's R_cbh/snow_units/dhs_files.R): the PR of the same recode version as the BR if
# held, else the account catalogue's flat-ASCII PR for the survey; the HW in Stata format (rdhs misparses flat HW).
# The HW file is read only when the PR's z-scores are not WHO-labelled (decided at run time), so an HW file is
# listed only where it is held (CG51FL needs none: its PR carries WHO z-scores). File names only; no data.
# Stops if a PR file is not in the local cache.
suppressPackageStartupMessages(library(data.table))
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, dir.exists(args[1]), file.exists("R_cbh/00_config.R"))
needs <- fread(file.path(args[1], "results/cbh/snow_units/feasibility/dhs_file_needs.csv"))
reg <- fread("data/derived_dhs/survey_registry.csv")[, .(svkey, SurveyId, br_stem = no_extension)]
stopifnot(nrow(needs) == 120L, all(needs$survey %in% reg$svkey))
cache <- path.expand("~/.rdhs_cache/datasets_reformatted")
held <- list.files(cache); held_stem <- toupper(sub("[.]rds$", "", held, ignore.case = TRUE))
k <- list.files("~/.rdhs_cache/db/keys/available_datasets_calls", full.names = TRUE)
catalogue <- as.data.table(readRDS(path.expand(file.path("~/.rdhs_cache/db/data", paste0(readLines(k[1], warn = FALSE)[1], ".rds")))))
cat_stem <- function(id, ftype, fmt) {
  x <- catalogue[SurveyId == id & FileType == ftype & FileFormat %like% fmt, FileName]
  if (length(x)) toupper(sub("[.]zip$", "", x[1], ignore.case = TRUE)) else NA_character_
}
d <- merge(needs[, .(svkey = survey, in_v9, br_has_who_z = who_br, needs_hw = nzchar(hw_file))], reg, by = "svkey")
d[, pr_stem := {
  same <- toupper(sub("^([A-Za-z]{2})BR(..)FL$", "\\1PR\\2FL", br_stem))
  fifelse(same %in% held_stem, same, vapply(SurveyId, cat_stem, "", "Household Member Recode", "^Flat ASCII"))
}]
d[, hw_stem := fifelse(needs_hw, vapply(SurveyId, cat_stem, "", "Height and Weight Scores - WHO Child Growth Standards", "^Stata"), NA_character_)]
d[, pr_held := pr_stem %in% held_stem]
if (!all(d$pr_held)) { print(d[pr_held == FALSE]); stop("PR files not in the local rdhs cache") }
miss_hw <- d[!is.na(hw_stem) & !hw_stem %in% held_stem]
if (nrow(miss_hw)) message("HW listed but not held (PR WHO z-scores are used if labelled): ", paste(miss_hw$svkey, collapse = ", "))
d[!hw_stem %in% held_stem, hw_stem := NA_character_]
dir.create("R_cbh/snow/config", recursive = TRUE, showWarnings = FALSE)
fwrite(d[order(svkey), .(svkey, SurveyId, in_v9, br_stem, pr_stem, hw_stem)], "R_cbh/snow/config/dhs_pr_hw_files.csv", na = "")
cat(sprintf("%d surveys: %d PR, %d HW (%d v9 surveys, %d others)\n", nrow(d), sum(!is.na(d$pr_stem)), sum(!is.na(d$hw_stem)), sum(d$in_v9), sum(!d$in_v9)))
