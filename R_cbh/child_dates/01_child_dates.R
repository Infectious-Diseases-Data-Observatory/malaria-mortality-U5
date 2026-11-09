#!/usr/bin/env Rscript
# Birth and death dates of every child in the child-band data (user request, 9 November 2026): all built DHS and MICS
# surveys (data/derived_cbh and data/derived_mics/cbh_build manifests), one row per child, matched to the recode the
# child-band records were built from by the child's row (child_id = survey:c:row; birth date checked against b3).
# - Birth: century-month code (CMC), year and calendar month; birth_month_reported when the survey's date flag says the
#   month was given (DHS b10 and MICS BH4F codes 1, 2 and 7; MICS without BH4F: BH4M in 1-12; neither: NA).
# - Death (b5 = no): age at death as reported (b6 units days, months or years; b7, the survey's imputed months, when b6
#   is unusable) and the survey's age-at-death flag (DHS b13, MICS BH9F). Completed months of age at death: from the
#   days when reported in days, the months when in months; deaths reported in years have only a 12-month window. The
#   month of death (death_cmc, death_year, death_month) is given when the age is in days or months: birth month +
#   completed months, uncertain by up to one month as the day of birth is not recorded (neonatal deaths, 0-30 days,
#   fall in the birth month). death_cmc_lo/hi always bound the month of death.
# - in_primary: the child has records in the primary prepared sample.
# Outputs: data/derived_cbh/child_dates/child_dates.rds (private, git-ignored); results/cbh/child_dates/
# reliability_by_survey.csv, reliability_by_age.csv, provenance.csv (aggregates).
suppressPackageStartupMessages({ library(data.table); library(haven) })
source("R_cbh/load_pipeline.R"); source("R_cbh/primary/settings.R")
P <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION", "gadm")); cfg <- cbh_config()
out <- "results/cbh/child_dates"; private <- "data/derived_cbh/child_dates"
for (p in c(out, private)) dir.create(p, recursive = TRUE, showWarnings = FALSE)
registry <- fread("data/derived_dhs/survey_registry.csv"); setup <- fread("data/derived_mics/survey_setup.csv")
dirs <- c(DHS = cfg$output_dir, MICS = "data/derived_mics/cbh_build")
man <- rbindlist(lapply(names(dirs), function(k) { m <- as.data.table(readRDS(file.path(dirs[[k]], "manifest.rds"))$manifest)
  m[status == "built", .(survey, programme = k, file = file.path(dirs[[k]], file))] }))
stopifnot(!anyDuplicated(man$survey), all(file.exists(man$file)))

# Birth month reported: DHS b10 / MICS BH4F codes 1, 2 and 7 (month and year; month and age, year imputed; month only),
# stored as codes (MICS, some DHS) or as their labels (DHS recodes, e.g. "month and year - information complete").
month_given <- function(v) { if (is.character(v) || is.factor(v)) { l <- tolower(trimws(as.character(v))); !is.na(l) & startsWith(l, "month") }
  else { v <- as.integer(zap_labels(v)); !is.na(v) & v %in% c(1L, 2L, 7L) } }
# Age at death flagged by the survey (DHS b13, MICS BH9F): any code but 0 / "no flag".
age_flagged <- function(v) { if (is.character(v) || is.factor(v)) { l <- tolower(trimws(as.character(v))); !is.na(l) & l != "no flag" }
  else { v <- as.integer(zap_labels(v)); !is.na(v) & v != 0L } }

one <- function(i) {
  s <- man$survey[i]; mics <- man$programme[i] == "MICS"
  b <- unique(as.data.table(readRDS(man$file[i])$data)[, .(child_id, country, birth_cmc, interview_cmc, cmc_offset_months)])
  stopifnot(!anyDuplicated(b$child_id))
  row <- as.integer(sub("^.*:c:", "", b$child_id)); stopifnot(!anyNA(row))
  if (mics) {
    rec <- readRDS(file.path("data/derived_mics/recodes", paste0(s, ".rds")))
    f <- file.path("data/raw/MICS_extracted", setup[svkey == s, folder], "bh.sav"); nm <- names(read_sav(f, n_max = 0))
    raw <- if (length(intersect(c("BH4F", "BH9F", "BH4M"), nm))) read_sav(f, col_select = any_of(c("BH4F", "BH9F", "BH4M"))) else NULL
    stopifnot(is.null(raw) || nrow(raw) == nrow(rec))
    bflag <- if ("BH4F" %in% nm) month_given(raw$BH4F) else if ("BH4M" %in% nm) { v <- as.integer(zap_labels(raw$BH4M)); !is.na(v) & v %in% 1:12 } else rep(NA, nrow(rec))
    bsrc <- if ("BH4F" %in% nm) "BH4F" else if ("BH4M" %in% nm) "BH4M" else "none"
    dflag <- if ("BH9F" %in% nm) age_flagged(raw$BH9F) else rep(NA, nrow(rec))
  } else {
    rec <- cbh_read_recode(registry[svkey == s, local_recode][1])
    bflag <- if ("b10" %in% names(rec)) month_given(rec$b10) else rep(NA, nrow(rec))
    bsrc <- if ("b10" %in% names(rec)) "b10" else "none"
    dflag <- if ("b13" %in% names(rec)) age_flagged(rec$b13) else rep(NA, nrow(rec))
  }
  stopifnot(max(row) <= nrow(rec), all(cbh_num(rec$b3)[row] + b$cmc_offset_months == b$birth_cmc))
  alive <- cbh_decode_category(rec$b5, c("no", "yes"), c(0, 1))[row]
  age <- cbh_death_age(rec$b6, cbh_num(rec$b7))
  b[, `:=`(survey = s, programme = man$programme[i], birth_flag_source = bsrc, birth_month_reported = bflag[row],
           died = as.integer(alive %in% 0), death_age_unit = age$unit[row], death_age_source = age$source[row],
           death_age_days = age$reported_days[row], death_age_lo = age$lo[row], death_age_hi = age$hi[row], death_age_flagged = dflag[row])]
  b
}
message("Reading ", nrow(man), " surveys")
d <- rbindlist(lapply(seq_len(nrow(man)), one))
stopifnot(!anyDuplicated(d$child_id))
d[, `:=`(birth_year = cbh_cmc_year(birth_cmc), birth_month = as.integer((birth_cmc - 1) %% 12 + 1))]
d[died == 0L, c("death_age_unit", "death_age_source", "death_age_days", "death_age_lo", "death_age_hi", "death_age_flagged") :=
  list(NA_character_, NA_character_, NA_real_, NA_real_, NA_real_, NA)]
# Completed months of age at death and its window [lo, hi); the month of death where the age is in days or months.
d[died == 1L, death_age_months_lo := fifelse(death_age_unit %in% "days" & is.finite(death_age_days), floor(death_age_days / 30.4375), death_age_lo)]
d[died == 1L, death_age_months_hi := fifelse(death_age_unit %in% "days" & is.finite(death_age_days), death_age_months_lo + 1, death_age_hi)]
d[died == 1L, death_month_known := death_age_unit %in% c("days", "months", "imputed_months") & death_age_months_hi - death_age_months_lo == 1]
d[died == 1L, `:=`(death_cmc_lo = birth_cmc + death_age_months_lo, death_cmc_hi = birth_cmc + death_age_months_hi - 1)]
d[died == 1L & death_month_known == TRUE, death_cmc := birth_cmc + death_age_months_lo]
d[!is.na(death_cmc), `:=`(death_year = cbh_cmc_year(death_cmc), death_month = as.integer((death_cmc - 1) %% 12 + 1))]
d[, c("death_age_lo", "death_age_hi", "cmc_offset_months") := NULL]
primary_children <- unique(as.character(readRDS(P$data)$data$child_id))
d[, in_primary := child_id %in% primary_children]
stopifnot(sum(d$in_primary) == length(primary_children))
setcolorder(d, c("child_id", "survey", "country", "programme", "in_primary", "interview_cmc", "birth_cmc", "birth_year", "birth_month",
  "birth_month_reported", "birth_flag_source", "died"))
cbh_atomic_rds(d, file.path(private, "child_dates.rds"))

## ---- Reliability (aggregates) ------------------------------------------------------------------------------
d[died == 1L, age_group := fcase(death_age_months_lo < 1, "<1 month", death_age_months_lo < 12, "1-11 months",
  death_age_months_lo < 24, "12-23 months", default = "24-59 months")]
pc <- function(v) round(100 * mean(v), 1)
rs <- d[, .(programme = programme[1], in_primary = any(in_primary), children = .N, deaths = sum(died),
  birth_month_reported_pct = pc(birth_month_reported %in% TRUE), birth_flag_source = birth_flag_source[1],
  deaths_birth_month_reported_pct = pc(birth_month_reported[died == 1L] %in% TRUE),
  deaths_month_known_pct = pc(death_month_known[died == 1L] %in% TRUE),
  deaths_1_23m_month_known_pct = pc(death_month_known[died == 1L & age_group %in% c("<1 month", "1-11 months", "12-23 months")] %in% TRUE),
  deaths_age_flagged_pct = pc(death_age_flagged[died == 1L] %in% TRUE)), by = survey][order(survey)]
cbh_atomic_csv(as.data.frame(rs), file.path(out, "reliability_by_survey.csv"))
ra <- rbind(d[died == 1L, .(sample = "all built surveys", deaths = .N, birth_month_reported_pct = pc(birth_month_reported %in% TRUE),
    death_month_known_pct = pc(death_month_known %in% TRUE), age_in_days_pct = pc(death_age_unit %in% "days"), age_in_months_pct = pc(death_age_unit %in% "months"),
    age_in_years_pct = pc(death_age_unit %in% "years"), age_imputed_pct = pc(death_age_source %in% "b7_imputed_months"), age_flagged_pct = pc(death_age_flagged %in% TRUE)), by = age_group],
  d[died == 1L & in_primary == TRUE, .(sample = "primary sample", deaths = .N, birth_month_reported_pct = pc(birth_month_reported %in% TRUE),
    death_month_known_pct = pc(death_month_known %in% TRUE), age_in_days_pct = pc(death_age_unit %in% "days"), age_in_months_pct = pc(death_age_unit %in% "months"),
    age_in_years_pct = pc(death_age_unit %in% "years"), age_imputed_pct = pc(death_age_source %in% "b7_imputed_months"), age_flagged_pct = pc(death_age_flagged %in% TRUE)), by = age_group])
ra <- ra[order(sample, match(age_group, c("<1 month", "1-11 months", "12-23 months", "24-59 months")))]
cbh_atomic_csv(as.data.frame(ra), file.path(out, "reliability_by_age.csv"))
files <- c(man$file, P$data, "R_cbh/child_dates/01_child_dates.R", "R_cbh/R/child_bands.R")
cbh_atomic_csv(data.frame(file = files, md5 = vapply(files, cbh_file_hash, "")), file.path(out, "provenance.csv"))
print(ra)
message(format(nrow(d), big.mark = ","), " children (", format(sum(d$in_primary), big.mark = ","), " in the primary sample), ",
  format(sum(d$died), big.mark = ","), " deaths, from ", nrow(man), " surveys: ", private, "/child_dates.rds")
