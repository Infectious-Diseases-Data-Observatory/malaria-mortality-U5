#!/usr/bin/env Rscript
# Supplementary figure and tables for the country fixed-effects sensitivity (author request, 31 October 2026): overlay
# the primary PfPR curves with those from the refit with a fixed effect for each country, tabulate the hazard ratios
# against no transmission, and apply the refitted curves to the primary's all-cause deaths by country, year and age
# band (UN IGME and IHME, crisis-free, as in R_cbh/burden/04_annual_comparison.R) to give the burden under this
# specification. Reads saved aggregates and PfPR bases only; no refitting, no TeX writes.
# Outputs (results/cbh/<id>/): comparison_pfpr_curves.csv, sfig_pfpr_splines_country_fixed_effects.png,
# hazard_ratios_vs_zero.csv, burden_comparison_2000_2024.csv, SUMMARY.md, CAPTION.md, report_provenance.csv.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/reporting/labels.R")
suppressPackageStartupMessages({ library(ggplot2); library(data.table); library(mgcv) })
stopifnot(identical(Sys.getenv("CBH_PRIMARY_VERSION"), "snow_merge"))
st <- list(id = "country_fixed_effects_snow520_merge_gamma2_v2")
st$out <- file.path("results/cbh", st$id); st$private <- file.path("data/derived_cbh/models", st$id)
primary <- cbh_primary_settings("snow_merge")
labels <- c(full = "Country random intercepts (primary analysis)",
            fe = "Country fixed effects (sensitivity)")
colours <- setNames(c("#B36B39", "#215E91"), labels)
ages <- cbh_config()$age_bands$age_band
age_label <- function(x) factor(x, levels = ages,
  labels = ifelse(ages == "<1", "<1 month", paste(ages, "months")))

ac <- file.path(primary$out, "annual_comparison")
inputs <- c(primary_curves = file.path(primary$out, "pfpr_curves.csv"), fe_curves = file.path(st$out, "pfpr_curves.csv"),
  primary_diagnostics = file.path(primary$out, "fit_diagnostics.csv"), fe_diagnostics = file.path(st$out, "fit_diagnostics.csv"),
  fe_manifest = file.path(st$out, "fit_manifest.csv"), primary_components = file.path(primary$private, "pfpr_components.rds"),
  fe_components = file.path(st$private, "pfpr_components.rds"),
  primary_hr = file.path(primary$out, "hazard_ratio_by_age/hazard_ratio_curves.csv"),
  age_estimates = file.path(ac, "source_age_estimates_2000_2024.csv"), national_pfpr = file.path(ac, "national_pfpr_2000_2024.csv"),
  annual_rates = file.path(ac, "source_annual_rates_2000_2024.csv"), country_estimates = file.path(ac, "country_estimates_2000_2024.csv"))
stopifnot(file.exists(inputs))
pc <- cbh_read_csv(inputs[["primary_curves"]]); pc <- pc[pc$series == "map_full", ]
fc <- cbh_read_csv(inputs[["fe_curves"]])
pd <- cbh_read_csv(inputs[["primary_diagnostics"]]); fd <- cbh_read_csv(inputs[["fe_diagnostics"]])
stopifnot(nrow(pd) == 7L, nrow(fd) == 7L, all(fd$converged), all(fd$gamma == 2),
          all(fd$input_verified), all(fd$min_smoothing_hessian_eigenvalue > 0),
          identical(sort(pd$rows), sort(fd$rows)), identical(sort(pd$deaths), sort(fd$deaths)))
common <- intersect(names(pc), names(fc))
curves <- rbind(pc[, common], fc[, common])
curves$series_label <- factor(c(rep(labels[["full"]], nrow(pc)), rep(labels[["fe"]], nrow(fc))), levels = labels)
curves$age_label <- age_label(curves$age_band)
cbh_atomic_csv(curves, file.path(st$out, "comparison_pfpr_curves.csv"))

# Sizes meet the paper's printed text-size rule (CLAUDE.md): saved 6.5 in wide and assumed printed at \linewidth
# (6.5 in), so printed sizes equal these (axis titles 11.9 pt; ticks and legend 9.9 pt; strips 10.8 pt). Layout as in
# R_cbh/sensitivity/nutrition/02_report.R.
paper <- theme_minimal(base_size = 9.9, base_line_size = .38) + theme(panel.grid.minor = element_blank(),
  axis.text = element_text(size = 9.9), axis.title = element_text(size = 11.92), strip.text = element_text(size = 10.8, face = "bold"),
  legend.position = "bottom", legend.direction = "vertical", legend.title = element_blank(), legend.text = element_text(size = 9.9),
  legend.margin = margin(0, 0, 0, 0), legend.box.spacing = grid::unit(6, "pt"), legend.key.spacing.y = grid::unit(1, "pt"),
  panel.spacing = grid::unit(10, "pt"), plot.margin = margin(6, 10, 6, 6))
central <- curves[curves$within_central_support, ]
p <- ggplot(central, aes(pfpr_pct, log_hazard_ratio, colour = series_label, fill = series_label)) +
  geom_hline(yintercept = 0, colour = "grey65", linewidth = .19) +
  geom_vline(xintercept = 20, colour = "grey80", linewidth = .19) +
  geom_ribbon(aes(ymin = lower_95, ymax = upper_95), alpha = .12, colour = NA) +
  geom_line(linewidth = .46) + facet_wrap(~age_label, ncol = 4) +
  scale_colour_manual(values = colours) + scale_fill_manual(values = colours) +
  scale_x_continuous(limits = c(0, 80), breaks = c(0, 20, 40, 60, 80)) +
  labs(x = "PfPR[2-10] (%)", y = "Log hazard ratio\nrelative to PfPR = 20%") + paper
stopifnot(is.null(p$labels$title), is.null(p$labels$subtitle), is.null(p$labels$caption))
figure <- file.path(st$out, "sfig_pfpr_splines_country_fixed_effects.png")
ggsave(figure, p, width = 6.5, height = 3.95, dpi = 320, device = ragg::agg_png, bg = "white")

# Hazard ratios against no transmission from the compact PfPR bases (Vp intervals, as in the primary).
pcomp <- readRDS(inputs[["primary_components"]]); fcomp <- readRDS(inputs[["fe_components"]])
stopifnot(identical(names(fcomp), paste0("countryfe_age_", seq_along(ages))),
          all(paste0("map_full_age_", seq_along(ages)) %in% names(pcomp)))
piece <- function(model, i) if (model == "primary") pcomp[[paste0("map_full_age_", i)]] else fcomp[[paste0("countryfe_age_", i)]]
log_hr_zero <- function(pc, p) PredictMat(pc$smooth, data.frame(pfpr_pct = p)) - PredictMat(pc$smooth, data.frame(pfpr_pct = rep(0, length(p))))
hr <- rbindlist(lapply(c("primary", "country_fe"), function(m) rbindlist(lapply(seq_along(ages), function(i) {
  pc <- piece(m, i); L <- log_hr_zero(pc, c(5, 20, 40))
  e <- drop(L %*% pc$coef); se <- sqrt(rowSums((L %*% pc$covariance) * L))
  data.table(model = m, age_band = ages[i], pfpr_pct = c(5, 20, 40), hazard_ratio = exp(e),
    lower_95 = exp(e - 1.96 * se), upper_95 = exp(e + 1.96 * se))
}))))
# The primary rows must reproduce the published Figure 2 curves.
ph <- fread(inputs[["primary_hr"]])[pfpr_pct %in% c(5, 20, 40)]
chk <- merge(hr[model == "primary"], ph[, .(age_band, pfpr_pct, published = hazard_ratio)], by = c("age_band", "pfpr_pct"))
stopifnot(nrow(chk) == 21L, max(abs(chk$hazard_ratio - chk$published)) < 1e-8)
cbh_atomic_csv(hr, file.path(st$out, "hazard_ratios_vs_zero.csv"))

# Burden: each model's attributable fraction at the national PfPR, applied to the primary's crisis-free all-cause
# deaths by source, country, year and age band.
age <- fread(inputs[["age_estimates"]])
age <- merge(age, fread(inputs[["national_pfpr"]])[, .(iso3, year, pfpr_pct)], by = c("iso3", "year"))
stopifnot(!anyNA(age$pfpr_pct))
age[, `:=`(af_primary = NA_real_, af_country_fe = NA_real_)]
for (i in seq_along(ages)) for (m in c("primary", "country_fe")) {
  rows <- age$age_band == ages[i]
  af <- -expm1(-drop(log_hr_zero(piece(m, i), age$pfpr_pct[rows]) %*% piece(m, i)$coef))
  set(age, which(rows), paste0("af_", m), af)
}
stopifnot(max(abs(age$af_primary - age$attributable_fraction)) < 1e-10)
tot <- age[, .(primary_deaths = sum(allcause_deaths * af_primary), country_fe_deaths = sum(allcause_deaths * af_country_fe)),
  by = .(source, year)]
rates <- fread(inputs[["annual_rates"]])[, .(source, year, under5_person_years, attributable_deaths)]
tot <- merge(tot, rates, by = c("source", "year"))
stopifnot(nrow(tot) == 50L, max(abs(tot$primary_deaths - tot$attributable_deaths)) < 1e-4)
est <- fread(inputs[["country_estimates"]])[, .(cacode = sum(who_cacode_deaths), ihme = sum(ihme_malaria_deaths)), by = year]
tot <- merge(tot, est, by = "year")
tot[, `:=`(cause_specific_deaths = fifelse(source == "UN IGME", cacode, ihme),
  cause_specific_source = fifelse(source == "UN IGME", "UN IGME (CA-CODE)", "IHME"))]
tot[, `:=`(primary_rate_per1000 = 1000 * primary_deaths / under5_person_years,
  country_fe_rate_per1000 = 1000 * country_fe_deaths / under5_person_years,
  change_pct = 100 * (country_fe_deaths / primary_deaths - 1),
  primary_excess_pct = 100 * (primary_deaths / cause_specific_deaths - 1),
  country_fe_excess_pct = 100 * (country_fe_deaths / cause_specific_deaths - 1))]
tot <- tot[order(source, year), .(source, year, under5_person_years, primary_deaths, country_fe_deaths, change_pct,
  primary_rate_per1000, country_fe_rate_per1000, cause_specific_source, cause_specific_deaths, primary_excess_pct, country_fe_excess_pct)]
cbh_atomic_csv(tot, file.path(st$out, "burden_comparison_2000_2024.csv"))

# Summary tables.
f2 <- function(x) sprintf("%.2f", x); k <- function(x) format(round(x / 1000), big.mark = ",")
ci <- function(z) sprintf("%s (%s–%s)", f2(z$hazard_ratio), f2(z$lower_95), f2(z$upper_95))
h40 <- dcast(hr[pfpr_pct == 40], age_band ~ model, value.var = c("hazard_ratio", "lower_95", "upper_95"))[match(ages, age_band)]
md <- c("# Country fixed-effects sensitivity", "",
  "## Hazard ratio at PfPR 40% against no transmission (95% interval)", "",
  "| Age (months) | Country random intercepts (primary) | Country fixed effects |", "|---|---:|---:|")
for (a in ages) md <- c(md, sprintf("| %s | %s | %s |", a, ci(hr[model == "primary" & age_band == a & pfpr_pct == 40]),
  ci(hr[model == "country_fe" & age_band == a & pfpr_pct == 40])))
md <- c(md, "", "## Malaria-attributable deaths in the 42 countries (thousands) and excess over cause-specific estimates", "",
  "| All-cause source | Year | Primary | Country fixed effects | Change | Cause-specific | Excess, primary | Excess, fixed effects |",
  "|---|---|---:|---:|---:|---:|---:|---:|")
for (r in split(tot[year %in% c(2000, 2015, 2024)], by = c("source", "year"))) md <- c(md, sprintf("| %s | %d | %s | %s | %+.1f%% | %s (%s) | %+.0f%% | %+.0f%% |",
  r$source, r$year, k(r$primary_deaths), k(r$country_fe_deaths), r$change_pct, k(r$cause_specific_deaths), r$cause_specific_source,
  r$primary_excess_pct, r$country_fe_excess_pct))
change <- function(s, m) { z <- tot[source == s]; 100 * (z[year == 2024][[m]] / z[year == 2015][[m]] - 1) }
md <- c(md, "", sprintf("Change in the UN IGME-based rate, 2015 to 2024: %+.1f%% (primary %+.1f%%); IHME-based %+.1f%% (primary %+.1f%%).",
  change("UN IGME", "country_fe_rate_per1000"), change("UN IGME", "primary_rate_per1000"),
  change("IHME", "country_fe_rate_per1000"), change("IHME", "primary_rate_per1000")),
  "Both models are fitted to the same records; intervals are conditional on the smoothing parameters.")
writeLines(md, file.path(st$out, "SUMMARY.md"))

g24 <- tot[source == "UN IGME" & year == 2024]; i24 <- tot[source == "IHME" & year == 2024]
fe14 <- hr[model == "country_fe" & pfpr_pct == 40 & age_band %in% ages[4:7]]
pr14 <- hr[model == "primary" & pfpr_pct == 40 & age_band %in% ages[4:7]]
caption <- c("# Supplementary figure caption: country fixed effects", "",
  paste0("Sensitivity of the fitted PfPR-mortality relationship to replacing the country random intercept with a fixed effect for each country, so that the effect of PfPR[2-10] is estimated from variation within countries only. ",
  "Log mortality hazard ratios relative to PfPR[2-10] = 20% by completed-month age band, with pointwise 95% conditional intervals shaded, from the ", cbh_paper_model_label(),
  " with country random intercepts (the primary analysis) and from a refit of the same seven models on the identical sample with country fixed effects. ",
  "Sample, exposure, covariates, reference knots, basis dimensions, gamma = 2, offset and the survey and survey-unit random intercepts are unchanged. ",
  "Each curve is drawn over the central 95% of its own exposure distribution. ",
  sprintf("At 1 to 4 years the hazard ratio at a PfPR[2-10] of 40%%, as compared with no transmission, was %s to %s with country fixed effects (primary %s to %s). ",
    f2(min(fe14$hazard_ratio)), f2(max(fe14$hazard_ratio)), f2(min(pr14$hazard_ratio)), f2(max(pr14$hazard_ratio))),
  sprintf("Applied to 2024, the refitted curves give %s malaria-attributable deaths with UN IGME all-cause mortality (primary %s; %+.0f%% relative to the UN IGME (CA-CODE) estimate of malaria deaths) and %s with IHME (primary %s; %+.0f%% relative to IHME). ",
    format(round(g24$country_fe_deaths, -3), big.mark = ","), format(round(g24$primary_deaths, -3), big.mark = ","), g24$country_fe_excess_pct,
    format(round(i24$country_fe_deaths, -3), big.mark = ","), format(round(i24$primary_deaths, -3), big.mark = ","), i24$country_fe_excess_pct),
  "The two models are fitted to the same records, so the comparison is descriptive."))
writeLines(caption, file.path(st$out, "CAPTION.md"))
prov <- c(unname(inputs), figure, "R_cbh/sensitivity/country_fe/02_report.R")
cbh_atomic_csv(data.frame(file = prov, md5 = vapply(prov, cbh_file_hash, "")), file.path(st$out, "report_provenance.csv"))
cat(md, sep = "\n")
cat("Country fixed-effects sensitivity figure and tables saved:", figure, "\n")
