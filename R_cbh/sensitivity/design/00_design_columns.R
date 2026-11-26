#!/usr/bin/env Rscript
# Survey design columns of the primary sample's records (reviewer comment on the hazards model: urban/rural strata and
# cluster dependence). The prepared dataset (R_cbh/primary/00_prepare.R) keeps child_id but not the design columns;
# this joins them back from the per-survey child-band files (DHS: data/derived_cbh/child_bands; MICS:
# <mics_output_dir>/child_bands): cluster (psu), stratum, urban/rural at interview (v025 / HH6, the classification the
# surveys stratify on), mother and survey weight. One row per child of the sample.
# Writes <private>/design_columns.rds (record level; private) and <out>/design_columns_summary.csv (aggregates).
suppressPackageStartupMessages(library(data.table))
source("R_cbh/primary/settings.R"); source("R_cbh/sensitivity/design/settings.R")
P <- cbh_primary_settings(); S <- cbh_design_settings()
for (p in c(S$private, S$out)) dir.create(p, recursive = TRUE, showWarnings = FALSE)
d <- as.data.table(readRDS(P$data)$data)[, .(child_id, survey)]
d <- unique(d[, survey := as.character(survey)])
stopifnot(!anyDuplicated(d$child_id))
dirs <- c("data/derived_cbh/child_bands", file.path(P$mics_output_dir, "child_bands"))
cols <- c("child_id", "mother_id", "psu", "stratum", "urban", "survey_weight")
one <- function(s) {
  f <- file.path(dirs, paste0(s, ".rds")); f <- f[file.exists(f)]
  if (length(f) != 1L) stop("Expected one child-band file for ", s, ", found ", length(f))
  x <- as.data.table(readRDS(f)$data)
  x <- unique(x[child_id %in% d$child_id[d$survey == s], ..cols])
  stopifnot(!anyDuplicated(x$child_id))
  x[, survey := s]
}
x <- rbindlist(lapply(unique(d$survey), one))
x <- merge(d, x, by = c("child_id", "survey"), all.x = TRUE, sort = FALSE)
stopifnot(nrow(x) == nrow(d))
# Declared rule: the Kenya 2009 MICS of the Mombasa informal settlements has no urban/rural variable and is urban by
# design (as the Dakar city survey is in R_mics/07_make_recodes.R).
urban_by_design <- "MC_KEN2009MOM"
stopifnot(all(is.na(x$urban[x$survey %in% urban_by_design])), !anyNA(x$urban[!x$survey %in% urban_by_design]))
x[survey %in% urban_by_design, urban := 1]
# Clusters, strata and mothers are numbered within a survey: make them unique across surveys.
for (v in c("psu", "stratum", "mother_id")) x[, (v) := ifelse(is.na(get(v)), NA_character_, paste(survey, get(v), sep = ":"))]
summary <- x[, .(children = .N, clusters = uniqueN(psu, na.rm = TRUE), strata = uniqueN(stratum, na.rm = TRUE),
  urban_share = mean(urban, na.rm = TRUE), weighted_urban_share = sum(survey_weight * urban, na.rm = TRUE) / sum(survey_weight[!is.na(urban)]),
  missing_cluster = sum(is.na(psu)), missing_urban = sum(is.na(urban)), missing_stratum = sum(is.na(stratum)),
  missing_weight = sum(!is.finite(survey_weight))), by = survey][order(survey)]
saveRDS(x, S$design)
fwrite(summary, file.path(S$out, "design_columns_summary.csv"))
print(summary[, lapply(.SD, sum), .SDcols = c("children", "clusters", "strata", "missing_cluster", "missing_urban", "missing_stratum", "missing_weight")])
print(summary[, .(surveys = .N, urban_share_unweighted = weighted.mean(urban_share, children, na.rm = TRUE), urban_share_weighted = weighted.mean(weighted_urban_share, children, na.rm = TRUE),
  surveys_oversampling_urban = sum(urban_share > weighted_urban_share + 0.02, na.rm = TRUE))])
