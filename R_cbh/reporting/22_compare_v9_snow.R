#!/usr/bin/env Rscript
# Supplementary comparison of the Snow-unit primary (snow_merge) with the v9 survey-region primary (ported from the
# analysis project's R_cbh/snow_units/13_compare.R): PfPR hazard-ratio curves against PfPR 0 by age band (95%
# intervals from each fit's PfPR coefficients and covariance), the per-band contrasts, and the attributable under-five
# deaths (42 countries) for 2005, 2015, 2024 and 2000-2024. Writes <Snow primary out>/comparison_v9/.
suppressPackageStartupMessages({ library(data.table); library(mgcv); library(ggplot2) })
source("R_cbh/load_pipeline.R"); source("R_cbh/primary/settings.R")
s9 <- cbh_primary_settings("regional_mics"); ss <- cbh_primary_settings("snow_merge")
out <- file.path(ss$out, "comparison_v9"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
v9 <- s9$out; sn <- ss$out
comp <- list(v9 = readRDS(file.path(s9$private, "pfpr_components.rds")), snow = readRDS(file.path(ss$private, "pfpr_components.rds")))
ages <- cbh_config()$age_bands$age_band
lab <- setNames(ifelse(ages == "<1", "<1 month", paste(sub("-", "–", ages), "months")), ages)
model_lab <- c(v9 = "v9 (survey-regions)", snow = "Snow et al. polygons (merge rule)")

# 1. Hazard ratio against PfPR 0 on a grid, within each fit's observed PfPR range.
curves <- rbindlist(lapply(names(comp), function(m) rbindlist(lapply(comp[[m]], function(p) {
  g <- seq(0, min(90, floor(p$support[4])), by = 1)
  nd <- data.frame(pfpr_pct = g); zero <- data.frame(pfpr_pct = rep(0, length(g)))
  L <- PredictMat(p$smooth, nd) - PredictMat(p$smooth, zero)
  est <- drop(L %*% p$coef); se <- sqrt(pmax(rowSums((L %*% p$covariance) * L), 0))
  data.table(model = m, age_band = p$age_band, pfpr_pct = g, log_hr = est, se = se, hr = exp(est),
             lower_95 = exp(est - 1.96 * se), upper_95 = exp(est + 1.96 * se),
             within_central_support = g >= p$support[2] & g <= p$support[3])
}))))
fwrite(curves, file.path(out, "pfpr_hr_vs_zero_curves.csv"))
curves[, `:=`(age_label = factor(lab[age_band], lab), model_label = factor(model_lab[model], model_lab))]
cols <- c("#215E91", "#D9822B"); names(cols) <- model_lab
fig <- ggplot(curves, aes(pfpr_pct, hr, colour = model_label, fill = model_label)) +
  geom_hline(yintercept = 1, colour = "grey60", linewidth = 0.3) +
  geom_ribbon(aes(ymin = lower_95, ymax = upper_95), alpha = 0.15, colour = NA) +
  geom_line(linewidth = 0.7) +
  facet_wrap(~age_label, ncol = 4) +
  scale_colour_manual(values = cols, name = NULL) + scale_fill_manual(values = cols, name = NULL) +
  scale_y_log10() + scale_x_continuous(breaks = seq(0, 80, 20)) +
  labs(x = expression(italic(Pf)*PR["2–10"]~"(%)"), y = expression("Hazard ratio against"~italic(Pf)*PR~"0 (log scale)")) +
  theme_minimal(base_size = 8.5) +
  theme(panel.grid.minor = element_blank(), strip.text = element_text(face = "bold"), legend.position = c(0.88, 0.2))
ggsave(file.path(out, "pfpr_hr_curves_v9_vs_snow.png"), fig, width = 180, height = 105, units = "mm", dpi = 600,
       device = ragg::agg_png, bg = "white")

# 2. Per-band contrasts (as written by the effects step of each analysis).
rd <- function(dir, f) fread(file.path(dir, f))
c20 <- merge(rd(v9, "pfpr_20_to_zero_contrasts.csv")[, .(age_band, v9_af20 = attributable_fraction_at_20pct, v9_af20_lo = lower_95, v9_af20_hi = upper_95)],
             rd(sn, "pfpr_20_to_zero_contrasts.csv")[, .(age_band, snow_af20 = attributable_fraction_at_20pct, snow_af20_lo = lower_95, snow_af20_hi = upper_95)], by = "age_band")
c40 <- merge(rd(v9, "pfpr_40_to_20_contrasts.csv")[, .(age_band, v9_hr40 = hazard_ratio_40_to_20, v9_hr40_lo = lower_95, v9_hr40_hi = upper_95)],
             rd(sn, "pfpr_40_to_20_contrasts.csv")[, .(age_band, snow_hr40 = hazard_ratio_40_to_20, snow_hr40_lo = lower_95, snow_hr40_hi = upper_95)], by = "age_band")
edf <- merge(rd(v9, "pfpr_edf.csv")[, .(age_band, v9_edf = edf)], rd(sn, "pfpr_edf.csv")[, .(age_band, snow_edf = edf)], by = "age_band")
bands <- Reduce(function(a, b) merge(a, b, by = "age_band"), list(c20, c40, edf))[match(ages, age_band)]
fwrite(bands, file.path(out, "age_band_contrasts_v9_vs_snow.csv"))

# 3. Attributable under-five deaths, 42 countries.
ys <- merge(rd(file.path(v9, "burden"), "year_summary.csv")[, .(year, v9_attributable = attributable_under5_deaths, ihme_malaria = ihme_malaria_deaths)],
            rd(file.path(sn, "burden"), "year_summary.csv")[, .(year, snow_attributable = attributable_under5_deaths)], by = "year")
ys[, ratio_snow_to_v9 := snow_attributable / v9_attributable]
fwrite(ys, file.path(out, "attributable_deaths_2005_2015_2024.csv"))
ct <- merge(rd(file.path(v9, "burden"), "country_totals.csv")[series == "map_full" & year == 2024 & is.finite(attributable_under5_deaths),
              .(iso3, country, pfpr_pct, v9 = attributable_under5_deaths, v9_af = attributable_fraction)],
            rd(file.path(sn, "burden"), "country_totals.csv")[series == "map_full" & year == 2024, .(iso3, snow = attributable_under5_deaths, snow_af = attributable_fraction)], by = "iso3")
fwrite(ct[order(-v9)], file.path(out, "country_attributable_2024_v9_vs_snow.csv"))
annual <- NULL
if (file.exists(file.path(sn, "annual_comparison", "annual_totals_2000_2024.csv"))) {
  a9 <- rd(file.path(v9, "annual_comparison"), "annual_totals_2000_2024.csv"); as <- rd(file.path(sn, "annual_comparison"), "annual_totals_2000_2024.csv")
  annual <- merge(a9[, .(year, v9 = model_deaths, ihme_malaria = ihme_malaria_deaths, un_igme_cacode = who_cacode_deaths)],
                  as[, .(year, snow = model_deaths)], by = "year")   # annual files name the attributable deaths model_deaths
  fwrite(annual, file.path(out, "annual_attributable_2000_2024_v9_vs_snow.csv"))
}
af <- function(x, lo, hi) sprintf("%.1f%% (%.1f to %.1f)", 100 * x, 100 * lo, 100 * hi)
hr <- function(x, lo, hi) sprintf("%.2f (%.2f to %.2f)", x, lo, hi)
f0 <- function(x) format(round(x), big.mark = ",")
lines <- c("# Snow-unit primary vs v9 survey-region primary: seven age-band models", "",
  "Snow-unit fits: the v9 specification with survey x unit areas (a Snow et al. polygon or a union of polygons; R_cbh/snow/README.md).", "",
  "## Effect of PfPR by age band", "",
  "| Age band | AF at PfPR 20% vs 0, v9 | Snow | HR for reducing PfPR from 40% to 20%, v9 | Snow | edf v9 | edf Snow |", "|---|---|---|---|---|---:|---:|",
  bands[, sprintf("| %s | %s | %s | %s | %s | %.2f | %.2f |", lab[age_band], af(v9_af20, v9_af20_lo, v9_af20_hi), af(snow_af20, snow_af20_lo, snow_af20_hi),
    hr(v9_hr40, v9_hr40_lo, v9_hr40_hi), hr(snow_hr40, snow_hr40_lo, snow_hr40_hi), v9_edf, snow_edf)], "",
  "## Attributable under-five deaths (42 countries)", "",
  "| Year | v9 | Snow units | Snow / v9 | IHME malaria |", "|---|---:|---:|---:|---:|",
  ys[, sprintf("| %d | %s | %s | %.3f | %s |", year, f0(v9_attributable), f0(snow_attributable), ratio_snow_to_v9, f0(ihme_malaria))])
if (!is.null(annual)) lines <- c(lines, "", sprintf("2000-2024 total: v9 %s, Snow %s (ratio %.3f).", f0(sum(annual$v9)), f0(sum(annual$snow)), sum(annual$snow) / sum(annual$v9)))
lines <- c(lines, "", sprintf("2024 by country: Spearman correlation of attributable deaths %.3f; median Snow/v9 ratio %.2f.",
  cor(ct$v9, ct$snow, method = "spearman"), median(ct$snow / ct$v9)))
writeLines(lines, file.path(out, "COMPARISON.md"))
cat(lines, sep = "\n")

inputs <- c(file.path(s9$private, "pfpr_components.rds"), file.path(ss$private, "pfpr_components.rds"), "R_cbh/reporting/22_compare_v9_snow.R")
cbh_atomic_csv(data.frame(file = inputs, md5 = vapply(inputs, cbh_file_hash, "")), file.path(out, "provenance.csv"))
