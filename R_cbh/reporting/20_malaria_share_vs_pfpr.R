#!/usr/bin/env Rscript
# Supplementary figure (added 1 October 2026, at the user's request): malaria's share of under-five
# deaths against national PfPR[2-10] in 2024, by country, for IHME, UN IGME (CA-CODE) and the PfPR-ACM
# model. x: the national PfPR used for the 2024 burden, MAP's own national estimate since 1 November 2026 (formerly
# the GPW 2020-weighted raster mean, whose raster-coverage marker is dropped), from burden/country_totals.csv. IHME: IHME under-5 malaria deaths / IHME all-cause under-5 deaths.
# UN IGME: the CA-CODE 2026 published malaria share of under-5 deaths with its published bounds
# (data/external/cacode/, fetched 1 October 2026). Its denominator is CA-CODE's sum over causes,
# which in some countries exceeds UN IGME's all-cause under-5 count (DRC 2024: 428,472 vs 385,039),
# so CA-CODE malaria deaths / UN IGME deaths would not reproduce it. Countries where CA-CODE takes
# malaria from WHO estimates (low-burden rule) are drawn hollow. PfPR-ACM: under-5 deaths
# attributable to malaria (PfPR to zero) / IHME all-cause under-5 deaths, with a 95% interval from
# independent draws of the seven age bands' log hazard ratios, as in Figure 4 (envelope fixed).
# The PfPR-ACM share includes indirect deaths; IHME and CA-CODE count deaths caused by malaria.
# Panels C and D (added the same day, user request): the PfPR-ACM share against the IHME and UN IGME
# shares, one point per country, with the line of equality.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/reporting/labels.R")
suppressPackageStartupMessages({library(data.table); library(ggplot2); library(patchwork)})
st <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION", "regional_mics"))
fig_year <- 2024L
out <- file.path(st$out, "malaria_share"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
paths <- c(totals = file.path(st$out, "burden/country_totals.csv"),
           bands = file.path(st$out, "burden/country_age_estimates.csv"),
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
bands <- fread(paths[["bands"]])[year == fig_year & status == "estimated"]
stopifnot(nrow(tot) == 42L, !anyDuplicated(tot$iso3), all(bands[, .N, by = iso3]$N == 7L),
          setequal(bands$iso3, tot$iso3), all(bands$log_hr_se > 0))
check <- bands[, .(af = sum(ihme_deaths * -expm1(log_hr_zero_vs_current)) / sum(ihme_deaths)), by = iso3]
stopifnot(max(abs(check$af - tot$attributable_fraction[match(check$iso3, tot$iso3)])) < 1e-9)
set.seed(st$seed); n_draws <- 4000L
acm <- bands[, {
  draws <- vapply(seq_len(.N), function(g) ihme_deaths[g] * -expm1(rnorm(n_draws, log_hr_zero_vs_current[g], log_hr_se[g])), numeric(n_draws))
  af <- rowSums(draws) / sum(ihme_deaths)
  .(acm_lower = unname(quantile(af, .025)), acm_upper = unname(quantile(af, .975)))
}, by = iso3]

cc <- fread(paths[["cacode"]])[TIME_PERIOD == fig_year & SEX == "_T" & AGE_GROUP == "Y0T4" &
                               INDICATOR == "FRACTION" & CAUSE_OF_DEATH == "MALARIA" & UNIT_MEASURE == "PCNT"]
stopifnot(!anyDuplicated(cc$REF_AREA), all(tot$iso3 %in% cc$REF_AREA))
d <- merge(tot[, .(iso3, country, pfpr_pct, acm = attributable_fraction,
                   ihme = ihme_malaria_deaths / ihme_under5_deaths)], acm, by = "iso3")
d <- merge(d, cc[, .(iso3 = REF_AREA, igme = OBS_VALUE / 100, igme_lower = LOWER_BOUND / 100,
                     igme_upper = UPPER_BOUND / 100)], by = "iso3")
d[, igme_who_malaria := iso3 %in% who_malaria]
stopifnot(nrow(d) == 42L, !anyNA(d), all(d$igme_lower <= d$igme & d$igme <= d$igme_upper))
display <- c(Swaziland = "Eswatini", `Cote d'Ivoire` = "Côte d'Ivoire", Congo = "Republic of the Congo",
             `Democratic Republic of the Congo` = "DR Congo")
d[, country := fifelse(country %in% names(display), display[country], country)]
setorder(d, -pfpr_pct)
cbh_atomic_csv(d[, .(iso3, country, year = fig_year, pfpr_pct, ihme_share_pct = 100 * ihme,
  igme_cacode_share_pct = 100 * igme, igme_cacode_share_lower_pct = 100 * igme_lower,
  igme_cacode_share_upper_pct = 100 * igme_upper, igme_cacode_uses_who_malaria = igme_who_malaria,
  pfpr_acm_share_pct = 100 * acm, pfpr_acm_share_lower95_pct = 100 * acm_lower,
  pfpr_acm_share_upper95_pct = 100 * acm_upper)],
  file.path(out, "malaria_share_vs_pfpr_2024.csv"))

## Table (added 1 October 2026, user request): the three shares for all 42 countries --------------
# Sorted by PfPR as in the figure. Dagger: CA-CODE uses WHO malaria estimates. Final row: unweighted medians across
# countries.
f1 <- function(x) formatC(x, format = "f", digits = 1)
ci <- function(v, lo, hi) sprintf("%s (%s–%s)", f1(100 * v), f1(100 * lo), f1(100 * hi))
tab <- d[, .(country, pfpr = f1(pfpr_pct), acm = ci(acm, acm_lower, acm_upper),
             ihme = f1(100 * ihme), igme = ci(igme, igme_lower, igme_upper), who = igme_who_malaria)]
medians <- d[, .(pfpr = f1(median(pfpr_pct)), acm = f1(median(100 * acm)), ihme = f1(median(100 * ihme)),
                 igme = f1(median(100 * igme)))]
cbh_atomic_csv(d[, .(country, iso3, pfpr_pct = round(pfpr_pct, 2),
  pfpr_acm_share_pct = round(100 * acm, 2), pfpr_acm_lower95_pct = round(100 * acm_lower, 2),
  pfpr_acm_upper95_pct = round(100 * acm_upper, 2), ihme_share_pct = round(100 * ihme, 2),
  igme_cacode_share_pct = 100 * igme, igme_cacode_lower_pct = 100 * igme_lower, igme_cacode_upper_pct = 100 * igme_upper,
  igme_cacode_uses_who_malaria = igme_who_malaria)], file.path(out, "malaria_share_table_2024.csv"))
note <- paste("PfPR-ACM model: share of IHME all-cause under-five deaths attributable to malaria (current *Pf*PR against *Pf*PR 0), including indirect deaths, with 95% intervals from the age-band hazard-ratio uncertainty only.",
  "IHME: under-five malaria deaths divided by all-cause under-five deaths (no interval in the export used).",
  "UN IGME: CA-CODE 2026 published malaria share of under-five deaths with its published bounds (interval level not stated).",
  "† CA-CODE input file flags WHO malaria estimates for this country.",
  "Last row: unweighted medians across the 42 countries.")
md <- c("# Malaria's share of under-five deaths by country, 2024", "",
  "| Country | *Pf*PR~2–10~ 2024 (%) | PfPR-ACM model (%) | IHME (%) | UN IGME (%) |", "|---|---:|---:|---:|---:|",
  tab[, sprintf("| %s | %s | %s | %s | %s%s |", country, pfpr, acm, ihme, igme, fifelse(who, " †", ""))],
  medians[, sprintf("| **Median, 42 countries** | %s | %s | %s | %s |", pfpr, acm, ihme, igme)], "", note)
writeLines(md, file.path(out, "malaria_share_table_2024.md"))
tex_name <- function(x) gsub("ô", "\\^{o}", x, fixed = TRUE)
tex <- c("% Replacement table source; saved as plain text. No manuscript file is edited.",
  "\\begin{table}[htbp]", "\\centering\\small",
  "\\caption{Malaria's share of under-five deaths in 2024 by country, from the PfPR-ACM model, IHME and UN IGME (CA-CODE), ordered by national \\textit{Pf}PR$_{2-10}$.}",
  "\\label{tab:malaria_share}", "\\begin{tabular}{lrrrr}", "\\toprule",
  "Country & \\textit{Pf}PR$_{2-10}$ (\\%) & PfPR-ACM model (\\%) & IHME (\\%) & UN IGME (\\%) \\\\", "\\midrule",
  tab[, sprintf("%s & %s & %s & %s & %s%s \\\\", tex_name(country), pfpr,
                gsub("–", "--", acm), ihme, gsub("–", "--", igme), fifelse(who, "$^{\\dagger}$", ""))],
  "\\midrule", medians[, sprintf("Median, 42 countries & %s & %s & %s & %s \\\\", pfpr, acm, ihme, igme)],
  "\\bottomrule", "\\end{tabular}", "\\par\\smallskip", "\\begin{minipage}{\\linewidth}\\footnotesize",
  gsub("\\*Pf\\*PR", "\\\\textit{Pf}PR", gsub("%", "\\\\%", gsub("†", "$^{\\\\dagger}$", gsub("‡", "$^{\\\\ddagger}$", note)))),
  "\\end{minipage}", "\\end{table}")
writeLines(tex, file.path(out, "malaria_share_table_2024.latex.txt"))

## Figure -------------------------------------------------------------------------------------------
# Saved 157 mm wide and printed at \linewidth (165 mm), so printed text is 1.05 times the script size and meets the
# paper's text-size rule (CLAUDE.md): axis titles 11.4 pt, other text 9.5 pt, panel titles with their tags 12.6 pt; lines
# and points are those of the earlier 180 mm drawing scaled by 157/180. The three shares measure
# different things: the model's is attributable (direct and indirect deaths; stated in the caption), IHME's and
# CA-CODE's are cause-assigned.
model <- cbh_paper_model_label()
keys <- c(acm = model, ihme = "IHME (cause of death)", igme = "UN IGME (cause of death)",
          who = "UN IGME (malaria from WHO estimates)")
cols <- setNames(c("#16747C", "#253746", "#CC6A30", "#CC6A30"), keys)   # as in Figure 3, panel C
fills <- setNames(c("#16747C", "#253746", "#CC6A30", "white"), keys)
shapes <- setNames(c(21, 24, 23, 23), keys)
ymax <- ceiling(100 * max(d$acm_upper, d$igme_upper, d$ihme) / 5) * 5
xmax <- ceiling(max(d$pfpr_pct) / 5) * 5
label_n <- 7L; shift <- .25   # comparators sit slightly right of the model point
# Every share axis has the same title (user request, 30 October 2026); the caption says which measure each axis shows.
share_lab <- "Share of all-cause mortality (%)"
# Long country names are labelled on two lines (figure only; the tables keep the full names on one line).
plot_name <- function(x) sub("^(Central African|Republic of|Equatorial) ", "\\1\n", x)
comparator <- function(src) {
  is_igme <- src == "igme"
  copy(d)[, `:=`(comp = 100 * get(src), comp_lo = if (is_igme) 100 * igme_lower else NA_real_,
                 comp_hi = if (is_igme) 100 * igme_upper else NA_real_,
                 series = if (is_igme) fifelse(igme_who_malaria, keys[["who"]], keys[["igme"]]) else keys[["ihme"]])]
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
                           direction = if (stack) "y" else "both", size = 9 / .pt, lineheight = .85, colour = "grey15",
                           bg.colour = "white", bg.r = .15, min.segment.length = 0, segment.colour = "grey35", segment.size = .3,
                           box.padding = if (stack) .12 else .3, point.padding = if (stack) .2 else .4, force = 4,
                           force_pull = if (stack) .1 else .5, max.overlaps = Inf, max.time = 5, max.iter = 1e6, seed = 1)
}
panel <- function(src, title) {
  is_igme <- src == "igme"  # not 'igme', which is a column of d
  z <- comparator(src)
  lab <- labelled(z)
  k <- unname(keys)   # same keys in both panels, so the legends collect into one
  p <- ggplot(z, aes(x = pfpr_pct)) +
    geom_segment(aes(xend = pfpr_pct + shift, y = 100 * acm, yend = comp), colour = "grey78", linewidth = .26) +
    geom_segment(data = lab, aes(xend = pfpr_pct + shift, y = 100 * acm, yend = comp), colour = "grey40", linewidth = .4) +
    geom_linerange(aes(ymin = 100 * acm_lower, ymax = 100 * acm_upper), colour = cols[[1]], alpha = .7, linewidth = .45)
  if (is_igme) p <- p + geom_linerange(aes(x = pfpr_pct + shift, ymin = comp_lo, ymax = comp_hi),
                                       colour = cols[["UN IGME (cause of death)"]], alpha = .6, linewidth = .45)
  # One legend for the figure, drawn from panel B: an invisible IHME layer gives B the IHME key.
  if (is_igme) p <- p + geom_point(data = z[1], aes(y = 100 * ihme, colour = keys[["ihme"]], shape = keys[["ihme"]],
                                                    fill = keys[["ihme"]]), alpha = 0)
  p <- p +
    geom_point(aes(y = 100 * acm, colour = keys[["acm"]], shape = keys[["acm"]], fill = keys[["acm"]]), size = 1.5, stroke = .35) +
    geom_point(aes(x = pfpr_pct + shift, y = comp, colour = series, shape = series, fill = series), size = 1.6, stroke = .45) +
    # The upper half is stacked in panel B only; in panel A (PfPR up to 37%) those labels have room to be placed freely.
    side_labels(z, lab, "left") + side_labels(z, lab, "right", stack = is_igme) +
    scale_colour_manual(values = cols, limits = k, name = NULL) +
    scale_fill_manual(values = fills, limits = k, name = NULL) +
    scale_shape_manual(values = shapes, limits = k, name = NULL) +
    guides(colour = guide_legend(nrow = 2, byrow = TRUE, override.aes = list(alpha = 1, size = 1.6)),
           fill = guide_legend(nrow = 2, byrow = TRUE), shape = guide_legend(nrow = 2, byrow = TRUE)) +
    scale_x_continuous(limits = c(0, xmax + 1), breaks = seq(0, xmax, 5), expand = expansion(add = c(.5, 0))) +
    scale_y_continuous(limits = c(0, ymax), breaks = seq(0, ymax, 5), expand = expansion(add = c(.6, 0))) +
    coord_cartesian(clip = "off") +
    labs(title = title, x = bquote("National"~italic(Pf)*PR["2–10"]*","~.(fig_year)~"(%)"),
         y = if (is_igme) NULL else share_lab) +
    theme_minimal(base_size = 10.8, base_line_size = .34) +
    theme(panel.grid.minor = element_blank(), legend.position = "bottom", legend.text = element_text(size = 9),
          axis.text = element_text(size = 9), legend.key.width = unit(2.6, "mm"), legend.key.spacing.y = unit(1, "pt"),
          plot.title = element_text(size = 12, face = "bold"), plot.title.position = "plot")
  if (is_igme) p else p + guides(colour = "none", fill = "none", shape = "none")
}
lim <- ceiling(100 * max(d$acm_upper, d$igme_upper, d$ihme) / 5) * 5
scatter <- function(src, title) {
  is_igme <- src == "igme"
  z <- comparator(src); lab <- labelled(z)
  higher <- sum(z$acm * 100 > z$comp)
  rho <- cor(z$acm, z$comp, method = "spearman")
  p <- ggplot(z, aes(x = comp, y = 100 * acm)) +
    geom_abline(slope = 1, intercept = 0, colour = "grey55", linetype = "dashed", linewidth = .3) +
    geom_linerange(aes(ymin = 100 * acm_lower, ymax = 100 * acm_upper), colour = cols[[1]], alpha = .6, linewidth = .4)
  if (is_igme) p <- p + geom_segment(aes(x = comp_lo, xend = comp_hi, yend = 100 * acm),
                                     colour = cols[["UN IGME (cause of death)"]], alpha = .55, linewidth = .4)
  p +
    geom_point(aes(colour = series, shape = series, fill = series), size = 1.6, stroke = .45) +
    # Labels start above their points for the upper half of the labelled countries and below for the rest, so that they
    # spread out of the cluster.
    ggrepel::geom_text_repel(aes(label = fifelse(iso3 %in% lab$iso3, plot_name(country), "")), size = 9 / .pt, lineheight = .9,
                             nudge_y = fifelse(z$iso3 %in% lab$iso3, fifelse(z$acm >= median(lab$acm), .1, -.15), 0) * lim,
                             colour = "grey15", bg.colour = "white", bg.r = .15, min.segment.length = 0, segment.colour = "grey35",
                             segment.size = .3, box.padding = .2, point.padding = .2, force = 4, force_pull = .3, max.overlaps = Inf,
                             max.time = 5, max.iter = 1e6, seed = 1) +
    annotate("text", x = .98 * lim, y = .02 * lim, hjust = 1, vjust = 0, size = 9 / .pt, colour = "grey20", lineheight = .95,
             label = sprintf("Spearman \u03c1 = %.2f\n%s higher\nin %d of %d", rho, model, higher, nrow(z))) +
    annotate("text", x = .97 * lim, y = .92 * lim, hjust = 1, vjust = 0, size = 9 / .pt, colour = "grey45", label = "equality") +
    scale_colour_manual(values = cols, limits = unname(keys), name = NULL) +
    scale_fill_manual(values = fills, limits = unname(keys), name = NULL) +
    scale_shape_manual(values = shapes, limits = unname(keys), name = NULL) +
    guides(colour = "none", fill = "none", shape = "none") +
    scale_x_continuous(limits = c(0, lim), breaks = seq(0, lim, 10), expand = expansion(add = c(.6, .6))) +
    scale_y_continuous(limits = c(0, lim), breaks = seq(0, lim, 10), expand = expansion(add = c(.6, .6))) +
    coord_equal(clip = "off") +
    labs(title = title, x = share_lab, y = if (is_igme) NULL else share_lab) +
    theme_minimal(base_size = 10.8, base_line_size = .34) +
    theme(panel.grid.minor = element_blank(), axis.text = element_text(size = 9), plot.title = element_text(size = 12, face = "bold"),
          plot.title.position = "plot")
}
fig <- (panel("ihme", "A  IHME") | panel("igme", "B  UN IGME (CA-CODE)")) /
  (scatter("ihme", paste0("C  ", model, " vs IHME")) |
   scatter("igme", paste0("D  ", model, " vs UN IGME"))) +
  plot_layout(guides = "collect", heights = c(1.2, 1.1)) + plot_annotation(theme = theme(legend.position = "bottom"))
ggsave(file.path(out, "sfig_malaria_share_vs_pfpr.png"), fig, width = 157, height = 198, units = "mm", dpi = 600,
       device = ragg::agg_png, bg = "white")

## Caption and provenance -----------------------------------------------------------------------------
sp <- function(v, rows = TRUE) cor(d$pfpr_pct[rows], v[rows], method = "spearman")
med <- function(v) median(100 * v)
who_in <- d[igme_who_malaria == TRUE, country]
writeLines(c("# Supplementary figure: malaria's share of under-five deaths against PfPR and between sources, 2024", "",
  sprintf(paste("Malaria's share of under-five deaths in %d against the Malaria Atlas Project's national *Pf*PR~2–10~ estimates for %d sub-Saharan African countries.",
    "The share for the *Pf*PR–all-cause mortality (PfPR-ACM) model is attributable: the share of IHME all-cause under-five deaths that would not occur at *Pf*PR 0, from the seven age-band hazard ratios, so it includes deaths caused indirectly by malaria.",
    "The IHME and UN IGME shares count deaths assigned to malaria as the cause.",
    "In panels A and B each country appears at its *Pf*PR; grey lines join its %s value (teal circles) to (A) IHME (navy triangles: IHME under-five malaria deaths divided by IHME all-cause under-five deaths) or",
    "(B) UN IGME (orange diamonds: the CA-CODE 2026 published malaria share of under-five deaths, with its published uncertainty bounds, interval level not stated in the download).",
    "Comparator points are shifted slightly right; darker lines mark the %d countries with the largest absolute difference from the %s value for each source, which are labelled in both of that source's panels.",
    "Panels C and D plot the %s share against the IHME and UN IGME shares, one point per country, with the line of equality (dashed); vertical bars are the model's 95%% intervals and horizontal bars in D the CA-CODE bounds.",
    "The model share is higher than IHME's in %d of %d countries and higher than UN IGME's in %d (Spearman correlation between the model and IHME shares %.2f, UN IGME %.2f).",
    "Model intervals (95%%) reflect only the age-band hazard-ratio uncertainty, drawn independently across bands, with *Pf*PR and IHME all-cause deaths held fixed, so they understate total uncertainty; IHME uncertainty intervals are not shown.",
    "The CA-CODE share is computed on CA-CODE's own total of cause-specific deaths, which can differ from the UN IGME all-cause count (DR Congo: 428,472 against 385,039 deaths).",
    "Hollow diamonds mark countries flagged in CA-CODE's published input file for WHO malaria estimates rather than its verbal-autopsy model (%s).",
    "Across countries the %s share rises with *Pf*PR almost by construction; Spearman correlation with *Pf*PR is %.2f for IHME and %.2f for UN IGME (%.2f excluding the WHO-estimate countries).",
    "Unweighted median share across the %d countries: %s %.1f%%, IHME %.1f%%, UN IGME %.1f%%.",
    "Lesotho has no MAP national estimate, Cabo Verde and São Tomé and Príncipe are outside the 42-country burden set, and Sudan and South Africa are not in the IHME export, so all five are excluded from every panel."),
    fig_year, nrow(d), model, label_n, model, model, sum(d$acm > d$ihme), nrow(d), sum(d$acm > d$igme),
    cor(d$acm, d$ihme, method = "spearman"), cor(d$acm, d$igme, method = "spearman"), paste(who_in, collapse = ", "), model,
    sp(d$ihme), sp(d$igme), sp(d$igme, !d$igme_who_malaria), nrow(d), model, med(d$acm), med(d$ihme), med(d$igme))),
  file.path(out, "CAPTION.md"))
inputs <- c(unname(paths), "R_cbh/reporting/20_malaria_share_vs_pfpr.R", "R_cbh/reporting/labels.R")
cbh_atomic_csv(data.frame(file = inputs, md5 = vapply(inputs, cbh_file_hash, "")), file.path(out, "provenance.csv"))
message(sprintf("Malaria share figure written: %s (%d countries; Spearman with PfPR: PfPR-ACM %.2f, IHME %.2f, UN IGME %.2f)",
                out, nrow(d), sp(d$acm), sp(d$ihme), sp(d$igme)))
