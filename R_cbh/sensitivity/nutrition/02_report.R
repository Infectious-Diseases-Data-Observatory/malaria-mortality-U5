#!/usr/bin/env Rscript
# Supplementary figure and tables for the no-nutrition sensitivity: overlay the
# primary PfPR curves with those from the refit that drops regional wasting and
# stunting. Reads saved aggregates and, for the figure's intervals, the saved fits; no refitting, no TeX writes.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/reporting/labels.R")
source("R_cbh/reporting/curves_vs_zero.R")
library(ggplot2)
args <- commandArgs(trailingOnly = TRUE); stopifnot(!length(args))
st <- list(out = file.path("results/cbh", "nutrition_adjustment_gadm_merge_gamma2_v9"))
primary <- cbh_primary_settings("gadm")
labels <- c(full = "All 17 covariates (primary analysis)",
            drop = "Wasting and stunting removed (sensitivity)")
colours <- setNames(c("#B36B39", "#215E91"), labels)
ages <- cbh_config()$age_bands$age_band
age_label <- function(x) factor(x, levels = ages,
  labels = ifelse(ages == "<1", "<1 month", paste(ages, "months")))

inputs <- c(file.path(primary$out, "pfpr_curves.csv"), file.path(st$out, "pfpr_curves.csv"),
            file.path(primary$out, "fit_diagnostics.csv"), file.path(st$out, "fit_diagnostics.csv"),
            file.path(st$out, "dropped_covariates.csv"), file.path(st$out, "fit_manifest.csv"),
            file.path(primary$out, "hazard_ratio_by_age", "hazard_ratio_curves.csv"), "R_cbh/reporting/curves_vs_zero.R")
stopifnot(file.exists(inputs))
pc <- cbh_read_csv(inputs[1]); pc <- pc[pc$series == "map_full", ]
nc <- cbh_read_csv(inputs[2])
pd <- cbh_read_csv(inputs[3]); nd <- cbh_read_csv(inputs[4])
stopifnot(nrow(pd) == 7L, nrow(nd) == 7L, all(nd$converged), all(nd$gamma == 2),
          all(nd$input_verified), all(nd$min_smoothing_hessian_eigenvalue > 0),
          identical(sort(pd$rows), sort(nd$rows)), identical(sort(pd$deaths), sort(nd$deaths)))
pc$series_label <- labels[["full"]]; nc$series_label <- labels[["drop"]]
curves <- rbind(pc[, intersect(names(pc), names(nc))], nc[, intersect(names(pc), names(nc))])
curves$series_label <- factor(c(rep(labels[["full"]], nrow(pc)), rep(labels[["drop"]], nrow(nc))),
                              levels = labels)
curves$age_label <- age_label(curves$age_band)
cbh_atomic_csv(curves, file.path(st$out, "comparison_pfpr_curves.csv"))

# Sizes meet the paper's printed text-size rule (CLAUDE.md) at 6.2 in: saved 6.5 in wide, so printed = 0.95 x size
# (axis titles 11.9 -> 11.3 pt; ticks and legend 9.9 -> 9.4 pt; strips 10.8 -> 10.3 pt). Lines, spacing and margins are
# those of the former 14-in version scaled by 6.5/14; the two legend entries are stacked.
paper <- theme_minimal(base_size = 9.9, base_line_size = .38) + theme(panel.grid.minor = element_blank(),
  axis.text = element_text(size = 9.9), axis.title = element_text(size = 11.92), strip.text = element_text(size = 10.8, face = "bold"),
  legend.position = "bottom", legend.direction = "vertical", legend.title = element_blank(), legend.text = element_text(size = 9.9),
  legend.margin = margin(0, 0, 0, 0), legend.box.spacing = grid::unit(6, "pt"), legend.key.spacing.y = grid::unit(1, "pt"),
  panel.spacing = grid::unit(10, "pt"), plot.margin = margin(6, 10, 6, 6))
# Figure: hazard ratios relative to zero prevalence on a linear axis, as in Figure 2 (author request, 3 November 2026).
# The primary curve and interval are Figure 2's own; the no-nutrition curves are re-referenced to zero with intervals
# from the PfPR smooth of each saved fit (fit_manifest.csv, hashes checked). Solid over each curve's central 95%,
# dashed from zero to its 2.5th percentile.
manifest <- cbh_read_csv(file.path(st$out, "fit_manifest.csv"))
vz_drop <- do.call(rbind, lapply(ages, function(a) {
  m <- manifest[manifest$age_band == a, ]; stopifnot(nrow(m) == 1L, identical(cbh_file_hash(m$model_file), m$md5))
  cbh_curve_vs_zero(nc[nc$age_band == a, ], readRDS(m$model_file)$fit)
}))
vz <- rbind(data.frame(series_label = labels[["full"]], cbh_primary_vs_zero(primary$out)),
            data.frame(series_label = labels[["drop"]], vz_drop))
vz <- vz[vz$segment != "outside", ]; rownames(vz) <- NULL
vz$series_label <- factor(vz$series_label, levels = labels)
cbh_atomic_csv(vz, file.path(st$out, "comparison_hazard_ratio_vs_zero.csv"))
vz$age_label <- age_label(vz$age_band)
# The dashed segment ends where the solid one starts.
p <- ggplot(vz, aes(pfpr_pct, hazard_ratio, colour = series_label, fill = series_label)) +
  geom_hline(yintercept = 1, colour = "grey65", linewidth = .19) +
  geom_ribbon(aes(ymin = lower_95, ymax = upper_95), alpha = .12, colour = NA) +
  geom_line(data = vz[vz$pfpr_pct <= vz$pfpr_p025, ], linewidth = .46, linetype = "22", show.legend = FALSE) +
  geom_line(data = vz[vz$segment == "central", ], linewidth = .46) + facet_wrap(~age_label, ncol = 4) +
  scale_colour_manual(values = colours) + scale_fill_manual(values = colours) +
  scale_x_continuous(limits = c(0, 80), breaks = c(0, 20, 40, 60, 80)) +
  scale_y_continuous(breaks = seq(0, 5, .5)) +
  labs(x = expression(italic(Pf)*PR[2-10]~"(%)"), y = "Mortality hazard ratio\nrelative to zero prevalence") + paper
figure <- file.path(st$out, "sfig_pfpr_splines_without_nutrition.png")
ggsave(figure, p, width = 6.5, height = 3.95, dpi = 320, device = ragg::agg_png, bg = "white")

# Contrasts on the shared grid: 40% to 20% and 20% to 0%.
contrast <- function(d, iteration) do.call(rbind, lapply(ages, function(a) {
  z <- d[d$age_band == a, ]
  g <- function(v) z[which.min(abs(z$pfpr_pct - v)), ]
  hi <- g(40); lo <- g(20); ze <- g(0)
  data.frame(age_band = a, iteration,
    hr_40_to_20 = exp(lo$log_hazard_ratio - hi$log_hazard_ratio),
    hr_20_to_0  = exp(ze$log_hazard_ratio - lo$log_hazard_ratio))
}))
tab <- rbind(contrast(pc, labels[["full"]]), contrast(nc, labels[["drop"]]))
cbh_atomic_csv(tab, file.path(st$out, "comparison_contrasts.csv"))
w <- reshape(tab, idvar = "age_band", timevar = "iteration", direction = "wide")
w <- w[match(ages, w$age_band), ]
delta <- max(abs(w[[2]] - w[[4]]))
fmt <- function(x) sprintf("%.2f", x)
md <- c("# No-nutrition sensitivity: hazard ratios for PfPR 40% to 20%", "",
  "| Age (months) | All 17 covariates | Wasting and stunting removed |", "|---|---:|---:|")
for (i in seq_len(nrow(w)))
  md <- c(md, sprintf("| %s | %s | %s |", w$age_band[i], fmt(w[[2]][i]), fmt(w[[4]][i])))
md <- c(md, "", sprintf("Largest absolute change in the 40%% to 20%% hazard ratio: %.3f.", delta))
writeLines(md, file.path(st$out, "CONTRASTS.md"))

caption <- c("# Supplementary figure caption: adjustment without wasting and stunting", "",
  paste0("Sensitivity of the fitted PfPR-mortality relationship to removing the two nutritional covariates. ",
  "Mortality hazard ratios relative to zero prevalence (PfPR[2-10] = 0) by completed-month age band, with pointwise 95% conditional intervals shaded, from the PfPR-ACM model with all 17 covariates (the primary analysis; the curves of Figure 2) and from a refit of the same seven models on the identical sample with regional wasting and stunting prevalence removed, leaving 15 covariates. ",
  "Wasting and stunting are measured in surviving children at the time of the survey and may lie on the causal pathway from malaria to death, so adjusting for them risks removing part of the association of interest. ",
  "Sample, exposure, reference knots, basis dimensions, gamma = 2, offset and random-effect structure are unchanged; only the adjustment set differs. ",
  "Each curve is solid over the central 95% of its own exposure distribution and dashed from zero to its 2.5th percentile, where the reference is reached by extrapolation into sparse data. ",
  sprintf("The largest absolute change in the hazard ratio for a reduction in PfPR[2-10] from 40%% to 20%% is %.3f, at %s months. ",
          delta, w$age_band[which.max(abs(w[[2]] - w[[4]]))]),
  "The two models are fitted to the same records, so the comparison is descriptive."))
writeLines(caption, file.path(st$out, "CAPTION.md"))
prov <- c(inputs, figure)
cbh_atomic_csv(data.frame(file = prov, md5 = vapply(prov, cbh_file_hash, "")),
               file.path(st$out, "report_provenance.csv"))
cat("No-nutrition sensitivity figure and tables saved:", figure, "\n")
cat(sprintf("Largest 40%%->20%% hazard-ratio change: %.3f\n", delta))
