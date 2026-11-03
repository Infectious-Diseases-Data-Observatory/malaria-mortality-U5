#!/usr/bin/env Rscript
# Figure 5 (user request, 28 October 2026): country malaria-attributable under-five mortality per 1,000 child-years in
# 2024, PfPR-ACM against the cause-specific estimate of the same all-cause source. A: PfPR-ACM with UN IGME all-cause
# mortality against UN IGME (CA-CODE) malaria deaths over the UN WPP population under 5. B: PfPR-ACM with IHME
# all-cause mortality against IHME malaria deaths over IHME person-years. One point per country, coloured by UN M49
# sub-region as in Figure 4; dashed line: equality; both panels share axis limits. Only the outliers are labelled, by
# name (see below). Vertical lines: 95% uncertainty intervals of the PfPR-ACM estimates
# (R_cbh/burden/06_uncertainty_draws.R; 1 November 2026); horizontal lines: the published intervals of the
# cause-specific estimates (2 November 2026). Reads the rates of R_cbh/reporting/25_country_rates_table.R.
# Sizes meet the paper's printed text-size rule (CLAUDE.md) at 6.5 in; no title or caption in the figure.
# Outputs (<out>/model_vs_cause_specific/): fig5_model_vs_cause_specific_2024.png, figure_data.csv, CAPTION.md, provenance.csv
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/reporting/labels.R")
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork) })
st <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION", "snow_merge")); root <- st$out
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
d <- rbind(
  w[, .(panel = "A", iso3, country, model = malaria_rate_per1000_unigme, model_lower = malaria_rate_per1000_lower_unigme,
    model_upper = malaria_rate_per1000_upper_unigme, cause_specific = cacode_malaria_rate)],
  w[, .(panel = "B", iso3, country, model = malaria_rate_per1000_ihme, model_lower = malaria_rate_per1000_lower_ihme,
    model_upper = malaria_rate_per1000_upper_ihme, cause_specific = ihme_malaria_rate)])
d[, region := factor(region_of[iso3], levels = names(m49))]
# Intervals of the cause-specific estimates (author request, 2 November 2026): CA-CODE's 90% bounds on its malaria
# deaths (A) and IHME's 95% uncertainty intervals (B), applied to the rates as the ratio of bound to estimate (the
# denominators are unchanged).
ce <- fread(paths[["country"]])[year == fig_year]
im <- fread(paths[["ihme_malaria"]])[Year == fig_year & Sex == "Both" & Condition == "Malaria" & Measure == "Deaths" &
  Age == "Under 5" & Unit == "Number"][, iso3 := countrycode::countrycode(Location, "country.name", "iso3c", warn = FALSE)]
stopifnot(!anyDuplicated(im$iso3), all(w$iso3 %in% im$iso3),
  max(abs(im$Value[match(ce$iso3, im$iso3)] - ce$ihme_malaria_deaths)) < 1e-6)
ratio <- function(b, v) fifelse(v > 0, b / v, 0)
bounds <- rbind(ce[, .(panel = "A", iso3, lo = ratio(who_cacode_lower90, who_cacode_deaths), hi = ratio(who_cacode_upper90, who_cacode_deaths))],
  im[iso3 %in% w$iso3, .(panel = "B", iso3, lo = ratio(Lower, Value), hi = ratio(Upper, Value))])
d <- merge(d, bounds, by = c("panel", "iso3"), all.x = TRUE, sort = FALSE)
d[, `:=`(cause_specific_lower = cause_specific * lo, cause_specific_upper = cause_specific * hi)][, c("lo", "hi") := NULL]
stopifnot(!anyNA(d), all(d$cause_specific_lower <= d$cause_specific & d$cause_specific <= d$cause_specific_upper))
# Only the outliers are labelled, by name (author request, 2 November 2026; ISO3 codes for every country at 2.5 or more
# per 1,000 made the figure too busy): countries where the PfPR-ACM estimate is more than 2.5 per 1,000 above the
# cause-specific estimate or more than 0.6 below it. In 2024 both thresholds fall in clear gaps (above: 2.72 then 2.00
# in A, 2.89 then 2.34 in B; below: 1.50 then 0.39 in A, 0.85 then 0.49 in B).
above_min <- 2.5; below_min <- 0.6
full_name <- c(`C. African Rep.` = "Central African Republic", `Eq. Guinea` = "Equatorial Guinea", `Rep. of Congo` = "Republic of the Congo")
d[, excess := model - cause_specific]
d[, labelled := excess > above_min | excess < -below_min]
d[, label := fifelse(labelled, sub("^(Central African|Republic of|Equatorial) ", "\\1\n", fcoalesce(unname(full_name[country]), country)), "")]
# Fixed label positions: offset from the point to the label centre, in rates per 1,000, chosen on these data so that
# no label covers a point or another label and no leader crosses another or passes through a point. The script stops
# if the labelled set changes. Positions are per version: gadm_merge (branch gadm-admin1) keeps the v14 positions,
# whose points moved by less than 0.6 per 1,000, and adds South Sudan; a version without any lets ggrepel place them.
offsets <- fread(text = "version,panel,iso3,dx,dy
snow_merge,A,GNQ,0.900,4.800
snow_merge,A,LBR,0.900,-0.600
snow_merge,B,BDI,1.100,-0.500
snow_merge,B,CAF,-1.300,1.300
snow_merge,B,GNQ,1.400,-0.800
snow_merge,B,NER,0.700,0.600
snow_merge,B,RWA,1.400,0.400
snow_merge,B,TCD,-0.400,0.600
gadm_merge,A,GNQ,0.900,4.800
gadm_merge,A,LBR,0.900,-0.600
gadm_merge,B,BDI,1.100,-0.500
gadm_merge,B,CAF,-1.300,1.300
gadm_merge,B,GNQ,1.400,-0.800
gadm_merge,B,NER,0.700,0.600
gadm_merge,B,RWA,1.400,0.400
gadm_merge,B,TCD,-0.400,0.600
gadm_merge,B,SSD,-1.900,-0.400")[version == st$version, !"version"]
fixed_labels <- nrow(offsets) > 0
if (fixed_labels) stopifnot(setequal(paste(offsets$panel, offsets$iso3), d[labelled == TRUE, paste(panel, iso3)]))
d[, c("dx", "dy") := 0]
if (fixed_labels) d[offsets, on = c("panel", "iso3"), c("dx", "dy") := .(i.dx, i.dy)]
cbh_atomic_csv(d, file.path(out, "figure_data.csv"))
# Axes reach the points and every interval no longer than 1.5 times the largest point; a longer interval (South
# Sudan's, from UN IGME's wide all-cause bounds) is truncated at the edge with an arrow and given in the caption.
reach <- 1.5 * max(d$model, d$cause_specific)
lim <- c(0, max(d$model, d$cause_specific, d$model_upper[d$model_upper <= reach]) * 1.04); axis_breaks <- seq(0, 2 * floor(lim[2] / 2), 2)
d[, `:=`(model_upper_shown = pmin(model_upper, lim[2]), truncated = model_upper > lim[2])]
stopifnot(all(d$cause_specific_upper <= lim[2]))   # the horizontal intervals are never truncated
# PfPR-ACM on the y-axis, the cause-specific estimate on the x-axis (user request, 28 October 2026).
panel <- function(p, source_label, tag) ggplot(d[panel == p], aes(cause_specific, model)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey55", linewidth = .35) +
  geom_linerange(aes(ymin = model_lower, ymax = model_upper_shown, colour = region), linewidth = .3, alpha = .55, show.legend = FALSE) +
  geom_linerange(aes(xmin = cause_specific_lower, xmax = cause_specific_upper, colour = region), linewidth = .3, alpha = .55, show.legend = FALSE) +
  geom_segment(data = d[panel == p & truncated], aes(x = cause_specific, xend = cause_specific, y = model, yend = lim[2], colour = region),
    linewidth = .3, alpha = .55, arrow = grid::arrow(length = grid::unit(1.4, "mm")), show.legend = FALSE) +
  geom_point(aes(colour = region), size = 1.7) +
  ggrepel::geom_text_repel(aes(label = label), size = 9 / .pt, colour = "grey20", seed = 20261028L, max.overlaps = Inf,
    nudge_x = d[panel == p, dx], nudge_y = d[panel == p, dy], max.iter = if (fixed_labels) 0 else 10000, point.size = 1.7, lineheight = .95,
    min.segment.length = grid::unit(1.5, "mm"), segment.colour = "grey50", segment.size = .25, box.padding = .2, point.padding = .15) +
  scale_colour_manual(values = colours, drop = FALSE, name = NULL) +
  scale_x_continuous(limits = lim, breaks = axis_breaks, expand = expansion(mult = c(0, .02))) +
  scale_y_continuous(limits = lim, breaks = axis_breaks, expand = expansion(mult = c(0, .02))) +
  coord_equal() +
  # Paper terms (author decision, 30 October 2026): "malaria deaths" for the cause-specific estimates (x),
  # "malaria-attributable deaths" for the PfPR-ACM estimates, which include indirect effects (y).
  labs(x = sprintf("Malaria deaths\nper 1,000 child-years (%s)", source_label),
       y = "Malaria-attributable deaths\nper 1,000 child-years (PfPR-ACM)", tag = tag) +
  theme_minimal(base_size = 9, base_line_size = .3) +
  theme(axis.title = element_text(size = 11), axis.text = element_text(size = 9), legend.text = element_text(size = 9),
    plot.tag = element_text(size = 12, face = "bold"), panel.grid.minor = element_blank(), plot.margin = margin(4, 8, 4, 4))
p <- panel("A", "UN IGME", "A") + panel("B", "IHME", "B") +
  plot_layout(nrow = 1, guides = "collect") & theme(legend.position = "bottom")
for (q in p$patches$plots) stopifnot(is.null(q$labels$title), is.null(q$labels$subtitle), is.null(q$labels$caption))
ggsave(file.path(out, sprintf("fig5_model_vs_cause_specific_%d.png", fig_year)), p, device = ragg::agg_png,
  width = 6.5, height = 4.1, dpi = 400, bg = "white")
rho <- d[, .(rho = cor(model, cause_specific, method = "spearman"), above = sum(model > cause_specific),
  lower_above = sum(model_lower > cause_specific), upper_below = sum(model_upper < cause_specific)), by = panel]
writeLines(c("# Figure 5 caption — PfPR-ACM against cause-specific malaria mortality, by country", "",
  paste0(sprintf("**Figure. Malaria-attributable under-five mortality in %d: PfPR-ACM model against cause-specific estimates.** ", fig_year),
    "Each point is a country; rates are deaths per 1,000 child-years under 5. ",
    "(A) PfPR-ACM estimates using UN IGME all-cause mortality (y) against UN IGME (CA-CODE) malaria deaths (x), both over the UN WPP population under 5. ",
    "(B) PfPR-ACM estimates using IHME all-cause mortality (y) against IHME malaria deaths (x), both over IHME person-years. ",
    "The PfPR-ACM estimate counts all deaths averted if prevalence fell to zero (direct and indirect); the cause-specific estimates count deaths assigned to malaria as the underlying cause. ",
    "The dashed line is equality; countries are coloured by UN M49 sub-region (Middle Africa as Central Africa). ",
    sprintf("Countries where the PfPR-ACM estimate is more than %.1f per 1,000 above the cause-specific estimate or more than %.1f below it are named. ",
      above_min, below_min),
    sprintf("Spearman correlation: %.2f (A) and %.2f (B); the PfPR-ACM estimate is higher in %d (A) and %d (B) of %d countries. ",
      rho[panel == "A", rho], rho[panel == "B", rho], rho[panel == "A", above], rho[panel == "B", above], nrow(w)),
    "Vertical lines are 95% uncertainty intervals of the PfPR-ACM estimates, from 500 joint draws of MAP's national PfPR[2–10], the all-cause deaths and the PfPR–death curves (Supplementary Methods); horizontal lines are the published intervals of the cause-specific estimates (the 90% bounds of the UN IGME (CA-CODE) malaria deaths in A, and IHME's 95% uncertainty intervals in B). ",
    sprintf("The lower bound exceeds the cause-specific estimate in %d (A) and %d (B) countries, and the upper bound is below it in %d (A) and %d (B). ",
      rho[panel == "A", lower_above], rho[panel == "B", lower_above], rho[panel == "A", upper_below], rho[panel == "B", upper_below]),
    if (any(d$truncated)) paste0("Intervals beyond the axes are truncated with an arrow: ",
      paste(d[truncated == TRUE, sprintf("%s in %s (upper bound %.1f)", country, panel, model_upper)], collapse = "; "), ". ") else "",
    "CA-CODE takes malaria from WHO estimates in 13 low-burden countries; South Sudan's IHME all-cause mortality is its crisis-free value.")),
  file.path(out, "CAPTION.md"))
provenance <- c(unname(paths), "R_cbh/reporting/27_model_vs_cause_specific.R", "R_cbh/reporting/labels.R")
cbh_atomic_csv(data.frame(file = provenance, md5 = vapply(provenance, cbh_file_hash, "")), file.path(out, "provenance.csv"))
print(rho)
message("Figure 5 saved: ", out)
