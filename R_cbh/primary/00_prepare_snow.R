#!/usr/bin/env Rscript
# Prepared dataset of the Snow-unit primary (ported from the analysis project's R_cbh/snow_units/09_assemble.R).
#   records:  the analysis units of R_cbh/snow/08_units.R (every eligible child-band record placed in the Snow et al.
#             polygons; merge rule: one unit per record, w = 1; national covariates and child HIV incidence as in v9);
#   exposure: MAP PfPR2-10 of the record's unit in its band-entry year: the population-weighted mean over the unit's
#             endemic polygons (R_cbh/snow/02_pfpr_polygons.R), identical to an extraction over their union;
#   regional covariates: the 13 v9 covariates of each (survey, unit) from the recodes (R_cbh/snow/09, 10), then the v9
#             fallbacks in the v9 order: national WUENIC DTP3/measles for the survey year (cbh_unicef_fill), then the
#             within-survey mean of the units with a value, variable by variable (weighted by the units' records in the
#             primary; arithmetic, as in the analysis project, in the reproduction);
#   national: the declared substitutions of R_cbh/primary/national_substitutions.R (merge variant only; the reproduction
#             keeps the analysis project's inputs): South Sudan's GDP per capita, health expenditure per capita and
#             political stability for band-entry years before independence (2011) are Sudan's for the same year, from
#             the cbh_config()$annual_panels files; its child HIV incidence is its own;
#   unit:     region = survey : unit (the analogue of the v9 survey-region random effect).
# Complete cases on the v9 requirements; z-scores as in v9 (weighted by w only in the split reproduction).
# Writes the prepared dataset (private) in the layout of 00_prepare_regional.R, and summaries in the result folder:
# prepared_sample.csv, prepared_selection_by_survey.csv, covariate_scaling.csv, covariate_fallbacks.csv,
# national_substitutions.csv (one row per substituted country and covariate; header only when none applies),
# complete_case_losses.csv (first missing input) and preparation_provenance.csv.
source("R_cbh/load_pipeline.R"); source("R_cbh/covariates/unicef.R"); source("R_cbh/primary/specification.R"); source("R_cbh/primary/settings.R")
source("R_cbh/primary/national_substitutions.R")
source("R_cbh/snow/R/settings.R")
suppressPackageStartupMessages(library(data.table))
settings <- cbh_primary_settings()
S <- snow_settings(settings$snow_variant)
stopifnot(identical(settings$unit, "snow"))
spec <- cbh_primary_regional_spec(settings); regional <- spec$regional; national <- spec$annual; covs <- spec$covariates
stopifnot(length(covs) == 17L)
for (p in c(settings$out, settings$private)) dir.create(p, recursive = TRUE, showWarnings = FALSE)
cfg <- cbh_config()
rel <- function(p) ifelse(startsWith(p, paste0(cfg$root, "/")), substring(p, nchar(cfg$root) + 2L), p)   # repository-relative
rules <- cbh_national_substitutions(); if (!identical(S$variant, "merge")) rules <- rules[0, ]
sv <- cbh_substituted_covariates(); stopifnot(setequal(sv$variable, setdiff(national, "log_hiv_incidence")))
src <- c(records = file.path(S$private, "records_units.rds"), dhs = file.path(S$private, "covariates_dhs_long.csv"),
         mics = file.path(S$private, "covariates_mics_long.csv"), pfpr = file.path(S$out, "pfpr", "pfpr_polygon_year.csv"),
         unicef = "data/derived_cbh/regional_adjustment/unicef/country_year_estimates.csv",
         setNames(rel(vapply(sv$panel, function(k) cfg$annual_panels[[k]]$path, "")), sv$panel),   # the substitutions' source panels
         code = "R_cbh/primary/00_prepare_snow.R", spec = "R_cbh/primary/specification.R", snow = "R_cbh/snow/R/settings.R",
         substitutions = "R_cbh/primary/national_substitutions.R")
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
weighted_fallback <- isTRUE(S$rule_fixes)
for (v in regional) {
  W[, paste0(v, "_regional_mean_imputed") := !is.finite(get(v)) & any(is.finite(get(v))), by = survey]
  W[, (v) := { x <- get(v); ok <- is.finite(x)
    if (!any(ok)) x else ifelse(ok, x, if (weighted_fallback) sum(x[ok] * records[ok]) / sum(records[ok]) else mean(x[ok])) }, by = survey]
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
required <- c("death", "age_band", "pfpr_pct", "calendar_year", "band_years", "survey", "country", "region", covs)
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
d <- d[ok]
ages <- cbh_config()$age_bands$age_band
d[, age_band := factor(age_band, levels = ages)]
for (v in c("survey", "country", "region")) d[, (v) := factor(get(v))]
stopifnot(all(d$w > 0 & d$w <= 1), d[, sum(w), by = .(child_id, age_band)]$V1 <= 1 + 1e-9, all(table(d$age_band) > 0),
          all(d$death %in% 0:1), all(d$band_years > 0))
unweighted <- all(d$w == 1)
if (unweighted) stopifnot(!anyDuplicated(d[, .(child_id, age_band)]))
wsd <- function(x, w) sqrt(sum(w * (x - weighted.mean(x, w))^2) / sum(w))
scaling <- data.frame(variable = covs,
  mean = vapply(covs, function(v) if (unweighted) mean(d[[v]]) else weighted.mean(d[[v]], d$w), 0),
  sd = vapply(covs, function(v) if (unweighted) sd(d[[v]]) else wsd(d[[v]], d$w), 0), row.names = NULL)
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
message("Snow-unit prepared dataset written (", S$variant, ")")
