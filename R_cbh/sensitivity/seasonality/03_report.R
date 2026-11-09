#!/usr/bin/env Rscript
# Seasonality sensitivity, step 3: one figure and caption per region, the tables and the report.
# A: hazard ratios relative to zero prevalence by band: the band model on all the region's children, and the refits on
#    the children whose birth month was reported without (A) and with (B) the calendar month at risk.
# B: model B's hazard ratio by calendar month relative to the average month, with the crude death rate by calendar
#    month relative to the band's average (children with a reported birth month).
# Outputs: <out>/<figure>.png per region (6.5 in wide; printed at \linewidth), CAPTION_<figure>.md, hazard_ratios.csv,
# month_hazard_ratios.csv, REPORT.md, report_provenance.csv.
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork) })
source("R_cbh/load_pipeline.R"); source("R_cbh/sensitivity/seasonality/settings.R")
S <- cbh_seasonality_settings()
rd <- function(f) fread(file.path(S$out, f))
pf <- rd("pfpr_curves.csv"); mo <- rd("month_curves.csv"); dm <- rd("deaths_by_month.csv"); smp <- rd("sample.csv")
tests <- rd("month_tests.csv"); rel <- rd("reliability_by_band.csv"); dg <- rd("fit_diagnostics.csv")
stopifnot(nrow(dg) == 9L * length(S$regions), all(dg$converged))
band_lab <- c(`<1` = "<1 month", `1-5` = "1-5 months", `6-11` = "6-11 months")
series <- c(ref = "All children", A = "Birth month reported: without month", B = "Birth month reported: with calendar month")
pf[, series := factor(series[model], levels = series)][, band := factor(band_lab[age_band], levels = band_lab)]

# Tables: hazard ratios at 20% and 40% relative to zero; month hazard ratios at whole months.
hr <- pf[pfpr_pct %in% c(20, 40), .(region, age_band, model, series, pfpr_pct, hazard_ratio, lower_95, upper_95)][
  order(match(region, names(S$regions)), match(age_band, S$bands), match(model, names(series)), pfpr_pct)]
cbh_atomic_csv(as.data.frame(hr), file.path(S$out, "hazard_ratios.csv"))
mh <- mo[abs(month - round(month)) < 1e-9 & month >= 1 & month <= 12][, month := as.integer(round(month))]
cbh_atomic_csv(as.data.frame(mh[order(match(region, names(S$regions)), match(age_band, S$bands), month)]), file.path(S$out, "month_hazard_ratios.csv"))

## ---- Figures -----------------------------------------------------------------------------------------------
# Printed at \linewidth (6.5 in) and saved 6.5 in wide, so sizes are printed sizes (CLAUDE.md): axis titles 11.9 pt,
# ticks and legend 9.9 pt, strips 10.8 pt, panel tags 13 pt.
paper <- theme_minimal(base_size = 9.9, base_line_size = .35) + theme(panel.grid.minor = element_blank(),
  axis.text = element_text(size = 9.9), axis.title = element_text(size = 11.92), strip.text = element_text(size = 10.8, face = "bold"),
  legend.position = "bottom", legend.text = element_text(size = 9.9), legend.title = element_blank(),
  legend.margin = margin(0, 0, 0, 0), legend.box.spacing = grid::unit(4, "pt"), panel.spacing = grid::unit(10, "pt"),
  plot.margin = margin(4, 10, 4, 4), plot.tag = element_text(size = 13, face = "bold"))
cols <- setNames(c("grey55", "#222222", "#C34D26"), series)
dm[, crude_ratio := deaths_per_1000_child_years / (sum(deaths) / sum(child_years) * 1000), by = .(region, age_band)]
dm[, band := factor(band_lab[age_band], levels = band_lab)]; mo[, band := factor(band_lab[age_band], levels = band_lab)]
draw <- function(r) {
  cv <- pf[region == r]
  pa <- ggplot(cv, aes(pfpr_pct, hazard_ratio, colour = series)) +
    geom_hline(yintercept = 1, colour = "grey60", linewidth = .17) +
    geom_ribbon(data = cv[model == "B"], aes(ymin = lower_95, ymax = upper_95), fill = "#C34D26", alpha = .14, colour = NA) +
    geom_line(data = cv[pfpr_pct <= pfpr_p025], linetype = "22", linewidth = .45, show.legend = FALSE) +
    geom_line(data = cv[pfpr_pct >= pfpr_p025], linewidth = .55) +
    facet_wrap(~band, nrow = 1) + scale_colour_manual(values = cols) +
    scale_x_continuous(limits = c(0, 80), breaks = c(0, 20, 40, 60, 80)) +
    guides(colour = guide_legend(nrow = 2, byrow = TRUE)) +
    labs(x = expression(italic(Pf)*PR[2-10]~"(%)"), y = "Hazard ratio relative\nto zero prevalence", tag = "A") + paper
  pb <- ggplot(mo[region == r], aes(month, hazard_ratio)) +
    geom_hline(yintercept = 1, colour = "grey60", linewidth = .17) +
    geom_ribbon(aes(ymin = lower_95, ymax = upper_95), fill = "#C34D26", alpha = .14) +
    geom_line(aes(colour = "Adjusted hazard ratio"), linewidth = .55) +
    geom_point(data = dm[region == r], aes(month, crude_ratio, shape = "Crude death rate"), colour = "grey35", size = 1.3, stroke = .4) +
    facet_wrap(~band, nrow = 1) + scale_colour_manual(values = c(`Adjusted hazard ratio` = "#C34D26")) +
    scale_shape_manual(values = c(`Crude death rate` = 1)) +
    scale_x_continuous(limits = S$month_knots, breaks = 1:12, labels = substr(month.abb, 1, 1)) +
    labs(x = "Calendar month at risk", y = "Hazard ratio relative\nto the average month", tag = "B") + paper
  stopifnot(is.null(pa$labels$title), is.null(pb$labels$title))
  ggsave(file.path(S$out, paste0(S$regions[[r]]$figure, ".png")), pa / pb + plot_layout(heights = c(1, 1)),
         width = 6.5, height = 6.3, dpi = 320, device = ragg::agg_png, bg = "white")
}
for (r in names(S$regions)) draw(r)

## ---- Captions and report ------------------------------------------------------------------------------------
f0 <- function(v) format(v, big.mark = ",", trim = TRUE, scientific = FALSE)
h <- function(r, b, m, x) { z <- hr[region == r & age_band == b & model == m & pfpr_pct == x]; sprintf("%.2f (%.2f-%.2f)", z$hazard_ratio, z$lower_95, z$upper_95) }
caption_for <- function(r) { R <- S$regions[[r]]; k <- smp[region == r]
  paste0(R$label, " sub-analysis (", R$definition, ") with the calendar month at risk added. ",
  "(A) Mortality hazard ratios relative to zero prevalence (PfPR[2-10] = 0) at <1, 1-5 and 6-11 months: the band model fitted to all the ",
  "sub-analysis's children (grey) and refitted to the children whose birth month was reported (DHS b10 and MICS BH4F: month given), ",
  "without (black) and with (orange, with its pointwise 95% conditional interval) a cyclic cubic spline of the calendar month at risk; ",
  "where the two refits give the same curve, the black line lies under the orange one. ",
  "Neonates are at risk in their birth month; at 1-5 and 6-11 months each child contributes one record per month of age, with the month of ",
  "age as a factor in both refits, so that a death's record carries its calendar month of death. Curves are dashed from zero to their 2.5th ",
  "percentile of PfPR[2-10]. (B) Hazard ratio by calendar month relative to the average month from the refits with month (orange line and ",
  "interval) and the crude death rate in each calendar month relative to the band's average (circles). ",
  sprintf("All children: %s surveys in %s countries. ", k$surveys[1], k$countries[1]),
  "Children with a reported birth month: ", paste(sprintf("%s %s children and %s deaths (of %s)", band_lab[k$age_band], f0(k$children), f0(k$deaths),
    f0(k$deaths_all)), collapse = "; "), ".") }
for (r in names(S$regions)) writeLines(c(paste("# Supplementary figure caption:", S$regions[[r]]$label, "sub-analysis with the calendar month"), "", caption_for(r)),
  file.path(S$out, paste0("CAPTION_", S$regions[[r]]$figure, ".md")))
section <- function(r) { R <- S$regions[[r]]; rl <- rel[region == r]
  c(paste0("## ", R$label, " (", R$definition, ")"), "",
  "### Reliability of the dates", "",
  "| Band | Records | Deaths | Birth month reported (%) | Deaths: birth month reported (%) | Deaths: age in days (%) | Deaths: age in months (%) | Deaths: age imputed (%) | Deaths: age flagged (%) | Neonatal deaths in first week (%) | Heaping at 6 months |",
  "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
  with(rl, sprintf("| %s | %s | %s | %.1f | %.1f | %.1f | %.1f | %.1f | %.1f | %s | %s |", age_band, f0(records), f0(deaths), birth_month_reported_pct,
    deaths_birth_month_reported_pct, deaths_age_in_days_pct, deaths_age_in_months_pct, deaths_age_imputed_pct, deaths_age_flagged_pct,
    ifelse(is.na(neonatal_deaths_first_week_pct), "", sprintf("%.1f", neonatal_deaths_first_week_pct)), ifelse(is.na(heaping_6_months), "", sprintf("%.2f", heaping_6_months)))), "",
  "### Hazard ratio relative to zero prevalence", "",
  "| Band | PfPR | All children | Without month | With month |", "|---|---:|---:|---:|---:|",
  unlist(lapply(S$bands, function(b) sprintf("| %s | %d%% | %s | %s | %s |", band_lab[[b]], c(20L, 40L),
    c(h(r, b, "ref", 20), h(r, b, "ref", 40)), c(h(r, b, "A", 20), h(r, b, "A", 40)), c(h(r, b, "B", 20), h(r, b, "B", 40))))), "",
  "### Calendar month (refits with month)", "",
  unlist(lapply(S$bands, function(b) { z <- mh[region == r & age_band == b]; t <- tests[region == r & age_band == b]
    sprintf("- %s: highest %s %.2f (%.2f-%.2f), lowest %s %.2f (%.2f-%.2f); edf %.1f, p = %s.", band_lab[[b]],
      month.name[z[which.max(hazard_ratio), month]], max(z$hazard_ratio), z[which.max(hazard_ratio), lower_95], z[which.max(hazard_ratio), upper_95],
      month.name[z[which.min(hazard_ratio), month]], min(z$hazard_ratio), z[which.min(hazard_ratio), lower_95], z[which.min(hazard_ratio), upper_95],
      t$edf, format.pval(t$p_value, digits = 2)) })), "",
  sprintf("![%s](%s.png)", R$label, R$figure), "", caption_for(r), "") }
writeLines(c("# Seasonality: the calendar month at risk in the first year of life", "",
  "Heaping: deaths at 6 months of age divided by the mean of the deaths at 5 and 7 months. Neonatal deaths are put in the birth month (no day of birth).", "",
  unlist(lapply(names(S$regions), section))), file.path(S$out, "REPORT.md"))
src <- c(file.path(S$out, c("pfpr_curves.csv", "month_curves.csv", "deaths_by_month.csv", "sample.csv", "month_tests.csv", "reliability_by_band.csv", "fit_diagnostics.csv")),
  "R_cbh/sensitivity/seasonality/03_report.R", "R_cbh/sensitivity/seasonality/settings.R")
cbh_atomic_csv(data.frame(file = src, md5 = vapply(src, cbh_file_hash, "")), file.path(S$out, "report_provenance.csv"))
message("Seasonality report: ", file.path(S$out, "REPORT.md"))
