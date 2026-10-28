#!/usr/bin/env Rscript
# Overlay subgroup PfPR curves on the full primary curves; saved aggregates only.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/reporting/labels.R")
source("R_cbh/sensitivity/subgroups/settings.R")
library(ggplot2)
args <- commandArgs(trailingOnly = TRUE); stopifnot(all(args %in% "--dhs-only"))
st <- cbh_subgroup_settings(cbh_subgroup_sample(args)); primary <- cbh_primary_settings(st$primary_version)
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
# Sizes meet the paper's printed text-size rule (CLAUDE.md) at 6.2 in: the figures are saved 6.5 in wide, so printed =
# 0.95 x size (axis titles 11.9 -> 11.3 pt; ticks and legend 9.9 -> 9.4 pt; strips 10.8 -> 10.3 pt). Lines, spacing and
# margins are those of the former 14-15 in versions scaled by about 6.5/15.
paper <- theme_minimal(base_size = 9.9, base_line_size = .35) + theme(panel.grid.minor = element_blank(),
  axis.text = element_text(size = 9.9), axis.title = element_text(size = 11.92),
  strip.text = element_text(size = 10.8, face = "bold"), legend.position = "bottom",
  legend.text = element_text(size = 9.9), legend.title = element_blank(), legend.margin = margin(0, 0, 0, 0),
  legend.box.spacing = grid::unit(6, "pt"), legend.key.spacing.y = grid::unit(1, "pt"),
  panel.spacing = grid::unit(10, "pt"), plot.margin = margin(4, 10, 4, 4))
# One spline figure per group of subsets (st$figures): v9 one figure with every subset; the Snow-unit suite one figure
# for Sahel and the survey periods and one for the UN M49 sub-regions.
for (fig_name in names(st$figures)) {
shown <- d[d$within_central_support & d$subgroup %in% c("map_full", st$figures[[fig_name]]), ]
shown$series <- droplevels(shown$series)
# PfPR axis 0-80%, as in the other supplementary spline figures; every curve's central support lies inside it.
stopifnot(max(shown$pfpr_pct) <= 80)
shown$is_full <- shown$subgroup == "map_full"
p <- ggplot(shown, aes(pfpr_pct, log_hazard_ratio, colour = series)) +
  geom_hline(yintercept = 0, colour = "grey60", linewidth = .17) +
  geom_vline(xintercept = 20, colour = "grey80", linewidth = .17) +
  geom_ribbon(data = shown[shown$is_full, ], aes(ymin = lower_95, ymax = upper_95),
              fill = "grey55", alpha = .18, colour = NA) +
  geom_line(aes(linewidth = is_full)) +
  scale_linewidth_manual(values = c(`TRUE` = .65, `FALSE` = .43), guide = "none") +
  facet_wrap(~age_label, ncol = 4) +
  scale_x_continuous(limits = c(0, 80), breaks = c(0, 20, 40, 60, 80)) +
  scale_colour_manual(values = colours) +
  guides(colour = guide_legend(ncol = 2, override.aes = list(linewidth = .56))) +
  labs(x = "PfPR[2–10] (%)", y = "Log hazard ratio\nrelative to PfPR = 20%") + paper
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
cz$age_label <- factor(cz$age_band, levels = rev(ages))
pc <- ggplot(cz, aes(hazard_ratio, age_label, colour = series)) +
  geom_vline(xintercept = 1, colour = "grey60", linetype = 2, linewidth = .23) +
  geom_pointrange(aes(xmin = lower_95, xmax = upper_95), position = position_dodge(width = .7), size = .23, linewidth = .23) +
  scale_x_log10(breaks = c(.5, .7, .8, .9, 1, 1.1, 1.25)) + scale_colour_manual(values = colours) +
  guides(colour = guide_legend(ncol = 2)) +
  labs(x = "Hazard ratio, PfPR 40% to 20% (95% interval, log scale)", y = "Age (completed months)") + paper
ggsave(file.path(st$out, "pfpr_40_to_20_by_subgroup.png"), pc, width = 6.5,
       height = if (length(st$labels) > 5) 5 else 4.5, dpi = 320,
       device = ragg::agg_png, bg = "white")

## ---- caption and report --------------------------------------------------------------
sample <- read("sample_summary.csv"); defs <- readLines(file.path(st$out, "subgroup_definitions.csv"))
cutoff <- as.integer(sub("median_survey_year,", "", defs[1]))
cc <- grep("^records_period_cutoff,", defs, value = TRUE)
calendar_cutoff <- if (length(cc)) as.numeric(sub("^records_period_cutoff,([0-9.]+).*$", "\\1", cc)) else NA_real_
fmt <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)
row <- function(s) sample[sample$subgroup == s, ]
describe <- function(s) sprintf(paste0("%s: %s children, %s records, %s deaths, %d ", if (identical(primary$unit, "snow")) "survey × unit areas" else "survey-regions", ", %d surveys, %d countries"),
  st$labels[[s]], fmt(row(s)$distinct_children), fmt(row(s)$records), fmt(row(s)$deaths),
  row(s)$survey_regions, row(s)$surveys, row(s)$countries)
subset_text <- c(sahel = if (identical(primary$unit, "snow")) "records whose survey-region boundary centroid lies at or north of 12°N and west of 36°E, excluding the Horn of Africa (Sahel)"
    else "survey regions with boundary centroids at or north of 12°N and west of 36°E, excluding the Horn of Africa (Sahel)",
  east_africa = "UN M49 Eastern Africa countries", west_africa = "UN M49 Western Africa countries",
  central_africa = "UN M49 Middle (Central) Africa countries",
  early = paste0("surveys conducted up to the median survey year (", cutoff, ")"), late = "surveys conducted after it",
  records_early = sprintf("child-band records with calendar year up to the median calendar year of the records (%.1f)", calendar_cutoff),
  records_late = "records after it")
not_fitted_text <- if (length(st$not_fitted)) { nf <- read("subregions_not_fitted.csv")
  sprintf(" Southern Africa (UN M49) is not refitted: it has %s deaths in %d surveys from %d countries and PfPR[2–10] never exceeds %.1f%% (95%% of records below %.1f%%), so its curve at 20%% and 40%% would be an extrapolation.",
    fmt(nf$deaths[1]), nf$surveys[1], nf$countries[1], nf$pfpr_max[1], nf$pfpr_p95[1]) } else ""
caption_for <- function(groups) paste(
  paste0("Sensitivity of the fitted PfPR–mortality relationship to the analysis subset. Log mortality hazard ratios relative to PfPR[2–10] = 20% by completed-month age band, from the ", cbh_paper_model_label(), " fitted to the full primary sample (black, with its pointwise 95% conditional interval shaded) and refitted separately in ",
    c("one subset", "two subsets", "three subsets", "four subsets", "five subsets", "six subsets", "seven subsets", "eight subsets")[length(groups)], ": ",
    if (length(groups) > 1) paste0(paste(subset_text[head(groups, -1)], collapse = "; "), "; and ", subset_text[[tail(groups, 1)]]) else subset_text[[groups]], ".", if (any(groups %in% c("west_africa", "central_africa", "east_africa"))) not_fitted_text else ""),
  "Each subset refit uses the same seven separate age-band models, 17 standardised covariates with the full-sample scaling, fixed HIV incidence imputation, gamma = 2 and basis dimensions as the primary analysis, with knots placed at quantiles of the subset's own predictor values. Each curve is drawn over the central 95% of its own exposure distribution.",
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
  "![40% to 20% contrasts](pfpr_40_to_20_by_subgroup.png)", "",
  "## Hazard ratios, PfPR 40% to 20%", "", "Values below one indicate lower mortality at 20% than at 40%. Intervals are pointwise conditional 95% intervals; the samples are nested, so compare descriptively.", "",
  table_lines, "",
  "## Validation", "",
  sprintf("All %d subgroup fits converged with full rank, finite coefficients and covariances and positive smoothing-Hessian eigenvalues; %d needed the tighter-tolerance restart (see restarts.csv where present). Fitted model columns were checked against the selected input rows; curves are anchored at zero at 20%% PfPR. Total pure fitting time %.0f seconds.",
    nrow(diag), sum(grepl("strict", cbh_read_csv(file.path(st$out, "fit_manifest.csv"))$selected_version)), sum(diag$elapsed_seconds)), "",
  paste0("Reproduce: `Rscript R_cbh/sensitivity/subgroups/01_fit.R` then `Rscript R_cbh/sensitivity/subgroups/02_report.R`", if (st$sample == "dhs") " (both with `--dhs-only`)" else "", ". Only aggregate tables and figures are published; fitted objects stay under the ignored data directory. Primary fits, burden estimates and manuscript files are unchanged."))
writeLines(lines, file.path(st$out, "REPORT.md"))
source_files <- c(full_path, file.path(primary$out, "fit_diagnostics.csv"),
  file.path(st$out, c("pfpr_curves.csv", "fit_diagnostics.csv", "sample_summary.csv")),
  "R_cbh/sensitivity/subgroups/02_report.R", "R_cbh/sensitivity/subgroups/settings.R", "R_cbh/reporting/labels.R")
write_csv(data.frame(file = source_files, md5 = vapply(source_files, cbh_file_hash, "")), "report_provenance.csv")
message("Subgroup overlays and report complete: ", st$out)
