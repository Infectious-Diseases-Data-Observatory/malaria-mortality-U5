#!/usr/bin/env Rscript
# Sahel seasonality sensitivity (user request, 9 November 2026), step 1: the month-of-exposure data.
# The Sahel subset of the subgroup suite (records whose analysis unit has its centroid at or north of 10N;
# R_cbh/sensitivity/subgroups, sahel_units.csv) in the bands <1, 1-5 and 6-11 months.
# - Every child's calendar month of birth, from the birth date of the child-band records (checked, child by child,
#   against b3 of the recode the records were built from).
# - For each death, the calendar month of death: birth month + age at death. Neonates: age in days (b6); every
#   neonatal death is put in the birth month, as the day of birth is not recorded (deaths at 0-30 days fall in the
#   birth month or the next). 1-11 months: completed months of age, from b6 when reported in months, from the reported
#   days when reported in days (more than 30), else from the survey's imputed b7.
# - A month of death cannot itself be a predictor, since survivors have none. The models take the calendar month in
#   which the child was at risk: the birth month for neonates (the band is one month long); for 1-5 and 6-11 months,
#   the calendar month of each month of age, with one record per child and month of age (death in the month of age
#   of the death; offset log(1/12)).
# - Birth months count as reported when the survey's date flag says the month was given (DHS b10 and MICS BH4F codes
#   1, 2 and 7); the models use only those children (02_fit.R), and the reliability of every step is tabulated.
# Outputs: <out>/reliability_by_band.csv, reliability_by_survey.csv, deaths_by_month.csv, preparation_provenance.csv;
# private: <private>/model_data.rds.
suppressPackageStartupMessages({ library(data.table); library(haven) })
source("R_cbh/load_pipeline.R"); source("R_cbh/primary/settings.R"); source("R_cbh/primary/specification.R")
source("R_cbh/sensitivity/subgroups/settings.R"); source("R_cbh/sensitivity/sahel_season/settings.R")
S <- cbh_sahel_season_settings(); P <- cbh_primary_settings(S$primary_version); st <- cbh_subgroup_settings()
for (p in c(S$out, S$private)) dir.create(p, recursive = TRUE, showWarnings = FALSE)
cfg <- cbh_config()
registry <- fread("data/derived_dhs/survey_registry.csv"); setup <- fread("data/derived_mics/survey_setup.csv")
units_file <- file.path(st$out, "sahel_units.csv")

x <- as.data.table(readRDS(P$data)$data)
su <- fread(units_file)
x <- x[as.character(unit) %in% su[sahel == TRUE, unit] & as.character(age_band) %in% S$bands]
x[, `:=`(child_id = as.character(child_id), age_band = as.character(age_band))]
stopifnot(!anyDuplicated(x, by = c("child_id", "age_band")))
surveys <- sort(unique(as.character(x$survey)))
message(length(surveys), " Sahel surveys; ", nrow(x), " records and ", sum(x$death), " deaths in ", paste(S$bands, collapse = ", "))

## ---- Dates and ages at death, child by child ---------------------------------------------------------------
# Birth month reported: DHS b10 / MICS BH4F codes 1, 2 and 7 (month and year; month and age, year imputed; month only),
# stored as codes (MICS, some DHS) or as their labels (DHS recodes, e.g. "month and year - information complete").
month_given <- function(v) { if (is.character(v) || is.factor(v)) { l <- tolower(trimws(as.character(v))); !is.na(l) & startsWith(l, "month") }
  else { v <- as.integer(zap_labels(v)); !is.na(v) & v %in% c(1L, 2L, 7L) } }
# Age at death flagged by the survey (DHS b13, MICS BH9F): any code but 0 / "no flag".
age_flagged <- function(v) { if (is.character(v) || is.factor(v)) { l <- tolower(trimws(as.character(v))); !is.na(l) & l != "no flag" }
  else { v <- as.integer(zap_labels(v)); !is.na(v) & v != 0L } }
one <- function(s) {
  mics <- startsWith(s, "MC_")
  shard <- if (mics) file.path("data/derived_mics/cbh_build/child_bands", paste0(s, ".rds")) else file.path(cfg$output_dir, "child_bands", paste0(s, ".rds"))
  b <- as.data.table(readRDS(shard)$data)[age_band %in% S$bands, .(child_id, age_band, birth_cmc, band_entry_cmc, age_lo, age_hi,
    death, cmc_offset_months)]
  row <- as.integer(sub("^.*:c:", "", b$child_id)); stopifnot(!anyNA(row))
  if (mics) {
    rec <- readRDS(file.path("data/derived_mics/recodes", paste0(s, ".rds")))
    raw <- read_sav(file.path("data/raw/MICS_extracted", setup[svkey == s, folder], "bh.sav"), col_select = any_of(c("BH4F", "BH9F")))
    stopifnot(nrow(raw) == nrow(rec))
    bflag <- if ("BH4F" %in% names(raw)) month_given(raw$BH4F) else rep(NA, nrow(rec))
    dflag <- if ("BH9F" %in% names(raw)) age_flagged(raw$BH9F) else rep(NA, nrow(rec))
  } else {
    rec <- cbh_read_recode(registry[svkey == s, local_recode][1])
    bflag <- if ("b10" %in% names(rec)) month_given(rec$b10) else rep(NA, nrow(rec))
    dflag <- if ("b13" %in% names(rec)) age_flagged(rec$b13) else rep(NA, nrow(rec))
  }
  stopifnot(max(row) <= nrow(rec), all(cbh_num(rec$b3)[row] + b$cmc_offset_months == b$birth_cmc))
  age <- cbh_death_age(rec$b6, cbh_num(rec$b7))
  b[, `:=`(survey = s, programme = if (mics) "MICS" else "DHS", birth_flag = bflag[row], death_flag = dflag[row],
           death_unit = age$unit[row], death_source = age$source[row], death_lo = age$lo[row], death_days = age$reported_days[row])]
  b
}
d <- rbindlist(lapply(surveys, one))
x <- merge(x, d[, !c("death", "survey"), with = FALSE], by = c("child_id", "age_band"), all.x = TRUE, sort = FALSE)
stopifnot(!anyNA(x$birth_cmc), all(x$band_entry_cmc == x$birth_cmc + x$age_lo))
x[, birth_month := as.integer((birth_cmc - 1) %% 12 + 1)]
x[, month_reported := birth_flag %in% TRUE]   # no flag in the survey: not counted as reported
# Completed months of age at death (1-11 months); neonatal deaths in the birth month.
x[death == 1 & age_band != "<1", death_age_months := fifelse(death_unit == "days" & is.finite(death_days), floor(death_days / 30.4375), death_lo)]
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
  neonatal_deaths_first_week_pct = if (age_band[1] == "<1") round(100 * mean(death_days[death == 1] <= 6, na.rm = TRUE), 1) else NA_real_), by = age_band]
rel <- rel[match(S$bands, age_band)]
# Heaping of infant deaths at 6 months: deaths at 6 months against the mean at 5 and 7 months.
ha <- x[death == 1 & age_band != "<1", .N, by = death_age_months]
rel[, heaping_6_months := fifelse(age_band == "<1", NA_real_, round(ha[death_age_months == 6, N] / mean(ha[death_age_months %in% c(5, 7), N]), 2))]
cbh_atomic_csv(as.data.frame(rel), file.path(S$out, "reliability_by_band.csv"))
rs <- x[, .(programme = programme[1], records = .N, deaths = sum(death), birth_month_reported_pct = pc(month_reported)), by = .(survey, age_band)]
cbh_atomic_csv(as.data.frame(dcast(rs, survey + programme ~ age_band, value.var = "birth_month_reported_pct")), file.path(S$out, "reliability_by_survey.csv"))
ages_dist <- x[death == 1 & age_band != "<1", .N, by = .(age_band, death_age_months)][order(age_band, death_age_months)]
cbh_atomic_csv(as.data.frame(ages_dist), file.path(S$out, "deaths_by_age_month.csv"))
print(rel)

## ---- Model data --------------------------------------------------------------------------------------------
form <- cbh_primary_regional_formula(P)
keep <- unique(c(all.vars(form), "age_band", "child_id", "month_reported", "birth_month"))
neo <- x[age_band == "<1", c(keep, "death_month"), with = FALSE][, month := birth_month]
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
model_data <- list(`<1` = neo, `1-5` = expand(x[age_band == "1-5"]), `6-11` = expand(x[age_band == "6-11"]))
dm <- rbindlist(lapply(names(model_data), function(b) model_data[[b]][(month_reported), .(deaths = sum(death), child_years = sum(band_years)), by = month][, age_band := b]))
dm[, deaths_per_1000_child_years := 1000 * deaths / child_years]
cbh_atomic_csv(as.data.frame(dm[order(match(age_band, S$bands), month)]), file.path(S$out, "deaths_by_month.csv"))
cbh_atomic_rds(model_data, file.path(S$private, "model_data.rds"))
files <- c(P$data, units_file, "R_cbh/sensitivity/sahel_season/01_prepare.R", "R_cbh/sensitivity/sahel_season/settings.R",
  "R_cbh/sensitivity/subgroups/settings.R", "R_cbh/R/child_bands.R")
cbh_atomic_csv(data.frame(file = files, md5 = vapply(files, cbh_file_hash, "")), file.path(S$out, "preparation_provenance.csv"))
message("Model data: ", paste(sprintf("%s %s rows, %d deaths", names(model_data), format(vapply(model_data, nrow, 0L), big.mark = ","),
  vapply(model_data, function(z) sum(z$death), 0L)), collapse = "; "))
