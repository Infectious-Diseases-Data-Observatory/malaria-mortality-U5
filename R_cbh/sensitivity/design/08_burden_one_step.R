#!/usr/bin/env Rscript
# One-step estimate of what the space-time test fits (05_spacetime_inla.R) would do to malaria-attributable under-five
# deaths: the paper's all-cause deaths by country, year, age band and source (IHME, UN IGME; crisis years already
# replaced; R_cbh/burden/04_annual_comparison.R) and national PfPR are kept, and the paper's attributable fraction is
# replaced by 1 - 1/HR(PfPR) from each test fit's PfPR curve (linear interpolation on its 1-point grid). Every test
# model fitted on all seven age bands is included. Point estimates only (no uncertainty draws); "paper" re-adds the
# paper's own fractions as a check.
# Writes <out>/burden_one_step_by_year.csv, burden_one_step_2024_by_age.csv and burden_one_step_2024_ages_1_59_months.csv
# (deaths by model, and each model's deaths as a share of M0's).
suppressPackageStartupMessages(library(data.table))
source("R_cbh/primary/settings.R"); source("R_cbh/sensitivity/design/settings.R"); source("R_cbh/00_config.R")
P <- cbh_primary_settings(); S <- cbh_design_settings(); bands <- as.character(cbh_config()$age_bands$age_band)
ac <- file.path(P$out, "annual_comparison")
d <- fread(file.path(ac, "source_age_estimates_2000_2024.csv"), colClasses = list(character = "age_band"))
pf <- fread(file.path(ac, "national_pfpr_2000_2024.csv"))[, .(iso3, year, pfpr_pct)]
d <- merge(d, pf, by = c("iso3", "year")); stopifnot(all(d$age_band %in% bands), all(is.finite(d$pfpr_pct)))
cv <- rbindlist(lapply(seq_along(bands), function(k) fread(file.path(S$out, paste0("band_", k, "_spacetime_pfpr_curves.csv")), colClasses = list(character = "age_band"))))
# Derived, not fitted: the cubic-spline M1 re-referenced to PfPR 1% (hazard ratio 1 below 1%), for a like-for-like
# comparison with M1_rw2_sqrt_ref1, whose reference is PfPR below 1%.
if ("M1" %in% cv$model) cv <- rbind(cv, cv[model == "M1"][, .(model = "M1_ref1", pfpr_pct, log_hazard_ratio = ifelse(pfpr_pct <= 1, 0,
  log_hazard_ratio - log_hazard_ratio[pfpr_pct == 1])), by = age_band], fill = TRUE)
models <- Reduce(intersect, lapply(bands, function(b) unique(cv[age_band == b]$model))); stopifnot("M0" %in% models)
d[, paper := allcause_deaths * attributable_fraction]; stopifnot(max(abs(d$paper - d$attributable_deaths)) < 1e-6)
for (m in models) d[, (m) := { z <- cv[model == m & age_band == .BY$age_band]; stopifnot(max(pfpr_pct) <= max(z$pfpr_pct))
  allcause_deaths * (1 - exp(-approx(z$pfpr_pct, z$log_hazard_ratio, pfpr_pct)$y)) }, by = age_band]
tot <- function(x, by) { z <- x[, c(.(countries = uniqueN(iso3), allcause_deaths = sum(allcause_deaths)), lapply(.SD, sum)), by = by, .SDcols = c("paper", models)]
  for (m in setdiff(models, "M0")) z[, (paste0(m, "_over_M0")) := get(m) / M0]; z }
year <- tot(d, c("source", "year"))[order(source, year)]
age <- tot(d[year == 2024], c("source", "age_band"))[, age_band := factor(age_band, levels = bands)][order(source, age_band)]
post <- tot(d[year == 2024 & age_band != "<1"], "source")
fwrite(year, file.path(S$out, "burden_one_step_by_year.csv")); fwrite(age, file.path(S$out, "burden_one_step_2024_by_age.csv"))
fwrite(post, file.path(S$out, "burden_one_step_2024_ages_1_59_months.csv"))
show <- function(z) print(z[, lapply(.SD, function(x) if (is.numeric(x) && max(x) > 100) round(x) else if (is.numeric(x)) round(x, 3) else x)])
show(year[year %in% c(2000, 2024), !"countries"]); show(age[, !"countries"]); show(post[, !"countries"])
