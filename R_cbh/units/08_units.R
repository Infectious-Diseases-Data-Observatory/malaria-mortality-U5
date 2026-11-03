#!/usr/bin/env Rscript
# Analysis units of the placed child-band records (R_cbh/units/R/placement.R, units_assign). Placement is per child
# (all bands of a child share it), so units are assigned per child and carried to its bands. Merge rule (user decisions
# of 11 October 2026): the record's unit is the GADM admin-1 unit holding >= 90% of its smallest reported admin unit's
# population, else the union of the admin-1 units each holding >= 5%; records whose unit is more than half malaria-free
# are dropped; one row per record, w = 1. Records of a survey with the same set of admin-1 units form one analysis unit;
# analysis units of a survey can overlap.
# Writes <private>/records_units.rds (record level; private) and, in <out>/units/, units.csv (one row per survey x unit),
# units_by_survey.csv and dropped_malaria_free.csv (aggregates).
suppressPackageStartupMessages(library(data.table))
source("R_cbh/R/geography.R"); source("R_cbh/units/R/settings.R"); source("R_cbh/units/R/placement.R")
S <- units_dirs(units_settings(), "units"); out <- file.path(S$out, "units")
rec <- readRDS(file.path(S$private, "records_placed.rds"))
pl <- unique(rec[, .(id = child_id, Admin_ID, w, rule)])
stopifnot(!anyDuplicated(pl[, .(id, Admin_ID)]))
un <- units_assign(pl, S)
base <- unique(rec[, !c("Admin_ID", "w", "rule"), with = FALSE])
stopifnot(!anyDuplicated(base[, .(child_id, age_band)]))
d <- merge(base, un[, .(child_id = id, unit, w, rule, n_polygons, malaria_free)], by = "child_id")
mfree <- pl[, .(malaria_free = pmax(0, 1 - sum(w))), by = .(child_id = id)]
dropped <- merge(base[!child_id %in% un$id], mfree, by = "child_id")
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
  S$units, S$rule, uniqueN(d$survey), format(round(sum(d$w)), big.mark = ","), format(round(sum(d$w * d$death)), big.mark = ","),
  nrow(units), sum(units$n_polygons > 1), 100 * sum(units[n_polygons > 1, records]) / sum(units$records), format(nrow(dropped), big.mark = ",")))
