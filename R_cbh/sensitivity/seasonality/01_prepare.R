#!/usr/bin/env Rscript
# Seasonality sensitivity (user requests, 9 November 2026), step 1: the month-of-exposure data, for each region of
# cbh_seasonality_settings() (the Sahel of the subgroup suite; southern Africa) in the bands <1, 1-5 and 6-11 months.
# - Dates from the child_dates stage (data/derived_cbh/child_dates/child_dates.rds; R_cbh/child_dates/01_child_dates.R):
#   every child's calendar month of birth and, for each death, the age at death.
# - For each death, the calendar month of death: birth month + age at death. Neonates: age in days (b6); every
#   neonatal death is put in the birth month, as the day of birth is not recorded (deaths at 0-30 days fall in the
#   birth month or the next). 1-11 months: completed months of age, from b6 when reported in months, from the reported
#   days when reported in days (more than 30), else from the survey's imputed b7.
# - A month of death cannot itself be a predictor, since survivors have none. The models take the calendar month in
#   which the child was at risk: the birth month for neonates (the band is one month long); for 1-5 and 6-11 months,
#   the calendar month of each month of age, with one record per child and month of age, so that a death's record
#   carries the calendar month of the death (offset log(1/12)).
# - Birth months count as reported when the survey's date flag says the month was given (DHS b10 and MICS BH4F codes
#   1, 2 and 7); the month models use only those children (02_fit.R), and the reliability of every step is tabulated.
# - Records: the primary's (v15), or those of S$data (variant mwi_districts: the finer-units data) for the same
#   children, selected by their unit in the primary's units.
# Outputs: <out>/reliability_by_band.csv, reliability_by_survey.csv, deaths_by_age_month.csv, deaths_by_month.csv,
# preparation_provenance.csv; private: <private>/model_data.rds (region -> band -> all-children band records and the
# month records).
suppressPackageStartupMessages(library(data.table))
source("R_cbh/load_pipeline.R"); source("R_cbh/primary/settings.R"); source("R_cbh/primary/specification.R")
source("R_cbh/sensitivity/subgroups/settings.R"); source("R_cbh/sensitivity/seasonality/settings.R")
S <- cbh_seasonality_settings(); P <- cbh_primary_settings(S$primary_version); st <- cbh_subgroup_settings()
for (p in c(S$out, S$private)) dir.create(p, recursive = TRUE, showWarnings = FALSE)
units_file <- file.path(st$out, "sahel_units.csv")
su <- fread(units_file)
region_units <- lapply(setNames(names(S$regions), names(S$regions)), function(r) cbh_seasonality_units(su, r, S))
stopifnot(!anyDuplicated(unlist(region_units)))   # regions do not overlap

data_file <- if (is.null(S$data)) P$data else S$data
x <- as.data.table(readRDS(data_file)$data)[as.character(age_band) %in% S$bands]
x[, `:=`(child_id = as.character(child_id), age_band = as.character(age_band))]
stopifnot(!anyDuplicated(x, by = c("child_id", "age_band")))
# zone = the seasonality region (column region is the model's survey x unit area), from the child's analysis unit in
# the primary's units, so that a variant on finer units (S$data) keeps the same children.
v15 <- if (identical(data_file, P$data)) x else as.data.table(readRDS(P$data)$data)[as.character(age_band) %in% S$bands][, child_id := as.character(child_id)]
zones <- unique(v15[, .(child_id, unit = as.character(unit))]); stopifnot(!anyDuplicated(zones$child_id))
zones[, zone := NA_character_]
for (r in names(region_units)) zones[unit %in% region_units[[r]], zone := r]
x[zones, on = "child_id", zone := i.zone]
v15_records <- v15[child_id %in% zones[!is.na(zone), child_id], .N]; rm(v15, zones); gc(FALSE)
x <- x[!is.na(zone)]
stopifnot(nrow(x) == v15_records)
surveys <- sort(unique(as.character(x$survey)))
print(x[, .(surveys = uniqueN(survey), records = .N, deaths = sum(death)), by = zone])

## ---- Dates and ages at death, child by child (R_cbh/child_dates/01_child_dates.R) ---------------------------
dates_file <- "data/derived_cbh/child_dates/child_dates.rds"
cd <- readRDS(dates_file)[child_id %in% x$child_id, .(child_id, programme, birth_cmc, birth_flag = birth_month_reported,
  death_flag = death_age_flagged, death_unit = death_age_unit, death_source = death_age_source, death_days = death_age_days,
  death_age_months_lo)]
stopifnot(setequal(cd$child_id, unique(x$child_id)))
bands <- data.table(age_band = S$bands, age_lo = c(0, 1, 6), age_hi = c(1, 6, 12))
x[, row_order := .I]
x <- merge(merge(x, cd, by = "child_id", sort = FALSE), bands, by = "age_band", sort = FALSE)
setorder(x, row_order); x[, row_order := NULL]
x[, band_entry_cmc := birth_cmc + age_lo]
stopifnot(!anyNA(x$birth_cmc), all(abs(x$calendar_year - cbh_cmc_time(x$band_entry_cmc)) < 1e-6))
x[, birth_month := as.integer((birth_cmc - 1) %% 12 + 1)]
x[, month_reported := birth_flag %in% TRUE]   # no flag in the survey: not counted as reported
# Completed months of age at death (1-11 months); neonatal deaths in the birth month.
x[death == 1 & age_band != "<1", death_age_months := death_age_months_lo]
x[death == 1 & age_band != "<1", outside_band := death_age_months < age_lo | death_age_months >= age_hi]
x[death == 1 & age_band != "<1", death_age_months := pmin(pmax(death_age_months, age_lo), age_hi - 1)]
x[death == 1, death_month := as.integer((birth_cmc + fifelse(age_band == "<1", 0, death_age_months) - 1) %% 12 + 1)]

## ---- Reliability ---------------------------------------------------------------------------------------------
pc <- function(v) round(100 * mean(v), 1)
rel <- x[, .(records = .N, deaths = sum(death), birth_month_reported_pct = pc(month_reported),
  deaths_birth_month_reported_pct = pc(month_reported[death == 1]),
  deaths_age_in_days_pct = pc(death_unit[death == 1] %in% "days"), deaths_age_in_months_pct = pc(death_unit[death == 1] %in% "months"),
  deaths_age_imputed_pct = pc(death_source[death == 1] %in% "b7_imputed_months"),
  deaths_age_flagged_pct = pc(death_flag[death == 1] %in% TRUE), surveys_without_birth_flag = uniqueN(survey[is.na(birth_flag)]),
  deaths_age_outside_band_pct = if (age_band[1] == "<1") NA_real_ else pc(outside_band[death == 1]),
  neonatal_deaths_first_week_pct = if (age_band[1] == "<1") round(100 * mean(death_days[death == 1] <= 6, na.rm = TRUE), 1) else NA_real_),
  by = .(region = zone, age_band)]
# Heaping of infant deaths at 6 months: deaths at 6 months against the mean at 5 and 7 months.
ha <- x[death == 1 & age_band != "<1", .N, by = .(region = zone, death_age_months)]
hp <- ha[, .(heaping_6_months = round(N[death_age_months == 6] / mean(N[death_age_months %in% c(5, 7)]), 2)), by = region]
rel[hp, on = "region", heaping_6_months := fifelse(age_band == "<1", NA_real_, i.heaping_6_months)]
rel <- rel[order(match(region, names(S$regions)), match(age_band, S$bands))]
cbh_atomic_csv(as.data.frame(rel), file.path(S$out, "reliability_by_band.csv"))
rs <- x[, .(programme = programme[1], records = .N, birth_month_reported_pct = pc(month_reported)), by = .(region = zone, survey, age_band)]
cbh_atomic_csv(as.data.frame(dcast(rs, region + survey + programme ~ age_band, value.var = "birth_month_reported_pct")), file.path(S$out, "reliability_by_survey.csv"))
ages_dist <- x[death == 1 & age_band != "<1", .N, by = .(region = zone, age_band, death_age_months)][order(region, age_band, death_age_months)]
cbh_atomic_csv(as.data.frame(ages_dist), file.path(S$out, "deaths_by_age_month.csv"))
print(rel)

## ---- Model data --------------------------------------------------------------------------------------------
form <- cbh_primary_regional_formula(P)
keep <- unique(c(all.vars(form), "age_band", "child_id", "month_reported", "birth_month"))
# Child-month records for 1-5 and 6-11 months: months of age age_lo..age_hi-1, up to the month of the death.
expand <- function(z) {
  z <- z[, c(keep, "age_lo", "age_hi", "band_entry_cmc", "death_age_months"), with = FALSE]
  last <- fifelse(z$death == 1, z$death_age_months, z$age_hi - 1)
  n <- as.integer(last - z$age_lo + 1); stopifnot(all(n >= 1))
  e <- z[rep(seq_len(nrow(z)), n)]
  e[, age_month := age_lo + sequence(n) - 1L]
  e[, death := as.integer(death == 1 & age_month == death_age_months)]
  e[, month := as.integer((band_entry_cmc + age_month - age_lo - 1) %% 12 + 1)]
  e[, band_years := 1 / 12]
  stopifnot(sum(e$death) == sum(z$death))
  e[, c("age_lo", "age_hi", "band_entry_cmc", "death_age_months") := NULL]
  e
}
model_data <- lapply(setNames(names(S$regions), names(S$regions)), function(r) {
  z <- x[zone == r]
  lapply(setNames(S$bands, S$bands), function(b) {
    band <- z[age_band == b, c(keep, "death_month"), with = FALSE]
    list(band = band, month = if (b == "<1") copy(band)[, month := birth_month] else expand(z[age_band == b]))
  })
})
dm <- rbindlist(lapply(names(model_data), function(r) rbindlist(lapply(S$bands, function(b)
  model_data[[r]][[b]]$month[(month_reported), .(deaths = sum(death), child_years = sum(band_years)), by = month][, `:=`(region = r, age_band = b)]))))
dm[, deaths_per_1000_child_years := 1000 * deaths / child_years]
cbh_atomic_csv(as.data.frame(dm[order(match(region, names(S$regions)), match(age_band, S$bands), month)]), file.path(S$out, "deaths_by_month.csv"))
cbh_atomic_rds(model_data, file.path(S$private, "model_data.rds"))
files <- c(unique(c(data_file, P$data)), units_file, dates_file, "R_cbh/sensitivity/seasonality/01_prepare.R", "R_cbh/sensitivity/seasonality/settings.R",
  "R_cbh/sensitivity/subgroups/settings.R", "R_cbh/R/child_bands.R")
cbh_atomic_csv(data.frame(file = files, md5 = vapply(files, cbh_file_hash, "")), file.path(S$out, "preparation_provenance.csv"))
for (r in names(model_data)) message(r, ": ", paste(sprintf("%s %s month rows, %d deaths", S$bands,
  format(vapply(model_data[[r]], function(z) nrow(z$month), 0L), big.mark = ","), vapply(model_data[[r]], function(z) sum(z$month$death), 0L)), collapse = "; "))
