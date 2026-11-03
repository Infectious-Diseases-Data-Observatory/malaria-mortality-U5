#!/usr/bin/env Rscript
# Comparison of the imputed-covariate sensitivity (v16) with the complete-case GADM-unit primary (v15), including the
# primary's declared national substitutions (national_substitutions.csv: South Sudan's pre-independence values are
# Sudan's in both analyses, so they are not counted as imputed): overlaid PfPR splines (supplementary manuscript
# figure), hazard ratio contrasts, sample sizes, caption and report. Reads saved aggregates and, for the figure's
# intervals, the saved fits; no refitting, no TeX writes.
source("R_cbh/load_pipeline.R")
source("R_cbh/reporting/labels.R")
source("R_cbh/reporting/curves_vs_zero.R")
source("R_cbh/sensitivity/imputation_dhsmics/settings.R")
library(ggplot2)
st <- cbh_imputed_dhsmics_settings(); out <- st$out; ref <- st$reference
vr <- sub(".*_(v[0-9]+)$", "\\1", basename(ref)); vi <- sub(".*_(v[0-9]+)$", "\\1", st$id)   # version labels, e.g. v15 and v16
mi_dir <- file.path(out, "multiple_imputation")
inputs <- c(file.path(ref, c("pfpr_curves.csv", "fit_diagnostics.csv", "prepared_sample.csv")),
  file.path(out, c("pfpr_curves.csv", "fit_diagnostics.csv", "prepared_sample.csv", "imputation_record_counts.csv",
                   "imputation_record_counts_by_survey.csv", "prepared_selection_by_survey.csv")),
  file.path(mi_dir, "pooled_contrasts.csv"), file.path(st$imputation_results, "national_imputation_summary.csv"),
  file.path(ref, "national_substitutions.csv"))
stopifnot(file.exists(inputs))
read <- function(i) cbh_read_csv(inputs[i])
pc <- read(1); pc <- pc[pc$series == "map_full", ]; pd <- read(2); ps <- read(3)
nc <- read(4); nd <- read(5); ns <- read(6); counts <- read(7); by_survey <- read(8); selection <- read(9)
pooled <- read(10)
# The primary's substitutions (one row per country), as text; every substituted record is retained.
subst <- unique(read(12)[c("country", "source_country", "before_year", "note", "records")])
stopifnot(nrow(pd) == 7L, nrow(nd) == 7L, all(nd$converged), all(nd$gamma == 2), all(nd$input_verified),
  all(nd$min_smoothing_hessian_eigenvalue > 0),
  counts$records[counts$programme == "All"] == ns$records,
  !anyDuplicated(subst$country), counts$national_substituted[counts$programme == "All"] == sum(subst$records))
ages <- cbh_config()$age_bands$age_band
labels <- setNames(st$comparison_labels, c("reference", "imputed"))
paper_labels <- c(reference = "Complete-case covariates (primary analysis)", imputed = "All covariate gaps imputed (sensitivity)")
keep <- intersect(names(pc), names(nc))
curves <- rbind(cbind(pc[keep], iteration = labels[["reference"]]), cbind(nc[keep], iteration = labels[["imputed"]]))
curves$series_label <- factor(paper_labels[match(curves$iteration, labels)], levels = unname(paper_labels))
curves$age_label <- factor(curves$age_band, levels = ages, labels = ifelse(ages == "<1", "<1 month", paste(ages, "months")))
cbh_atomic_csv(curves, file.path(out, "comparison_pfpr_curves.csv"))

## ---- figure -----------------------------------------------------------------------------------
colours <- setNames(c("#B36B39", "#215E91"), paper_labels)
# Sizes meet the paper's printed text-size rule (CLAUDE.md) at 6.2 in: saved 6.5 in wide, so printed = 0.95 x size
# (axis titles 11.9 -> 11.3 pt; ticks and legend 9.9 -> 9.4 pt; strips 10.8 -> 10.3 pt). Lines, spacing and margins are
# those of the former 14-in version scaled by 6.5/14; the two legend entries are stacked.
paper <- theme_minimal(base_size = 9.9, base_line_size = .38) + theme(panel.grid.minor = element_blank(),
  axis.text = element_text(size = 9.9), axis.title = element_text(size = 11.92), strip.text = element_text(size = 10.8, face = "bold"),
  legend.position = "bottom", legend.direction = "vertical", legend.title = element_blank(), legend.text = element_text(size = 9.9),
  legend.margin = margin(0, 0, 0, 0), legend.box.spacing = grid::unit(6, "pt"), legend.key.spacing.y = grid::unit(1, "pt"),
  panel.spacing = grid::unit(10, "pt"), plot.margin = margin(6, 10, 6, 6))
# Figure: hazard ratios relative to zero prevalence on a linear axis, as in Figure 2 (author request, 3 November 2026).
# The complete-case curve and interval are Figure 2's own; the imputed-covariate curves are re-referenced to zero with
# intervals from the PfPR smooth of each saved fit (fit_manifest.csv, hashes checked). Solid over each curve's central
# 95%, dashed from zero to its 2.5th percentile.
manifest <- cbh_read_csv(file.path(out, "fit_manifest.csv"))
vz_imp <- do.call(rbind, lapply(ages, function(a) {
  m <- manifest[manifest$age_band == a, ]; stopifnot(nrow(m) == 1L, identical(cbh_file_hash(m$model_file), m$md5))
  cbh_curve_vs_zero(nc[nc$age_band == a, ], readRDS(m$model_file)$fit)
}))
vz <- rbind(data.frame(series_label = paper_labels[["reference"]], cbh_primary_vs_zero(ref)),
            data.frame(series_label = paper_labels[["imputed"]], vz_imp))
vz <- vz[vz$segment != "outside", ]; rownames(vz) <- NULL
vz$series_label <- factor(vz$series_label, levels = unname(paper_labels))
cbh_atomic_csv(vz, file.path(out, "comparison_hazard_ratio_vs_zero.csv"))
vz$age_label <- factor(vz$age_band, levels = ages, labels = ifelse(ages == "<1", "<1 month", paste(ages, "months")))
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
figure <- file.path(out, "sfig_pfpr_splines_imputed_covariates.png")
ggsave(figure, p, width = 6.5, height = 3.95, dpi = 320, device = ragg::agg_png, bg = "white")

## ---- contrasts and sample -------------------------------------------------------------------------
contrasts <- do.call(rbind, lapply(c(40, 0), function(x) {
  z <- curves[curves$pfpr_pct == x, ]; sign <- if (x == 40) -1 else 1; loghr <- sign * z$log_hazard_ratio
  data.frame(iteration = z$iteration, age_band = z$age_band, contrast = if (x == 40) "40% to 20%" else "20% to 0%",
    hazard_ratio = exp(loghr), lower_95 = exp(loghr - 1.96 * z$standard_error), upper_95 = exp(loghr + 1.96 * z$standard_error))
}))
cbh_atomic_csv(contrasts, file.path(out, "comparison_contrasts.csv"))
sample <- data.frame(measure = c("Child-band records", "Distinct children", "Deaths", "Survey x unit areas", "Surveys", "Countries"),
  previous = c(ps$records, ps$children, ps$deaths, ps$regions, ps$surveys, ps$countries),
  revised = c(ns$records, ns$children, ns$deaths, ns$regions, ns$surveys, ns$countries))
cbh_atomic_csv(sample, file.path(out, "comparison_sample.csv"))
hr <- function(iter, contrast) { d <- contrasts[contrasts$iteration == iter & contrasts$contrast == contrast, ]
  d <- d[match(ages, d$age_band), ]; sprintf("%.2f", d$hazard_ratio) }
wide_hr <- function(contrast) { a <- contrasts[contrasts$contrast == contrast, ]
  r <- a[a$iteration == labels[["reference"]], ]; i <- a[a$iteration == labels[["imputed"]], ]
  r <- r[match(ages, r$age_band), ]; i <- i[match(ages, i$age_band), ]; list(r = r, i = i) }
w40 <- wide_hr("40% to 20%"); delta <- max(abs(w40$i$hazard_ratio - w40$r$hazard_ratio))
mi40 <- pooled[pooled$contrast == "40% to 20%", ]; mi40 <- mi40[match(ages, mi40$age_band), ]
mi_delta <- max(abs(mi40$pooled_hr - mi40$point_hr)); max_share <- max(pooled$between_imputation_share)
M <- st$m
row <- function(m) sample[sample$measure == m, ]
fmt <- function(x) format(round(x), big.mark = ",")
mics_surveys <- sum(selection$programme == "MICS")
fmt_share <- sprintf("%.1f%%", 100 * max_share)
cname <- function(x) countrycode::countrycode(x, "iso3c", "country.name", warn = FALSE)
subst_text <- if (nrow(subst)) paste(sprintf("%s (%s) takes %s's observed GDP per capita, health expenditure per capita and political stability for band-entry years before %d",
  cname(subst$country), subst$note, cname(subst$source_country), subst$before_year), collapse = "; ") else ""

## ---- caption ---------------------------------------------------------------------------------------
caption <- c("# Supplementary figure caption: imputed-covariate sensitivity (DHS and MICS)", "",
  paste0("Sensitivity of the fitted PfPR–mortality relationship to the treatment of missing covariates. ",
  "Mortality hazard ratios relative to zero prevalence (PfPR[2–10] = 0) by completed-month age band, with pointwise 95% conditional intervals shaded, from the ", cbh_paper_model_label(), " fitted to the complete-case primary sample (",
  fmt(row("Child-band records")$previous), " child–age-band records, ", fmt(row("Deaths")$previous), " deaths, ", row("Surveys")$previous, " surveys in ", row("Countries")$previous,
  " countries) and to every record placed in a GADM 4.1 admin-1 unit after imputing all remaining covariate gaps (",
  fmt(row("Child-band records")$revised), " records, ", fmt(row("Deaths")$revised), " deaths, ", row("Surveys")$revised, " surveys in ", row("Countries")$revised,
  " countries, including all five Malaria Indicator Surveys and all ", mics_surveys, " MICS surveys with complete birth histories outside Lesotho",
  ", the Comoros and São Tomé and Príncipe, which have no malaria-endemic unit). ",
  "Whole-survey gaps in the regional indicators (wasting, stunting, facility delivery, electricity and the wealth score) were imputed by chained equations at the survey × unit level (predictive mean matching, ", M, " imputations, point value their mean); the missing 2001 World Governance Indicators round by linear interpolation; ",
  "health expenditure for Zimbabwe 2000–2009, Somalia 2000–2012 and all countries in 2024 from a generalised additive model on the observed national panel; ",
  "Liberia's child HIV incidence from UNAIDS counts of new infections among children (São Tomé and Príncipe, the only country without an incidence series, has no analysis unit). ",
  paste0(if (nzchar(subst_text)) paste0("In both analyses, ", subst_text, ". "), "Values used by the complete-case analysis were never replaced. "),
  "The specification, reference knots, basis dimensions and gamma = 2 are those of the primary analysis; covariates were re-standardised on the enlarged sample. ",
  "Each curve is solid over the central 95% of its own exposure distribution and dashed from zero to its 2.5th percentile, where the reference is reached by extrapolation into sparse data; the complete-case curves are those of Figure 2. ",
  "Hazard ratios for PfPR 40% to 20% are ", paste(hr(labels[["reference"]], "40% to 20%"), collapse = ", "), " (complete case) and ",
  paste(hr(labels[["imputed"]], "40% to 20%"), collapse = ", "), " (imputed) for the seven bands from youngest to oldest. ",
  sprintf("Refitting the imputed version in each of the %d imputed datasets and pooling with Rubin's rules changed these hazard ratios by at most %.3f; the between-imputation share of interval variance was at most %s. ", M, mi_delta, fmt_share),
  "The two samples are nested, so the comparison is descriptive."))
writeLines(caption, file.path(out, "CAPTION_sfig_imputed_covariates.md"))

## ---- report ------------------------------------------------------------------------------------------
fmt_ci <- function(d) sprintf("%.2f (%.2f–%.2f)", d$hazard_ratio, d$lower_95, d$upper_95)
w0 <- wide_hr("20% to 0%")
tab <- function(w, title) c(paste0("### PfPR ", title), "", paste0("| Age (months) | ", labels[["reference"]], " | ", labels[["imputed"]], " |"), "|---|---:|---:|",
  sprintf("| %s | %s | %s |", ages, fmt_ci(w$r), fmt_ci(w$i)), "")
tot <- counts[counts$programme == "All", ]
lines <- c(sprintf("# Imputed-covariate sensitivity on the DHS and MICS sample (%s)", vi), "",
  sprintf("The 17-covariate primary specification refitted after imputing every remaining covariate gap, so that every DHS and MICS record placed in a GADM 4.1 admin-1 unit is retained. Reference: the complete-case GADM-unit primary `%s`. This version: `%s`.", basename(ref), st$id), "",
  "## Sample", "", sprintf("| Measure | Complete case (%s) | Imputed (%s) |", vr, vi), "|---|---:|---:|",
  sprintf("| %s | %s | %s |", sample$measure, fmt(sample$previous), fmt(sample$revised)), "",
  sprintf("Records whose values were imputed (point version): regional covariates %s; political stability %s (2001 interpolation); GDP %s; health expenditure %s; child HIV incidence without an adolescent series %s.%s The extended HIV panel also changes censored and imputed incidence values in other countries, so the comparison mixes the covariate imputation with that panel change, as for v4 against v3.",
    fmt(tot$regional_any_model_imputed), fmt(tot$political_stability_imputed), fmt(tot$gdp_imputed), fmt(tot$health_expenditure_imputed), fmt(tot$hiv_no_adolescent_series),
    if (nzchar(subst_text)) sprintf(" As in the primary analysis, %s (%s records); these values are not counted as imputed.", subst_text, fmt(tot$national_substituted)) else ""), "",
  "## Figure", "", "![Complete-case versus imputed PfPR curves](sfig_pfpr_splines_imputed_covariates.png)", "", caption[3], "",
  "## Hazard ratios", "", "Pointwise conditional 95% intervals; the samples are nested, so compare descriptively.", "",
  tab(w40, "40% to 20%"), tab(w0, "20% to 0%"),
  sprintf("Largest absolute change in the 40%% to 20%% hazard ratio between the complete-case and imputed fits: %.3f. Multiple-imputation check (%d imputed datasets, fixed smoothing parameters, Rubin's rules): largest change from the point fit %.3f; between-imputation share of variance at most %s ([report](multiple_imputation/REPORT.md)).", delta, M, mi_delta, fmt_share), "",
  "## Fits", "",
  sprintf("All seven fits converged with full rank, finite coefficients and covariances and positive smoothing-Hessian eigenvalues; %d used the tighter-tolerance restart. Fitted model columns were checked against the input rows. Total fitting time %.0f minutes.",
    sum(grepl("strict", cbh_read_csv(file.path(out, "fit_manifest.csv"))$selected_version)), sum(nd$elapsed_seconds) / 60), "",
  sprintf("Imputation audits: [regional](../%s/REGIONAL_IMPUTATION.md) and [national](../%s/NATIONAL_IMPUTATION.md). Per-survey imputed-record counts: [imputation_record_counts_by_survey.csv](imputation_record_counts_by_survey.csv).",
    a <- basename(st$imputation_results), a), "",
  "Reproduce, from the project root: `Rscript R_cbh/sensitivity/imputation_dhsmics/0N_*.R` for N = 1 to 6 in order (fits and the multiple-imputation refits are long; run them detached). Only aggregate tables and figures are published; prepared data and fitted objects stay under the ignored data directory. The primary analysis and manuscript files are unchanged.")
writeLines(lines, file.path(out, "REPORT.md"))
prov <- c(inputs, file.path(out, "fit_manifest.csv"), file.path(ref, "hazard_ratio_by_age", "hazard_ratio_curves.csv"),
          "R_cbh/reporting/curves_vs_zero.R", figure)
cbh_atomic_csv(data.frame(file = prov, md5 = vapply(prov, cbh_file_hash, ""), row.names = NULL), file.path(out, "sfig_provenance.csv"))
print(data.frame(age = ages, complete_case = w40$r$hazard_ratio, imputed = w40$i$hazard_ratio, pooled = mi40$pooled_hr))
cat(sprintf("Largest 40%%->20%% change complete case -> imputed: %.3f; MI vs point: %.3f; max between share %s\n", delta, mi_delta, fmt_share))
