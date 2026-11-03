#!/usr/bin/env Rscript
# Prepared dataset of the Snow-unit primary (ported from the analysis project's R_cbh/snow_units/09_assemble.R).
#   records:  the analysis units of R_cbh/snow/08_units.R (every eligible child-band record placed in the Snow et al.
#             polygons; merge rule: one unit per record, w = 1; national covariates and child HIV incidence as in v9);
#   exposure: MAP PfPR2-10 of the record's unit in its band-entry year: the population-weighted mean over the unit's
#             endemic polygons (R_cbh/snow/02_pfpr_polygons.R), identical to an extraction over their union;
#   regional covariates: the 13 v9 covariates of each (survey, unit) from the recodes (R_cbh/snow/09, 10), then the v9
#             fallbacks in the v9 order: national WUENIC DTP3/measles for the survey year (cbh_unicef_fill), then the
#             within-survey mean of the units with a value, variable by variable (weighted by the units' records);
#   national: the declared substitutions of R_cbh/primary/national_substitutions.R: South Sudan's GDP per capita,
#             health expenditure per capita and political stability for band-entry years before independence (2011)
#             are Sudan's for the same year, from the cbh_config()$annual_panels files; its child HIV incidence is its
#             own; and the declared fills of R_cbh/primary/national_interpolations.R: political stability in 2001, a
#             year without a WGI round, is the mean of the country's 2000 and 2002 values, and health expenditure in
#             2024, not yet published, is the country's 2023 value;
#   unit:     region = survey : unit (the analogue of the v9 survey-region random effect).
# Complete cases on the v9 requirements; z-scores as in v9 (the merge rule gives one row per record, w = 1).
# Writes the prepared dataset (private) in the layout of v9's preparation, and summaries in the result folder:
# prepared_sample.csv, prepared_selection_by_survey.csv, covariate_scaling.csv, covariate_fallbacks.csv,
# national_substitutions.csv (one row per substituted country and covariate; header only when none applies),
# national_interpolations.csv (one row per filled covariate, country and year),
# complete_case_losses.csv (first missing input) and preparation_provenance.csv.
source("R_cbh/load_pipeline.R"); source("R_cbh/covariates/unicef.R"); source("R_cbh/primary/specification.R"); source("R_cbh/primary/settings.R")
source("R_cbh/primary/national_substitutions.R"); source("R_cbh/primary/national_interpolations.R")
source("R_cbh/snow/R/settings.R")
suppressPackageStartupMessages(library(data.table))
settings <- cbh_primary_settings()
S <- snow_settings(settings$snow_variant)
stopifnot(identical(settings$unit, "snow"))
# The unit scripts take their variant from SNOW_VARIANT; a different one set here would mix unit sets.
if (nzchar(Sys.getenv("SNOW_VARIANT")) && !identical(Sys.getenv("SNOW_VARIANT"), S$variant))
  stop("SNOW_VARIANT=", Sys.getenv("SNOW_VARIANT"), " but primary version ", settings$version, " uses Snow variant ", S$variant)
spec <- cbh_primary_regional_spec(settings); regional <- spec$regional; national <- spec$annual; covs <- spec$covariates
stopifnot(length(covs) == 17L)
for (p in c(settings$out, settings$private)) dir.create(p, recursive = TRUE, showWarnings = FALSE)
cfg <- cbh_config()
rel <- function(p) ifelse(startsWith(p, paste0(cfg$root, "/")), substring(p, nchar(cfg$root) + 2L), p)   # repository-relative
rules <- cbh_national_substitutions()
sv <- cbh_substituted_covariates(); stopifnot(setequal(sv$variable, setdiff(national, "log_hiv_incidence")))
src <- c(records = file.path(S$private, "records_units.rds"), dhs = file.path(S$private, "covariates_dhs_long.csv"),
         mics = file.path(S$private, "covariates_mics_long.csv"), pfpr = file.path(S$out, "pfpr", "pfpr_polygon_year.csv"),
         unicef = "data/derived_cbh/regional_adjustment/unicef/country_year_estimates.csv",
         setNames(rel(vapply(sv$panel, function(k) cfg$annual_panels[[k]]$path, "")), sv$panel),   # the substitutions' source panels
         code = "R_cbh/primary/00_prepare_snow.R", spec = "R_cbh/primary/specification.R", snow = "R_cbh/snow/R/settings.R",
         substitutions = "R_cbh/primary/national_substitutions.R", interpolations = "R_cbh/primary/national_interpolations.R")
stopifnot(all(file.exists(src)))
signature <- cbh_hash(list(files = unname(src), hashes = vapply(src, cbh_file_hash, ""), spec = spec, variant = S$variant))
signature_path <- file.path(settings$private, "preparation_signature.rds")
if (file.exists(settings$data) && file.exists(signature_path)) {
  cache <- readRDS(signature_path)
  if (identical(cache$signature, signature) && identical(cache$data_md5, cbh_file_hash(settings$data))) {
    message("Verified current Snow prepared dataset; retaining it."); quit(save = "no", status = 0)
  }
}

rec <- readRDS(src[["records"]])
L <- rbind(fread(src[["dhs"]])[, .(survey, unit, variable, value)], fread(src[["mics"]])[, .(survey, unit, variable, value)])
stopifnot(!anyDuplicated(L[, .(survey, unit, variable)]), all(L$variable %in% regional))

# Regional covariates per (survey, unit), then the v9 fallbacks.
frame <- rec[, .(records = sum(w)), by = .(survey, unit, country, survey_year)]
stopifnot(!anyDuplicated(frame[, .(survey, unit)]))
W <- merge(frame, dcast(L, survey + unit ~ variable, value.var = "value"), by = c("survey", "unit"), all.x = TRUE)
for (v in regional) if (!v %in% names(W)) W[, (v) := NA_real_]
observed <- W[, lapply(.SD, function(x) sum(is.finite(x))), .SDcols = regional]
panel <- cbh_read_csv(src[["unicef"]])
W <- as.data.table(cbh_unicef_fill(as.data.frame(W), panel, c("dtp3_pct", "measles_pct")))
for (v in regional) {
  W[, paste0(v, "_regional_mean_imputed") := !is.finite(get(v)) & any(is.finite(get(v))), by = survey]
  W[, (v) := { x <- get(v); ok <- is.finite(x)
    if (!any(ok)) x else ifelse(ok, x, sum(x[ok] * records[ok]) / sum(records[ok])) }, by = survey]
}
fills <- rbindlist(lapply(regional, function(v) data.table(variable = v, survey_units = nrow(W), observed = observed[[v]],
  wuenic = if (v %in% c("dtp3_pct", "measles_pct")) sum(W[[paste0(v, "_imputed")]]) else 0L,
  survey_mean = sum(W[[paste0(v, "_regional_mean_imputed")]]), still_missing = sum(!is.finite(W[[v]])))))
fwrite(W, file.path(settings$private, "regional_covariates_wide_snow.csv"))
cbh_atomic_csv(fills, file.path(settings$out, "covariate_fallbacks.csv"))

# Exposure: unit PfPR by entry year = population-weighted mean over the unit's polygons.
pf <- fread(src[["pfpr"]])[, .(Admin_ID, year, pfpr2_10, population_weight)]
um <- unique(rec[, .(unit)])[, .(Admin_ID = strsplit(unit, "+", fixed = TRUE)[[1]]), by = unit]
stopifnot(all(um$Admin_ID %in% pf$Admin_ID))
up <- merge(um, pf, by = "Admin_ID", allow.cartesian = TRUE)[, .(pfpr_pct = sum(population_weight * pfpr2_10) / sum(population_weight)), by = .(unit, entry_year = year)]
stopifnot(all(is.finite(up$pfpr_pct)), all(up$pfpr_pct >= 0 & up$pfpr_pct <= 100))   # every unit has a MAP estimate

d <- merge(rec, W[, c("survey", "unit", regional), with = FALSE], by = c("survey", "unit"))
d <- merge(d, up, by = c("unit", "entry_year"), all.x = TRUE)
d[, region := paste(survey, unit, sep = ":")]

# Declared national substitutions, before complete cases: the source country's values for the same year replace the
# record's (missing or own) values; every covered record must get one.
ns <- cbh_national_substitute(d$country, d$entry_year, cfg, rules)
own <- lapply(setNames(sv$variable, sv$variable), function(v) is.finite(d[[v]][ns$row]))   # own values replaced
for (v in sv$variable) {
  if (!all(is.finite(ns[[v]]))) stop("No ", v, " in the source panel for ", paste(unique(paste(ns$source_country, ns$year)[!is.finite(ns[[v]])]), collapse = ", "))
  if (nrow(ns)) set(d, ns$row, v, ns[[v]])
}
# Declared fills, after the substitutions, where the record has no value: political stability in a WGI gap year, and
# health expenditure in a carried year.
gi <- which(!is.finite(d$political_stability) & d$entry_year %in% cbh_wgi_gap_years())
gv <- as.numeric(cbh_political_stability_interpolated(as.character(d$country[gi]), d$entry_year[gi], cfg))
if (length(gi)) set(d, gi, "political_stability", gv)
hi <- which(!is.finite(d$log_health_expenditure_pc) & as.character(d$entry_year) %in% names(cbh_health_expenditure_carry_years()))
hv <- as.numeric(cbh_health_expenditure_carried(as.character(d$country[hi]), d$entry_year[hi], cfg))
if (length(hi)) set(d, hi, "log_health_expenditure_pc", hv)
required <-c("death", "age_band", "pfpr_pct", "calendar_year", "band_years", "survey", "country", "region", covs)
ok <- complete.cases(d[, ..required])
for (v in required) if (is.numeric(d[[v]])) ok <- ok & is.finite(d[[v]])
first_missing <- apply(as.matrix(d[!ok, c("pfpr_pct", national, regional), with = FALSE]), 1, function(r) names(r)[which(!is.finite(as.numeric(r)))[1]])
lost <- d[!ok][, missing := first_missing][, .(rows = .N, records = sum(w), deaths = sum(w * death)), by = .(survey, country, missing)][order(survey, missing)]
cbh_atomic_csv(lost, file.path(settings$out, "complete_case_losses.csv"))
# Record of the substitutions: band-entry years, records and deaths covered, own values replaced, and those in the sample.
span <- function(y) if (length(y)) paste(unique(range(y)), collapse = "-") else NA_character_
nsub <- rbindlist(lapply(sv$variable, function(v) data.table(ns[c("country", "source_country", "year")], variable = v, w = d$w[ns$row],
  death = d$death[ns$row], own = own[[v]], kept = ok[ns$row])))[, .(years = span(year), records = sum(w), deaths = sum(w * death),
  own_values_replaced = sum(w[own]), records_in_sample = sum(w[kept]), deaths_in_sample = sum((w * death)[kept])), by = .(country, source_country, variable)]
nsub <- merge(nsub, rules[c("country", "before_year", "note")], by = "country", sort = FALSE)
setcolorder(nsub, c("country", "source_country", "variable", "before_year"))
cbh_atomic_csv(nsub, file.path(settings$out, "national_substitutions.csv"))
# Record of the fills: the value (model scale), records and deaths covered, and those in the sample, by covariate,
# country and year.
fills_rows <- rbind(data.table(row = gi, variable = "political_stability", rule = "mean of the adjacent years", value = gv),
  data.table(row = hi, variable = "log_health_expenditure_pc", rule = "2023 value carried forward", value = hv))
nint <- fills_rows[, .(variable, rule, country = as.character(d$country[row]), year = d$entry_year[row], value, w = d$w[row],
  death = d$death[row], kept = ok[row])][, .(value = value[1], records = sum(w), deaths = sum(w * death),
  records_in_sample = sum(w[kept]), deaths_in_sample = sum((w * death)[kept])), by = .(variable, rule, country, year)][order(variable, country, year)]
cbh_atomic_csv(nint, file.path(settings$out, "national_interpolations.csv"))
d <- d[ok]
# Surveys of a reference version (gadm_merge: those of the Snow v14 primary): no other survey may enter; any lost is listed.
if (!is.null(settings$survey_reference)) {
  ref <- fread(settings$survey_reference)
  added <- setdiff(unique(as.character(d$survey)), ref$survey)
  if (length(added)) stop("Surveys outside the reference sample (", settings$survey_reference, "): ", paste(added, collapse = ", "))
  cbh_atomic_csv(data.table(survey = ref$survey, country = ref$country, in_sample = ref$survey %in% d$survey),
                 file.path(settings$out, "surveys_vs_reference.csv"))
}
ages <- cbh_config()$age_bands$age_band
d[, age_band := factor(age_band, levels = ages)]
for (v in c("survey", "country", "region")) d[, (v) := factor(get(v))]
stopifnot(all(d$w > 0 & d$w <= 1), d[, sum(w), by = .(child_id, age_band)]$V1 <= 1 + 1e-9, all(table(d$age_band) > 0),
          all(d$death %in% 0:1), all(d$band_years > 0))
stopifnot(all(d$w == 1), !anyDuplicated(d[, .(child_id, age_band)]))
scaling <- data.frame(variable = covs, mean = vapply(covs, function(v) mean(d[[v]]), 0),
  sd = vapply(covs, function(v) sd(d[[v]]), 0), row.names = NULL)
stopifnot(all(is.finite(scaling$sd) & scaling$sd > 0))
for (i in seq_len(nrow(scaling))) d[, (paste0("z_", scaling$variable[i])) := (get(scaling$variable[i]) - scaling$mean[i]) / scaling$sd[i]]
keep <- unique(c(required, paste0("z_", covs), "child_id", "entry_year", "survey_year", "regkey", "unit", "n_polygons", "rule", "w"))
d <- as.data.frame(d[, ..keep])

counts <- data.frame(records = sum(d$w), children = uniqueN(d$child_id), deaths = sum(d$w * d$death), regions = nlevels(d$region),
  surveys = nlevels(d$survey), countries = nlevels(d$country), rows = nrow(d),
  polygons = uniqueN(unlist(strsplit(unique(as.character(d$unit)), "+", fixed = TRUE))),
  merged_units = uniqueN(d$region[d$n_polygons > 1]))
selection <- as.data.frame(as.data.table(d)[, .(records = sum(w), deaths = sum(w * death), units = uniqueN(region)), by = .(survey = as.character(survey), country = as.character(country))][order(survey)])
prepared <- list(signature = signature, data = d, scaling = scaling, specification = spec, counts = counts, selection = selection,
  national_substitutions = as.data.frame(nsub),
  source_hashes = data.frame(file = unname(src), md5 = vapply(src, cbh_file_hash, ""), row.names = NULL), snow = S)
cbh_atomic_rds(prepared, settings$data)
cbh_atomic_rds(list(signature = signature, data_md5 = cbh_file_hash(settings$data)), signature_path)
cbh_atomic_csv(counts, file.path(settings$out, "prepared_sample.csv"))
cbh_atomic_csv(scaling, file.path(settings$out, "covariate_scaling.csv"))
cbh_atomic_csv(selection, file.path(settings$out, "prepared_selection_by_survey.csv"))
cbh_atomic_csv(prepared$source_hashes, file.path(settings$out, "preparation_provenance.csv"))
print(counts); print(fills)
for (k in unique(nsub$country)) with(nsub[nsub$country == k, ], message(sprintf("National substitution: %s band-entry years %s (before %d) take %s's %s: %s records, %s deaths (%s records and %s deaths in the sample)",
  k, years[1], before_year[1], source_country[1], paste(variable, collapse = ", "), format(records[1], big.mark = ","), format(deaths[1], big.mark = ","),
  format(records_in_sample[1], big.mark = ","), format(deaths_in_sample[1], big.mark = ","))))
for (v in unique(nint$variable)) with(nint[nint$variable == v, ], message(sprintf("National fill: %s in %s (%s) for %d countries: %s records, %s deaths (%s records and %s deaths in the sample)",
  v, paste(unique(year), collapse = ", "), rule[1], length(unique(country)), format(sum(records), big.mark = ","), format(sum(deaths), big.mark = ","),
  format(sum(records_in_sample), big.mark = ","), format(sum(deaths_in_sample), big.mark = ","))))
message("Snow-unit prepared dataset written (", S$variant, ")")
