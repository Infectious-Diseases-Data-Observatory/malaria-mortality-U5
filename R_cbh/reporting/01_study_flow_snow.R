#!/usr/bin/env Rscript
# Study flow (Figure S1) for the Snow-unit primary: the v9 ledger of R_cbh/reporting/01_study_flow.R with the
# survey-region MAP step replaced by placement in the Snow et al. (2017) polygons (R_cbh/snow/). Aggregate inputs,
# except the count of mothers, which reads the record shards as 03_survey_map.R does.
# The full ledger (flow_counts.csv) runs: survey registry -> band entries within 5 years of interview -> eligible
# child-age bands -> placed in a Snow polygon -> primary analysis sample, with exclusions for surveys not processed (no
# MAP geography) or without a complete birth history; band eligibility; not placed (survey-region not matched; no Snow
# polygon; malaria-free or island unit; unit more than half malaria-free); required covariate unavailable (first
# missing input). The diagram (simplified 27 October 2026, user request, to match the Results text) shows the survey
# steps all surveys -> complete birth history -> included (at least one primary record), with the excluded surveys by
# reason, then the records excluded within the included surveys. The declared national substitutions of the
# preparation (national_substitutions.csv: South Sudan before independence takes Sudan's values) are stated in the
# caption and counted (national_substituted).
# Writes <out>/study_flow/: study_flow_diagram.png, CAPTION.md, flow_counts.csv, survey_selection.csv (the layout
# 03_survey_map.R reads), excluded_surveys.csv, figure_labels.csv, provenance.csv.
source("R_cbh/load_pipeline.R"); source("R_cbh/primary/settings.R"); source("R_cbh/snow/R/settings.R")
library(ggplot2)
settings <- cbh_primary_settings(); stopifnot(identical(settings$unit, "snow"))
S <- snow_settings(settings$snow_variant)
root <- settings$out; out <- file.path(root, "study_flow"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
md <- settings$mics_output_dir
input_paths <- c(survey_manifest = "data/derived_cbh/survey_manifest.csv", child_checks = "data/derived_cbh/child_checks.csv",
  eligibility = "data/derived_cbh/eligibility_flow.csv", mics_manifest = file.path(md, "survey_manifest.csv"),
  mics_child_checks = file.path(md, "child_checks.csv"), mics_eligibility = file.path(md, "eligibility_flow.csv"),
  registry = cbh_config()$registry,
  mics_registry = "data/derived_mics/survey_registry_mics.csv", mics_inventory = "results/mics_inventory/survey_inventory.csv",
  placement = file.path(S$out, "placement", "placement_summary.csv"), units = file.path(S$out, "units", "units_by_survey.csv"),
  regions = file.path(S$out, "feasibility", "region_classification.csv"),
  selection = file.path(root, "prepared_selection_by_survey.csv"), losses = file.path(root, "complete_case_losses.csv"),
  substitutions = file.path(root, "national_substitutions.csv"),
  sample = file.path(root, "primary_sample.csv"), survey_coverage = file.path(root, "survey_coverage.csv"),
  diagnostics = file.path(root, "fit_diagnostics.csv"), fits = file.path(root, "fit_manifest.csv"))
stopifnot(all(file.exists(input_paths)))
rd <- function(k) cbh_read_csv(input_paths[[k]])
m <- rd("survey_manifest"); c <- rd("child_checks"); e <- rd("eligibility")
m <- rbind(m, rd("mics_manifest")[names(m)]); c <- rbind(c, rd("mics_child_checks")[names(c)]); e <- rbind(e, rd("mics_eligibility")[names(e)])
mics_inv <- rd("mics_inventory")
pl <- rd("placement"); un <- rd("units"); rc <- rd("regions"); s <- rd("selection"); lost <- rd("losses")
d <- rd("diagnostics"); d <- d[d$series == "map_full", ]; f <- rd("fits"); f <- f[f$series == "map_full", ]
sample <- rd("sample"); coverage <- rd("survey_coverage")
ages <- cbh_config()$age_bands$age_band
cbh_unique(m, "survey", "Survey manifest"); cbh_unique(e, c("survey", "age_band"), "Eligibility ledger")
stopifnot(nrow(d) == 7, nrow(f) == 7, setequal(d$age_band, ages), all(d$gamma == 2), all(d$converged), all(d$input_verified),
  !any(m$status == "failed"), all(f$prepared_data_md5 == cbh_file_hash(settings$data)), nrow(sample) == 1L,
  sample$records == sum(d$rows), sample$deaths == sum(d$deaths))
built <- m[m$status %in% c("built", "cached"), ]; omitted <- m[!m$status %in% c("built", "cached"), ]
stopifnot(all(omitted$status == "missing_map_geography"), setequal(unique(e$survey), built$survey),
  all(e$entered_in_lookback == e$incomplete_potential_band + e$full_band_before_interview),
  all(e$full_band_before_interview == e$entry_year_outside_range + e$eligible_band_rows),
  sum(c$children[c$status == "valid"]) == sum(e$valid_children_reaching_band[e$age_band == "<1"]))

# Per-survey ledger: eligible rows -> region matched (placement input) -> placed (units) -> complete cases.
sel <- data.frame(survey = built$survey, country = built$country, eligible_rows = built$rows)
sel$matched_rows <- pl$records[match(sel$survey, pl$survey)]; sel$matched_rows[is.na(sel$matched_rows)] <- 0
sel$placed_rows <- un$records[match(sel$survey, un$survey)]; sel$placed_rows[is.na(sel$placed_rows)] <- 0
sel$complete_case_rows <- s$records[match(sel$survey, s$survey)]; sel$complete_case_rows[is.na(sel$complete_case_rows)] <- 0
sel$complete_case_deaths <- s$deaths[match(sel$survey, s$survey)]; sel$complete_case_deaths[is.na(sel$complete_case_deaths)] <- 0
sel$pfpr_available_rows <- sel$placed_rows   # read by 03_survey_map.R: records with an exposure value
sel$excluded_incomplete <- sel$placed_rows - sel$complete_case_rows
stopifnot(all(sel$matched_rows <= sel$eligible_rows), all(sel$placed_rows <= sel$matched_rows), all(sel$excluded_incomplete >= 0),
  sum(sel$complete_case_rows) == sum(d$rows), sum(sel$complete_case_deaths) == sum(d$deaths),
  setequal(coverage$survey, sel$survey[sel$complete_case_rows > 0]))
cbh_atomic_csv(sel, file.path(out, "survey_selection.csv"))
# Declared national substitutions (one row per country and covariate), checked against the per-survey ledger.
ns <- rd("substitutions")
stopifnot(all(ns$variable %in% c("log_gdp_pc", "log_health_expenditure_pc", "political_stability")))
nsc <- unique(ns[c("country", "source_country", "before_year", "years", "records_in_sample", "deaths_in_sample", "note")])
cbh_unique(nsc, "country", "National substitutions")
stopifnot(all(nsc$records_in_sample <= vapply(nsc$country, function(k) sum(sel$complete_case_rows[sel$country == k]), 0)))
cbh_atomic_csv(omitted[c("survey", "country", "survey_year", "status")], file.path(out, "excluded_surveys.csv"))
# Records not placed, by reason (region classes over the eligible region-matched rows).
no_polygon <- sum(rc$records[rc$class == "no polygon"]); malaria_free <- sum(rc$records[rc$class == "inside a malaria-free/island unit"])
stopifnot(abs(sum(sel$matched_rows) - sum(rc$records)) < 1e-6)
fmt <- function(x) format(round(x), big.mark = ",", scientific = FALSE, trim = TRUE)
n <- list(dhs_registry = sum(!startsWith(m$survey, "MC_")), mics_registry = nrow(mics_inv), mics_no_cbh = sum(!mics_inv$has_bh),
  omitted = nrow(omitted), built = nrow(built), built_countries = length(unique(built$country)),
  entered = sum(e$entered_in_lookback), incomplete = sum(e$incomplete_potential_band), outside_year = sum(e$entry_year_outside_range),
  eligible = sum(e$eligible_band_rows), unmatched = sum(sel$eligible_rows - sel$matched_rows), matched = sum(sel$matched_rows),
  no_polygon = no_polygon, malaria_free_unit = malaria_free, placed = sum(sel$placed_rows),
  missing_covariates = sum(sel$excluded_incomplete), primary = sum(sel$complete_case_rows), deaths = sum(sel$complete_case_deaths),
  surveys = sum(sel$complete_case_rows > 0), countries = length(unique(sel$country[sel$complete_case_rows > 0])),
  units = sum(un$units), primary_distinct_children = sample$distinct_children)   # survey x unit areas of the placed records
n$mostly_malaria_free <- n$matched - n$placed - n$no_polygon - n$malaria_free_unit
n$not_placed <- n$unmatched + n$no_polygon + n$malaria_free_unit + n$mostly_malaria_free
n$excluded_eligibility <- n$incomplete + n$outside_year
n$registry_all <- n$dhs_registry + n$mics_registry
n$registry_countries_all <- length(unique(c(m$country, substr(mics_inv$survey, 1, 3))))
n$omitted_total <- n$omitted + n$mics_no_cbh
n$recorded_births <- sum(c$children); n$valid_births <- sum(c$children[c$status == "valid"])
n$national_substituted <- sum(nsc$records_in_sample)   # sample records whose GDP, health expenditure and political stability are another country's
stopifnot(n$entered - n$excluded_eligibility == n$eligible, n$eligible - n$not_placed == n$placed, n$placed - n$missing_covariates == n$primary,
  n$mostly_malaria_free >= 0, abs(sum(lost$records) - n$missing_covariates) < 1e-6)
# Survey steps of the diagram: surveys with a complete birth history, then the included surveys (at least one primary
# record). A processed survey with no placed record has no Snow polygon; one with placed records but no primary record
# lacks a required covariate in every survey x unit area.
types <- rbind(rd("registry")[c("svkey", "SurveyType")], rd("mics_registry")[c("svkey", "SurveyType")])
cbh_unique(types, "svkey", "DHS and MICS registries")
kind <- function(s) types$SurveyType[match(s, types$svkey)]
cbh <- rbind(built[c("survey", "country")], omitted[c("survey", "country")])
no_polygon_surveys <- sel$survey[sel$placed_rows == 0]
no_covariate_surveys <- sel$survey[sel$placed_rows > 0 & sel$complete_case_rows == 0]
inc <- sel[sel$complete_case_rows > 0, ]
stopifnot(!anyNA(kind(c(cbh$survey, m$survey))), all(kind(cbh$survey) %in% c("DHS", "MIS", "MICS")),
  nrow(cbh) == n$dhs_registry + sum(mics_inv$has_bh), all(rc$class[rc$survey %in% no_polygon_surveys] == "no polygon"),
  nrow(cbh) - n$omitted - length(no_polygon_surveys) - length(no_covariate_surveys) == nrow(inc), nrow(inc) == n$surveys)
n$cbh_surveys <- nrow(cbh); n$cbh_countries <- length(unique(cbh$country))
n$excluded_surveys <- n$omitted + length(no_polygon_surveys) + length(no_covariate_surveys)
n$excluded_no_polygon <- length(no_polygon_surveys); n$excluded_no_covariate <- length(no_covariate_surveys)
# Record steps within the included surveys only (the excluded surveys' records are in the full ledger above).
ei <- e[e$survey %in% inc$survey, ]; rci <- rc[rc$survey %in% inc$survey, ]; losti <- lost[lost$survey %in% inc$survey, ]
n$included_entered <- sum(ei$entered_in_lookback)
n$included_incomplete <- sum(ei$incomplete_potential_band); n$included_outside_year <- sum(ei$entry_year_outside_range)
n$included_excluded_eligibility <- n$included_incomplete + n$included_outside_year
n$included_unmatched <- sum(inc$eligible_rows - inc$matched_rows)
n$included_no_polygon <- sum(rci$records[rci$class == "no polygon"])
n$included_malaria_free <- sum(inc$matched_rows - inc$placed_rows) - n$included_no_polygon   # malaria-free/island or mostly malaria-free units
n$included_not_placed <- n$included_unmatched + n$included_no_polygon + n$included_malaria_free
n$included_missing_covariates <- sum(inc$placed_rows - inc$complete_case_rows)
n$included_excluded <- n$included_excluded_eligibility + n$included_not_placed + n$included_missing_covariates
n$primary_units <- unique(d$regions)
stopifnot(n$included_entered - n$included_excluded_eligibility == sum(inc$eligible_rows), n$included_malaria_free >= 0,
  abs(sum(rci$records) - sum(inc$matched_rows)) < 1e-6, abs(sum(losti$records) - n$included_missing_covariates) < 1e-6,
  n$included_entered - n$included_excluded == n$primary, length(n$primary_units) == 1L,
  # The included surveys' only records without a Snow polygon are Zanzibar's (Tanzania), as the caption says.
  all(rci$country[rci$class == "no polygon"] == "TZA"))
# Mothers (complete birth histories) with at least one record in the primary sample, counted as in 03_survey_map.R:
# children in the prepared sample matched to their shard's mother id.
analysed <- unique(as.character(readRDS(settings$data)$data$child_id))
shard_dirs <- c(cbh_config()$output_dir, md)
parents <- do.call(rbind, lapply(shard_dirs, function(dir) {
  sm <- readRDS(file.path(dir, "manifest.rds"))$manifest; sm <- sm[sm$survey %in% inc$survey, ]
  do.call(rbind, lapply(seq_len(nrow(sm)), function(i) {
    o <- readRDS(file.path(dir, sm$file[i])); stopifnot(identical(o$signature, sm$signature[i]))
    k <- as.character(o$data$child_id) %in% analysed
    data.frame(survey = sm$survey[i], children = length(unique(o$data$child_id[k])), mothers = length(unique(o$data$mother_id[k])))
  }))
}))
cbh_unique(parents, "survey", "Mothers by survey")
stopifnot(setequal(parents$survey, inc$survey), sum(parents$children) == n$primary_distinct_children, all(parents$mothers > 0))
n$primary_mothers <- sum(parents$mothers)
cbh_atomic_csv(data.frame(item = names(n), count = unlist(n), row.names = NULL), file.path(out, "flow_counts.csv"))
# First missing covariate of the records excluded within the included surveys (caption).
attr <- aggregate(records ~ missing, data = losti, FUN = sum); attr <- attr[order(-attr$records), ]
short <- c(wasting_pct = "Wasting", stunting_pct = "Stunting", facility_delivery_pct = "Facility delivery", electricity_pct = "Electricity",
  political_stability = "Political stability", log_hiv_incidence = "HIV incidence", log_health_expenditure_pc = "Health expenditure",
  mean_wealth_quintile = "Wealth score", log_gdp_pc = "GDP", pfpr_pct = "PfPR", improved_water_pct = "Water", improved_sanitation_pct = "Sanitation",
  dtp3_pct = "DTP3", measles_pct = "Measles", urban_pct = "Urban", mean_maternal_education_years = "Education",
  mean_maternal_age_first_birth = "Age at first birth", short_birth_interval_pct = "Birth interval")
first_missing <- paste(sprintf("%s %s", ifelse(attr$missing %in% names(short), tolower(short[attr$missing]), attr$missing), fmt(attr$records)), collapse = "; ")
country_names <- function(iso) sub(" & ", " and ", paste(sort(unique(countrycode::countrycode(iso, "iso3c", "country.name", warn = FALSE))), collapse = " and "), fixed = TRUE)
omitted_names <- country_names(omitted$country); no_polygon_names <- country_names(sel$country[sel$survey %in% no_polygon_surveys])
# Survey counts by type, e.g. "119 DHS, 5 MIS, 93 MICS".
by_type <- function(s) { k <- table(factor(kind(s), levels = c("DHS", "MIS", "MICS"))); k <- k[k > 0]; paste(fmt(k), names(k), collapse = ", ") }
all_types <- sprintf("%s, %s MICS", by_type(m$survey[!startsWith(m$survey, "MC_")]), fmt(n$mics_registry))
nodes <- data.frame(
  id = c("registry", "cbh", "included", "sample", "omit_cbh", "omit_surveys", "omit_records"),
  x = c(rep(3.7, 4), rep(9.75, 3)), y = c(13.6, 11.1, 8.3, 5.2, 12.35, 9.75, 6.8),
  w = c(rep(6.7, 4), rep(4.9, 3)), h = c(1.35, 1.35, 1.6, 1.95, 1.0, 2.15, 2.15), role = c(rep("main", 4), rep("excluded", 3)),
  heading = c("Surveys in sub-Saharan Africa since 2000", "Recorded complete birth histories", "Surveys included", "Primary analysis sample",
    paste(fmt(n$mics_no_cbh), "MICS surveys excluded"), paste(fmt(n$excluded_surveys), "surveys excluded"),
    paste(fmt(n$included_excluded), "records excluded")),
  detail = c(sprintf("%s surveys (%s)\n%s countries", fmt(n$registry_all), all_types, fmt(n$registry_countries_all)),
    sprintf("%s surveys (%s)\n%s countries", fmt(n$cbh_surveys), by_type(cbh$survey), fmt(n$cbh_countries)),
    sprintf("%s surveys (%s) · %s countries\n%s child age-band records entered\nin the 5 years before interview",
      fmt(n$surveys), by_type(inc$survey), fmt(n$countries), fmt(n$included_entered)),
    sprintf("%s child age-band records\n%s children · %s deaths\n%s complete birth histories\n%s survey-by-area units",
      fmt(n$primary), fmt(n$primary_distinct_children), fmt(n$deaths), fmt(n$primary_mothers), fmt(n$primary_units)),
    "No complete birth history",
    sprintf("%s %s: malaria free\n%s %s:\noutside the Snow et al. polygons\n%s (%s): a confounder\nunavailable in every area",
      fmt(n$omitted), omitted_names, fmt(n$excluded_no_polygon), no_polygon_names, fmt(n$excluded_no_covariate), by_type(no_covariate_surveys)),
    sprintf("%s: band not completed by interview\nor begun outside 2000–2024\n%s: area not placed in a polygon\nor mainly malaria free\n%s: a confounder unavailable",
      fmt(n$included_excluded_eligibility), fmt(n$included_not_placed), fmt(n$included_missing_covariates))))
cbh_atomic_csv(nodes, file.path(out, "figure_labels.csv"))
fill <- c(main = "#EAF2F8", excluded = "#F6F3EF"); border <- c(main = "#346A8C", excluded = "#A29588")
p <- ggplot() + theme_void() + coord_cartesian(xlim = c(0, 12.4), ylim = c(4.05, 14.4), expand = FALSE, clip = "off") + theme(plot.margin = margin(8, 12, 8, 12))
segment <- function(x, y, xe, ye, arrow = FALSE) {
  if (arrow) annotate("segment", x = x, y = y, xend = xe, yend = ye, colour = "#687780", linewidth = .7, arrow = grid::arrow(length = grid::unit(2.5, "mm"), type = "closed"))
  else annotate("segment", x = x, y = y, xend = xe, yend = ye, colour = "#687780", linewidth = .7)
}
main <- which(nodes$role == "main"); side <- which(nodes$role == "excluded")
for (i in main[-length(main)]) p <- p + segment(3.7, nodes$y[i] - nodes$h[i] / 2, 3.7, nodes$y[i + 1] + nodes$h[i + 1] / 2, TRUE)
for (i in side) p <- p + segment(3.7, nodes$y[i], nodes$x[i] - nodes$w[i] / 2, nodes$y[i], TRUE)
for (i in seq_len(nrow(nodes))) {
  z <- nodes[i, ]; small <- z$role == "excluded"
  p <- p + annotate("rect", xmin = z$x - z$w / 2, xmax = z$x + z$w / 2, ymin = z$y - z$h / 2, ymax = z$y + z$h / 2, fill = fill[z$role], colour = border[z$role], linewidth = .75)
  n_lines <- length(strsplit(z$detail, "\n")[[1]]); line_h <- if (small) .21 else .25
  title_y <- z$y + z$h / 2 - .36; detail_y <- title_y - .30 - line_h * n_lines / 2
  p <- p + annotate("text", x = z$x, y = title_y, label = z$heading, fontface = "bold", family = "sans", size = if (small) 5.2 else 5.9, lineheight = 1.1, colour = "#183746")
  p <- p + annotate("text", x = z$x, y = detail_y, label = z$detail, family = "sans", size = if (small) 4.3 else 5.4, lineheight = 1.1, colour = "#243D49")
}
ggsave(file.path(out, "study_flow_diagram.png"), p, width = 11.5, height = 9.2, dpi = 300, device = ragg::agg_png, bg = "white")
cname <- function(x) countrycode::countrycode(x, "iso3c", "country.name", warn = FALSE)
var_label <- c(log_gdp_pc = "GDP per capita", log_health_expenditure_pc = "health expenditure per capita", political_stability = "political stability")
and_list <- function(x) if (length(x) < 2) x else paste(paste(x[-length(x)], collapse = ", "), "and", x[length(x)])
subst_text <- paste0(vapply(seq_len(nrow(nsc)), function(i) sprintf(" For %s (%s), %s for band-entry years before %d are %s's values for the same year (%s: %s records, %s deaths); its child HIV incidence is its own series.",
  cname(nsc$country[i]), nsc$note[i], and_list(unname(var_label[ns$variable[ns$country == nsc$country[i]]])), nsc$before_year[i], cname(nsc$source_country[i]),
  sub("-", "–", nsc$years[i], fixed = TRUE), fmt(nsc$records_in_sample[i]), fmt(nsc$deaths_in_sample[i])), ""), collapse = "")
caption <- c("# Figure caption — primary sample inclusion (Snow et al. polygons)", "",
  sprintf("**Figure. Sample inclusion for the primary analysis.** Of %s DHS, MIS and MICS surveys conducted in sub-Saharan Africa since 2000 (%s; %s countries), %s recorded complete birth histories (%s; %s countries); the other %s MICS surveys recorded only summary birth histories. %s surveys were excluded: %s from %s, which is malaria free and has no Malaria Atlas Project prevalence surface; %s from %s, which lie outside the Snow et al. (2017) polygons; and %s (%s) in which at least one required covariate was unavailable in every survey × unit area. %s surveys (%s) from %s countries were included.",
    fmt(n$registry_all), all_types, fmt(n$registry_countries_all), fmt(n$cbh_surveys), by_type(cbh$survey), fmt(n$cbh_countries), fmt(n$mics_no_cbh),
    fmt(n$excluded_surveys), fmt(n$omitted), omitted_names, fmt(n$excluded_no_polygon), no_polygon_names, fmt(n$excluded_no_covariate),
    by_type(no_covariate_surveys), fmt(n$surveys), by_type(inc$survey), fmt(n$countries)), "",
  sprintf("In the included surveys, %s child age-band records were entered within the 60 months before interview; counts from here are records, not unique children. %s were excluded because the band could not be completed by the interview (%s) or began outside 2000–2024 (%s); %s because the record's area could not be placed in a Snow et al. polygon (%s in survey-regions not matched to a boundary; %s in Zanzibar, which has no polygon) or lay in malaria-free or island units or in units more than half malaria free (%s); and %s because at least one required covariate was unavailable (first missing: %s). Each record is placed in the polygons through its smallest reported administrative unit: the polygon holding at least 90%% of that unit's population, or else the union of the polygons each holding at least 5%%. The primary sample has %s records and %s deaths from %s children of %s mothers (complete birth histories), in %s survey × unit areas.",
    fmt(n$included_entered), fmt(n$included_excluded_eligibility), fmt(n$included_incomplete), fmt(n$included_outside_year), fmt(n$included_not_placed),
    fmt(n$included_unmatched), fmt(n$included_no_polygon), fmt(n$included_malaria_free), fmt(n$included_missing_covariates), first_missing,
    fmt(n$primary), fmt(n$deaths), fmt(n$primary_distinct_children), fmt(n$primary_mothers), fmt(n$primary_units)), "",
  sprintf("Record counts over all %s processed surveys, including the excluded ones, are in the full ledger: %s band entries, %s eligible records, %s placed in %s survey × unit areas.",
    fmt(n$built), fmt(n$entered), fmt(n$eligible), fmt(n$placed), fmt(n$units)), "",
  paste0("Seven completed-month bands are analysed separately: <1, 1–5, 6–11, 12–23, 24–35, 36–47 and 48–59. The outcome is death during the band. Annual MAP PfPR₂–₁₀ of the record's unit (population-weighted over its polygons) and the national covariates are assigned at band-entry year. The 17 adjustment variables comprise survey × unit summaries of maternal age at first birth, education, wealth, urban residence, DTP3/measles coverage, facility delivery, short birth interval, improved water, improved sanitation, electricity, wasting and stunting, computed from the DHS and MICS recodes, plus national annual log child HIV incidence, log GDP per capita, log health expenditure per capita and political stability.", subst_text),
  "Counts are read from the saved build, eligibility, placement, unit and selection ledgers and reconciled with the seven age-band fits. See [counts](flow_counts.csv) and [survey selection](survey_selection.csv).")
writeLines(caption, file.path(out, "CAPTION.md"))
provenance <- c(unname(input_paths), settings$data, file.path(shard_dirs, "manifest.rds"),
  "R_cbh/reporting/01_study_flow_snow.R", "R_cbh/primary/settings.R", "R_cbh/snow/R/settings.R")
cbh_atomic_csv(data.frame(file = provenance, md5 = vapply(provenance, cbh_file_hash, "")), file.path(out, "provenance.csv"))
message("Saved Snow-unit study flow and caption: ", out)
