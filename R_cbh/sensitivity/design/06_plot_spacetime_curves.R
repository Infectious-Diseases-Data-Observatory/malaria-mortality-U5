#!/usr/bin/env Rscript
# PfPR curves of the space-time test fits (05_spacetime_inla.R) for one age band (band number as the argument; default
# settings$test_band): hazard ratio against PfPR 0 with 95% intervals, one panel per model, beside the paper's fit
# (bam, penalised spline, Bayesian covariance). Exploratory figure, not for the paper.
# Writes <out>/band_<k>_spacetime_pfpr_curves[_<tag>].png.
suppressPackageStartupMessages({library(data.table); library(mgcv); library(ggplot2)})
source("R_cbh/primary/settings.R"); source("R_cbh/sensitivity/design/settings.R")
P <- cbh_primary_settings(); S <- cbh_design_settings(); source("R_cbh/00_config.R"); bands <- as.character(cbh_config()$age_bands$age_band)
# Arguments: band number; then, optionally, a tag for the file name and the models to show (the first INLA model listed
# is repeated as a dashed line in every panel). Default: paper, M0, M1.
arg <- commandArgs(trailingOnly = TRUE); k <- if (length(arg)) as.integer(arg[1]) else match(S$test_band, bands); band <- bands[k]
tag <- if (length(arg) > 1) paste0("_", arg[2]) else ""; show <- if (length(arg) > 2) arg[-(1:2)] else c("paper", "M0", "M1")
cv <- fread(file.path(S$out, paste0("band_", k, "_spacetime_pfpr_curves.csv")))
manifest <- read.csv(file.path(P$out, "fit_manifest.csv")); f <- readRDS(manifest$model_file[manifest$age_band == band])$fit
sm <- f$smooth[[1]]; j <- sm$first.para:sm$last.para; grid <- sort(unique(cv$pfpr_pct))
G <- PredictMat(sm, data.frame(pfpr_pct = grid)); G <- sweep(G, 2, drop(PredictMat(sm, data.frame(pfpr_pct = 0))))
est <- drop(G %*% coef(f)[j]); se <- sqrt(pmax(0, rowSums((G %*% f$Vp[j, j]) * G)))
paper <- data.table(model = "paper", pfpr_pct = grid, log_hazard_ratio = est, lower_95 = est - 1.96 * se, upper_95 = est + 1.96 * se)
labels <- c(paper = "Paper fit (bam, penalised)", M0 = "M0: current structure (INLA)", M1 = "M1: + year walk + spatial", M2 = "M2: + unit-by-year",
  M1_rw2 = "M1, walk on PfPR", M1_rw2_sqrt = "M1, walk on sqrt(PfPR)", M1_rw2_log = "M1, walk on log(1 + PfPR)", M1_rw2_sqrt_ref1 = "M1, sqrt walk, below 1% as reference",
  M1_rw2_sqrt_ref1_int = "The same, smoothness uncertainty included", M3_rw2_sqrt_ref1 = "With country-specific year trends",
  M3y_rw2_sqrt_ref1 = "Country trends + unit-by-year effect", M3cy_rw2_sqrt_ref1 = "Country trends + unit-by-year + cluster effects",
  M3c_rw2_sqrt_ref1 = "Country trends + cluster effect")
if (any(grepl("^M3", show))) labels[c("M1_rw2_sqrt_ref1", "M3_rw2_sqrt_ref1")] <- c("Common year trend", "Country-specific year trends")
if (identical(show[1], "M1")) labels["M1"] <- "M1, cubic spline"
d <- rbind(paper, cv[, names(paper), with = FALSE]); stopifnot(show %in% names(labels), show %in% d$model); d <- d[model %in% show]
d[, panel := factor(labels[model], levels = labels[show])]
ref <- d[model == setdiff(show, "paper")[1], .(pfpr_pct, m0 = log_hazard_ratio)]; d <- merge(d, ref, by = "pfpr_pct", all.x = TRUE)
p <- ggplot(d, aes(pfpr_pct)) +
  geom_hline(yintercept = 1, linewidth = 0.3, colour = "grey50") +
  geom_ribbon(aes(ymin = exp(lower_95), ymax = exp(upper_95)), fill = "#2a78b5", alpha = 0.25) +
  geom_line(aes(y = exp(m0)), linetype = "22", colour = "grey35", linewidth = 0.4) +
  geom_line(aes(y = exp(log_hazard_ratio)), colour = "#1c5a8a", linewidth = 0.8) +
  facet_wrap(~panel, nrow = 1) + scale_y_log10(breaks = c(1, 1.5, 2, 3, 4)) +
  labs(x = expression(italic(Pf) * PR[2-10] ~ "(%)"), y = paste0("Hazard ratio against ", if (any(grepl("_ref1", show))) "below 1%,\n" else "0%, ", band, " months")) +
  theme_bw(base_size = 11) + theme(axis.text = element_text(size = 9), strip.text = element_text(size = 9), panel.grid.minor = element_blank())
ggsave(file.path(S$out, paste0("band_", k, "_spacetime_pfpr_curves", tag, ".png")), p, width = 7.5, height = 3.2, dpi = 200)
