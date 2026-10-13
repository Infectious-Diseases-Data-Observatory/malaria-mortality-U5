#!/usr/bin/env Rscript
# Study flow (Figure S1) for the Snow-unit primary: the v9 ledger of R_cbh/reporting/01_study_flow.R with the
# survey-region MAP step replaced by placement in the Snow et al. (2017) polygons (R_cbh/snow/). Aggregate inputs only.
# Stages: survey registry -> band entries within 5 years of interview -> eligible child-age bands -> placed in a Snow
# polygon -> primary analysis sample. Exclusions: surveys not processed (no MAP geography) or without a complete birth
# history; band eligibility; not placed (survey-region not matched; no Snow polygon; malaria-free or island unit; unit
# more than half malaria-free); required covariate unavailable (first missing input). The declared national
# substitutions of the preparation (national_substitutions.csv: South Sudan before independence takes Sudan's values)
# are stated in the caption and counted (national_substituted).
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
cbh_atomic_csv(data.frame(item = names(n), count = unlist(n), row.names = NULL), file.path(out, "flow_counts.csv"))
attr <- aggregate(records ~ missing, data = lost, FUN = sum); attr <- attr[order(-attr$records), ]
short <- c(wasting_pct = "Wasting", stunting_pct = "Stunting", facility_delivery_pct = "Facility delivery", electricity_pct = "Electricity",
  political_stability = "Political stability", log_hiv_incidence = "HIV incidence", log_health_expenditure_pc = "Health expenditure",
  mean_wealth_quintile = "Wealth score", log_gdp_pc = "GDP", pfpr_pct = "PfPR", improved_water_pct = "Water", improved_sanitation_pct = "Sanitation",
  dtp3_pct = "DTP3", measles_pct = "Measles", urban_pct = "Urban", mean_maternal_education_years = "Education",
  mean_maternal_age_first_birth = "Age at first birth", short_birth_interval_pct = "Birth interval")
items <- sprintf("%s %s", ifelse(attr$missing %in% names(short), short[attr$missing], attr$missing), fmt(attr$records))
if (length(items) > 6) items <- c(items[1:5], paste("other", fmt(sum(attr$records[-(1:5)]))))
reason_text <- paste(vapply(split(items, ceiling(seq_along(items) / 2)), paste, "", collapse = " · "), collapse = "\n")
omitted_names <- paste(sort(unique(countrycode::countrycode(omitted$country, "iso3c", "country.name", warn = FALSE))), collapse = ", ")
nodes <- data.frame(
  id = c("registry", "entered", "eligible", "placed", "sample", "omit_surveys", "omit_eligibility", "omit_placement", "omit_covariates"),
  x = c(rep(3.7, 5), rep(9.75, 4)), y = c(13.75, 11.55, 9.4, 7.25, 5.0, 12.69, 10.44, 8.33, 6.2),
  w = c(rep(6.7, 5), rep(4.7, 4)), h = c(1.35, 1.5, 1.35, 1.35, 1.65, 1.35, 1.75, 1.75, 2.0), role = c(rep("main", 5), rep("excluded", 4)),
  heading = c("Survey registry", "Band entries within 5 years of interview", "Eligible child–age bands", "Placed in Snow et al. polygons",
    "Primary analysis sample", paste(fmt(n$omitted_total), "surveys excluded"), paste(fmt(n$excluded_eligibility), "records excluded"),
    paste(fmt(n$not_placed), "records excluded"), paste(fmt(n$missing_covariates), "records excluded")),
  detail = c(sprintf("%s DHS/MIS + %s MICS surveys\n%s countries", fmt(n$dhs_registry), fmt(n$mics_registry), fmt(n$registry_countries_all)),
    sprintf("%s child–age bands\n%s surveys · %s countries", fmt(n$entered), fmt(n$built), fmt(n$built_countries)),
    paste(fmt(n$eligible), "records"), sprintf("%s records · %s survey × unit areas", fmt(n$placed), fmt(n$units)),
    sprintf("%s records · %s deaths\n%s surveys · %s countries", fmt(n$primary), fmt(n$deaths), fmt(n$surveys), fmt(n$countries)),
    sprintf("%s MICS: no complete birth history\n%s in %s (malaria free, no MAP)", fmt(n$mics_no_cbh), fmt(n$omitted), omitted_names),
    sprintf("%s: band not complete by interview\n%s: entry year outside 2000–2024", fmt(n$incomplete), fmt(n$outside_year)),
    sprintf("%s: no Snow polygon (Comoros,\nZanzibar, São Tomé and Príncipe) · %s: survey-region\nnot matched · %s: malaria-free/island unit\nor unit more than half malaria free",
      fmt(n$no_polygon), fmt(n$unmatched), fmt(n$malaria_free_unit + n$mostly_malaria_free)),
    paste0("Required covariate unavailable:\n", reason_text)))
cbh_atomic_csv(nodes, file.path(out, "figure_labels.csv"))
fill <- c(main = "#EAF2F8", excluded = "#F6F3EF"); border <- c(main = "#346A8C", excluded = "#A29588")
p <- ggplot() + theme_void() + coord_cartesian(xlim = c(0, 12.3), ylim = c(4.0, 14.55), expand = FALSE, clip = "off") + theme(plot.margin = margin(8, 12, 8, 12))
segment <- function(x, y, xe, ye, arrow = FALSE) {
  if (arrow) annotate("segment", x = x, y = y, xend = xe, yend = ye, colour = "#687780", linewidth = .7, arrow = grid::arrow(length = grid::unit(2.5, "mm"), type = "closed"))
  else annotate("segment", x = x, y = y, xend = xe, yend = ye, colour = "#687780", linewidth = .7)
}
for (i in 1:4) p <- p + segment(3.7, nodes$y[i] - nodes$h[i] / 2, 3.7, nodes$y[i + 1] + nodes$h[i + 1] / 2, TRUE)
for (i in 6:9) p <- p + segment(3.7, nodes$y[i], nodes$x[i] - nodes$w[i] / 2, nodes$y[i], TRUE)
for (i in seq_len(nrow(nodes))) {
  z <- nodes[i, ]; small <- z$role == "excluded"
  p <- p + annotate("rect", xmin = z$x - z$w / 2, xmax = z$x + z$w / 2, ymin = z$y - z$h / 2, ymax = z$y + z$h / 2, fill = fill[z$role], colour = border[z$role], linewidth = .75)
  n_lines <- length(strsplit(z$detail, "\n")[[1]]); line_h <- if (small) .21 else .25
  title_y <- z$y + z$h / 2 - .36; detail_y <- title_y - .30 - line_h * n_lines / 2
  p <- p + annotate("text", x = z$x, y = title_y, label = z$heading, fontface = "bold", family = "sans", size = if (small) 5.2 else 5.9, lineheight = 1.1, colour = "#183746")
  p <- p + annotate("text", x = z$x, y = detail_y, label = z$detail, family = "sans", size = if (small) 4.0 else 5.4, lineheight = 1.1, colour = "#243D49")
}
ggsave(file.path(out, "study_flow_diagram.png"), p, width = 11.5, height = 9.6, dpi = 300, device = ragg::agg_png, bg = "white")
zero <- sel$survey[sel$complete_case_rows == 0]
cname <- function(x) countrycode::countrycode(x, "iso3c", "country.name", warn = FALSE)
var_label <- c(log_gdp_pc = "GDP per capita", log_health_expenditure_pc = "health expenditure per capita", political_stability = "political stability")
and_list <- function(x) if (length(x) < 2) x else paste(paste(x[-length(x)], collapse = ", "), "and", x[length(x)])
subst_text <- paste0(vapply(seq_len(nrow(nsc)), function(i) sprintf(" For %s (%s), %s for band-entry years before %d are %s's values for the same year (%s: %s records, %s deaths); its child HIV incidence is its own series.",
  cname(nsc$country[i]), nsc$note[i], and_list(unname(var_label[ns$variable[ns$country == nsc$country[i]]])), nsc$before_year[i], cname(nsc$source_country[i]),
  sub("-", "–", nsc$years[i], fixed = TRUE), fmt(nsc$records_in_sample[i]), fmt(nsc$deaths_in_sample[i])), ""), collapse = "")
caption <- c("# Figure caption — primary sample inclusion (Snow et al. polygons)", "",
  sprintf("**Figure. Sample inclusion for the primary analysis.** The survey registry contains %s DHS and MIS surveys and %s MICS surveys in %s countries. %s MICS surveys have no complete birth history and %s surveys are excluded because %s is malaria free and the Malaria Atlas Project publishes no prevalence surface for it, leaving %s processed surveys in %s countries. Counts below the registry refer to child–age-band records, not unique children.",
    fmt(n$dhs_registry), fmt(n$mics_registry), fmt(n$registry_countries_all), fmt(n$mics_no_cbh), fmt(n$omitted), omitted_names, fmt(n$built), fmt(n$built_countries)), "",
  sprintf("Among %s band entries within the 60 months before interview, %s have an incomplete potential band and %s have entry years outside 2000–2024, leaving %s eligible records. Each record is placed in the Snow et al. (2017) malaria-endemic polygons through its smallest reported administrative unit: the polygon holding at least 90%% of that unit's population, or else the union of the polygons each holding at least 5%%. %s records are not placed: %s in survey-regions with no Snow polygon (the Comoros, Zanzibar and São Tomé and Príncipe), %s whose survey-region could not be matched to a boundary, and %s in malaria-free or island units or in units more than half malaria free. %s records remain in %s survey × unit areas; %s of them lack at least one required covariate (first missing: %s), leaving %s records and %s deaths in %s surveys from %s countries.",
    fmt(n$entered), fmt(n$incomplete), fmt(n$outside_year), fmt(n$eligible), fmt(n$not_placed), fmt(n$no_polygon), fmt(n$unmatched),
    fmt(n$malaria_free_unit + n$mostly_malaria_free), fmt(n$placed), fmt(n$units), fmt(n$missing_covariates),
    paste(sprintf("%s %s", ifelse(attr$missing %in% names(short), tolower(short[attr$missing]), attr$missing), fmt(attr$records)), collapse = "; "),
    fmt(n$primary), fmt(n$deaths), fmt(n$surveys), fmt(n$countries)), "",
  sprintf("%s processed surveys contribute no records to the final sample. The final records represent %s distinct children.", fmt(length(zero)), fmt(n$primary_distinct_children)), "",
  paste0("Seven completed-month bands are analysed separately: <1, 1–5, 6–11, 12–23, 24–35, 36–47 and 48–59. The outcome is death during the band. Annual MAP PfPR₂–₁₀ of the record's unit (population-weighted over its polygons) and the national covariates are assigned at band-entry year. The 17 adjustment variables comprise survey × unit summaries of maternal age at first birth, education, wealth, urban residence, DTP3/measles coverage, facility delivery, short birth interval, improved water, improved sanitation, electricity, wasting and stunting, computed from the DHS and MICS recodes, plus national annual log child HIV incidence, log GDP per capita, log health expenditure per capita and political stability.", subst_text),
  "Counts are read from the saved build, eligibility, placement, unit and selection ledgers and reconciled with the seven age-band fits. See [counts](flow_counts.csv) and [survey selection](survey_selection.csv).")
writeLines(caption, file.path(out, "CAPTION.md"))
provenance <- c(unname(input_paths), settings$data, "R_cbh/reporting/01_study_flow_snow.R", "R_cbh/primary/settings.R", "R_cbh/snow/R/settings.R")
cbh_atomic_csv(data.frame(file = provenance, md5 = vapply(provenance, cbh_file_hash, "")), file.path(out, "provenance.csv"))
message("Saved Snow-unit study flow and caption: ", out)
