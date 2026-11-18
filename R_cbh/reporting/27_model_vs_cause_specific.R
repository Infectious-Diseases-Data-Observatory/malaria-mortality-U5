#!/usr/bin/env Rscript
# Country malaria-attributable under-five mortality per 1,000 child-years in 2024, PfPR-ACM against the cause-specific
# estimate of the same all-cause source (user request, 28 October 2026). Three figures:
# Figure 5 (main text; UN IGME only: author request, 18 November 2026): PfPR-ACM with UN IGME all-cause mortality
#   against UN IGME (CA-CODE) malaria deaths under 5, both over the UN WPP population under 5, on linear axes. The
#   comparison is under 5 as a whole because CA-CODE publishes malaria deaths for 1-59 months as a whole (none under
#   1 month, no finer age groups; UNICEF dataflow CME_CAUSE_OF_DEATH), so an age-specific comparison cannot be made.
# Supplementary figure, log scale (author request, 18 November 2026): Figure 5 on log axes from 0.1 per 1,000, where
#   the low-burden countries separate and every country is named.
# Supplementary figure, IHME (panel B of Figure 5 until 18 November 2026): PfPR-ACM with IHME all-cause mortality
#   against IHME malaria deaths under 5, both over IHME person-years, on the axis limits of Figure 5.
# One point per country in a single colour (the UN sub-region colours were removed on 18 November 2026, author
# request), its size proportional to the square root of the UN WPP population under 5, so its area to the population
# (author request, 18 November 2026); dashed line: equality. Vertical lines: 95% uncertainty intervals of the PfPR-ACM estimates
# (R_cbh/burden/06_uncertainty_draws.R; 1 November 2026); horizontal lines: the published intervals of the
# cause-specific estimates (2 November 2026). Reads the rates of R_cbh/reporting/25_country_rates_table.R.
# Sizes meet the paper's printed text-size rule (CLAUDE.md) at 6.5 in; no title or caption in the figures.
# Outputs (<out>/model_vs_cause_specific/): fig5_model_vs_cause_specific_2024.png, figure_data.csv, CAPTION.md,
# sfig_model_vs_cause_specific_log_2024.png, CAPTION_log.md, sfig_model_vs_cause_specific_ihme_2024.png,
# figure_data_ihme.csv, CAPTION_ihme.md, provenance.csv
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/reporting/labels.R")
suppressPackageStartupMessages({ library(data.table); library(ggplot2) })
st <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION", "gadm")); root <- st$out
out <- file.path(root, "model_vs_cause_specific"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
fig_year <- 2024L
paths <- c(rates = file.path(root, sprintf("tables/country_rates_%d.csv", fig_year)),
  country = file.path(root, "annual_comparison/country_estimates_2000_2024.csv"),
  population = file.path(root, "annual_comparison/source_country_rates_2000_2024.csv"),
  ihme_malaria = "data/ihme_malaria_u5_deaths_by_age_country_year.csv")
stopifnot(all(file.exists(paths)))
w <- fread(paths[["rates"]])
stopifnot(nrow(w) == 42L, !anyDuplicated(w$iso3))
# Intervals of the cause-specific estimates (author request, 2 November 2026): CA-CODE's 90% bounds on its malaria
# deaths and IHME's 95% uncertainty intervals, applied to the rates as the ratio of bound to estimate (the denominators
# are unchanged).
ce <- fread(paths[["country"]])[year == fig_year]
im <- fread(paths[["ihme_malaria"]])[Year == fig_year & Sex == "Both" & Condition == "Malaria" & Measure == "Deaths" &
  Age == "Under 5" & Unit == "Number"][, iso3 := countrycode::countrycode(Location, "country.name", "iso3c", warn = FALSE)]
stopifnot(!anyDuplicated(im$iso3), all(w$iso3 %in% im$iso3),
  max(abs(im$Value[match(ce$iso3, im$iso3)] - ce$ihme_malaria_deaths)) < 1e-6)
ratio <- function(b, v) fifelse(v > 0, b / v, 0)
# Linear figures name only the higher-burden countries, those with an estimate of at least 4 per 1,000 from either
# source, so that the names stay readable (author request, 18 November 2026; naming every country at 1 or more was too
# busy). Every country is named in the log-scale figure.
label_min <- 4
# Point size: proportional to the square root of the UN WPP population under 5 (the same population in all three
# figures), the largest country at size_max.
size_max <- 8
pop <- fread(paths[["population"]])[source == "UN IGME" & year == fig_year, .(iso3, under5_population = under5_person_years)]
stopifnot(setequal(pop$iso3, w$iso3), all(pop$under5_population > 0))
point_size <- function(n) size_max * sqrt(n / max(pop$under5_population))
prepare <- function(z, bounds) {
  z <- merge(z, bounds, by = "iso3", sort = FALSE)
  z[, `:=`(cause_specific_lower = cause_specific * lo, cause_specific_upper = cause_specific * hi)][, c("lo", "hi") := NULL]
  stopifnot(nrow(z) == 42L, !anyNA(z), all(z$cause_specific_lower <= z$cause_specific & z$cause_specific <= z$cause_specific_upper))
  z[, labelled := pmax(model, cause_specific) >= label_min]
  z <- merge(z, pop, by = "iso3", sort = FALSE)[, psize := point_size(under5_population)]
  setorder(z, -psize)   # the largest points are drawn first, so that a small country is not hidden under a large one
  stopifnot(nrow(z) == 42L, !anyNA(z$psize))
  z[]
}
d <- prepare(w[, .(iso3, country, model = malaria_rate_per1000_unigme, model_lower = malaria_rate_per1000_lower_unigme,
    model_upper = malaria_rate_per1000_upper_unigme, cause_specific = cacode_malaria_rate)],
  ce[, .(iso3, lo = ratio(who_cacode_lower90, who_cacode_deaths), hi = ratio(who_cacode_upper90, who_cacode_deaths))])
h <- prepare(w[, .(iso3, country, model = malaria_rate_per1000_ihme, model_lower = malaria_rate_per1000_lower_ihme,
    model_upper = malaria_rate_per1000_upper_ihme, cause_specific = ihme_malaria_rate)],
  im[iso3 %in% w$iso3, .(iso3, lo = ratio(Lower, Value), hi = ratio(Upper, Value))])
# Linear axis limits from the UN IGME figure alone, so that the main-text figure does not depend on IHME; the IHME
# figure uses the same limits. They reach the points and every interval no longer than 1.5 times the largest point; a
# longer interval (South Sudan's, from UN IGME's wide all-cause bounds) is truncated at the edge with an arrow and
# given in the caption.
reach <- 1.5 * max(d$model, d$cause_specific)
lim <- c(0, max(d$model, d$cause_specific, d$model_upper[d$model_upper <= reach]) * 1.04); axis_breaks <- seq(0, 2 * floor(lim[2] / 2), 2)
for (z in list(d, h)) {
  z[, `:=`(model_upper_shown = pmin(model_upper, lim[2]), truncated = model_upper > lim[2])]
  stopifnot(all(z$model <= lim[2]), all(z$cause_specific_upper <= lim[2]))   # points and horizontal intervals are never cut
}
cbh_atomic_csv(d, file.path(out, "figure_data.csv")); cbh_atomic_csv(h, file.path(out, "figure_data_ihme.csv"))
point_colour <- "#0072B2"; interval_colour <- "grey70"
# Country names: placed by ggrepel from a fixed seed, with the iteration limit (not the time limit) ending the search,
# so the layout is the same on every run. Each label starts on the far side of its point from the equality line
# (nudges nx, ny, in axis units); the limits keep the names inside the panel.
# The names keep clear of the points (point.size: each point's own size) and have a white halo, so that they stay
# readable where they cross an interval line.
name_labels <- function(lab, xlim, ylim, points) ggrepel::geom_text_repel(data = lab, aes(label = label), size = points / .pt, colour = "grey10",
  bg.color = "white", bg.r = .13, seed = 20261118L, max.overlaps = Inf, nudge_x = lab$nx, nudge_y = lab$ny, max.iter = 100000, max.time = 600,
  force = 2.5, force_pull = .8, point.size = lab$psize, box.padding = .3, point.padding = .15, min.segment.length = 0, segment.colour = "grey35",
  segment.size = .25, xlim = xlim, ylim = ylim)
# Points: filled circles with a white edge; the legend shows the size of 1, 5 and 20 million children under 5.
size_keys <- c(1, 5, 20)
size_legend <- list(scale_size_identity(name = "Children under 5\n(millions)", guide = "legend", breaks = point_size(size_keys * 1e6), labels = as.character(size_keys)),
  guides(size = guide_legend(override.aes = list(shape = 21, fill = "#0072B2", colour = "white", stroke = .3, alpha = .8))))
# Paper terms (author decision, 30 October 2026): "malaria deaths" for the cause-specific estimates (x),
# "malaria-attributable deaths" for the PfPR-ACM estimates, which include indirect effects (y).
axis_titles <- function(source_label) labs(x = sprintf("Malaria deaths per 1,000 child-years (%s)", source_label),
  y = "Malaria-attributable deaths per 1,000 child-years (PfPR-ACM)")
figure_theme <- theme_minimal(base_size = 9, base_line_size = .3) +
  theme(axis.title = element_text(size = 11), axis.text = element_text(size = 9), panel.grid.minor = element_blank(), plot.margin = margin(4, 8, 4, 4),
    # The size legend sits inside the panel's lower right corner, which is empty in all three figures.
    legend.position = "inside", legend.position.inside = c(.98, .02), legend.justification = c(1, 0), legend.title = element_text(size = 11),
    legend.text = element_text(size = 9), legend.background = element_rect(fill = "white", colour = NA), legend.key.spacing.y = grid::unit(1, "pt"))
# PfPR-ACM on the y-axis, the cause-specific estimate on the x-axis (user request, 28 October 2026).
scatter <- function(z, source_label) {
  # Unnamed countries are passed with an empty label, so that the names keep clear of their points too.
  lab <- z[, .(cause_specific, model, psize, label = fifelse(labelled, country, ""), above = model >= cause_specific)]
  # A start outside the panel would drop the label, so the nudge stops short of the edges.
  inside <- function(v, step) pmin(pmax(v + step, lim[1] + .05), lim[2] - .05) - v
  lab[, `:=`(nx = inside(cause_specific, fifelse(above, -.45, .45)), ny = inside(model, fifelse(above, .4, -.4)))]
  ggplot(z, aes(cause_specific, model)) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey50", linewidth = .35) +
    geom_linerange(aes(ymin = model_lower, ymax = model_upper_shown), linewidth = .3, colour = interval_colour) +
    geom_linerange(aes(xmin = cause_specific_lower, xmax = cause_specific_upper), linewidth = .3, colour = interval_colour) +
    geom_segment(data = z[truncated == TRUE], aes(x = cause_specific, xend = cause_specific, y = model, yend = lim[2]),
      linewidth = .3, colour = interval_colour, arrow = grid::arrow(length = grid::unit(1.4, "mm"))) +
    geom_point(aes(size = psize), shape = 21, fill = point_colour, colour = "white", stroke = .3, alpha = .8) +
    name_labels(lab, lim, lim, 10) + size_legend +
    scale_x_continuous(limits = lim, breaks = axis_breaks, expand = expansion(mult = c(0, .02))) +
    scale_y_continuous(limits = lim, breaks = axis_breaks, expand = expansion(mult = c(0, .02))) +
    coord_equal() + axis_titles(source_label) + figure_theme
}
# Log-scale version of Figure 5: both axes start at 0.1 per 1,000 and a value below it is drawn at 0.1 with an open
# circle; the x-axis ends at 10 and the y-axis at 16, which hold every point and interval. Grid lines at every 1-9
# multiple of each decade (the decades darker); 1, 2, 3 and 5 of each decade are labelled.
floor_at <- 0.1; top_x <- 10; top_y <- 16
scatter_log <- function(z, source_label) {
  clamp <- function(v, top) pmin(pmax(v, floor_at), top)
  z <- copy(z)[, `:=`(x = clamp(cause_specific, top_x), y = clamp(model, top_y), below = cause_specific < floor_at | model < floor_at,
    xlo = clamp(cause_specific_lower, top_x), xhi = clamp(cause_specific_upper, top_x), ylo = clamp(model_lower, top_y), yhi = clamp(model_upper, top_y))]
  stopifnot(all(z$model_upper <= top_y), all(z$cause_specific_upper <= top_x))   # nothing is cut at the top or right
  # One label for countries drawn at the same place (both values below the floor). Nudges are in log10 units: into the
  # panel for points at the left or bottom edge, and to the right for four countries in the densest part, where the
  # space is between the cluster and the line.
  lab <- z[, .(label = paste(country, collapse = ", "), iso3 = iso3[1], psize = max(psize), above = model[1] >= cause_specific[1]), by = .(x, y)]
  lab[, `:=`(nx = fifelse(x <= floor_at * 1.1, .07, fifelse(above, -.07, .07)), ny = fifelse(y <= floor_at * 1.1, .06, fifelse(above, .05, -.05)))]
  lab[data.table(iso3 = c("MOZ", "BDI", "UGA", "TCD"), nx = c(.11, .11, .07, .08), ny = c(.01, -.03, -.07, -.05)), on = "iso3", `:=`(nx = i.nx, ny = i.ny)]
  grid_at <- function(top) { g <- as.vector(outer(1:9, 10^(-1:1))); g[g >= floor_at & g <= top] }
  decades <- c(0.1, 1, 10); labelled_ticks <- c(0.1, 0.2, 0.3, 0.5, 1, 2, 3, 5, 10)
  # Breaks come back from the log scale with rounding error, so they are matched to the labelled values with a tolerance.
  tick <- function(b) vapply(b, function(v) { k <- which(abs(log10(v / labelled_ticks)) < 1e-6); if (length(k)) as.character(labelled_ticks[k]) else "" }, "")
  ggplot(z, aes(x, y)) +
    geom_vline(xintercept = setdiff(grid_at(top_x), decades), colour = "grey92", linewidth = .25) +
    geom_hline(yintercept = setdiff(grid_at(top_y), decades), colour = "grey92", linewidth = .25) +
    geom_vline(xintercept = decades, colour = "grey80", linewidth = .3) + geom_hline(yintercept = decades, colour = "grey80", linewidth = .3) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey50", linewidth = .35) +
    geom_linerange(aes(ymin = ylo, ymax = yhi), linewidth = .3, colour = interval_colour) +
    geom_linerange(aes(xmin = xlo, xmax = xhi), linewidth = .3, colour = interval_colour) +
    geom_point(data = z[below == FALSE], aes(size = psize), shape = 21, fill = point_colour, colour = "white", stroke = .3, alpha = .8) +
    geom_point(data = z[below == TRUE], aes(size = psize), shape = 21, fill = "white", colour = point_colour, stroke = .6, show.legend = FALSE) +
    name_labels(lab, log10(c(floor_at * .9, top_x * 1.08)), log10(c(floor_at * .9, top_y)), 9) + size_legend +   # ggrepel's limits are on the log scale
    scale_x_log10(limits = c(floor_at, top_x), breaks = grid_at(top_x), labels = tick, expand = expansion(mult = .03)) +
    scale_y_log10(limits = c(floor_at, top_y), breaks = grid_at(top_y), labels = tick, expand = expansion(mult = .03)) +
    coord_fixed() + axis_titles(source_label) + figure_theme + theme(panel.grid = element_blank())
}
save_figure <- function(p, file, height) {
  stopifnot(is.null(p$labels$title), is.null(p$labels$subtitle), is.null(p$labels$caption))
  ggsave(file.path(out, file), p, device = ragg::agg_png, width = 6.5, height = height, dpi = 400, bg = "white")
}
save_figure(scatter(d, "UN IGME"), sprintf("fig5_model_vs_cause_specific_%d.png", fig_year), 6.3)
save_figure(scatter_log(d, "UN IGME"), sprintf("sfig_model_vs_cause_specific_log_%d.png", fig_year), 6.9)
save_figure(scatter(h, "IHME"), sprintf("sfig_model_vs_cause_specific_ihme_%d.png", fig_year), 6.3)
summarise <- function(z) z[, .(rho = cor(model, cause_specific, method = "spearman"), above = sum(model > cause_specific),
  lower_above = sum(model_lower > cause_specific), upper_below = sum(model_upper < cause_specific))]
caption <- function(z, heading, title, axes, cause, cause_interval, names_text, cut_text, last) { s <- summarise(z); c(heading, "",
  paste0(sprintf("**Figure. Malaria-attributable under-five mortality in %d: %s.** ", fig_year, title),
    "Each point is a country; rates are deaths per 1,000 child-years under 5. ", axes,
    sprintf("The PfPR-ACM estimate counts all deaths averted if prevalence fell to zero (direct and indirect); %s counts deaths assigned to malaria as the underlying cause. ", cause),
    "The dashed line is equality. Point area is proportional to the population under 5 (UN WPP). ", names_text,
    sprintf("Spearman correlation: %.2f; the PfPR-ACM estimate is higher in %d of %d countries. ", s$rho, s$above, nrow(z)),
    sprintf("Vertical lines are 95%% uncertainty intervals of the PfPR-ACM estimates, from 500 joint draws of MAP's national PfPR[2–10], the all-cause deaths and the PfPR–death curves (Supplementary Methods); horizontal lines are %s. ", cause_interval),
    sprintf("The lower bound exceeds the %s estimate in %d countries, and the upper bound is below it in %d. ", cause, s$lower_above, s$upper_below),
    cut_text, last)) }
linear_names <- function(z) sprintf("Countries with an estimate of at least %g per 1,000 from either source are named (%d of %d). ", label_min, sum(z$labelled), nrow(z))
linear_cut <- function(z) if (any(z$truncated)) paste0("Intervals beyond the axes are truncated with an arrow: ",
  paste(z[truncated == TRUE, sprintf("%s (upper bound %.1f)", country, model_upper)], collapse = "; "), ". ") else ""
unigme_axes <- "PfPR-ACM estimates using UN IGME all-cause mortality (y) against UN IGME (CA-CODE) malaria deaths (x), both over the UN WPP population under 5. "
unigme_last <- "CA-CODE assigns malaria deaths to ages 1–59 months as a whole and none under 1 month, and takes malaria from WHO estimates in 13 low-burden countries."
writeLines(caption(d, "# Figure 5 caption — PfPR-ACM against UN IGME malaria mortality, by country",
  "PfPR-ACM model against UN IGME malaria deaths", unigme_axes, "UN IGME", "the 90% bounds of the UN IGME (CA-CODE) malaria deaths",
  linear_names(d), linear_cut(d), unigme_last), file.path(out, "CAPTION.md"))
low <- d[cause_specific < floor_at | model < floor_at]
writeLines(caption(d, "# Supplementary figure caption — PfPR-ACM against UN IGME malaria mortality, by country, log scale",
  "PfPR-ACM model against UN IGME malaria deaths, on log scales", unigme_axes, "UN IGME", "the 90% bounds of the UN IGME (CA-CODE) malaria deaths",
  "The data are those of the main-text figure; every country is named. ",
  sprintf("Both axes are logarithmic and start at %g per 1,000: a value below that is drawn at %g with an open circle (%s), and intervals are cut there. ",
    floor_at, floor_at, paste(sprintf("%s: UN IGME %.2f, PfPR-ACM %.2f", low$country, low$cause_specific, low$model), collapse = "; ")),
  unigme_last), file.path(out, "CAPTION_log.md"))
writeLines(caption(h, "# Supplementary figure caption — PfPR-ACM against IHME malaria mortality, by country",
  "PfPR-ACM model with IHME all-cause mortality against IHME malaria deaths",
  "PfPR-ACM estimates using IHME all-cause mortality (y) against IHME malaria deaths (x), both over IHME person-years. ",
  "IHME", "IHME's 95% uncertainty intervals", linear_names(h), linear_cut(h),
  "The axes are those of the main-text figure (UN IGME). South Sudan's IHME all-cause mortality is its crisis-free value."),
  file.path(out, "CAPTION_ihme.md"))
provenance <- c(unname(paths), "R_cbh/reporting/27_model_vs_cause_specific.R", "R_cbh/reporting/labels.R")
cbh_atomic_csv(data.frame(file = provenance, md5 = vapply(provenance, cbh_file_hash, "")), file.path(out, "provenance.csv"))
print(rbind(cbind(figure = "UN IGME", summarise(d), named = sum(d$labelled)), cbind(figure = "IHME", summarise(h), named = sum(h$labelled))))
message("Figure 5 (UN IGME), its log-scale version and the IHME figure saved: ", out)
