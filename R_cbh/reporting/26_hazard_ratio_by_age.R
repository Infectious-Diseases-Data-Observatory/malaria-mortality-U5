#!/usr/bin/env Rscript
# Figure 2 (user request, 28 October 2026; formerly the supplementary log-HR curves relative to PfPR = 20%): the
# hazard ratio of death in each age band at national-scale PfPR[2-10] P relative to zero prevalence,
# exp{f_g(P) - f_g(0)}, from the seven saved primary spline fits, so that values can be read off and compared with
# the hazard ratios and attributable fractions in the text (1 - 1/HR). Pointwise 95% intervals use the spline
# coefficients' covariance, conditional on the smoothing parameters. Curves are solid over the central 95% of each
# band's exposure distribution and dashed from zero to its 2.5th percentile, where the reference is reached by
# extrapolation into sparse data. Sizes meet the paper's printed text-size rule (CLAUDE.md) at 6.2 in: saved 6.5 in
# wide, so printed = 0.95 x size. No title or caption in the figure.
# Outputs (<out>/hazard_ratio_by_age/): fig2_hazard_ratio_by_age.png, hazard_ratio_curves.csv, CAPTION.md, provenance.csv
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/reporting/labels.R")
suppressPackageStartupMessages({ library(mgcv); library(ggplot2) })
st <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION", "regional_mics")); root <- st$out
out <- file.path(root, "hazard_ratio_by_age"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
paths <- c(components = file.path(st$private, "pfpr_components.rds"), manifest = file.path(root, "fit_manifest.csv"),
  curves = file.path(root, "pfpr_curves.csv"))
stopifnot(all(file.exists(paths)))
components <- readRDS(paths[["components"]]); manifest <- cbh_read_csv(paths[["manifest"]]); curves <- cbh_read_csv(paths[["curves"]])
ages <- cbh_config()$age_bands$age_band
stopifnot(length(components) == 7L, nrow(manifest) == 7L)
d <- do.call(rbind, lapply(seq_along(ages), function(i) {
  id <- paste0("map_full_age_", i); piece <- components[[id]]
  stopifnot(identical(piece$age_band, ages[i]), identical(piece$model_md5, manifest$md5[match(id, manifest$fit_id)]))
  grid <- data.frame(pfpr_pct = sort(unique(c(seq(0, ceiling(piece$support[3]), by = .5), piece$support[2:3]))))
  grid <- grid[grid$pfpr_pct <= piece$support[3], , drop = FALSE]
  L <- PredictMat(piece$smooth, grid) - PredictMat(piece$smooth, data.frame(pfpr_pct = rep(0, nrow(grid))))
  est <- drop(L %*% piece$coef); se <- sqrt(pmax(rowSums((L %*% piece$covariance) * L), 0))
  # Same contrast as the saved curves (relative to 20%), re-referenced to zero.
  z <- curves[curves$age_band == ages[i], ]; k <- match(grid$pfpr_pct, z$pfpr_pct)
  stopifnot(any(!is.na(k)), max(abs(est[!is.na(k)] - (z$log_hazard_ratio[k[!is.na(k)]] - z$log_hazard_ratio[z$pfpr_pct == 0]))) < 1e-8)
  data.frame(age_band = ages[i], pfpr_pct = grid$pfpr_pct, log_hr_vs_zero = est, se = se, hazard_ratio = exp(est),
    lower_95 = exp(est - 1.96 * se), upper_95 = exp(est + 1.96 * se),
    segment = ifelse(grid$pfpr_pct < piece$support[2], "extrapolated", "central"), pfpr_p025 = piece$support[2], pfpr_p975 = piece$support[3])
}))
cbh_atomic_csv(d, file.path(out, "hazard_ratio_curves.csv"))
d$age_label <- factor(d$age_band, levels = ages, labels = ifelse(ages == "<1", "<1 month", paste(ages, "months")))
# The dashed segment ends where the solid one starts.
p <- ggplot(d, aes(pfpr_pct, hazard_ratio)) +
  geom_hline(yintercept = 1, colour = "grey55", linewidth = .25) +
  geom_ribbon(aes(ymin = lower_95, ymax = upper_95), fill = "#215E91", alpha = .17) +
  geom_line(data = d[d$segment == "extrapolated" | d$pfpr_pct == d$pfpr_p025, ], colour = "#215E91", linewidth = .46, linetype = "22") +
  geom_line(data = d[d$segment == "central", ], colour = "#215E91", linewidth = .46) +
  facet_wrap(~age_label, ncol = 4) +
  scale_x_continuous(limits = c(0, 80), breaks = c(0, 20, 40, 60, 80)) +
  scale_y_continuous(breaks = seq(1, 3.5, .5), minor_breaks = seq(1, 3.5, .25)) +
  labs(x = expression(italic(Pf)*PR[2-10]~"(%)"), y = "Mortality hazard ratio\nrelative to zero prevalence") +
  theme_minimal(base_size = 9.9, base_line_size = .3) +
  theme(panel.grid.minor.x = element_blank(), panel.grid.minor.y = element_line(linewidth = .15),
    axis.title = element_text(size = 11.92), axis.text = element_text(size = 9.9), strip.text = element_text(size = 10.8, face = "bold"),
    panel.spacing = grid::unit(11, "pt"), plot.margin = margin(5, 11, 5, 5))
stopifnot(is.null(p$labels$title), is.null(p$labels$subtitle), is.null(p$labels$caption))
ggsave(file.path(out, "fig2_hazard_ratio_by_age.png"), p, width = 6.5, height = 3.9, dpi = 320, device = ragg::agg_png, bg = "white")
at <- function(age, x) { z <- d[d$age_band == age & d$pfpr_pct == x, ]; sprintf("%.2f (%.2f–%.2f)", z$hazard_ratio, z$lower_95, z$upper_95) }
writeLines(c("# Figure 2 caption — hazard ratio of death by age band, relative to zero prevalence", "",
  paste0("**Figure. Malaria prevalence and age-specific all-cause mortality.** Hazard ratio of death in each age band at national ",
    "PfPR[2–10] relative to zero prevalence, from the seven age-band models of the ", cbh_paper_model_label(), ". ",
    "Lines are point estimates and shaded areas pointwise 95% confidence intervals (conditional on the estimated smoothing parameters). ",
    "Curves are solid over the central 95% of each band's exposure distribution and dashed from zero to its 2.5th percentile (about 2%), ",
    "where the zero-prevalence reference is reached by extrapolation. The attributable fraction at prevalence P is 1 − 1/HR(P). ",
    sprintf("For example, at 40%% prevalence the hazard ratio is %s for neonates and %s at 24–35 months.", at("<1", 40), at("24-35", 40)))),
  file.path(out, "CAPTION.md"))
provenance <- c(unname(paths), "R_cbh/reporting/26_hazard_ratio_by_age.R", "R_cbh/reporting/labels.R")
cbh_atomic_csv(data.frame(file = provenance, md5 = vapply(provenance, cbh_file_hash, "")), file.path(out, "provenance.csv"))
message("Figure 2 (hazard ratio relative to zero prevalence) saved: ", out)
