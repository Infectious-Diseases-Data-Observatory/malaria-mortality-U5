#!/usr/bin/env Rscript
# Country malaria-attributable under-five mortality per 1,000 child-years in 2024, PfPR-ACM against the cause-specific
# estimate of the same all-cause source (user request, 28 October 2026).
# Figure 5 (main text; UN IGME only, by age group: author requests, 18 November 2026): one panel for each age group
# in which UN IGME reports all-cause deaths (<1 month, 1-11 months, 1-4 years). y: PfPR-ACM attributable deaths in the
# age group (UN IGME all-cause deaths); x: UN IGME (CA-CODE) malaria deaths under 5, the same value in every panel,
# because CA-CODE publishes malaria deaths for 1-59 months as a whole (none under 1 month, no finer age groups;
# UNICEF dataflow CME_CAUSE_OF_DEATH). Both are over the UN WPP population under 5, so the three panels' PfPR-ACM
# rates sum to the under-five rate. The panels share the x-axis and have their own y-axes.
# Supplementary figure (IHME; in the main figure as panel B until 18 November 2026): PfPR-ACM with IHME all-cause
# mortality against IHME malaria deaths under 5, both over IHME person-years, with the outliers named.
# One point per country, coloured by UN M49 sub-region as in Figure 4; dashed line: equality. Vertical lines: 95%
# uncertainty intervals of the PfPR-ACM estimates (R_cbh/burden/06_uncertainty_draws.R); horizontal lines: the
# published intervals of the cause-specific estimates. Reads the rates of R_cbh/reporting/25_country_rates_table.R.
# Sizes meet the paper's printed text-size rule (CLAUDE.md) at 6.5 in; no title or caption in the figures.
# Outputs (<out>/model_vs_cause_specific/): fig5_model_vs_cause_specific_2024.png, figure_data.csv, CAPTION.md,
# sfig_model_vs_cause_specific_ihme_2024.png, figure_data_ihme.csv, CAPTION_ihme.md, provenance.csv
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/reporting/labels.R")
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork) })
st <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION", "gadm")); root <- st$out
out <- file.path(root, "model_vs_cause_specific"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
fig_year <- 2024L
paths <- c(rates = file.path(root, sprintf("tables/country_rates_%d.csv", fig_year)),
  country = file.path(root, "annual_comparison/country_estimates_2000_2024.csv"),
  groups = file.path(root, "uncertainty/country_year_age_group_intervals_2000_2024.csv"),
  group_totals = file.path(root, "uncertainty/annual_age_group_intervals_2000_2024.csv"),
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
ce <- fread(paths[["country"]])[year == fig_year]
ratio <- function(b, v) fifelse(v > 0, b / v, 0)
# Paper terms (author decision, 30 October 2026): "malaria deaths" for the cause-specific estimates (x),
# "malaria-attributable deaths" for the PfPR-ACM estimates, which include indirect effects (y).
base_theme <- theme_minimal(base_size = 9, base_line_size = .3) +
  theme(axis.title = element_text(size = 11), axis.text = element_text(size = 9), legend.text = element_text(size = 9),
    strip.text = element_text(size = 10), plot.tag = element_text(size = 12, face = "bold"), panel.grid.minor = element_blank(),
    plot.margin = margin(4, 8, 4, 4))
no_subtext <- function(p) for (q in if (inherits(p, "patchwork")) c(p$patches$plots, list(p)) else list(p))
  stopifnot(is.null(q$labels$title), is.null(q$labels$subtitle), is.null(q$labels$caption))

## ---- Figure 5: UN IGME, by age group ---------------------------------------------------------------------------------
groups <- c(`<1 month` = "Under 1 month", `1-11 months` = "1\u201311 months", `1-4 years` = "1\u20134 years")
g <- fread(paths[["groups"]])[source == "UN IGME" & year == fig_year]
stopifnot(setequal(g$age_group, names(groups)), nrow(g) == 42L * length(groups), setequal(g$iso3, w$iso3))
# The three groups sum to the under-five PfPR-ACM rate of the country table.
stopifnot(max(abs(g[, .(s = sum(malaria_rate_per1000)), by = iso3][w, on = "iso3", s - i.malaria_rate_per1000_unigme])) < 1e-9)
# CA-CODE's 90% bounds on its malaria deaths, applied to the rate as the ratio of bound to estimate (the denominator
# is unchanged).
d <- merge(g[, .(iso3, country, age_group, model = malaria_rate_per1000, model_lower = malaria_rate_per1000_lower,
    model_upper = malaria_rate_per1000_upper, attributable_deaths)],
  merge(w[, .(iso3, cause_specific = cacode_malaria_rate)],
    ce[, .(iso3, lo = ratio(who_cacode_lower90, who_cacode_deaths), hi = ratio(who_cacode_upper90, who_cacode_deaths))], by = "iso3"), by = "iso3")
d[, `:=`(cause_specific_lower = cause_specific * lo, cause_specific_upper = cause_specific * hi)][, c("lo", "hi") := NULL]
d[, `:=`(region = factor(region_of[iso3], levels = names(m49)), age_group = factor(age_group, levels = names(groups)))]
setorder(d, age_group, iso3)
stopifnot(!anyNA(d), all(d$cause_specific_lower <= d$cause_specific & d$cause_specific <= d$cause_specific_upper),
  all(d$model_lower <= d$model & d$model <= d$model_upper))
cbh_atomic_csv(d, file.path(out, "figure_data.csv"))
# Axes: x is shared (UN IGME malaria deaths under 5 and their bounds); y is each panel's own, because the three age
# groups differ about tenfold in level. Each y-axis reaches every interval, except that the longest is left out when it
# is more than 1.3 times the second longest (South Sudan's, from UN IGME's wide all-cause bounds): it is truncated at
# the edge with an arrow and given in the caption. A PfPR-ACM interval that goes below zero (the age band's curve does
# not exclude no effect) is drawn to zero.
xlim <- c(0, ceiling(max(d$cause_specific_upper)))
d[, ymax := { u <- sort(model_upper, decreasing = TRUE); 1.04 * if (u[1] > 1.3 * u[2]) u[2] else u[1] }, by = age_group]
d[, `:=`(model_upper_shown = pmin(model_upper, ymax), truncated = model_upper > ymax, label = groups[as.character(age_group)])]
age_panel <- function(a, tag) { z <- d[age_group == a]; ggplot(z, aes(cause_specific, model)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey55", linewidth = .35) +
  geom_linerange(aes(ymin = pmax(model_lower, 0), ymax = model_upper_shown, colour = region), linewidth = .3, alpha = .55, show.legend = FALSE) +
  geom_linerange(aes(xmin = cause_specific_lower, xmax = cause_specific_upper, colour = region), linewidth = .3, alpha = .55, show.legend = FALSE) +
  geom_segment(data = z[truncated == TRUE], aes(x = cause_specific, xend = cause_specific, y = model, yend = ymax, colour = region),
    linewidth = .3, alpha = .55, arrow = grid::arrow(length = grid::unit(1.2, "mm")), show.legend = FALSE) +
  geom_point(aes(colour = region), size = 1.3) +
  facet_wrap(~ label) +
  scale_colour_manual(values = colours, drop = FALSE, name = NULL) +
  scale_x_continuous(breaks = seq(0, xlim[2], 2), expand = expansion(mult = c(0, .02))) +
  scale_y_continuous(expand = expansion(mult = c(0, 0))) +
  coord_cartesian(xlim = xlim, ylim = c(0, z$ymax[1])) +
  # The x-axis title is drawn once, under the middle panel, and the y-axis title once, beside the first.
  labs(x = if (tag == "B") "Malaria deaths under 5 per 1,000 child-years (UN IGME)" else "",
       y = if (tag == "A") "Malaria-attributable deaths\nper 1,000 child-years (PfPR-ACM)" else NULL, tag = tag) +
  base_theme + theme(aspect.ratio = 1) }
p <- age_panel(names(groups)[1], "A") + age_panel(names(groups)[2], "B") + age_panel(names(groups)[3], "C") +
  plot_layout(nrow = 1, guides = "collect") & theme(legend.position = "bottom")
no_subtext(p)
ggsave(file.path(out, sprintf("fig5_model_vs_cause_specific_%d.png", fig_year)), p, device = ragg::agg_png,
  width = 6.5, height = 3.1, dpi = 400, bg = "white")
by_group <- d[, .(rho = cor(model, cause_specific, method = "spearman"), above = sum(model > cause_specific),
  lower_above = sum(model_lower > cause_specific), upper_below = sum(model_upper < cause_specific),
  lower_below_zero = sum(model_lower < 0)), by = age_group]
tot <- fread(paths[["group_totals"]])[source == "UN IGME" & year == fig_year][match(names(groups), age_group)]
stopifnot(!anyNA(tot$attributable_deaths), abs(sum(tot$attributable_deaths) - sum(d$attributable_deaths)) < 1e-6)
k <- function(x) format(round(x, -3), big.mark = ","); abc <- function(x, f = "%d") paste(sprintf(paste0(f, " (%s)"), x, c("A", "B", "C")), collapse = ", ")
writeLines(c("# Figure 5 caption — PfPR-ACM by age group against UN IGME malaria mortality, by country", "",
  paste0(sprintf("**Figure. Malaria-attributable under-five mortality in %d by age group: PfPR-ACM model against UN IGME malaria deaths.** ", fig_year),
    "Each point is a country. ",
    "The y-axis is the PfPR-ACM estimate of malaria-attributable deaths at (A) under 1 month, (B) 1–11 months and (C) 1–4 years, the age groups in which UN IGME reports all-cause deaths. ",
    "The x-axis is the same in every panel: UN IGME (CA-CODE) malaria deaths under 5, which CA-CODE assigns to ages 1–59 months as a whole (none under 1 month). ",
    "All rates are deaths per 1,000 child-years under 5 (UN WPP population under 5), so the three PfPR-ACM rates of a country sum to its under-five rate. ",
    "The PfPR-ACM estimate counts all deaths averted if prevalence fell to zero (direct and indirect); UN IGME counts deaths assigned to malaria as the underlying cause. ",
    "The dashed line is equality, where the PfPR-ACM estimate for the age group alone would equal UN IGME's under-five malaria deaths; the y-axis differs between panels. ",
    "Countries are coloured by UN M49 sub-region (Middle Africa as Central Africa). ",
    sprintf("Across the %d countries the PfPR-ACM model attributes %s deaths (95%% uncertainty interval %s to %s) under 1 month, %s (%s to %s) at 1–11 months and %s (%s to %s) at 1–4 years, against %s UN IGME malaria deaths. ",
      nrow(w), k(tot$attributable_deaths[1]), k(tot$attributable_deaths_lower[1]), k(tot$attributable_deaths_upper[1]),
      k(tot$attributable_deaths[2]), k(tot$attributable_deaths_lower[2]), k(tot$attributable_deaths_upper[2]),
      k(tot$attributable_deaths[3]), k(tot$attributable_deaths_lower[3]), k(tot$attributable_deaths_upper[3]), k(sum(ce$who_cacode_deaths))),
    sprintf("Spearman correlation with UN IGME malaria deaths: %s; the PfPR-ACM estimate for the age group alone is higher than UN IGME's under-five malaria deaths in %s of %d countries. ",
      abc(by_group$rho, "%.2f"), abc(by_group$above), nrow(w)),
    "Vertical lines are 95% uncertainty intervals of the PfPR-ACM estimates, from 500 joint draws of MAP's national PfPR[2–10], the all-cause deaths and the PfPR–death curves (Supplementary Methods); horizontal lines are the 90% bounds of the UN IGME (CA-CODE) malaria deaths. ",
    sprintf("Intervals that go below zero are drawn to zero (%s countries). ", abc(by_group$lower_below_zero)),
    if (any(d$truncated)) paste0("Intervals beyond the y-axis are truncated with an arrow: ",
      paste(d[truncated == TRUE, sprintf("%s in %s (upper bound %.1f)", country, c("A", "B", "C")[as.integer(age_group)], model_upper)], collapse = "; "), ". ") else "",
    "CA-CODE takes malaria from WHO estimates in 13 low-burden countries.")),
  file.path(out, "CAPTION.md"))

## ---- Supplementary figure: IHME --------------------------------------------------------------------------------------
im <- fread(paths[["ihme_malaria"]])[Year == fig_year & Sex == "Both" & Condition == "Malaria" & Measure == "Deaths" &
  Age == "Under 5" & Unit == "Number"][, iso3 := countrycode::countrycode(Location, "country.name", "iso3c", warn = FALSE)]
stopifnot(!anyDuplicated(im$iso3), all(w$iso3 %in% im$iso3),
  max(abs(im$Value[match(ce$iso3, im$iso3)] - ce$ihme_malaria_deaths)) < 1e-6)
# IHME's 95% uncertainty intervals, applied to the rate as the ratio of bound to estimate.
h <- merge(w[, .(iso3, country, model = malaria_rate_per1000_ihme, model_lower = malaria_rate_per1000_lower_ihme,
    model_upper = malaria_rate_per1000_upper_ihme, cause_specific = ihme_malaria_rate)],
  im[iso3 %in% w$iso3, .(iso3, lo = ratio(Lower, Value), hi = ratio(Upper, Value))], by = "iso3")
h[, `:=`(cause_specific_lower = cause_specific * lo, cause_specific_upper = cause_specific * hi)][, c("lo", "hi") := NULL]
h[, region := factor(region_of[iso3], levels = names(m49))]
stopifnot(!anyNA(h), all(h$cause_specific_lower <= h$cause_specific & h$cause_specific <= h$cause_specific_upper))
# Only the outliers are labelled, by name (author request, 2 November 2026): countries where the PfPR-ACM estimate is
# more than 2.5 per 1,000 above the cause-specific estimate or more than 0.6 below it. In 2024 both thresholds fall in
# clear gaps (above: 2.89 then 2.34; below: 0.85 then 0.49).
above_min <- 2.5; below_min <- 0.6
full_name <- c(`C. African Rep.` = "Central African Republic", `Eq. Guinea` = "Equatorial Guinea", `Rep. of Congo` = "Republic of the Congo")
h[, excess := model - cause_specific]
h[, labelled := excess > above_min | excess < -below_min]
h[, label := fifelse(labelled, sub("^(Central African|Republic of|Equatorial) ", "\\1\n", fcoalesce(unname(full_name[country]), country)), "")]
# Fixed label positions: offset from the point to the label centre, in rates per 1,000, chosen on these data so that
# no label covers a point or another label and no leader crosses another or passes through a point. The script stops
# if the labelled set changes. Positions are per version (gadm: set on the GADM-unit estimates, 3 November 2026); a
# version without rows lets ggrepel place the labels.
offsets <- fread(text = "version,iso3,dx,dy
gadm,BDI,1.100,-0.500
gadm,CAF,-1.300,1.300
gadm,GNQ,1.400,-0.800
gadm,NER,0.700,0.600
gadm,RWA,1.400,0.400
gadm,TCD,-0.400,0.600
gadm,SSD,-1.900,-0.400")[version == st$version, !"version"]
fixed_labels <- nrow(offsets) > 0
if (fixed_labels) stopifnot(setequal(offsets$iso3, h[labelled == TRUE, iso3]))
h[, c("dx", "dy") := 0]
if (fixed_labels) h[offsets, on = "iso3", c("dx", "dy") := .(i.dx, i.dy)]
cbh_atomic_csv(h, file.path(out, "figure_data_ihme.csv"))
hlim <- c(0, ceiling(max(h$model_upper, h$cause_specific_upper)))
ps <- ggplot(h, aes(cause_specific, model)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey55", linewidth = .35) +
  geom_linerange(aes(ymin = model_lower, ymax = model_upper, colour = region), linewidth = .3, alpha = .55, show.legend = FALSE) +
  geom_linerange(aes(xmin = cause_specific_lower, xmax = cause_specific_upper, colour = region), linewidth = .3, alpha = .55, show.legend = FALSE) +
  geom_point(aes(colour = region), size = 1.7) +
  ggrepel::geom_text_repel(aes(label = label), size = 9 / .pt, colour = "grey20", seed = 20261028L, max.overlaps = Inf,
    nudge_x = h$dx, nudge_y = h$dy, max.iter = if (fixed_labels) 0 else 10000, point.size = 1.7, lineheight = .95,
    min.segment.length = grid::unit(1.5, "mm"), segment.colour = "grey50", segment.size = .25, box.padding = .2, point.padding = .15) +
  scale_colour_manual(values = colours, drop = FALSE, name = NULL) +
  scale_x_continuous(limits = hlim, breaks = seq(0, hlim[2], 2), expand = expansion(mult = c(0, .02))) +
  scale_y_continuous(limits = hlim, breaks = seq(0, hlim[2], 2), expand = expansion(mult = c(0, .02))) +
  coord_equal() +
  labs(x = "Malaria deaths\nper 1,000 child-years (IHME)", y = "Malaria-attributable deaths\nper 1,000 child-years (PfPR-ACM)") +
  base_theme + theme(legend.position = "right")
no_subtext(ps)
ggsave(file.path(out, sprintf("sfig_model_vs_cause_specific_ihme_%d.png", fig_year)), ps, device = ragg::agg_png,
  width = 6.5, height = 4.4, dpi = 400, bg = "white")
hs <- h[, .(rho = cor(model, cause_specific, method = "spearman"), above = sum(model > cause_specific),
  lower_above = sum(model_lower > cause_specific), upper_below = sum(model_upper < cause_specific))]
writeLines(c("# Supplementary figure caption — PfPR-ACM against IHME malaria mortality, by country", "",
  paste0(sprintf("**Figure. Malaria-attributable under-five mortality in %d: PfPR-ACM model with IHME all-cause mortality against IHME malaria deaths.** ", fig_year),
    "Each point is a country; rates are deaths per 1,000 child-years under 5, both over IHME person-years. ",
    "The PfPR-ACM estimate (y) counts all deaths averted if prevalence fell to zero (direct and indirect); IHME (x) counts deaths assigned to malaria as the underlying cause. ",
    "The dashed line is equality; countries are coloured by UN M49 sub-region (Middle Africa as Central Africa). ",
    sprintf("Countries where the PfPR-ACM estimate is more than %.1f per 1,000 above the IHME estimate or more than %.1f below it are named. ",
      above_min, below_min),
    sprintf("Spearman correlation: %.2f; the PfPR-ACM estimate is higher in %d of %d countries. ", hs$rho, hs$above, nrow(w)),
    "Vertical lines are 95% uncertainty intervals of the PfPR-ACM estimates, from 500 joint draws of MAP's national PfPR[2–10], the all-cause deaths and the PfPR–death curves (Supplementary Methods); horizontal lines are IHME's 95% uncertainty intervals. ",
    sprintf("The lower bound exceeds the IHME estimate in %d countries, and the upper bound is below it in %d. ", hs$lower_above, hs$upper_below),
    "South Sudan's IHME all-cause mortality is its crisis-free value.")),
  file.path(out, "CAPTION_ihme.md"))
provenance <- c(unname(paths), "R_cbh/reporting/27_model_vs_cause_specific.R", "R_cbh/reporting/labels.R")
cbh_atomic_csv(data.frame(file = provenance, md5 = vapply(provenance, cbh_file_hash, "")), file.path(out, "provenance.csv"))
print(by_group); print(hs)
message("Figure 5 and its IHME supplementary figure saved: ", out)
