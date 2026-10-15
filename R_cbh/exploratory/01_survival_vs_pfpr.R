#!/usr/bin/env Rscript
# Exploratory plot (user request, 15 October 2026): survival through each age band against PfPR[2-10], one point per
# survey x area unit x band-entry year of the Snow-unit primary sample, to look at the raw data behind the Central
# Africa refit (flat curves at older ages). Not part of the pipeline; reads the prepared dataset of the primary.
#   Point: survival proportion = 1 - deaths / children entering the band, at the unit's MAP PfPR[2-10] for that entry
#          year; size = children entering the band.
#   Groups: UN M49 Middle ("Central") Africa against the other sub-regions, as defined for the subgroup refits
#          (R_cbh/sensitivity/subgroups/settings.R).
#   Lines: record-weighted survival in 5-point PfPR bins (bins with at least 500 children), by group.
#   y-axis: each panel shows survival from the record-weighted 2nd percentile of the points up to 100%; points below
#          are drawn at the lower edge as open triangles and counted in points_below_limits.csv.
# Outputs (results/cbh/exploratory/survival_vs_pfpr/, aggregates only; results/ is not committed):
#   survival_vs_pfpr_by_band.png, area_year_points.csv, summary_by_band_group.csv
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork) })
source("R_cbh/primary/settings.R"); source("R_cbh/sensitivity/subgroups/settings.R")
P <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION", "snow_merge"))
G <- cbh_subgroup_settings()
out <- file.path("results/cbh/exploratory/survival_vs_pfpr"); dir.create(out, recursive = TRUE, showWarnings = FALSE)

d <- as.data.table(readRDS(P$data)$data)[, .(survey = as.character(survey), country = as.character(country),
  area = as.character(region), age_band = as.character(age_band), entry_year, pfpr_pct, death, w)]
stopifnot(all(d$w == 1))
d[, group := fcase(country %in% G$central_africa, "Central Africa", country %in% G$west_africa, "West Africa",
                   country %in% G$east_africa, "East Africa", country %in% G$southern_africa, "Southern Africa")]
stopifnot(!anyNA(d$group))
ages <- c("<1", "1-5", "6-11", "12-23", "24-35", "36-47", "48-59")
labels <- setNames(c("<1 month", "1-5 months", "6-11 months", "12-23 months", "24-35 months", "36-47 months", "48-59 months"), ages)

# One point per survey x area unit x band-entry year (PfPR is constant within it).
pts <- d[, .(children = .N, deaths = sum(death), pfpr = mean(pfpr_pct), pfpr_range = diff(range(pfpr_pct))),
         by = .(age_band, group, country, survey, area, entry_year)]
stopifnot(max(pts$pfpr_range) < 1e-9)
pts[, survival := 1 - deaths / children][, pfpr_range := NULL]
fwrite(pts[order(match(age_band, ages), group, survey, area, entry_year)], file.path(out, "area_year_points.csv"))

# Summary by band and group: data volume and exposure range (record-weighted quantiles).
wq <- function(x, w, p) { o <- order(x); x <- x[o]; cw <- cumsum(w[o]) / sum(w); x[findInterval(p, cw) + 1L] }
summ <- d[, .(children = .N, deaths = sum(death), surveys = uniqueN(survey), countries = uniqueN(country),
              area_years = uniqueN(paste(area, entry_year)), survival = 1 - mean(death),
              pfpr_p025 = wq(pfpr_pct, rep(1, .N), .025), pfpr_median = median(pfpr_pct), pfpr_p975 = wq(pfpr_pct, rep(1, .N), .975),
              share_pfpr_below_20 = mean(pfpr_pct < 20), deaths_pfpr_below_20 = sum(death[pfpr_pct < 20])),
          by = .(age_band, group)][order(match(age_band, ages), group)]
summ[, median_deaths_per_area_year := pts[, .(m = median(deaths)), by = .(age_band, group)][summ, on = .(age_band, group), m]]
fwrite(summ, file.path(out, "summary_by_band_group.csv"))

# Binned record-weighted survival by group.
bins <- seq(0, 100, by = 5)
d[, bin := findInterval(pfpr_pct, bins, rightmost.closed = TRUE)]
bl <- d[, .(children = .N, survival = 1 - mean(death), pfpr = mean(pfpr_pct)), by = .(age_band, plot_group = fifelse(group == "Central Africa", group, "Other sub-regions"), bin)][children >= 500]

colours <- c("Central Africa" = "#B5307A", "Other sub-regions" = "#7A7A7A")
pts[, plot_group := fifelse(group == "Central Africa", "Central Africa", "Other sub-regions")]
setorder(pts, -plot_group)   # Central Africa drawn on top
clipped <- list()
panel <- function(a) {
  p <- pts[age_band == a]; b <- bl[age_band == a]
  lo <- wq(p$survival, p$children, .02); lo <- max(0, floor(lo * 400) / 400)
  p[, below := survival < lo]; p[, y := pmax(survival, lo)]
  clipped[[a]] <<- p[, .(age_band = a, lower_limit = lo, points_below = sum(below), children_below = sum(children[below]))]
  ggplot(p, aes(pfpr, y, colour = plot_group)) +
    geom_point(data = p[below == FALSE], aes(size = children), alpha = .28, stroke = 0) +
    geom_point(data = p[below == TRUE], shape = 2, size = .9, alpha = .6) +
    geom_line(data = b, aes(pfpr, survival, colour = plot_group), linewidth = .9) +
    scale_colour_manual(values = colours, name = NULL) +
    scale_size_area(max_size = 2.6, limits = c(0, max(pts$children)), breaks = c(10, 50, 200), name = "Children entering the band") +
    scale_x_continuous(limits = c(0, 85), breaks = seq(0, 80, 20)) +
    scale_y_continuous(labels = function(x) sprintf("%.1f", 100 * x)) +
    coord_cartesian(ylim = c(lo, 1)) +
    labs(title = labels[[a]], x = "PfPR[2-10] (%)", y = if (a %in% c("<1", "24-35")) "Survival through the band (%)" else NULL) +
    theme_minimal(base_size = 9) +
    theme(plot.title = element_text(face = "bold", size = 9.5), panel.grid.minor = element_blank(),
          axis.title = element_text(size = 8, colour = "grey30"), legend.position = "right", legend.box = "vertical") +
    guides(colour = guide_legend(order = 1, override.aes = list(size = 2.2, alpha = 1, shape = 16)),
           size = guide_legend(order = 2, override.aes = list(alpha = .6, colour = "#7A7A7A")))
}
plots <- lapply(ages, panel)
fig <- wrap_plots(plots, ncol = 4) + guide_area() + plot_layout(guides = "collect") +
  plot_annotation(caption = paste0("One point per survey x area unit x band-entry year (size: children entering the band); y: survival through the band (%); x: MAP PfPR[2-10] of the unit in the entry year (%).\n",
    "Lines: record-weighted survival in 5-point PfPR bins with at least 500 children. Open triangles: points below the panel's lower limit (record-weighted 2nd percentile), drawn at the limit.\nCentral Africa: UN M49 Middle Africa (AGO, CAF, CMR, COD, COG, GAB, TCD)."),
    theme = theme(plot.caption = element_text(hjust = 0, size = 7.5, colour = "grey30")))
ggsave(file.path(out, "survival_vs_pfpr_by_band.png"), fig, width = 12, height = 7.2, dpi = 220, device = ragg::agg_png, bg = "white")
cl <- rbindlist(clipped); fwrite(cl, file.path(out, "points_below_limits.csv"))
print(summ[, .(age_band, group, children, deaths, area_years, median_deaths_per_area_year, survival = round(survival, 4),
               pfpr_p025 = round(pfpr_p025, 1), pfpr_median = round(pfpr_median, 1), pfpr_p975 = round(pfpr_p975, 1),
               share_pfpr_below_20 = round(share_pfpr_below_20, 3))])
print(cl)
