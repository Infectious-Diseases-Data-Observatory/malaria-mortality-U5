#!/usr/bin/env Rscript
# Country malaria-attributable under-five mortality per 1,000 child-years in 2024, PfPR-ACM against the cause-specific
# estimate of the same all-cause source (user request, 28 October 2026), one figure per source:
# Figure 5 (main text; UN IGME only: author request, 18 November 2026): PfPR-ACM with UN IGME all-cause mortality
#   against UN IGME (CA-CODE) malaria deaths under 5, both over the UN WPP population under 5. The comparison is under 5
#   as a whole because CA-CODE publishes malaria deaths for 1-59 months as a whole (none under 1 month, no finer age
#   groups; UNICEF dataflow CME_CAUSE_OF_DEATH), so an age-specific comparison cannot be made with UN IGME.
# Supplementary figure (IHME; panel B of Figure 5 until 18 November 2026): PfPR-ACM with IHME all-cause mortality
#   against IHME malaria deaths under 5, both over IHME person-years, on the axis limits of Figure 5.
# One point per country, coloured by UN M49 sub-region as in Figure 4; dashed line: equality. Only the outliers are
# labelled, by name (see below). Vertical lines: 95% uncertainty intervals of the PfPR-ACM estimates
# (R_cbh/burden/06_uncertainty_draws.R; 1 November 2026); horizontal lines: the published intervals of the
# cause-specific estimates (2 November 2026). Reads the rates of R_cbh/reporting/25_country_rates_table.R.
# Sizes meet the paper's printed text-size rule (CLAUDE.md) at 6.5 in; no title or caption in the figures.
# Outputs (<out>/model_vs_cause_specific/): fig5_model_vs_cause_specific_2024.png, figure_data.csv, CAPTION.md,
# sfig_model_vs_cause_specific_ihme_2024.png, figure_data_ihme.csv, CAPTION_ihme.md, provenance.csv
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/reporting/labels.R")
suppressPackageStartupMessages({ library(data.table); library(ggplot2) })
st <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION", "gadm")); root <- st$out
out <- file.path(root, "model_vs_cause_specific"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
fig_year <- 2024L
paths <- c(rates = file.path(root, sprintf("tables/country_rates_%d.csv", fig_year)),
  country = file.path(root, "annual_comparison/country_estimates_2000_2024.csv"),
  ihme_malaria = "data/ihme_malaria_u5_deaths_by_age_country_year.csv")
stopifnot(all(file.exists(paths)))
w <- fread(paths[["rates"]])
stopifnot(nrow(w) == 42L, !anyDuplicated(w$iso3))
m49 <- list(`West Africa` = c("BEN","BFA","CIV","CPV","GHA","GIN","GMB","GNB","LBR","MLI","MRT","NER","NGA","SEN","SLE","TGO"),
  `Central Africa` = c("AGO","CAF","CMR","COD","COG","GAB","GNQ","STP","TCD"),
  `East Africa` = c("BDI","COM","DJI","ERI","ETH","KEN","MDG","MOZ","MUS","MWI","RWA","SOM","SSD","TZA","UGA","ZMB","ZWE"),
  `Southern Africa` = c("BWA","LSO","NAM","SWZ","ZAF"))
region_of <- setNames(rep(names(m49), lengths(m49)), unlist(m49))
colours <- c(`West Africa` = "#0072B2", `Central Africa` = "#CC79A7", `East Africa` = "#009E73", `Southern Africa` = "#E69F00")
# Intervals of the cause-specific estimates (author request, 2 November 2026): CA-CODE's 90% bounds on its malaria
# deaths and IHME's 95% uncertainty intervals, applied to the rates as the ratio of bound to estimate (the denominators
# are unchanged).
ce <- fread(paths[["country"]])[year == fig_year]
im <- fread(paths[["ihme_malaria"]])[Year == fig_year & Sex == "Both" & Condition == "Malaria" & Measure == "Deaths" &
  Age == "Under 5" & Unit == "Number"][, iso3 := countrycode::countrycode(Location, "country.name", "iso3c", warn = FALSE)]
stopifnot(!anyDuplicated(im$iso3), all(w$iso3 %in% im$iso3),
  max(abs(im$Value[match(ce$iso3, im$iso3)] - ce$ihme_malaria_deaths)) < 1e-6)
ratio <- function(b, v) fifelse(v > 0, b / v, 0)
# Only the outliers are labelled, by name (author request, 2 November 2026; ISO3 codes for every country at 2.5 or more
# per 1,000 made the figure too busy): countries where the PfPR-ACM estimate is more than 2.5 per 1,000 above the
# cause-specific estimate or more than 0.6 below it. In 2024 both thresholds fall in clear gaps (above: 2.72 then 2.00
# for UN IGME, 2.89 then 2.34 for IHME; below: 1.50 then 0.39 for UN IGME, 0.85 then 0.49 for IHME).
above_min <- 2.5; below_min <- 0.6
full_name <- c(`C. African Rep.` = "Central African Republic", `Eq. Guinea` = "Equatorial Guinea", `Rep. of Congo` = "Republic of the Congo")
# Fixed label positions: offset from the point to the label centre, in rates per 1,000, chosen on these data so that
# no label covers a point or another label and no leader crosses another or passes through a point. The script stops
# if the labelled set changes. Positions are per version (gadm: set on the GADM-unit estimates, 3 November 2026); a
# version without rows lets ggrepel place the labels.
offsets <- fread(text = "version,figure,iso3,dx,dy
gadm,unigme,GNQ,0.900,4.800
gadm,unigme,LBR,0.900,-0.600
gadm,ihme,BDI,1.100,-0.500
gadm,ihme,CAF,-1.300,1.300
gadm,ihme,GNQ,1.400,-0.800
gadm,ihme,NER,0.700,0.600
gadm,ihme,RWA,1.400,0.400
gadm,ihme,TCD,-0.400,0.600
gadm,ihme,SSD,-1.900,-0.400")[version == st$version, !"version"]
fixed_labels <- nrow(offsets) > 0
prepare <- function(z, bounds, fig) {
  z <- merge(z, bounds, by = "iso3", sort = FALSE)
  z[, `:=`(cause_specific_lower = cause_specific * lo, cause_specific_upper = cause_specific * hi)][, c("lo", "hi") := NULL]
  z[, region := factor(region_of[iso3], levels = names(m49))]
  stopifnot(nrow(z) == 42L, !anyNA(z), all(z$cause_specific_lower <= z$cause_specific & z$cause_specific <= z$cause_specific_upper))
  z[, excess := model - cause_specific]
  z[, labelled := excess > above_min | excess < -below_min]
  z[, label := fifelse(labelled, sub("^(Central African|Republic of|Equatorial) ", "\\1\n", fcoalesce(unname(full_name[country]), country)), "")]
  o <- offsets[figure == fig]
  if (fixed_labels) stopifnot(setequal(o$iso3, z[labelled == TRUE, iso3]))
  z[, c("dx", "dy") := 0]
  if (fixed_labels) z[o, on = "iso3", c("dx", "dy") := .(i.dx, i.dy)]
  z[]
}
d <- prepare(w[, .(iso3, country, model = malaria_rate_per1000_unigme, model_lower = malaria_rate_per1000_lower_unigme,
    model_upper = malaria_rate_per1000_upper_unigme, cause_specific = cacode_malaria_rate)],
  ce[, .(iso3, lo = ratio(who_cacode_lower90, who_cacode_deaths), hi = ratio(who_cacode_upper90, who_cacode_deaths))], "unigme")
h <- prepare(w[, .(iso3, country, model = malaria_rate_per1000_ihme, model_lower = malaria_rate_per1000_lower_ihme,
    model_upper = malaria_rate_per1000_upper_ihme, cause_specific = ihme_malaria_rate)],
  im[iso3 %in% w$iso3, .(iso3, lo = ratio(Lower, Value), hi = ratio(Upper, Value))], "ihme")
# Axis limits from the UN IGME figure alone, so that the main-text figure does not depend on IHME; the IHME figure uses
# the same limits. They reach the points and every interval no longer than 1.5 times the largest point; a longer
# interval (South Sudan's, from UN IGME's wide all-cause bounds) is truncated at the edge with an arrow and given in
# the caption.
reach <- 1.5 * max(d$model, d$cause_specific)
lim <- c(0, max(d$model, d$cause_specific, d$model_upper[d$model_upper <= reach]) * 1.04); axis_breaks <- seq(0, 2 * floor(lim[2] / 2), 2)
for (z in list(d, h)) {
  z[, `:=`(model_upper_shown = pmin(model_upper, lim[2]), truncated = model_upper > lim[2])]
  stopifnot(all(z$model <= lim[2]), all(z$cause_specific_upper <= lim[2]))   # points and horizontal intervals are never cut
}
cbh_atomic_csv(d, file.path(out, "figure_data.csv")); cbh_atomic_csv(h, file.path(out, "figure_data_ihme.csv"))
# PfPR-ACM on the y-axis, the cause-specific estimate on the x-axis (user request, 28 October 2026).
scatter <- function(z, source_label) ggplot(z, aes(cause_specific, model)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey55", linewidth = .35) +
  geom_linerange(aes(ymin = model_lower, ymax = model_upper_shown, colour = region), linewidth = .3, alpha = .55, show.legend = FALSE) +
  geom_linerange(aes(xmin = cause_specific_lower, xmax = cause_specific_upper, colour = region), linewidth = .3, alpha = .55, show.legend = FALSE) +
  geom_segment(data = z[truncated == TRUE], aes(x = cause_specific, xend = cause_specific, y = model, yend = lim[2], colour = region),
    linewidth = .3, alpha = .55, arrow = grid::arrow(length = grid::unit(1.4, "mm")), show.legend = FALSE) +
  geom_point(aes(colour = region), size = 1.7) +
  ggrepel::geom_text_repel(aes(label = label), size = 9 / .pt, colour = "grey20", seed = 20261028L, max.overlaps = Inf,
    nudge_x = z$dx, nudge_y = z$dy, max.iter = if (fixed_labels) 0 else 10000, point.size = 1.7, lineheight = .95,
    min.segment.length = grid::unit(1.5, "mm"), segment.colour = "grey50", segment.size = .25, box.padding = .2, point.padding = .15) +
  scale_colour_manual(values = colours, drop = FALSE, name = NULL) +
  scale_x_continuous(limits = lim, breaks = axis_breaks, expand = expansion(mult = c(0, .02))) +
  scale_y_continuous(limits = lim, breaks = axis_breaks, expand = expansion(mult = c(0, .02))) +
  coord_equal() +
  # Paper terms (author decision, 30 October 2026): "malaria deaths" for the cause-specific estimates (x),
  # "malaria-attributable deaths" for the PfPR-ACM estimates, which include indirect effects (y).
  labs(x = sprintf("Malaria deaths\nper 1,000 child-years (%s)", source_label),
       y = "Malaria-attributable deaths\nper 1,000 child-years (PfPR-ACM)") +
  theme_minimal(base_size = 9, base_line_size = .3) +
  theme(axis.title = element_text(size = 11), axis.text = element_text(size = 9), legend.text = element_text(size = 9),
    panel.grid.minor = element_blank(), plot.margin = margin(4, 8, 4, 4), legend.position = "right")
save_figure <- function(p, file) {
  stopifnot(is.null(p$labels$title), is.null(p$labels$subtitle), is.null(p$labels$caption))
  ggsave(file.path(out, file), p, device = ragg::agg_png, width = 6.5, height = 4.4, dpi = 400, bg = "white")
}
save_figure(scatter(d, "UN IGME"), sprintf("fig5_model_vs_cause_specific_%d.png", fig_year))
save_figure(scatter(h, "IHME"), sprintf("sfig_model_vs_cause_specific_ihme_%d.png", fig_year))
summarise <- function(z) z[, .(rho = cor(model, cause_specific, method = "spearman"), above = sum(model > cause_specific),
  lower_above = sum(model_lower > cause_specific), upper_below = sum(model_upper < cause_specific))]
caption <- function(z, heading, title, axes, cause, cause_interval, last) { s <- summarise(z); c(heading, "",
  paste0(sprintf("**Figure. Malaria-attributable under-five mortality in %d: %s.** ", fig_year, title),
    "Each point is a country; rates are deaths per 1,000 child-years under 5. ", axes,
    sprintf("The PfPR-ACM estimate counts all deaths averted if prevalence fell to zero (direct and indirect); %s counts deaths assigned to malaria as the underlying cause. ", cause),
    "The dashed line is equality; countries are coloured by UN M49 sub-region (Middle Africa as Central Africa). ",
    sprintf("Countries where the PfPR-ACM estimate is more than %.1f per 1,000 above the %s estimate or more than %.1f below it are named. ",
      above_min, cause, below_min),
    sprintf("Spearman correlation: %.2f; the PfPR-ACM estimate is higher in %d of %d countries. ", s$rho, s$above, nrow(z)),
    sprintf("Vertical lines are 95%% uncertainty intervals of the PfPR-ACM estimates, from 500 joint draws of MAP's national PfPR[2–10], the all-cause deaths and the PfPR–death curves (Supplementary Methods); horizontal lines are %s. ", cause_interval),
    sprintf("The lower bound exceeds the %s estimate in %d countries, and the upper bound is below it in %d. ", cause, s$lower_above, s$upper_below),
    if (any(z$truncated)) paste0("Intervals beyond the axes are truncated with an arrow: ",
      paste(z[truncated == TRUE, sprintf("%s (upper bound %.1f)", country, model_upper)], collapse = "; "), ". ") else "",
    last)) }
writeLines(caption(d, "# Figure 5 caption — PfPR-ACM against UN IGME malaria mortality, by country",
  "PfPR-ACM model against UN IGME malaria deaths",
  "PfPR-ACM estimates using UN IGME all-cause mortality (y) against UN IGME (CA-CODE) malaria deaths (x), both over the UN WPP population under 5. ",
  "UN IGME", "the 90% bounds of the UN IGME (CA-CODE) malaria deaths",
  "CA-CODE assigns malaria deaths to ages 1–59 months as a whole and none under 1 month, and takes malaria from WHO estimates in 13 low-burden countries."),
  file.path(out, "CAPTION.md"))
writeLines(caption(h, "# Supplementary figure caption — PfPR-ACM against IHME malaria mortality, by country",
  "PfPR-ACM model with IHME all-cause mortality against IHME malaria deaths",
  "PfPR-ACM estimates using IHME all-cause mortality (y) against IHME malaria deaths (x), both over IHME person-years. ",
  "IHME", "IHME's 95% uncertainty intervals",
  "The axes are those of the main-text figure (UN IGME). South Sudan's IHME all-cause mortality is its crisis-free value."),
  file.path(out, "CAPTION_ihme.md"))
provenance <- c(unname(paths), "R_cbh/reporting/27_model_vs_cause_specific.R", "R_cbh/reporting/labels.R")
cbh_atomic_csv(data.frame(file = provenance, md5 = vapply(provenance, cbh_file_hash, "")), file.path(out, "provenance.csv"))
print(rbind(cbind(figure = "UN IGME", summarise(d)), cbind(figure = "IHME", summarise(h))))
message("Figure 5 (UN IGME) and its IHME supplementary figure saved: ", out)
