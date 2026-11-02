#!/usr/bin/env Rscript
# Figure 3: age-specific fraction of all-cause mortality attributable to PfPR.
# Read the saved primary spline components; no refitting or national IHME inputs.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
library(mgcv)
library(ggplot2)
st <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION","snow_merge")); out <- st$out
component_path <- file.path(st$private, "pfpr_components.rds")
components <- readRDS(component_path)
manifest <- cbh_read_csv(file.path(out, "fit_manifest.csv"))
diagnostics <- cbh_read_csv(file.path(out, "fit_diagnostics.csv"))
curves <- cbh_read_csv(file.path(out, "pfpr_curves.csv"))
ages <- cbh_config()$age_bands$age_band
prevalences <- c(10, 20, 30, 40)
stopifnot(length(components) == 7L, nrow(manifest) == 7L,
  all(manifest$series == "map_full"), all(diagnostics$gamma == 2), all(diagnostics$converged))
rows <- lapply(seq_along(ages), function(i) {
  id <- paste0("map_full_age_", i); piece <- components[[id]]
  stopifnot(identical(piece$model_md5, manifest$md5[match(id, manifest$fit_id)]),
            identical(piece$age_band, ages[i]))
  nd <- data.frame(pfpr_pct = prevalences); zero <- nd; zero$pfpr_pct <- 0
  # HR is zero prevalence versus P, not P versus the 20% plotting reference.
  L <- PredictMat(piece$smooth, zero) - PredictMat(piece$smooth, nd)
  loghr <- drop(L %*% piece$coef)
  variance <- rowSums((L %*% piece$covariance) * L)
  stopifnot(all(is.finite(variance)), min(variance) >= -1e-9)
  se <- sqrt(pmax(variance, 0))
  z <- curves[curves$age_band == ages[i], ]
  expected <- z$log_hazard_ratio[z$pfpr_pct == 0] -
    z$log_hazard_ratio[match(prevalences, z$pfpr_pct)]
  stopifnot(max(abs(loghr - expected)) < 1e-9)
  data.frame(age_band = ages[i], pfpr_pct = prevalences,
    log_hr_zero_vs_current = loghr, log_hr_se = se,
    attributable_fraction = -expm1(loghr),
    af_lower_95 = -expm1(loghr + 1.96*se), af_upper_95 = -expm1(loghr - 1.96*se),
    zero_below_observed_support = piece$support[1] > 0,
    current_outside_central95 = prevalences < piece$support[2] | prevalences > piece$support[3])
})
d <- do.call(rbind, rows)
stopifnot(nrow(d) == 28L, all(is.finite(d$attributable_fraction)),
          all(d$attributable_fraction >= 0 & d$attributable_fraction <= 1))
# This is a fraction within each age band; no across-age normalization or clipping.
cbh_atomic_csv(d, file.path(out, "attributable_fraction_by_age.csv"))
d$age_band <- factor(d$age_band, levels = ages)
d$prevalence <- factor(d$pfpr_pct, levels = prevalences, labels = paste0(prevalences, "%"))
# Age is drawn to scale (user request, 27 October 2026): each estimate sits at its band's midpoint, dodged
# by a fixed share of the band width so the four prevalence series stay legible and inside their band.
bands <- cbh_config()$age_bands
stopifnot(identical(bands$age_band, ages), bands$age_lo[1] == 0, all(bands$age_lo[-1] == bands$age_hi[-7]))
b <- match(d$age_band, ages); width <- bands$age_hi[b] - bands$age_lo[b]
d$age_months <- (bands$age_lo[b] + bands$age_hi[b]) / 2 +
  width * c(-.15, -.05, .05, .15)[match(d$pfpr_pct, prevalences)]
# Top panel: each band's share of observed deaths as a bar of equal width (the neonatal band's 1 month) at the
# band midpoint (user request, 27 October 2026), so bar height, not area, is the share.
deaths <- data.frame(age_band = ages, age_lo = bands$age_lo, age_hi = bands$age_hi,
                     deaths = diagnostics$deaths[match(paste0("map_full_age_", seq_along(ages)), diagnostics$fit_id)])
stopifnot(!anyNA(deaths$deaths), identical(diagnostics$age_band[match(paste0("map_full_age_", seq_along(ages)), diagnostics$fit_id)], ages))
deaths$share <- 100 * deaths$deaths / sum(deaths$deaths)
deaths$mid <- (deaths$age_lo + deaths$age_hi) / 2
bar_width <- bands$age_hi[1] - bands$age_lo[1]
deaths$label <- paste0(round(deaths$share), "%")
# A centred label on the neonatal bar would be clipped at the left edge, so it sits to the right of the bar top.
deaths$label_x <- ifelse(deaths$age_band == ages[1], deaths$mid + bar_width / 2 + .3, deaths$mid)
deaths$label_hjust <- ifelse(deaths$age_band == ages[1], 0, .5)
boundaries <- bands$age_lo[-1]
# Months 0 and 1 are too close to label both; the 1-month boundary is the first vertical line.
x_scale <- scale_x_continuous(breaks = c(0, boundaries[-1], 60), limits = c(0, 60), expand = expansion(add = .6))
x_lines <- geom_vline(xintercept = boundaries, colour = "grey88", linewidth = .23)
# Sizes meet the paper's printed text-size rule (CLAUDE.md) at 6.2 in (printed at 0.95\linewidth = 6.18 in); line,
# point and margin sizes are those of the former 11 in canvas scaled to 6.2 in.
base <- theme_minimal(base_size = 11.7, base_line_size = .5) +
  theme(axis.text = element_text(size = 9.9), axis.title = element_text(size = 11.92),
    panel.grid.minor = element_blank(), panel.grid.major.x = element_blank())
top <- ggplot(deaths) + x_lines +
  geom_rect(aes(xmin = mid - bar_width / 2, xmax = mid + bar_width / 2, ymin = 0, ymax = share), fill = "grey65") +
  geom_text(aes(x = label_x, y = share, label = label, hjust = label_hjust),
            vjust = -.4, size = 9.9 / .pt, colour = "grey25") +
  x_scale +
  # No zero label: it would collide with the 100% label of the panel below.
  scale_y_continuous(breaks = function(l) setdiff(scales::extended_breaks()(l), 0),
                     expand = expansion(mult = c(0, .2))) +
  labs(x = NULL, y = "% of all\ndeaths") +
  base + theme(axis.text.x = element_blank(), plot.margin = margin(9, 11, 0, 7))
# Conditional pointwise 95% intervals.
# The lower limit is allowed below zero: the neonatal interval at 10% includes zero.
y_floor <- min(0, floor(min(d$af_lower_95) * 20) / 20)
stopifnot(max(d$af_upper_95) <= 1)
bottom <- ggplot(d, aes(age_months, attributable_fraction, colour = prevalence, group = prevalence)) + x_lines +
  geom_hline(yintercept = 0, colour = "grey65", linewidth = .23) +
  geom_linerange(aes(ymin = af_lower_95, ymax = af_upper_95), linewidth = .4) +
  # Dashed (user request, 27 October 2026): the lines only join discrete band estimates.
  geom_line(linewidth = .62, linetype = "22") + geom_point(size = 1.35) +
  scale_colour_manual(values = c("10%" = "#0072B2", "20%" = "#009E73",
                                 "30%" = "#E69F00", "40%" = "#CC79A7")) +
  x_scale +
  # The 100% label is dropped because it would sit on the seam with the deaths panel.
  scale_y_continuous(breaks = seq(0,.8,.2), labels = scales::label_percent(accuracy = 1),
                     expand = expansion(mult = 0)) +
  coord_cartesian(ylim = c(y_floor, 1)) +
  labs(x = "Age (months)", y = "Malaria-attributable share\nof all-cause deaths",
       colour = expression(italic(Pf)*PR[2-10])) +
  base + theme(legend.position = "bottom", legend.text = element_text(size = 9.9),
    legend.title = element_text(size = 11.46), plot.margin = margin(2,11,7,7))
for (panel in list(top, bottom))
  stopifnot(is.null(panel$labels$title), is.null(panel$labels$subtitle), is.null(panel$labels$caption))
p <- patchwork::wrap_plots(top, bottom, ncol = 1, heights = c(1.2, 3))
ggsave(file.path(out, "attributable_fraction_by_age.png"), p, width = 6.2, height = 5.1,
       dpi = 400, device = ragg::agg_png, bg = "white")
inputs <- c(component_path, file.path(out, c("fit_manifest.csv", "fit_diagnostics.csv", "pfpr_curves.csv")),
            "R_cbh/reporting/06_attributable_fraction_by_age.R", "R_cbh/primary/settings.R")
cbh_atomic_csv(data.frame(file = inputs, md5 = vapply(inputs, cbh_file_hash, "")),
               file.path(out, "attributable_fraction_by_age_provenance.csv"))
message("Attributable-fraction figure (to-scale age, deaths-by-age panel) with intervals and all 28 age/prevalence estimates saved")
