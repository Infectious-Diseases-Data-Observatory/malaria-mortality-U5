#!/usr/bin/env Rscript
# Supplementary figure (user request, 15 October 2026): survival through each age band against PfPR[2-10] in the raw
# data of the Snow-unit primary sample, by UN M49 sub-region, with an unadjusted spline fit for each sub-region. It shows
# the data behind the sub-region refits of 01_fit.R (for example the flat Central Africa curves at older ages, where
# the low-prevalence records come mostly from Chad).
#   Points: one per survey x area unit x band-entry year; survival = 1 - deaths / children entering the band, at the
#          unit's MAP PfPR[2-10] in that year; size = children entering the band.
#   Fits:  for each age band and sub-region, a binomial GAM of deaths among children entering the band with a
#          complementary log-log link and a penalised cubic regression spline of PfPR[2-10] (basis dimension 5, as in
#          the primary analysis; REML, gamma = 2), with no covariates. Drawn over the central 95% of the sub-region's
#          exposure in that band, with pointwise 95% intervals. Southern Africa is shown as points only: its PfPR[2-10]
#          spans 0-10%, too narrow a range for a spline (the reason it is not refitted either).
#   Axes:  every panel has the same y-axis range (survival from the lowest record-weighted 2nd percentile of the seven
#          bands up to 100%); points below it are drawn at the lower edge as open triangles.
# Sub-regions: the UN M49 lists of R_cbh/sensitivity/subgroups/settings.R (Middle Africa as "Central Africa"; Southern
# Africa is shown although it is not refitted). Snow-unit primary only (CBH_PRIMARY_VERSION=snow_merge).
# Outputs (st$out, aggregates only): sfig_survival_vs_pfpr_by_subregion.png, CAPTION_sfig_survival_vs_pfpr_by_subregion.md,
#   survival_spline_fits.csv (fitted curves), survival_by_subregion_summary.csv, central_africa_low_prevalence.csv
#   (who supplies the low-prevalence records of Central Africa at 24-59 months, and their survival), survival_figure_provenance.csv.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/sensitivity/subgroups/settings.R")
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(mgcv) })
st <- cbh_subgroup_settings()
if (!identical(st$primary_version, "snow_merge")) stop("This figure belongs to the Snow-unit primary; set CBH_PRIMARY_VERSION=snow_merge.")
primary <- cbh_primary_settings(st$primary_version)
write_csv <- function(d, name) cbh_atomic_csv(d, file.path(st$out, name))
ages <- cbh_config()$age_bands$age_band
age_labels <- setNames(ifelse(ages == "<1", "<1 month", paste(ages, "months")), ages)
regions <- c(west_africa = "Western Africa", central_africa = "Central Africa", east_africa = "Eastern Africa", southern_africa = "Southern Africa")
colours <- setNames(c(st$colours[["west_africa"]], st$colours[["central_africa"]], st$colours[["east_africa"]], "#E69F00"), regions)

x <- readRDS(primary$data)
d <- as.data.table(x$data)[, .(survey = as.character(survey), country = as.character(country), area = as.character(region),
  age_band = as.character(age_band), entry_year, pfpr_pct, death, w)]
stopifnot(all(d$w == 1), all(d$death %in% 0:1))
d[, region := NA_character_]
for (k in names(regions)) d[country %in% st[[k]], region := regions[[k]]]
if (anyNA(d$region)) stop("Countries without a UN M49 sub-region: ", paste(unique(d[is.na(region), country]), collapse = ", "))

# One point per survey x area unit x band-entry year (PfPR is constant within it).
pts <- d[, .(children = .N, deaths = sum(death), pfpr = mean(pfpr_pct), spread = diff(range(pfpr_pct))),
         by = .(age_band, region, survey, area, entry_year)]
stopifnot(max(pts$spread) < 1e-9, sum(pts$children) == nrow(d), sum(pts$deaths) == sum(d$death))
pts[, `:=`(survival = 1 - deaths / children, spread = NULL)]

wq <- function(v, w, p) { o <- order(v); v <- v[o]; cw <- cumsum(w[o]) / sum(w); v[pmin(findInterval(p, cw) + 1L, length(v))] }
# Unadjusted spline fit by age band and sub-region.
fitted_regions <- setdiff(unname(regions), "Southern Africa")
fits <- rbindlist(lapply(ages, function(a) rbindlist(lapply(fitted_regions, function(r) {
  p <- pts[age_band == a & region == r]
  f <- gam(cbind(deaths, children - deaths) ~ s(pfpr, bs = "cr", k = 5), family = binomial(link = "cloglog"),
           data = p, method = "REML", gamma = 2)
  rng <- wq(p$pfpr, p$children, c(.025, .975))
  g <- data.table(pfpr = seq(rng[1], rng[2], length.out = 120))
  pr <- predict(f, g, se.fit = TRUE)
  surv <- function(eta) exp(-exp(eta))            # cloglog: P(death) = 1 - exp(-exp(eta))
  g[, `:=`(age_band = a, region = r, survival = surv(pr$fit), lower_95 = surv(pr$fit + 1.96 * pr$se.fit),
           upper_95 = surv(pr$fit - 1.96 * pr$se.fit), edf = sum(f$edf[-1]), converged = f$converged)]
}))))
stopifnot(all(fits$converged), all(is.finite(fits$survival)))
write_csv(fits[, .(age_band, region, pfpr, survival, lower_95, upper_95, edf)], "survival_spline_fits.csv")

summ <- d[, .(surveys = uniqueN(survey), countries = uniqueN(country), children = .N, deaths = sum(death), survival = 1 - mean(death),
              pfpr_p025 = wq(pfpr_pct, rep(1, .N), .025), pfpr_p975 = wq(pfpr_pct, rep(1, .N), .975)), by = .(age_band, region)]
summ <- merge(summ, pts[, .(area_years = .N), by = .(age_band, region)], by = c("age_band", "region"))
summ[, age_band := factor(age_band, ages)]; setorder(summ, age_band, region)
write_csv(summ, "survival_by_subregion_summary.csv")

# Low-prevalence records (PfPR[2-10] < 10%) at 24-59 months: Central Africa by country, against the other sub-regions.
older <- c("24-35", "36-47", "48-59")
low <- d[age_band %in% older & pfpr_pct < 10]
ca <- low[region == "Central Africa", .(children = .N, deaths = sum(death)), by = country][, `:=`(
  share_of_central_africa = children / sum(children), survival = 1 - deaths / children)][order(-children)]
rest <- low[region != "Central Africa", .(country = "Other sub-regions", children = .N, deaths = sum(death),
  share_of_central_africa = NA_real_, survival = 1 - sum(death) / .N)]
write_csv(rbind(ca, rest), "central_africa_low_prevalence.csv")

# Common y-axis: from the lowest of the seven bands' record-weighted 2nd percentiles (rounded down to 0.5 points) to 100%.
lo <- min(pts[, .(q = wq(survival, children, .02)), by = age_band]$q); lo <- floor(lo * 200) / 200
pts[, below := survival < lo][, y := pmax(survival, lo)]
below <- pts[, .(points = .N, points_below = sum(below), children_below = sum(children[below])), by = age_band]
pts[, age_label := factor(age_labels[age_band], unname(age_labels))]; fits[, age_label := factor(age_labels[age_band], unname(age_labels))]
pts[, region := factor(region, unname(regions))]; fits[, region := factor(region, unname(regions))]
setorder(pts, region)   # draw order: Western, Central, Eastern, Southern

paper <- theme_minimal(base_size = 18) + theme(panel.grid.minor = element_blank(),
  axis.text = element_text(size = 14), axis.title = element_text(size = 18),
  strip.text = element_text(size = 16, face = "bold"), legend.position = "bottom",
  legend.text = element_text(size = 15), legend.title = element_text(size = 15),
  panel.spacing = grid::unit(20, "pt"), plot.margin = margin(10, 24, 10, 10))
p <- ggplot() +
  geom_point(data = pts[below == FALSE], aes(pfpr, y, colour = region, size = children), alpha = .22, stroke = 0) +
  geom_point(data = pts[below == TRUE], aes(pfpr, y, colour = region), shape = 2, size = 1.1, alpha = .55) +
  geom_ribbon(data = fits, aes(pfpr, ymin = lower_95, ymax = upper_95, fill = region), alpha = .18, colour = NA) +
  geom_line(data = fits, aes(pfpr, survival, colour = region), linewidth = 1.2) +
  facet_wrap(~age_label, ncol = 4) +
  scale_colour_manual(values = colours, name = NULL, drop = FALSE) +
  scale_fill_manual(values = colours, guide = "none") +
  scale_size_area(max_size = 3.2, limits = c(0, max(pts$children)), breaks = c(10, 50, 200), name = "Children entering the band") +
  scale_x_continuous(limits = c(0, ceiling(max(pts$pfpr) / 5) * 5), breaks = seq(0, 80, 20)) +
  scale_y_continuous(labels = function(v) sprintf("%.0f", 100 * v), breaks = seq(0, 1, .01)) +
  coord_cartesian(ylim = c(lo, 1)) +
  labs(x = "PfPR[2–10] (%)", y = "Survival through the age band (%)") + paper +
  guides(colour = guide_legend(order = 1, nrow = 1, override.aes = list(size = 3, alpha = 1, shape = 16, linewidth = 1.2)),
         size = guide_legend(order = 2, override.aes = list(alpha = 1, colour = "grey35")))
stopifnot(is.null(p$labels$title))
figure <- file.path(st$out, "sfig_survival_vs_pfpr_by_subregion.png")
ggsave(figure, p, width = 15, height = 8.5, dpi = 240, device = ragg::agg_png, bg = "white")

fmt <- function(v) format(round(v), big.mark = ",", trim = TRUE)
tot <- d[, .(surveys = uniqueN(survey), countries = uniqueN(country)), by = region][match(unname(regions), region)]
caption <- paste0(
  "Survival through each age band against PfPR[2–10] in the primary analysis sample, by UN sub-region. Each point is one survey × area unit × band-entry year: ",
  "the proportion of children entering the band who survived it, at the unit's MAP PfPR[2–10] in that year (point size: children entering the band; ",
  fmt(nrow(pts)), " points over the seven bands). Lines are unadjusted spline fits for each sub-region (binomial generalised additive model of deaths with a complementary log-log link and a penalised cubic regression spline of PfPR[2–10], basis dimension 5, gamma = 2, no covariates), ",
  "drawn over the central 95% of the sub-region's exposure in each band, with pointwise 95% intervals shaded. Sub-regions (UN M49): ",
  paste(sprintf("%s (%d surveys in %d countries)", tot$region, tot$surveys, tot$countries), collapse = ", "),
  "; Central Africa is UN Middle Africa. Southern Africa is shown as points only: its PfPR[2–10] spans 0–10%, too narrow a range for a spline fit (it is not refitted in the sub-region sensitivity analysis either). ",
  "All panels share the same y-axis; ", fmt(sum(below$points_below)), " points (", sprintf("%.1f", 100 * sum(below$children_below) / nrow(d)),
  "% of children) lie below ", sprintf("%.1f", 100 * lo), "% and are drawn at the lower edge as open triangles. ",
  "The fits are descriptive: unlike the adjusted age-band models of the sub-region refits, they do not adjust for confounders, calendar time or survey and area effects, and they mix variation within and between countries.")
writeLines(c("# Supplementary figure caption: survival against PfPR by sub-region", "", caption), file.path(st$out, "CAPTION_sfig_survival_vs_pfpr_by_subregion.md"))
src <- c(primary$data, "R_cbh/sensitivity/subgroups/03_survival_by_subregion.R", "R_cbh/sensitivity/subgroups/settings.R", "R_cbh/primary/settings.R")
write_csv(data.frame(file = c(src, figure), md5 = vapply(c(src, figure), cbh_file_hash, "")), "survival_figure_provenance.csv")
print(below); print(summ[, .(age_band, region, children, deaths, area_years)])
message("Survival-by-sub-region figure written: ", figure, " (y-axis from ", 100 * lo, "%)")
