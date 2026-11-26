#!/usr/bin/env Rscript
# PfPR curves of the space-time test fits (05_spacetime_inla.R) for every age band fitted: hazard ratio against PfPR 0,
# one panel per age band; two test models with 95% intervals, and the paper's fit (bam, penalised spline) as a dashed
# line. Arguments (optional): a tag for the file name, then the two models to show; default M0 and M1. A band is drawn
# with whichever of the two models it has. The reference prevalence is 0%, or below 1% for a model named *_ref1.
# Exploratory figure, not for the paper.
# Writes <out>/spacetime_pfpr_curves_all_bands[_<tag>].png, spacetime_contrasts_all_bands.csv and
# spacetime_hyperparameters_all_bands.csv (every model on file).
suppressPackageStartupMessages({library(data.table); library(mgcv); library(ggplot2)})
source("R_cbh/primary/settings.R"); source("R_cbh/sensitivity/design/settings.R")
P <- cbh_primary_settings(); S <- cbh_design_settings(); source("R_cbh/00_config.R"); bands <- as.character(cbh_config()$age_bands$age_band)
arg <- commandArgs(trailingOnly = TRUE); tag <- if (length(arg)) paste0("_", arg[1]) else ""; show <- if (length(arg) > 1) arg[-1] else c("M0", "M1")
all_labels <- c(M0 = "M0: current structure", M1 = if ("M0" %in% show) "M1: year walk + spatial effect" else "M1, cubic spline", M2 = "M2: + unit-by-year",
  M1_rw2 = "M1, walk on PfPR", M1_rw2_sqrt = "M1, walk on sqrt(PfPR)", M1_rw2_log = "M1, walk on log(1 + PfPR)", M1_rw2_sqrt_ref1 = "M1, sqrt walk, below 1% as reference",
  M1_rw2_sqrt_ref1_int = "The same, smoothness uncertainty included", M3_rw2_sqrt_ref1 = "With country-specific year trends",
  M3y_rw2_sqrt_ref1 = "Country trends + unit-by-year effect", M3cy_rw2_sqrt_ref1 = "Country trends + unit-by-year + cluster effects",
  M3c_rw2_sqrt_ref1 = "Country trends + cluster effect")
if (any(grepl("^M3", show))) all_labels[c("M1_rw2_sqrt_ref1", "M3_rw2_sqrt_ref1", "M1_rw2_sqrt_ref1_int", "M3_rw2_sqrt_ref1_int")] <-
  rep(c("Common year trend", "Country-specific year trends"), 2)   # the same pair at test quality and at final quality (_int)
stopifnot(length(show) == 2, show %in% names(all_labels), !anyDuplicated(all_labels[show]))
manifest <- read.csv(file.path(P$out, "fit_manifest.csv"))
one <- function(k) {
  file <- file.path(S$out, paste0("band_", k, "_spacetime_pfpr_curves.csv")); if (!file.exists(file)) return(NULL)
  cv <- fread(file, colClasses = list(character = "age_band"))[model %in% show]; if (!nrow(cv)) return(NULL)
  f <- readRDS(manifest$model_file[manifest$age_band == bands[k]])$fit; sm <- f$smooth[[1]]; j <- sm$first.para:sm$last.para
  grid <- sort(unique(cv$pfpr_pct)); G <- PredictMat(sm, data.frame(pfpr_pct = grid)); G <- sweep(G, 2, drop(PredictMat(sm, data.frame(pfpr_pct = 0))))
  rbind(cv[, .(model, age_band = bands[k], pfpr_pct, log_hazard_ratio, lower_95, upper_95)],
    data.table(model = "paper", age_band = bands[k], pfpr_pct = grid, log_hazard_ratio = drop(G %*% coef(f)[j]), lower_95 = NA_real_, upper_95 = NA_real_))
}
d <- rbindlist(lapply(seq_along(bands), one)); stopifnot(nrow(d) > 0)
d[, age := factor(paste(age_band, "months"), levels = paste(bands, "months"))]
labels <- c(paper = "Paper fit (bam)", all_labels[show])
d[, model := factor(labels[model], levels = labels)]
colours <- setNames(c("grey25", "#1c5a8a", "#c8571b"), labels)
p <- ggplot(d, aes(pfpr_pct, exp(log_hazard_ratio), colour = model, fill = model)) +
  geom_hline(yintercept = 1, linewidth = 0.3, colour = "grey50") +
  geom_ribbon(data = d[!is.na(lower_95)], aes(ymin = exp(lower_95), ymax = exp(upper_95)), alpha = 0.18, colour = NA, show.legend = FALSE) +
  geom_line(aes(linetype = model, linewidth = model)) +
  facet_wrap(~age, nrow = 2) + scale_y_log10(breaks = c(0.75, 1, 1.5, 2, 3, 4), labels = function(x) format(x, drop0trailing = TRUE)) +
  scale_colour_manual(values = colours) + scale_fill_manual(values = colours, guide = "none") +
  scale_linetype_manual(values = setNames(c("22", "solid", "solid"), labels)) + scale_linewidth_manual(values = setNames(c(0.45, 0.75, 0.75), labels)) +
  labs(x = expression(italic(Pf) * PR[2-10] ~ "(%)"), y = if (any(grepl("_ref1", show))) "Hazard ratio against the reference prevalence" else "Hazard ratio against 0%", colour = NULL, fill = NULL, linetype = NULL, linewidth = NULL) +
  theme_bw(base_size = 11) + theme(axis.text = element_text(size = 9), strip.text = element_text(size = 9), legend.text = element_text(size = 9),
    panel.grid.minor = element_blank(), legend.position = "bottom")
ggsave(file.path(S$out, paste0("spacetime_pfpr_curves_all_bands", tag, ".png")), p, width = 7.5, height = 5, dpi = 200)
files <- list.files(S$out, "^band_[1-7]_spacetime_contrasts.csv$", full.names = TRUE)
con <- rbindlist(lapply(files, fread, colClasses = list(character = "age_band")), fill = TRUE)[, age_band := factor(age_band, levels = bands)][order(age_band, contrast, model)]
fwrite(con, file.path(S$out, "spacetime_contrasts_all_bands.csv"))
hyp <- rbindlist(lapply(sub("contrasts", "hyperparameters", files), fread, colClasses = list(character = "age_band")))[, age_band := factor(age_band, levels = bands)][order(age_band, model)]
fwrite(hyp, file.path(S$out, "spacetime_hyperparameters_all_bands.csv"))
z <- con[model %in% show & contrast == "PfPR 20 to 0", .(age_band, model, hr = 1 / hazard_ratio, lo = 1 / upper_95, hi = 1 / lower_95, sd, waic, minutes)]
print(z, digits = 3)
