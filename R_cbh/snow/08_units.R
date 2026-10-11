#!/usr/bin/env Rscript
# Analysis units of the placed child-band records (R_cbh/snow/R/placement.R, snow_assign). Placement is per child
# (all bands of a child share it), so units are assigned per child and carried to its bands.
#   merge (primary; user decisions of 11 October 2026; tested in the analysis project's 19_merge_rule_all.R): the
#     record's unit is the Snow polygon holding >= 90% of its smallest reported admin unit's population, else the
#     union of the polygons each holding >= 5%; records whose unit is more than half malaria-free are dropped; one row
#     per record, w = 1. Records of a survey with the same polygon set form one unit; units of a survey can overlap.
#   split (reproduction only): one row per record and polygon, w = population share, as in the analysis project.
# Writes <private>/records_units.rds (record level; private) and, in <out>/units/, units.csv (one row per survey x unit),
# units_by_survey.csv and dropped_malaria_free.csv (aggregates).
suppressPackageStartupMessages(library(data.table))
source("R_cbh/R/geography.R"); source("R_cbh/snow/R/settings.R"); source("R_cbh/snow/R/placement.R")
S <- snow_dirs(snow_settings(), "units"); out <- file.path(S$out, "units")
rec <- readRDS(file.path(S$private, "records_placed.rds"))
pl <- unique(rec[, .(id = child_id, Admin_ID, w, rule)])
stopifnot(!anyDuplicated(pl[, .(id, Admin_ID)]))
un <- snow_assign(pl, S)
if (identical(S$rule, "merge")) {
  base <- unique(rec[, !c("Admin_ID", "w", "rule"), with = FALSE])
  stopifnot(!anyDuplicated(base[, .(child_id, age_band)]))
  d <- merge(base, un[, .(child_id = id, unit, w, rule, n_polygons, malaria_free)], by = "child_id")
  mfree <- pl[, .(malaria_free = pmax(0, 1 - sum(w))), by = .(child_id = id)]
  dropped <- merge(base[!child_id %in% un$id], mfree, by = "child_id")
} else {
  d <- merge(rec, un[, .(child_id = id, Admin_ID = unit, n_polygons, malaria_free)], by = c("child_id", "Admin_ID"))
  d[, unit := Admin_ID]
  dropped <- rec[0][, malaria_free := numeric()]
}
stopifnot(all(d$w > 0 & d$w <= 1), d[, sum(w), by = .(child_id, age_band)]$V1 <= 1 + 1e-9)
saveRDS(d, file.path(S$private, "records_units.rds"))
units <- d[, .(n_polygons = n_polygons[1], records = sum(w), deaths = sum(w * death), children = uniqueN(child_id)), by = .(survey, country, unit)]
fwrite(units[order(country, survey, unit)], file.path(out, "units.csv"))
bys <- d[, .(records = sum(w), deaths = sum(w * death), units = uniqueN(unit), merged_units = uniqueN(unit[n_polygons > 1]),
             records_in_merged = sum(w[n_polygons > 1])), by = .(survey, country)]
bys <- merge(bys, dropped[, .(dropped_malaria_free = .N), by = survey], by = "survey", all.x = TRUE)[is.na(dropped_malaria_free), dropped_malaria_free := 0L]
fwrite(bys[order(country, survey)], file.path(out, "units_by_survey.csv"))
fwrite(dropped[, .(records = .N, deaths = sum(death), mean_malaria_free = mean(malaria_free)), by = .(survey, country, regkey)][order(survey, regkey)],
       file.path(out, "dropped_malaria_free.csv"))
cat(sprintf("%s (%s rule): %d surveys, %s records (%s deaths), %d units (%d merged; %.1f%% of records), %s records dropped as mostly malaria-free\n",
  S$variant, S$rule, uniqueN(d$survey), format(round(sum(d$w)), big.mark = ","), format(round(sum(d$w * d$death)), big.mark = ","),
  nrow(units), sum(units$n_polygons > 1), 100 * sum(units[n_polygons > 1, records]) / sum(units$records), format(nrow(dropped), big.mark = ",")))
