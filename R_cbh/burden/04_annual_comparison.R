#!/usr/bin/env Rscript
# Figure 5 inputs and annual point estimates. No model refitting or downloads.
# Malaria-attributable mortality rates are estimated from two all-cause sources (main analysis from 27 October
# 2026, user request): IHME (country_estimates_2000_2024.csv, unchanged) and UN IGME, side by side in the
# source_*_2000_2024.csv files.
# National PfPR is MAP's own national (admin-0) estimate of the configured release (cbh_map_national; 1 November 2026,
# author request), as in R_cbh/burden/00_national_inputs.R. Run from project root; --audit-only checks the inputs only.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(mgcv))
settings <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION","regional_mics"))
out <- file.path(settings$out, "annual_comparison")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
years <- 2000:2024
ages <- cbh_config()$age_bands$age_band
allcause_path <- list.files("data", pattern = "2026-09-09 10-58-22[.]csv$", full.names = TRUE)
stopifnot(length(allcause_path) == 1)
malaria_path <- "data/ihme_malaria_u5_deaths_by_age_country_year.csv"
who_path <- "data/external/figure5/unicef_cacode_u5_malaria_2000_2024.csv"
igme_path <- "data/unicef/fusion_GLOBAL_DATAFLOW_UNICEF_1.0_igme_wpp_subset.csv"
component_path <- file.path(settings$private, "pfpr_components.rds")
baseline_path <- file.path(settings$out, "burden/country_totals.csv")
map_path <- cbh_config()$map_national
inputs <- c(allcause_path, malaria_path, who_path, "data/external/figure5/source.json", igme_path,
  component_path, baseline_path, map_path, "R_cbh/R/external_data.R", "R_cbh/00_config.R",
  file.path(settings$out, c("fit_manifest.csv", "fit_diagnostics.csv")))
stopifnot(all(file.exists(inputs)))
previous <- fread(baseline_path)
countries <- unique(previous[status == "estimated", .(iso3, country)])
setorder(countries, iso3)
stopifnot(nrow(countries) == 42, all(previous[status == "estimated", .N, by = year]$N == 42))
components <- readRDS(component_path)
manifest <- fread(file.path(settings$out, "fit_manifest.csv"))
diagnostics <- fread(file.path(settings$out, "fit_diagnostics.csv"))
stopifnot(length(components) == 7, all(diagnostics$converged), all(diagnostics$input_verified))
for (piece in components) stopifnot(identical(piece$model_md5,
  manifest$md5[match(piece$fit_id, manifest$fit_id)]))

read_ihme <- function(path, cause) {
  z <- fread(path)[Year %in% years & Sex == "Both" & Condition == cause & Measure == "Deaths"]
  z[, iso3 := countrycode::countrycode(Location, "country.name", "iso3c", warn = FALSE)]
  stopifnot(!anyNA(z$iso3), all(is.finite(z$Value)), all(z$Value >= 0))
  cbh_unique(as.data.frame(z), c("iso3", "Year", "Age", "Unit"), path)
  z
}
allcause <- read_ihme(allcause_path, "All causes")
malaria <- read_ihme(malaria_path, "Malaria")[Age == "Under 5"]
who <- fread(who_path)
stopifnot(all(who$INDICATOR == "DEATHS"), all(who$CAUSE_OF_DEATH == "MALARIA"),
  all(who$SEX == "_T"), all(who$AGE_GROUP == "Y0T4"), all(who$UNIT_MEASURE == "D"),
  all(who$SERIES_NAME == "CA CODE"))
who <- who[REF_AREA %in% countries$iso3 & TIME_PERIOD %in% years,
  .(iso3 = REF_AREA, year = TIME_PERIOD, who_cacode_deaths = OBS_VALUE,
    who_cacode_lower90 = LOWER_BOUND, who_cacode_upper90 = UPPER_BOUND)]
cbh_unique(as.data.frame(who), c("iso3", "year"), "WHO/UNICEF CA-CODE")
stopifnot(nrow(who) == 42 * length(years), all(is.finite(who$who_cacode_deaths)),
  all(who$who_cacode_deaths >= 0))
# UN IGME all-cause deaths (under 5, <1 month, 1-11 months, 1-4 years) and UN WPP population under 5 (thousands),
# the population IGME itself uses (committed extract of the UNICEF data dump, R_inputs/trim_unicef_fusion.R).
igme <- fread(igme_path)[REF_AREA %in% countries$iso3 & TIME_PERIOD %in% years]
stopifnot(all(igme$SEX == "_T"), all(igme$DATA_SOURCE[igme$INDICATOR != "DM_POP_U5"] == "UN_IGME"),
  all(igme$UNIT_MEASURE == fifelse(igme$INDICATOR == "DM_POP_U5", "PS", "D")),
  all(igme$UNIT_MULTIPLIER[igme$INDICATOR == "DM_POP_U5"] == 3), all(is.na(igme$UNIT_MULTIPLIER[igme$INDICATOR != "DM_POP_U5"])),
  all(is.finite(igme$OBS_VALUE)), all(igme$OBS_VALUE >= 0))
cbh_unique(as.data.frame(igme), c("REF_AREA", "INDICATOR", "TIME_PERIOD"), igme_path)
iw <- dcast(igme, REF_AREA + TIME_PERIOD ~ INDICATOR, value.var = "OBS_VALUE")
setnames(iw, c("REF_AREA", "TIME_PERIOD", "DM_POP_U5"), c("iso3", "year", "wpp_population_u5_thousands"))
iw[, wpp_population_u5 := 1e3 * wpp_population_u5_thousands]
stopifnot(nrow(iw) == 42 * length(years), !anyNA(iw), all(iw$wpp_population_u5 > 0),
  max(abs((iw$CME_TMM0 + iw$CME_TMM1T11 + iw$CME_TMY1T4) / iw$CME_TMY0T4 - 1)) < 1e-6)

wide <- dcast(allcause, iso3 + Location + Year + Age ~ Unit, value.var = "Value")
wide[, implied_person_years := Number / `Rate (per 100,000)` * 1e5]
stopifnot(all(is.finite(wide$implied_person_years)), all(wide$implied_person_years > 0))
leaf_ages <- c("0 to 6 days (early neonatal)", "7 to 27 days (late neonatal)",
  "1 to 5 months", "6-11 months", "12 to 23 months", "2 to 4")
leaf_sums <- wide[Age %in% leaf_ages, .(leaf_deaths = sum(Number),
  leaf_person_years = sum(implied_person_years), age_rows = .N), by = .(iso3, Year)]
denominators <- merge(wide[Age == "Under 5", .(iso3, Year,
  allcause_deaths = Number, under5_person_years = implied_person_years)], leaf_sums,
  by = c("iso3", "Year"))
denominators[, `:=`(death_sum_relative_error = leaf_deaths / allcause_deaths - 1,
  person_year_sum_relative_error = leaf_person_years / under5_person_years - 1)]
stopifnot(all(denominators$age_rows == 6),
  max(abs(denominators$death_sum_relative_error)) < 1e-5)
m <- dcast(malaria, iso3 + Year ~ Unit, value.var = "Value")
m[, malaria_native_person_years := fifelse(`Rate (per 100,000)` > 0,
  Number / `Rate (per 100,000)` * 1e5, NA_real_)]
setnames(m, c("Year", "Number", "Rate (per 100,000)"),
  c("year", "ihme_malaria_deaths", "ihme_native_rate_per100000"))
setnames(denominators, "Year", "year")
denominators <- merge(denominators, m, by = c("iso3", "year"), all.x = TRUE)
denominators[, malaria_denominator_relative_difference := malaria_native_person_years / under5_person_years - 1]
cbh_atomic_csv(denominators, file.path(out, "denominator_audit.csv"))

# Check every required country-year, never allow a changing annual country set.
grid <- CJ(iso3 = countries$iso3, year = years)
coverage <- merge(grid, denominators, by = c("iso3", "year"), all.x = TRUE)
coverage <- merge(coverage, who, by = c("iso3", "year"), all.x = TRUE)
coverage[, complete := is.finite(allcause_deaths) & is.finite(under5_person_years) &
  is.finite(ihme_malaria_deaths) & is.finite(who_cacode_deaths)]
cbh_atomic_csv(coverage, file.path(out, "country_year_input_audit.csv"))
stopifnot(nrow(coverage) == 42 * length(years), all(coverage$complete))
nat <- as.data.table(cbh_map_national(countries$iso3, years))
map_audit <- nat[, .(country_years = .N, years = paste(range(year), collapse = "-"), map_release = map_release[1],
  min_pfpr_pct = min(pfpr_pct), max_pfpr_pct = max(pfpr_pct), lci_zero = sum(pfpr_lci_pct == 0)), by = iso3]
stopifnot(nrow(nat) == nrow(grid), setequal(nat$iso3, countries$iso3), all(map_audit$country_years == length(years)))
cbh_atomic_csv(map_audit, file.path(out, "map_input_audit.csv"))
cbh_atomic_csv(countries, file.path(out, "included_countries.csv"))
metadata <- rbindlist(lapply(list(allcause, malaria), function(z)
  unique(z[, .(Condition, Data_Suite, Data_Type, Data_Type_Level)])))
cbh_atomic_csv(metadata, file.path(out, "ihme_release_metadata.csv"))
message("Input audit passed: 42 countries x ", length(years), " years for all three death series and MAP national PfPR (release ",
  cbh_config()$map_release, ").")
if ("--audit-only" %in% commandArgs(TRUE)) quit(save = "no", status = 0)

# MAP's national estimates (read above). The raster-coverage field of the former aggregation has no counterpart.
nat[, `:=`(map_population_coverage = NA_real_, population_weight_year = NA_integer_)]
stopifnot(all(is.finite(nat$pfpr_pct)), all(nat$pfpr_pct >= 0 & nat$pfpr_pct <= 100))
cbh_atomic_csv(nat, file.path(out, "national_pfpr_2000_2024.csv"))

bands <- rbindlist(lapply(seq_len(nrow(grid)), function(i) {
  iso <- grid$iso3[i]; y <- grid$year[i]
  z <- wide[iso3 == iso & Year == y & Age %in% leaf_ages]
  z <- z[match(leaf_ages, Age)]
  stopifnot(nrow(z) == 6, !anyNA(z$Age))
  data.table(iso3 = iso, year = y, age_band = ages,
    allcause_deaths = c(sum(z$Number[1:2]), z$Number[3:5], rep(z$Number[6] / 3, 3)),
    age_person_years = c(sum(z$implied_person_years[1:2]), z$implied_person_years[3:5],
      rep(z$implied_person_years[6] / 3, 3)))
}))
bands <- merge(bands, nat, by = c("iso3", "year"))
bands <- rbindlist(lapply(seq_along(ages), function(i) {
  z <- bands[age_band == ages[i]]
  piece <- components[[paste0("map_full_age_", i)]]
  L <- PredictMat(piece$smooth, data.frame(pfpr_pct = rep(0, nrow(z)))) -
    PredictMat(piece$smooth, data.frame(pfpr_pct = z$pfpr_pct))
  z[, log_hr_zero_vs_current := drop(L %*% piece$coef)]
  z[, attributable_fraction := -expm1(log_hr_zero_vs_current)]
  z[, attributable_deaths := allcause_deaths * attributable_fraction]
  z[, `:=`(zero_below_observed_support = piece$support[1] > 0,
    current_outside_observed_support = pfpr_pct < piece$support[1] | pfpr_pct > piece$support[4])]
  z
}))
stopifnot(all(is.finite(bands$attributable_deaths)))
cbh_atomic_csv(bands, file.path(out, "country_age_estimates_2000_2024.csv"))
totals <- bands[, .(model_deaths = sum(attributable_deaths),
  any_current_outside_support = any(current_outside_observed_support)), by = .(iso3, year)]
totals <- merge(totals, coverage, by = c("iso3", "year"))
totals <- merge(totals, nat, by = c("iso3", "year"))
totals <- merge(totals, countries, by = "iso3")
for (s in c("model", "ihme_malaria", "who_cacode"))
  totals[, (paste0(s, "_rate_per100000")) := get(paste0(s, "_deaths")) / under5_person_years * 1e5]
setorder(totals, year, iso3)
cbh_atomic_csv(totals, file.path(out, "country_estimates_2000_2024.csv"))

# Numerical regression check against all 126 existing primary country estimates.
check <- merge(totals, previous[status == "estimated", .(iso3, year,
  previous_deaths = attributable_under5_deaths, previous_pfpr = pfpr_pct,
  previous_ihme = ihme_malaria_deaths)], by = c("iso3", "year"))
check[, `:=`(death_difference = model_deaths - previous_deaths,
  pfpr_difference = pfpr_pct - previous_pfpr,
  ihme_difference = ihme_malaria_deaths - previous_ihme)]
stopifnot(nrow(check) == 126, max(abs(check$death_difference)) < .01,
  max(abs(check$pfpr_difference)) < 1e-6, max(abs(check$ihme_difference)) < 1e-6)
cbh_atomic_csv(check[, .(iso3, year, death_difference, pfpr_difference, ihme_difference)],
  file.path(out, "agreement_with_existing_primary.csv"))
annual <- totals[, .(countries = .N, under5_person_years = sum(under5_person_years),
  model_deaths = sum(model_deaths), ihme_malaria_deaths = sum(ihme_malaria_deaths),
  who_cacode_deaths = sum(who_cacode_deaths)), by = year]
for (s in c("model", "ihme_malaria", "who_cacode"))
  annual[, (paste0(s, "_rate_per100000")) := get(paste0(s, "_deaths")) / under5_person_years * 1e5]
stopifnot(nrow(annual) == length(years), all(annual$countries == 42))
cbh_atomic_csv(annual, file.path(out, "annual_totals_2000_2024.csv"))

# Malaria-attributable mortality rates by all-cause source. Both sources take the same age-band attributable
# fractions (national PfPR above) times the source's all-cause deaths by band, divided by the source's under-five
# person-years (IHME: implied by its deaths and rates; UN IGME: UN WPP population under 5). IGME's three age groups
# are split across the model bands by the primary sample's observed deaths within each group, pooled over
# countries and years (user decision, 27 October 2026).
igme_group <- setNames(c("CME_TMM0", "CME_TMM1T11", "CME_TMM1T11", rep("CME_TMY1T4", 4)), ages)
fits <- match(paste0("map_full_age_", seq_along(ages)), diagnostics$fit_id)
stopifnot(!anyNA(fits), identical(diagnostics$age_band[fits], ages))
split <- data.table(age_band = ages, igme_indicator = unname(igme_group), sample_deaths = diagnostics$deaths[fits])
split[, within_group_share := sample_deaths / sum(sample_deaths), by = igme_indicator]
cbh_atomic_csv(split, file.path(out, "igme_age_split.csv"))
groups <- melt(iw, id.vars = c("iso3", "year"), measure.vars = c("CME_TMM0", "CME_TMM1T11", "CME_TMY1T4"),
  variable.name = "igme_indicator", value.name = "group_deaths", variable.factor = FALSE)
ib <- merge(groups, split[, .(age_band, igme_indicator, within_group_share)], by = "igme_indicator", allow.cartesian = TRUE)
ib[, allcause_deaths := group_deaths * within_group_share]
ib <- merge(ib, iw[, .(iso3, year, wpp_population_u5)], by = c("iso3", "year"))
ib <- merge(ib, bands[, .(iso3, year, age_band, attributable_fraction)], by = c("iso3", "year", "age_band"))
stopifnot(nrow(ib) == nrow(bands), abs(sum(ib$allcause_deaths) / sum(iw$CME_TMY0T4) - 1) < 1e-9)
# Each band's death rate is its deaths over the source's person-years for that band (IHME) or under 5 (IGME).
source_bands <- rbind(
  bands[, .(source = "IHME", iso3, year, age_band, allcause_deaths, rate_denominator = age_person_years, attributable_fraction)],
  ib[, .(source = "UN IGME", iso3, year, age_band, allcause_deaths, rate_denominator = wpp_population_u5, attributable_fraction)])
person_years <- rbind(totals[, .(source = "IHME", iso3, year, under5_person_years)],
  iw[, .(source = "UN IGME", iso3, year, under5_person_years = wpp_population_u5)])
stopifnot(all(source_bands$allcause_deaths > 0), all(source_bands$rate_denominator > 0))

# Crisis years (user decision, 27 October 2026). The attributable fraction of deaths in a mortality crisis (conflict,
# famine, drought) need not resemble that of other years, so crisis years take crisis-free values. A crisis year is a
# country-year whose all-cause under-five death rate in that source is more than 25% above its crisis-free trend: the
# log-linear interpolation between the nearest earlier and later non-crisis years (the nearest non-crisis year at
# either end of the series), found iteratively from the largest excess. A rule in standard errors of the sources'
# uncertainty intervals was rejected: IHME's narrow intervals flag ordinary declines, and IGME's wide ones in conflict
# settings miss multi-year crises. In a crisis year each age band's death rate is replaced by the same interpolation
# of that band's rate, times the year's reported person-years.
crisis_ratio <- 1.25
crisis_trend <- function(y, crisis, t) {
  ok <- setdiff(which(!crisis), t); lo <- ok[ok < t]; hi <- ok[ok > t]
  if (length(lo) && length(hi)) {
    lo <- max(lo); hi <- min(hi); y[lo] + (y[hi] - y[lo]) * (t - lo) / (hi - lo)
  } else y[if (length(lo)) max(lo) else min(hi)]
}
find_crises <- function(y) {
  crisis <- rep(FALSE, length(y))
  repeat {
    excess <- vapply(seq_along(y), function(t) if (crisis[t]) -Inf else y[t] - crisis_trend(y, crisis, t), 0)
    t <- which.max(excess)
    if (excess[t] <= log(crisis_ratio)) return(crisis)
    crisis[t] <- TRUE
  }
}
u5 <- merge(source_bands[, .(allcause_deaths = sum(allcause_deaths)), by = .(source, iso3, year)], person_years,
  by = c("source", "iso3", "year"))
setorder(u5, source, iso3, year)
stopifnot(nrow(u5) == 2 * nrow(grid), all(u5[, identical(year, years), by = .(source, iso3)]$V1))
u5[, crisis_year := find_crises(log(allcause_deaths / under5_person_years)), by = .(source, iso3)]
source_bands <- merge(source_bands, u5[, .(source, iso3, year, crisis_year)], by = c("source", "iso3", "year"))
setorder(source_bands, source, iso3, age_band, year)
source_bands[, allcause_deaths_reported := allcause_deaths]
source_bands[, allcause_deaths := {
  y <- log(allcause_deaths / rate_denominator); z <- allcause_deaths
  for (t in which(crisis_year)) z[t] <- exp(crisis_trend(y, crisis_year, t)) * rate_denominator[t]
  z
}, by = .(source, iso3, age_band)]
source_bands[, attributable_deaths := allcause_deaths * attributable_fraction]
stopifnot(all(is.finite(source_bands$allcause_deaths)),
  all(source_bands[crisis_year == FALSE, allcause_deaths == allcause_deaths_reported]))
setorder(source_bands, source, year, iso3, age_band)
cbh_atomic_csv(source_bands[, .(source, iso3, year, age_band, crisis_year, allcause_deaths_reported, allcause_deaths,
  rate_denominator, attributable_fraction, attributable_deaths)], file.path(out, "source_age_estimates_2000_2024.csv"))
rates <- source_bands[, .(crisis_year = crisis_year[1], allcause_deaths_reported = sum(allcause_deaths_reported),
  allcause_deaths = sum(allcause_deaths), attributable_deaths = sum(attributable_deaths)), by = .(source, iso3, year)]
rates <- merge(rates, person_years, by = c("source", "iso3", "year"))
rates <- merge(rates, nat[, .(iso3, year, pfpr_pct, pfpr_lci_pct, pfpr_uci_pct)], by = c("iso3", "year"))
rates <- merge(rates, countries, by = "iso3")
rates[, `:=`(allcause_rate_per1000_reported = 1000 * allcause_deaths_reported / under5_person_years,
  allcause_rate_per1000 = 1000 * allcause_deaths / under5_person_years,
  malaria_rate_per1000 = 1000 * attributable_deaths / under5_person_years,
  malaria_fraction = attributable_deaths / allcause_deaths)]
setcolorder(rates, c("source", "iso3", "country", "year"))
setorder(rates, source, year, iso3)
# Outside crisis years the IHME rows reproduce the existing IHME-based country estimates.
check_ihme <- merge(rates[source == "IHME"], totals[, .(iso3, year, model_deaths, u5_deaths = allcause_deaths)], by = c("iso3", "year"))
stopifnot(nrow(rates) == 2 * nrow(grid), nrow(check_ihme) == nrow(grid),
  max(abs(check_ihme[crisis_year == FALSE]$attributable_deaths - check_ihme[crisis_year == FALSE]$model_deaths)) < 1e-6,
  max(abs(check_ihme$allcause_deaths_reported / check_ihme$u5_deaths - 1)) < 1e-5,
  all(is.finite(rates$malaria_rate_per1000)), all(rates$malaria_fraction >= 0 & rates$malaria_fraction <= 1))
cbh_atomic_csv(rates, file.path(out, "source_country_rates_2000_2024.csv"))
crises <- rates[crisis_year == TRUE, .(source, iso3, country, year, allcause_rate_per1000_reported, allcause_rate_per1000,
  excess_ratio = allcause_deaths_reported / allcause_deaths, allcause_deaths_reported, allcause_deaths,
  crisis_deaths_removed = allcause_deaths_reported - allcause_deaths)]
setorder(crises, source, country, year)
cbh_atomic_csv(crises, file.path(out, "crisis_years.csv"))
# 42-country population-weighted averages: PfPR weighted by the UN WPP population under 5 (the same in both sources),
# mortality rates by the source's child-years (total deaths over total child-years).
wpp <- iw[, .(iso3, year, wpp_population_u5)]
source_annual <- merge(rates, wpp, by = c("iso3", "year"))[, .(countries = .N, crisis_years = sum(crisis_year),
  under5_person_years = sum(under5_person_years), allcause_deaths_reported = sum(allcause_deaths_reported),
  allcause_deaths = sum(allcause_deaths), attributable_deaths = sum(attributable_deaths),
  pfpr_pct_wpp_weighted = sum(pfpr_pct * wpp_population_u5) / sum(wpp_population_u5)),
  by = .(source, year)]
source_annual[, `:=`(allcause_rate_per1000 = 1000 * allcause_deaths / under5_person_years,
  malaria_rate_per1000 = 1000 * attributable_deaths / under5_person_years, malaria_fraction = attributable_deaths / allcause_deaths)]
setorder(source_annual, source, year)
stopifnot(nrow(source_annual) == 2 * length(years), all(source_annual$countries == 42))
cbh_atomic_csv(source_annual, file.path(out, "source_annual_rates_2000_2024.csv"))
inputs <- unique(c(inputs, "R_cbh/burden/04_annual_comparison.R", "R_cbh/primary/settings.R"))
cbh_atomic_csv(data.frame(file = inputs, md5 = vapply(inputs, cbh_file_hash, "")),
  file.path(out, "input_provenance.csv"))
print(annual[year %in% c(2000, 2004, 2005, 2015, 2024)])
