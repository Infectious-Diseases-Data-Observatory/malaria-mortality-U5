#!/usr/bin/env Rscript
# Supplementary figure (added 1 October 2026, at the user's request): malaria's share of under-five
# deaths against national PfPR[2-10] in 2024, by country, for IHME, CA-CODE and the PfPR-ACM model.
# x: MAP's own national PfPR estimate, the one the burden uses.
# IHME: IHME under-5 malaria deaths / IHME all-cause under-5 deaths (burden/country_totals.csv).
# CA-CODE: the CA-CODE 2026 published malaria share of under-5 deaths with its published bounds
# (data/external/cacode/, fetched 1 October 2026), as in the country table (25_country_rates_table.R). Its denominator
# is CA-CODE's sum over causes, which in some countries exceeds UN IGME's all-cause under-5 count (DRC 2024: 428,472 vs
# 385,039), so CA-CODE malaria deaths / UN IGME deaths would not reproduce it. Countries where CA-CODE takes malaria
# from WHO estimates (low-burden rule) are drawn hollow.
# PfPR-ACM: the malaria-attributable share of all-cause under-5 deaths with its 95% uncertainty interval, from the
# paper's uncertainty draws (R_cbh/burden/06_uncertainty_draws.R). Each comparator is set against the model based on
# the same all-cause source (author request, 21 November 2026, when the paper's primary analysis became UN IGME): the
# IHME-based model in the IHME panels (A, C) and the UN IGME-based model in the CA-CODE panels (B, D). Until then
# every panel used the IHME-based model, with intervals from the hazard ratios alone.
# The PfPR-ACM share includes indirect deaths; IHME and CA-CODE count deaths caused by malaria.
# Panels C and D: the PfPR-ACM share against the IHME and CA-CODE shares, one point per country, with the line of
# equality.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/reporting/labels.R")
suppressPackageStartupMessages({library(data.table); library(ggplot2); library(patchwork)})
st <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION", "gadm"))
fig_year <- 2024L
out <- file.path(st$out, "malaria_share"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
paths <- c(totals = file.path(st$out, "burden/country_totals.csv"),
           intervals = file.path(st$out, "uncertainty/country_year_intervals_2000_2024.csv"),
           rates = file.path(st$out, "annual_comparison/source_country_rates_2000_2024.csv"),
           cacode = "data/external/cacode/unicef_cacode_u5_malaria_fraction_2000_2024.csv",
           cacode_source = "data/external/cacode/source.json")
stopifnot(all(file.exists(paths)))
# CA-CODE low-burden countries flagged for WHO malaria estimates: malwho == 1 in the published input file
# github.com/JHU-CACODE/BMJ2026-MortUnder5 Postneonates/data/WHOmal_20241009.csv, with Namibia removed
# in Predict_VA_stan.R ("WHO estimate is >60%"). Sub-Saharan entries only (read 1 October 2026). The step
# that substitutes WHO values reads an input file not in the repository, so this is the published flag,
# not a confirmed list for the 2024 series.
who_malaria <- c("BWA", "COM", "CPV", "DJI", "ERI", "ETH", "MDG", "SDN", "SOM", "STP", "SWZ", "ZAF", "ZWE")

tot <- fread(paths[["totals"]])[year == fig_year & status == "estimated"]
stopifnot(nrow(tot) == 42L, !anyDuplicated(tot$iso3))
# The model's share and 95% uncertainty interval by all-cause source (crisis-free values in a crisis year).
ui <- fread(paths[["intervals"]])[year == fig_year]
stopifnot(setequal(ui$source, c("IHME", "UN IGME")), all(ui[, .N, by = source]$N == 42L), !anyDuplicated(ui[, .(source, iso3)]),
          setequal(ui$iso3, tot$iso3), all(ui$malaria_fraction_lower <= ui$malaria_fraction_upper),
          max(abs(ui$pfpr_pct - tot$pfpr_pct[match(ui$iso3, tot$iso3)])) < 1e-9)
model_share <- function(src, tag) setnames(ui[source == src, .(iso3, malaria_fraction, malaria_fraction_lower, malaria_fraction_upper)],
  c("iso3", paste0("acm_", tag, c("", "_lower", "_upper"))))
acm <- merge(model_share("IHME", "ihme"), model_share("UN IGME", "unigme"), by = "iso3")

cc <- fread(paths[["cacode"]])[TIME_PERIOD == fig_year & SEX == "_T" & AGE_GROUP == "Y0T4" &
                               INDICATOR == "FRACTION" & CAUSE_OF_DEATH == "MALARIA" & UNIT_MEASURE == "PCNT"]
stopifnot(!anyDuplicated(cc$REF_AREA), all(tot$iso3 %in% cc$REF_AREA))
d <- merge(tot[, .(iso3, country, pfpr_pct, ihme = ihme_malaria_deaths / ihme_under5_deaths)], acm, by = "iso3")
d <- merge(d, cc[, .(iso3 = REF_AREA, cacode = OBS_VALUE / 100, cacode_lower = LOWER_BOUND / 100,
                     cacode_upper = UPPER_BOUND / 100)], by = "iso3")
d[, cacode_who_malaria := iso3 %in% who_malaria]
stopifnot(nrow(d) == 42L, !anyNA(d), all(d$cacode_lower <= d$cacode & d$cacode <= d$cacode_upper))
display <- c(Swaziland = "Eswatini", `Cote d'Ivoire` = "Côte d'Ivoire", Congo = "Republic of the Congo",
             `Democratic Republic of the Congo` = "DR Congo")
d[, country := fifelse(country %in% names(display), display[country], country)]
setorder(d, -pfpr_pct)
pc <- function(v) 100 * v
cbh_atomic_csv(d[, .(iso3, country, year = fig_year, pfpr_pct, ihme_share_pct = pc(ihme),
  cacode_share_pct = pc(cacode), cacode_share_lower_pct = pc(cacode_lower), cacode_share_upper_pct = pc(cacode_upper),
  cacode_uses_who_malaria = cacode_who_malaria,
  pfpr_acm_ihme_share_pct = pc(acm_ihme), pfpr_acm_ihme_share_lower95_pct = pc(acm_ihme_lower),
  pfpr_acm_ihme_share_upper95_pct = pc(acm_ihme_upper),
  pfpr_acm_unigme_share_pct = pc(acm_unigme), pfpr_acm_unigme_share_lower95_pct = pc(acm_unigme_lower),
  pfpr_acm_unigme_share_upper95_pct = pc(acm_unigme_upper))],
  file.path(out, "malaria_share_vs_pfpr_2024.csv"))

## Figure -------------------------------------------------------------------------------------------
# Saved 157 mm wide and printed at 0.9\linewidth (148.6 mm; main.tex), so printed text is 0.946 times the script size
# and meets the paper's text-size rule (CLAUDE.md): axis titles 11.7 pt in the script (11.1 pt printed), other text
# 9.6 pt (9.1 pt), panel titles with their tags 12.8 pt (12.1 pt). The three shares measure different things: the
# model's is attributable (direct and indirect deaths; stated in the caption), IHME's and CA-CODE's are cause-assigned.
txt <- 9.6; axis_title <- 11.7; panel_title <- 12.8
model <- cbh_paper_model_label(); short <- sub(" model$", "", model)   # short form for the titles of panels C and D
keys <- c(acm = model, ihme = "IHME (cause of death)", cacode = "CA-CODE (cause of death)",
          who = "CA-CODE (malaria from WHO estimates)")
cols <- setNames(c("#16747C", "#253746", "#CC6A30", "#CC6A30"), keys)   # as in Figure 3, panel C
fills <- setNames(c("#16747C", "#253746", "#CC6A30", "white"), keys)
shapes <- setNames(c(21, 24, 23, 23), keys)
ymax <- ceiling(100 * max(d$acm_ihme_upper, d$acm_unigme_upper, d$cacode_upper, d$ihme) / 5) * 5
xmax <- ceiling(max(d$pfpr_pct) / 5) * 5
label_n <- 7L; shift <- .25   # comparators sit slightly right of the model point
# Every share axis has the same title (user request, 30 October 2026); the caption says which measure each axis shows.
share_lab <- "Share of all-cause mortality (%)"
# Long country names are labelled on two lines (figure only; the tables keep the full names on one line).
plot_name <- function(x) sub("^(Central African|Republic of|Equatorial) ", "\\1\n", x)
# A comparator's rows carry the model based on the same all-cause source: IHME for IHME, UN IGME for CA-CODE.
comparator <- function(src) {
  is_cacode <- src == "cacode"
  copy(d)[, `:=`(comp = 100 * get(src), comp_lo = if (is_cacode) 100 * cacode_lower else NA_real_,
                 comp_hi = if (is_cacode) 100 * cacode_upper else NA_real_,
                 acm = if (is_cacode) acm_unigme else acm_ihme, acm_lower = if (is_cacode) acm_unigme_lower else acm_ihme_lower,
                 acm_upper = if (is_cacode) acm_unigme_upper else acm_ihme_upper,
                 series = if (is_cacode) fifelse(cacode_who_malaria, keys[["who"]], keys[["cacode"]]) else keys[["ihme"]])]
}
# The same countries are labelled in the PfPR panel and the scatter panel for each source.
labelled <- function(z) z[order(-abs(comp - 100 * acm))][seq_len(label_n)]
# Labels in panels A and B, one layer for the labelled countries in the lower half of their PfPR range and one for the
# rest; the other points, model points included, are unlabelled rows that labels avoid. A stacked layer starts 3 points
# to the left (lower half) or right of the comparator point, extends away from it and moves only vertically, so its
# labels stack beside the cluster of points at PfPR 15-25%; an unstacked layer is placed freely near the points.
side_labels <- function(z, lab, side, stack = TRUE) {
  left <- side == "left"; on <- z$iso3 %in% lab$iso3 & (z$pfpr_pct < median(lab$pfpr_pct)) == left
  rows <- rbind(z[, .(x = pfpr_pct + shift, y = comp, label = fifelse(on, plot_name(country), ""),
                      nx = fifelse(on & stack, if (left) -3 else 3, 0))], z[, .(x = pfpr_pct, y = 100 * acm, label = "", nx = 0)])
  ggrepel::geom_text_repel(data = rows, aes(x = x, y = y, label = label), nudge_x = rows$nx, hjust = if (!stack) .5 else if (left) 1 else 0,
                           direction = if (stack) "y" else "both", size = txt / .pt, lineheight = .85, colour = "grey15",
                           bg.colour = "white", bg.r = .15, min.segment.length = 0, segment.colour = "grey35", segment.size = .3,
                           box.padding = if (stack) .12 else .3, point.padding = if (stack) .2 else .4, force = 4,
                           force_pull = if (stack) .1 else .5, max.overlaps = Inf, max.time = Inf, max.iter = 1e5, seed = 1)
}
panel <- function(src, title) {
  is_cacode <- src == "cacode"  # not 'cacode', which is a column of d
  z <- comparator(src)
  lab <- labelled(z)
  k <- unname(keys)   # same keys in both panels, so the legends collect into one
  p <- ggplot(z, aes(x = pfpr_pct)) +
    geom_segment(aes(xend = pfpr_pct + shift, y = 100 * acm, yend = comp), colour = "grey78", linewidth = .26) +
    geom_segment(data = lab, aes(xend = pfpr_pct + shift, y = 100 * acm, yend = comp), colour = "grey40", linewidth = .4) +
    geom_linerange(aes(ymin = 100 * acm_lower, ymax = 100 * acm_upper), colour = cols[[1]], alpha = .7, linewidth = .45)
  if (is_cacode) p <- p + geom_linerange(aes(x = pfpr_pct + shift, ymin = comp_lo, ymax = comp_hi),
                                       colour = cols[[keys[["cacode"]]]], alpha = .6, linewidth = .45)
  # One legend for the figure, drawn from panel B: an invisible IHME layer gives B the IHME key.
  if (is_cacode) p <- p + geom_point(data = z[1], aes(y = 100 * ihme, colour = keys[["ihme"]], shape = keys[["ihme"]],
                                                    fill = keys[["ihme"]]), alpha = 0)
  p <- p +
    geom_point(aes(y = 100 * acm, colour = keys[["acm"]], shape = keys[["acm"]], fill = keys[["acm"]]), size = 1.5, stroke = .35) +
    geom_point(aes(x = pfpr_pct + shift, y = comp, colour = series, shape = series, fill = series), size = 1.6, stroke = .45) +
    # The upper half is stacked in panel B only; in panel A (PfPR up to 37%) those labels have room to be placed freely.
    side_labels(z, lab, "left") + side_labels(z, lab, "right", stack = is_cacode) +
    scale_colour_manual(values = cols, limits = k, name = NULL) +
    scale_fill_manual(values = fills, limits = k, name = NULL) +
    scale_shape_manual(values = shapes, limits = k, name = NULL) +
    guides(colour = guide_legend(nrow = 2, byrow = TRUE, override.aes = list(alpha = 1, size = 1.6)),
           fill = guide_legend(nrow = 2, byrow = TRUE), shape = guide_legend(nrow = 2, byrow = TRUE)) +
    scale_x_continuous(limits = c(0, xmax + 1), breaks = seq(0, xmax, 5), expand = expansion(add = c(.5, 0))) +
    scale_y_continuous(limits = c(0, ymax), breaks = seq(0, ymax, 5), expand = expansion(add = c(.6, 0))) +
    coord_cartesian(clip = "off") +
    labs(title = title, x = bquote("National"~italic(Pf)*PR["2–10"]*","~.(fig_year)~"(%)"),
         y = if (is_cacode) NULL else share_lab) +
    theme_minimal(base_size = axis_title, base_line_size = .34) +
    theme(panel.grid.minor = element_blank(), legend.position = "bottom", legend.text = element_text(size = txt),
          axis.text = element_text(size = txt), legend.key.width = unit(2.6, "mm"), legend.key.spacing.y = unit(1, "pt"),
          plot.title = element_text(size = panel_title, face = "bold"), plot.title.position = "plot")
  if (is_cacode) p else p + guides(colour = "none", fill = "none", shape = "none")
}
lim <- ymax
scatter <- function(src, title) {
  is_cacode <- src == "cacode"
  z <- comparator(src); lab <- labelled(z)
  higher <- sum(z$acm * 100 > z$comp)
  rho <- cor(z$acm, z$comp, method = "spearman")
  p <- ggplot(z, aes(x = comp, y = 100 * acm)) +
    geom_abline(slope = 1, intercept = 0, colour = "grey55", linetype = "dashed", linewidth = .3) +
    geom_linerange(aes(ymin = 100 * acm_lower, ymax = 100 * acm_upper), colour = cols[[1]], alpha = .6, linewidth = .4)
  if (is_cacode) p <- p + geom_segment(aes(x = comp_lo, xend = comp_hi, yend = 100 * acm),
                                     colour = cols[[keys[["cacode"]]]], alpha = .55, linewidth = .4)
  p +
    geom_point(aes(colour = series, shape = series, fill = series), size = 1.6, stroke = .45) +
    # Labels start above their points for the upper half of the labelled countries and below for the rest, so that they
    # spread out of the cluster.
    ggrepel::geom_text_repel(aes(label = fifelse(iso3 %in% lab$iso3, plot_name(country), "")), size = txt / .pt, lineheight = .9,
                             nudge_y = fifelse(z$iso3 %in% lab$iso3, fifelse(z$acm >= median(lab$acm), .2, -.15), 0) * lim,
                             xlim = c(0, lim), ylim = c(0, lim),
                             colour = "grey15", bg.colour = "white", bg.r = .15, min.segment.length = 0, segment.colour = "grey35",
                             segment.size = .3, box.padding = .2, point.padding = .2, force = 4, force_pull = .3, max.overlaps = Inf,
                             max.time = Inf, max.iter = 1e5, seed = 1) +
    annotate("text", x = .98 * lim, y = .02 * lim, hjust = 1, vjust = 0, size = txt / .pt, colour = "grey20", lineheight = .95,
             label = sprintf("Spearman \u03c1 = %.2f\n%s higher\nin %d of %d", rho, model, higher, nrow(z))) +
    annotate("text", x = .97 * lim, y = .92 * lim, hjust = 1, vjust = 0, size = txt / .pt, colour = "grey45", label = "equality") +
    scale_colour_manual(values = cols, limits = unname(keys), name = NULL) +
    scale_fill_manual(values = fills, limits = unname(keys), name = NULL) +
    scale_shape_manual(values = shapes, limits = unname(keys), name = NULL) +
    guides(colour = "none", fill = "none", shape = "none") +
    scale_x_continuous(limits = c(0, lim), breaks = seq(0, lim, 10), expand = expansion(add = c(.6, .6))) +
    scale_y_continuous(limits = c(0, lim), breaks = seq(0, lim, 10), expand = expansion(add = c(.6, .6))) +
    coord_equal(clip = "off") +
    labs(title = title, x = share_lab, y = if (is_cacode) NULL else share_lab) +
    theme_minimal(base_size = axis_title, base_line_size = .34) +
    theme(panel.grid.minor = element_blank(), axis.text = element_text(size = txt), plot.title = element_text(size = panel_title, face = "bold"),
          plot.title.position = "plot")
}
fig <- (panel("ihme", "A  IHME") | panel("cacode", "B  CA-CODE")) /
  (scatter("ihme", paste0("C  ", short, " vs IHME")) |
   scatter("cacode", paste0("D  ", short, " vs CA-CODE"))) +
  plot_layout(guides = "collect", heights = c(1.2, 1.1)) + plot_annotation(theme = theme(legend.position = "bottom"))
ggsave(file.path(out, "sfig_malaria_share_vs_pfpr.png"), fig, width = 157, height = 198, units = "mm", dpi = 600,
       device = ragg::agg_png, bg = "white")

## Caption and provenance -----------------------------------------------------------------------------
sp <- function(v, rows = TRUE) cor(d$pfpr_pct[rows], v[rows], method = "spearman")
med <- function(v) median(100 * v)
who_in <- d[cacode_who_malaria == TRUE, country]
# A country in a crisis year takes its crisis-free values (R_cbh/burden/04_annual_comparison.R); the caption names it.
rates <- fread(paths[["rates"]])[year == fig_year & crisis_year == TRUE]
crisis_note <- if (nrow(rates)) sprintf(" In a crisis year the model share is the crisis-free value (%s).",
  paste(sprintf("%s, %s-based", d$country[match(rates$iso3, d$iso3)], rates$source), collapse = "; ")) else ""
writeLines(c("# Supplementary figure: malaria's share of under-five deaths against PfPR and between sources, 2024", "",
  sprintf(paste0("Malaria's share of under-five deaths in %d in %d sub-Saharan African countries: the malaria-attributable share from the %s ",
    "compared with the share of deaths assigned to malaria by IHME and by CA-CODE. ",
    "The model's share is the share of all-cause under-five deaths that would not occur at *Pf*PR 0, so it includes deaths caused indirectly by malaria; ",
    "it is based on IHME all-cause deaths in panels A and C and on UN IGME all-cause deaths in panels B and D. ",
    "A, B: each country is plotted at its national *Pf*PR~2–10~ (Malaria Atlas Project); a grey line joins its model value (teal circles) to ",
    "the IHME value (A, navy triangles: IHME under-five malaria deaths divided by IHME all-cause under-five deaths) or ",
    "the CA-CODE value (B, orange diamonds: CA-CODE's published malaria share of under-five deaths). Comparator points are shifted slightly to the right. ",
    "C, D: the model's share against the IHME share (C) and the CA-CODE share (D), one point per country; the dashed line shows equality. ",
    "Vertical bars are the model's 95%% uncertainty intervals; orange bars are CA-CODE's published bounds (interval level not stated in the download); IHME intervals are not shown. ",
    "For each source the %d countries with the largest absolute difference from the model are named, with darker joining lines in A and B. ",
    "Hollow diamonds mark countries flagged in CA-CODE's published input file for WHO malaria estimates in place of its verbal-autopsy model (%s). ",
    "The model's share is higher than IHME's in %d of %d countries and higher than CA-CODE's in %d (Spearman correlation %.2f and %.2f). ",
    "Median share across the %d countries: model %.1f%% (IHME-based) and %.1f%% (UN IGME-based), IHME %.1f%%, CA-CODE %.1f%%. ",
    "Spearman correlation with *Pf*PR: IHME %.2f, CA-CODE %.2f (%.2f without the WHO-estimate countries).%s ",
    "The CA-CODE share is computed on CA-CODE's own total of cause-specific deaths, which can differ from the UN IGME all-cause count (DR Congo: 428,472 against 385,039 deaths). ",
    "Lesotho has no MAP national estimate, Cabo Verde and São Tomé and Príncipe are outside the 42-country burden set, and Sudan and South Africa are not in the IHME export, so all five are excluded from every panel."),
    fig_year, nrow(d), model, label_n, paste(who_in, collapse = ", "),
    sum(d$acm_ihme > d$ihme), nrow(d), sum(d$acm_unigme > d$cacode),
    cor(d$acm_ihme, d$ihme, method = "spearman"), cor(d$acm_unigme, d$cacode, method = "spearman"),
    nrow(d), med(d$acm_ihme), med(d$acm_unigme), med(d$ihme), med(d$cacode),
    sp(d$ihme), sp(d$cacode), sp(d$cacode, !d$cacode_who_malaria), crisis_note)),
  file.path(out, "CAPTION.md"))
inputs <- c(unname(paths), "R_cbh/reporting/20_malaria_share_vs_pfpr.R", "R_cbh/reporting/labels.R")
cbh_atomic_csv(data.frame(file = inputs, md5 = vapply(inputs, cbh_file_hash, "")), file.path(out, "provenance.csv"))
message(sprintf("Malaria share figure written: %s (%d countries; model higher than IHME in %d, than CA-CODE in %d)",
                out, nrow(d), sum(d$acm_ihme > d$ihme), sum(d$acm_unigme > d$cacode)))
