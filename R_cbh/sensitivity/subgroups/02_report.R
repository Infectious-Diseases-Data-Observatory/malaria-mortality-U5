#!/usr/bin/env Rscript
# Overlay subgroup PfPR curves on the full primary curves; saved aggregates only.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/reporting/labels.R")
source("R_cbh/reporting/curves_vs_zero.R")
source("R_cbh/sensitivity/subgroups/settings.R")
library(ggplot2)
args <- commandArgs(trailingOnly = TRUE); stopifnot(!length(args))
st <- cbh_subgroup_settings(); primary <- cbh_primary_settings(st$primary_version)
read <- function(x) cbh_read_csv(file.path(st$out, x))
write_csv <- function(d, name) cbh_atomic_csv(d, file.path(st$out, name))
ages <- cbh_config()$age_bands$age_band
subgroups <- st$subgroups
diag <- read("fit_diagnostics.csv")
stopifnot(nrow(diag) == 7L * length(subgroups), all(diag$converged), all(diag$input_verified), all(diag$gamma == 2),
  all(diag$rank == diag$coefficients), all(diag$min_smoothing_hessian_eigenvalue > 0))
sub <- read("pfpr_curves.csv")
full_path <- file.path(primary$out, "pfpr_curves.csv")
full <- cbh_read_csv(full_path)
pd <- cbh_read_csv(file.path(primary$out, "fit_diagnostics.csv"))
stopifnot(all(pd$gamma == 2), all(pd$converged), all(full$series == "map_full"))
full$subgroup <- "map_full"; full <- full[names(sub)]
d <- rbind(full, sub)
d$hazard_ratio <- exp(d$log_hazard_ratio)
stopifnot(all(abs(d$log_hazard_ratio[d$pfpr_pct == 20]) < 1e-10), all(is.finite(d$hazard_ratio)),
  all(d$reference_within_observed_support))
d$series <- factor(st$labels[d$subgroup], levels = unname(st$labels))
write_csv(d, "pfpr_curves_comparison.csv")
write_csv(unique(d[c("subgroup", "series", "age_band", "pfpr_min", "pfpr_p025", "pfpr_p975", "pfpr_max")]),
          "exposure_support.csv")
d$age_label <- factor(d$age_band, levels = ages, labels = ifelse(ages == "<1", "<1 month", paste(ages, "months")))
colours <- setNames(unname(st$colours), unname(st$labels))
# Sizes meet the paper's printed text-size rule (CLAUDE.md): the figures are saved 6.5 in wide and printed at \linewidth
# (6.5 in), so printed = size (axis titles 11.9 pt; ticks and legend 9.9 pt; strips 10.8 pt). Lines, spacing and
# margins are those of the former 14-15 in versions scaled by about 6.5/15.
paper <- theme_minimal(base_size = 9.9, base_line_size = .35) + theme(panel.grid.minor = element_blank(),
  axis.text = element_text(size = 9.9), axis.title = element_text(size = 11.92),
  strip.text = element_text(size = 10.8, face = "bold"), legend.position = "bottom",
  legend.text = element_text(size = 9.9), legend.title = element_blank(), legend.margin = margin(0, 0, 0, 0),
  legend.box.spacing = grid::unit(6, "pt"), legend.key.spacing.y = grid::unit(1, "pt"),
  panel.spacing = grid::unit(10, "pt"), plot.margin = margin(4, 10, 4, 4))
# Figures: hazard ratios relative to zero prevalence on a linear axis, as in Figure 2 (author request, 3 November 2026).
# The full analysis is Figure 2's own curve and interval; each subset curve is its saved curve re-referenced to zero
# (point estimates only: subset intervals are omitted for legibility). Curves are solid over their central 95% and
# dashed from zero to their 2.5th percentile.
vz <- rbind(data.frame(subgroup = "map_full", cbh_primary_vs_zero(primary$out)),
  do.call(rbind, lapply(split(sub, list(sub$subgroup, sub$age_band), drop = TRUE),
                        function(z) data.frame(subgroup = z$subgroup[1], cbh_curve_vs_zero(z)))))
vz <- vz[vz$segment != "outside", ]; rownames(vz) <- NULL
vz$series <- factor(st$labels[vz$subgroup], levels = unname(st$labels))
write_csv(vz, "hazard_ratio_vs_zero.csv")
vz$age_label <- factor(vz$age_band, levels = ages, labels = ifelse(ages == "<1", "<1 month", paste(ages, "months")))
# One spline figure per group of subsets (st$figures): Sahel, the UN M49 sub-regions and the periods.
for (fig_name in names(st$figures)) {
shown <- vz[vz$subgroup %in% c("map_full", st$figures[[fig_name]]), ]
shown$series <- droplevels(shown$series)
# PfPR axis 0-80%, as in the other supplementary spline figures; every curve's central support lies inside it.
stopifnot(max(shown$pfpr_pct) <= 80)
shown$is_full <- shown$subgroup == "map_full"
# The dashed segment ends where the solid one starts.
p <- ggplot(shown, aes(pfpr_pct, hazard_ratio, colour = series)) +
  geom_hline(yintercept = 1, colour = "grey60", linewidth = .17) +
  geom_ribbon(data = shown[shown$is_full, ], aes(ymin = lower_95, ymax = upper_95),
              fill = "grey55", alpha = .18, colour = NA) +
  geom_line(data = shown[shown$pfpr_pct <= shown$pfpr_p025, ], aes(linewidth = is_full), linetype = "22", show.legend = FALSE) +
  geom_line(data = shown[shown$segment == "central", ], aes(linewidth = is_full)) +
  scale_linewidth_manual(values = c(`TRUE` = .65, `FALSE` = .43), guide = "none") +
  facet_wrap(~age_label, ncol = 4) +
  scale_x_continuous(limits = c(0, 80), breaks = c(0, 20, 40, 60, 80)) +
  scale_y_continuous(breaks = seq(0, 5, .5)) +
  scale_colour_manual(values = colours) +
  guides(colour = guide_legend(ncol = 2, override.aes = list(linewidth = .56))) +
  labs(x = expression(italic(Pf)*PR[2-10]~"(%)"), y = "Mortality hazard ratio\nrelative to zero prevalence") + paper
stopifnot(is.null(p$labels$title), is.null(p$labels$subtitle))
# Height grows with the legend rows (two columns), so the panels are the same size in every figure.
ggsave(file.path(st$out, paste0(fig_name, ".png")), p, width = 6.5, height = 3.55 + .2 * ceiling(nlevels(shown$series) / 2),
       dpi = 320, device = ragg::agg_png, bg = "white")
}

# Contrasts identified directly from each curve; the subgroups are nested in the full sample.
contrasts <- do.call(rbind, lapply(c(0, 40), function(x) {
  z <- d[d$pfpr_pct == x, ]
  sign <- if (x == 40) -1 else 1
  loghr <- sign * z$log_hazard_ratio
  data.frame(subgroup = z$subgroup, series = z$series, age_band = z$age_band,
    contrast = if (x == 40) "40% to 20%" else "20% to 0%",
    hazard_ratio = exp(loghr), lower_95 = exp(loghr - 1.96 * z$standard_error),
    upper_95 = exp(loghr + 1.96 * z$standard_error),
    both_values_within_observed_support = x >= z$pfpr_min & x <= z$pfpr_max & z$reference_within_observed_support,
    both_values_within_central_support = pmin(x, 20) >= z$pfpr_p025 & pmax(x, 20) <= z$pfpr_p975)
}))
write_csv(contrasts, "pfpr_contrasts.csv")
cz <- contrasts[contrasts$contrast == "40% to 20%", ]

## ---- caption and report --------------------------------------------------------------
sample <- read("sample_summary.csv"); defs <- readLines(file.path(st$out, "subgroup_definitions.csv"))
cutoff <- as.integer(sub("median_survey_year,", "", defs[1]))
cc <- grep("^records_period_cutoff,", defs, value = TRUE)
calendar_cutoff <- if (length(cc)) as.numeric(sub("^records_period_cutoff,([0-9.]+).*$", "\\1", cc)) else NA_real_
fmt <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)
row <- function(s) sample[sample$subgroup == s, ]
describe <- function(s) sprintf("%s: %s children, %s records, %s deaths, %d survey × unit areas, %d surveys, %d countries",
  st$labels[[s]], fmt(row(s)$distinct_children), fmt(row(s)$records), fmt(row(s)$deaths),
  row(s)$survey_regions, row(s)$surveys, row(s)$countries)
subset_text <- c(sahel = "records whose survey-region boundary centroid lies at or north of 12°N and west of 36°E, excluding the Horn of Africa (Sahel)",
  east_africa = "UN M49 Eastern Africa countries", west_africa = "UN M49 Western Africa countries",
  central_africa = "UN M49 Middle (Central) Africa countries",
  early = paste0("surveys conducted up to the median survey year (", cutoff, ")"), late = "surveys conducted after it",
  records_early = sprintf("child-band records with calendar year up to the median calendar year of the records (%.1f)", calendar_cutoff),
  records_late = "records after it")
not_fitted_text <- if (length(st$not_fitted)) { nf <- read("subregions_not_fitted.csv")
  sprintf(" Southern Africa (UN M49) is not refitted: it has %s deaths in %d surveys from %d countries and PfPR[2–10] never exceeds %.1f%% (95%% of records below %.1f%%), so its curve at 20%% and 40%% would be an extrapolation.",
    fmt(nf$deaths[1]), nf$surveys[1], nf$countries[1], nf$pfpr_max[1], nf$pfpr_p95[1]) } else ""
caption_for <- function(groups) paste(
  paste0("Sensitivity of the fitted PfPR–mortality relationship to the analysis subset. Mortality hazard ratios relative to zero prevalence (PfPR[2–10] = 0) by completed-month age band, from the ", cbh_paper_model_label(), " fitted to the full primary sample (black, with its pointwise 95% conditional interval shaded; the curves of Figure 2) and refitted separately in ",
    c("one subset", "two subsets", "three subsets", "four subsets", "five subsets", "six subsets", "seven subsets", "eight subsets")[length(groups)], ": ",
    if (length(groups) > 1) paste0(paste(subset_text[head(groups, -1)], collapse = "; "), "; and ", subset_text[[tail(groups, 1)]]) else subset_text[[groups]], ".", if (any(groups %in% c("west_africa", "central_africa", "east_africa"))) not_fitted_text else ""),
  "Each subset refit uses the same seven separate age-band models, 17 standardised covariates with the full-sample scaling, fixed HIV incidence imputation, gamma = 2 and basis dimensions as the primary analysis, with knots placed at quantiles of the subset's own predictor values. Each curve is solid over the central 95% of its own exposure distribution and dashed from zero to its 2.5th percentile, where the reference is reached by extrapolation into sparse data.",
  paste0("Subset sizes. ", paste(vapply(groups, describe, ""), collapse = "; "), "."),
  "The subsets overlap the full sample and one another, so the curves are not independent and their differences are descriptive; the comparison does not constitute a test of effect modification. Subset intervals are omitted for legibility and are available in the saved curve table.")
caption <- caption_for(st$figures[[1]])
writeLines(c("# Supplementary figure caption: PfPR splines by subgroup", "", caption), file.path(st$out, "CAPTION.md"))
if (length(st$figures) > 1) for (k in 2:length(st$figures))
  writeLines(c(paste("# Supplementary figure caption:", sub("^sfig_", "", names(st$figures)[k])), "", caption_for(st$figures[[k]])),
             file.path(st$out, paste0("CAPTION_", names(st$figures)[k], ".md")))
hr <- function(x) sprintf("%.2f (%.2f–%.2f)", x$hazard_ratio, x$lower_95, x$upper_95)
table_lines <- c(paste0("| Age (months) | ", paste(unname(st$labels), collapse = " | "), " |"),
  paste0("|---|", paste(rep("---:", length(st$labels)), collapse = "|"), "|"))
for (age in ages) {
  a <- cz[cz$age_band == age, ]
  table_lines <- c(table_lines, paste0("| ", age, " | ",
    paste(vapply(names(st$labels), function(s) hr(a[a$subgroup == s, ]), ""), collapse = " | "), " |"))
}
lines <- c("# Subgroup sensitivity of the primary PfPR models", "",
  paste0("Seven separate MAP gamma=2 age-band models refitted in ", c("one subset", "two subsets", "three subsets", "four subsets", "five subsets", "six subsets", "seven subsets", "eight subsets")[length(subgroups)], " of the fitted 17-variable sample (`", primary$id, "`). Reference: the full primary fits in `", primary$out, "`.", not_fitted_text), "",
  "## Subsets", "", paste0("- ", vapply(subgroups, describe, "")), "",
  paste0("Definitions: ", paste(defs[-1], collapse = "; "), ". Survey regions enter whole; centroids are survey-specific boundary centroids (DHS: the cached shapefile summary; MICS: the analysis-region polygons, `R_mics/11_region_centroids.R`). The period split counts each survey once."), "",
  "## Figures", "",
  unlist(lapply(names(st$figures), function(f) c(sprintf("![%s](%s.png)", c(sfig_pfpr_splines_by_subgroup = "Splines by subgroup",
    sfig_pfpr_splines_by_subregion = "Splines by UN sub-region", sfig_pfpr_splines_by_period = "Splines by period")[[f]], f), "", caption_for(st$figures[[f]]), ""))),
  "## Hazard ratios, PfPR 40% to 20%", "", "Values below one indicate lower mortality at 20% than at 40%. Intervals are pointwise conditional 95% intervals; the samples are nested, so compare descriptively.", "",
  table_lines, "",
  "## Validation", "",
  sprintf("All %d subgroup fits converged with full rank, finite coefficients and covariances and positive smoothing-Hessian eigenvalues; %d needed the tighter-tolerance restart (see restarts.csv where present). Fitted model columns were checked against the selected input rows; curves are anchored at zero at 20%% PfPR. Total pure fitting time %.0f seconds.",
    nrow(diag), sum(grepl("strict", cbh_read_csv(file.path(st$out, "fit_manifest.csv"))$selected_version)), sum(diag$elapsed_seconds)), "",
  paste0("Reproduce: `Rscript R_cbh/sensitivity/subgroups/01_fit.R` then `Rscript R_cbh/sensitivity/subgroups/02_report.R`", ". Only aggregate tables and figures are published; fitted objects stay under the ignored data directory. Primary fits, burden estimates and manuscript files are unchanged."))
writeLines(lines, file.path(st$out, "REPORT.md"))
source_files <- c(full_path, file.path(primary$out, c("fit_diagnostics.csv", "hazard_ratio_by_age/hazard_ratio_curves.csv")),
  file.path(st$out, c("pfpr_curves.csv", "fit_diagnostics.csv", "sample_summary.csv")),
  "R_cbh/sensitivity/subgroups/02_report.R", "R_cbh/sensitivity/subgroups/settings.R", "R_cbh/reporting/labels.R",
  "R_cbh/reporting/curves_vs_zero.R")
write_csv(data.frame(file = source_files, md5 = vapply(source_files, cbh_file_hash, "")), "report_provenance.csv")
message("Subgroup overlays and report complete: ", st$out)
