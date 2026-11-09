#!/usr/bin/env Rscript
# Sahel seasonality sensitivity, step 3: figure, tables, caption and report.
# A: hazard ratios relative to zero prevalence by band: the Sahel refit of the subgroup suite (all children; Figure S3),
#    and the refits on the children whose birth month was reported without (A) and with (B) the calendar month at risk.
# B: model B's hazard ratio by calendar month relative to the average month, with the crude death rate by calendar
#    month relative to the band's average (children with a reported birth month).
# Outputs: <out>/sfig_sahel_season.png (6.5 in wide; printed at \linewidth), CAPTION.md, hazard_ratios.csv,
# month_hazard_ratios.csv, REPORT.md, report_provenance.csv.
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork) })
source("R_cbh/load_pipeline.R"); source("R_cbh/reporting/curves_vs_zero.R")
source("R_cbh/sensitivity/subgroups/settings.R"); source("R_cbh/sensitivity/sahel_season/settings.R")
S <- cbh_sahel_season_settings(); st <- cbh_subgroup_settings()
rd <- function(f) fread(file.path(S$out, f))
pf <- rd("pfpr_curves.csv"); mo <- rd("month_curves.csv"); dm <- rd("deaths_by_month.csv"); smp <- rd("sample.csv")
tests <- rd("month_tests.csv"); rel <- rd("reliability_by_band.csv"); dg <- rd("fit_diagnostics.csv")
stopifnot(nrow(dg) == 6L, all(dg$converged))
band_lab <- c(`<1` = "<1 month", `1-5` = "1-5 months", `6-11` = "6-11 months")

# The Sahel refit of the subgroup suite (all children), with its intervals from the saved fits.
man <- fread(file.path(st$out, "fit_manifest.csv"))[subgroup == "sahel" & age_band %in% S$bands]
stopifnot(nrow(man) == 3L, all(unname(tools::md5sum(man$model_file)) == man$md5))
cur <- fread(file.path(st$out, "hazard_ratio_vs_zero.csv"))[subgroup == "sahel"]
ref <- rbindlist(lapply(S$bands, function(b) { x <- as.data.frame(cur[age_band == b]); x$log_hazard_ratio <- x$log_hr_vs_zero
  v <- as.data.table(cbh_curve_vs_zero(x, readRDS(man[age_band == b, model_file])$fit))
  v[segment != "outside", .(pfpr_pct, hazard_ratio, lower_95, upper_95, pfpr_p025, pfpr_p975, age_band = b, model = "ref")] }))
curves <- rbind(ref, pf, use.names = TRUE)
series <- c(ref = "Sahel, all children (Figure S3)", A = "Birth month reported: without month",
            B = "Birth month reported: with calendar month")
curves[, series := factor(series[model], levels = series)][, band := factor(band_lab[age_band], levels = band_lab)]

# Tables: hazard ratios at 20% and 40% relative to zero; month hazard ratios at whole months.
hr <- curves[pfpr_pct %in% c(20, 40), .(age_band, model, series, pfpr_pct, hazard_ratio, lower_95, upper_95)][order(match(age_band, S$bands), model, pfpr_pct)]
cbh_atomic_csv(as.data.frame(hr), file.path(S$out, "hazard_ratios.csv"))
mh <- mo[abs(month - round(month)) < 1e-9 & month >= 1 & month <= 12][, month := as.integer(round(month))]
cbh_atomic_csv(as.data.frame(mh[order(match(age_band, S$bands), month)]), file.path(S$out, "month_hazard_ratios.csv"))

## ---- Figure ----------------------------------------------------------------------------------------------
# Printed at \linewidth (6.5 in) and saved 6.5 in wide, so sizes are printed sizes (CLAUDE.md): axis titles 11.9 pt,
# ticks and legend 9.9 pt, strips 10.8 pt, panel tags 13 pt.
paper <- theme_minimal(base_size = 9.9, base_line_size = .35) + theme(panel.grid.minor = element_blank(),
  axis.text = element_text(size = 9.9), axis.title = element_text(size = 11.92), strip.text = element_text(size = 10.8, face = "bold"),
  legend.position = "bottom", legend.text = element_text(size = 9.9), legend.title = element_blank(),
  legend.margin = margin(0, 0, 0, 0), legend.box.spacing = grid::unit(4, "pt"), panel.spacing = grid::unit(10, "pt"),
  plot.margin = margin(4, 10, 4, 4), plot.tag = element_text(size = 13, face = "bold"))
cols <- c("grey55", "#222222", "#C34D26"); names(cols) <- series
pa <- ggplot(curves, aes(pfpr_pct, hazard_ratio, colour = series)) +
  geom_hline(yintercept = 1, colour = "grey60", linewidth = .17) +
  geom_ribbon(data = curves[model == "B"], aes(ymin = lower_95, ymax = upper_95), fill = "#C34D26", alpha = .14, colour = NA) +
  geom_line(data = curves[pfpr_pct <= pfpr_p025], linetype = "22", linewidth = .45, show.legend = FALSE) +
  geom_line(data = curves[pfpr_pct >= pfpr_p025], linewidth = .55) +
  facet_wrap(~band, nrow = 1) + scale_colour_manual(values = cols) +
  scale_x_continuous(limits = c(0, 80), breaks = c(0, 20, 40, 60, 80)) +
  guides(colour = guide_legend(nrow = 2, byrow = TRUE)) +
  labs(x = expression(italic(Pf)*PR[2-10]~"(%)"), y = "Hazard ratio relative\nto zero prevalence", tag = "A") + paper
dm[, crude_ratio := deaths_per_1000_child_years / (sum(deaths) / sum(child_years) * 1000), by = age_band]
dm[, band := factor(band_lab[age_band], levels = band_lab)]; mo[, band := factor(band_lab[age_band], levels = band_lab)]
pb <- ggplot(mo, aes(month, hazard_ratio)) +
  geom_hline(yintercept = 1, colour = "grey60", linewidth = .17) +
  geom_ribbon(aes(ymin = lower_95, ymax = upper_95), fill = "#C34D26", alpha = .14) +
  geom_line(aes(colour = "Adjusted hazard ratio"), linewidth = .55) +
  geom_point(data = dm, aes(month, crude_ratio, shape = "Crude death rate"), colour = "grey35", size = 1.3, stroke = .4) +
  facet_wrap(~band, nrow = 1) + scale_colour_manual(values = c(`Adjusted hazard ratio` = "#C34D26")) +
  scale_shape_manual(values = c(`Crude death rate` = 1)) +
  scale_x_continuous(limits = S$month_knots, breaks = 1:12, labels = substr(month.abb, 1, 1)) +
  labs(x = "Calendar month at risk", y = "Hazard ratio relative\nto the average month", tag = "B") + paper
p <- pa / pb + plot_layout(heights = c(1, 1))
stopifnot(is.null(pa$labels$title), is.null(pb$labels$title))
ggsave(file.path(S$out, "sfig_sahel_season.png"), p, width = 6.5, height = 6.3, dpi = 320, device = ragg::agg_png, bg = "white")

## ---- Caption and report -----------------------------------------------------------------------------------
f0 <- function(v) format(v, big.mark = ",", trim = TRUE, scientific = FALSE)
h <- function(b, m, x) { z <- hr[age_band == b & model == m & pfpr_pct == x]; sprintf("%.2f (%.2f-%.2f)", z$hazard_ratio, z$lower_95, z$upper_95) }
caption <- paste0("Sahel sub-analysis (records whose analysis unit has its centroid at or north of 10°N; Figure S3) with the calendar month ",
  "at risk added. (A) Mortality hazard ratios relative to zero prevalence (PfPR[2-10] = 0) at <1, 1-5 and 6-11 months: the Sahel refit of ",
  "Figure S3 (all children; grey) and refits on the children whose birth month was reported (DHS b10 and MICS BH4F: month given), ",
  "without (black) and with (orange, with its pointwise 95% conditional interval) a cyclic cubic spline of the calendar month at risk; ",
  "the two refits give the same curves, so the black line lies under the orange one. ",
  "Neonates are at risk in their birth month; at 1-5 and 6-11 months each child contributes one record per month of age, with the month of ",
  "age as a factor in both refits. Curves are dashed from zero to their 2.5th percentile of PfPR[2-10]. (B) Hazard ratio by calendar month ",
  "relative to the average month from the refits with month (orange line and interval) and the crude death rate in each calendar month ",
  "relative to the band's average (circles). Children with a reported birth month: ",
  paste(sprintf("%s %s children and %s deaths", band_lab[smp$age_band], f0(smp$children), f0(smp$deaths)), collapse = "; "),
  " (", paste(sprintf("%s fewer deaths", f0(smp$dropped_deaths)), collapse = ", "), " than in Figure S3).")
writeLines(c("# Supplementary figure caption: Sahel sub-analysis with the calendar month", "", caption), file.path(S$out, "CAPTION.md"))
lines <- c("# Sahel sub-analysis with the calendar month at risk", "",
  "## Reliability of the dates (Sahel records, bands <1, 1-5, 6-11 months)", "",
  paste0("| Band | Records | Deaths | Birth month reported (%) | Deaths: birth month reported (%) | Deaths: age in days (%) | Deaths: age in months (%) | Deaths: age imputed (%) | Deaths: age flagged (%) | Neonatal deaths in first week (%) | Heaping at 6 months |"),
  "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
  with(rel, sprintf("| %s | %s | %s | %.1f | %.1f | %.1f | %.1f | %.1f | %.1f | %s | %s |", age_band, f0(records), f0(deaths), birth_month_reported_pct,
    deaths_birth_month_reported_pct, deaths_age_in_days_pct, deaths_age_in_months_pct, deaths_age_imputed_pct, deaths_age_flagged_pct,
    ifelse(is.na(neonatal_deaths_first_week_pct), "", sprintf("%.1f", neonatal_deaths_first_week_pct)), ifelse(is.na(heaping_6_months), "", sprintf("%.2f", heaping_6_months)))), "",
  "Heaping: deaths at 6 months of age divided by the mean of the deaths at 5 and 7 months. Neonatal deaths are put in the birth month (no day of birth).", "",
  "## Hazard ratio relative to zero prevalence", "",
  "| Band | PfPR | Sahel, all children | Without month | With month |", "|---|---:|---:|---:|---:|",
  unlist(lapply(S$bands, function(b) sprintf("| %s | %d%% | %s | %s | %s |", band_lab[[b]], c(20L, 40L),
    c(h(b, "ref", 20), h(b, "ref", 40)), c(h(b, "A", 20), h(b, "A", 40)), c(h(b, "B", 20), h(b, "B", 40))))), "",
  "## Calendar month (refits with month)", "",
  unlist(lapply(S$bands, function(b) { z <- mh[age_band == b]; t <- tests[age_band == b]
    sprintf("- %s: highest %s %.2f (%.2f-%.2f), lowest %s %.2f (%.2f-%.2f); edf %.1f, p = %s.", band_lab[[b]],
      month.name[z[which.max(hazard_ratio), month]], max(z$hazard_ratio), z[which.max(hazard_ratio), lower_95], z[which.max(hazard_ratio), upper_95],
      month.name[z[which.min(hazard_ratio), month]], min(z$hazard_ratio), z[which.min(hazard_ratio), lower_95], z[which.min(hazard_ratio), upper_95],
      t$edf, format.pval(t$p_value, digits = 2)) })), "",
  "![Sahel seasonality](sfig_sahel_season.png)", "", caption)
writeLines(lines, file.path(S$out, "REPORT.md"))
src <- c(file.path(S$out, c("pfpr_curves.csv", "month_curves.csv", "deaths_by_month.csv", "sample.csv", "month_tests.csv", "reliability_by_band.csv", "fit_diagnostics.csv")),
  file.path(st$out, c("hazard_ratio_vs_zero.csv", "fit_manifest.csv")), "R_cbh/sensitivity/sahel_season/03_report.R", "R_cbh/sensitivity/sahel_season/settings.R",
  "R_cbh/reporting/curves_vs_zero.R")
cbh_atomic_csv(data.frame(file = src, md5 = vapply(src, cbh_file_hash, "")), file.path(S$out, "report_provenance.csv"))
message("Sahel seasonality report: ", file.path(S$out, "REPORT.md"))
