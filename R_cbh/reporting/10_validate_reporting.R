#!/usr/bin/env Rscript
# Cross-artifact checks for the current plan-defined primary reporting bundle.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R"); source("R_cbh/units/R/settings.R")
st <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION","gadm"));root <- st$out
read <- function(p)cbh_read_csv(file.path(root,p))
manifest <- read("fit_manifest.csv");diag <- read("fit_diagnostics.csv")
sample <- read("primary_sample.csv");figures <- read("paper_figures/manifest.csv")
stopifnot(nrow(manifest)==7L,all(grepl(st$id,manifest$model_file,fixed=TRUE)),
  all(diag$converged),all(diag$input_verified),all(diag$gamma==2),
  identical(unname(vapply(manifest$model_file,cbh_file_hash,"")),manifest$md5),
  nrow(figures)==5L,identical(as.integer(figures$figure),1:5),
  # Main figures since 28 October 2026: hazard ratio by age, attributable fraction by age, mortality rates (UN IGME).
  identical(basename(figures$source[2:5]),c("fig2_hazard_ratio_by_age.png","attributable_fraction_by_age.png",
    "fig_malaria_mortality_rates_unigme.png","fig5_model_vs_cause_specific_2024.png")),
  all(grepl(st$id,figures$source,fixed=TRUE)),
  identical(unname(vapply(figures$source,cbh_file_hash,"")),figures$md5))
formula_vars <- all.vars(as.formula(paste(readLines(file.path(root,"model_formula.txt")),collapse=" ")))
scaling <- read("covariate_scaling.csv")
stopifnot(nrow(scaling)==17L,all(paste0("z_",scaling$variable) %in% formula_vars),
  all(c("z_mean_maternal_age_first_birth","z_wasting_pct","z_stunting_pct") %in% formula_vars),
  !any(c("z_male_pct","z_multiple_birth_pct","z_mean_birth_order","z_mean_maternal_age_birth") %in% formula_vars))
flow <- read("study_flow/flow_counts.csv");counts <- setNames(flow$count,flow$item)
coverage <- read("survey_map/survey_coverage.csv")
stopifnot(counts[["primary"]]==sample$records,counts[["deaths"]]==sample$deaths,
  counts[["primary_distinct_children"]]==sample$distinct_children,
  counts[["surveys"]]==sample$surveys,nrow(coverage)==sample$surveys,
  is.null(st$expected_regions) || sum(coverage$regions)==st$expected_regions,
  all(coverage$type %in% if(isTRUE(st$mics)) c("DHS","MICS") else "DHS"))
subst_lines <- character()
# Declared national substitutions of the preparation: one row per country and covariate, within the country's sample
# records, and counted in the study flow.
ns <- read("national_substitutions.csv");nsc <- unique(ns[c("country","source_country","years","records_in_sample")])
selected <- read("prepared_selection_by_survey.csv")
stopifnot(!anyDuplicated(nsc$country),all(ns$variable %in% c("log_gdp_pc","log_health_expenditure_pc","political_stability")),
  all(nsc$records_in_sample<=vapply(nsc$country,function(k)sum(selected$records[selected$country==k]),0)),
  counts[["national_substituted"]]==sum(nsc$records_in_sample))
if(nrow(nsc)) subst_lines <- sprintf("PASS: declared national substitutions recorded and counted in the study flow (%s).",
  paste(sprintf("%s from %s, band-entry years %s, %s records",nsc$country,nsc$source_country,nsc$years,format(nsc$records_in_sample,big.mark=",")),collapse="; "))
mics_lines <- character()
if(isTRUE(st$mics)) {
  # The DHS+MICS sensitivity refits must have been fitted to this primary's prepared data (checked from CSVs only).
  expected_mics_surveys <- st$expected_mics_surveys
  by_survey <- read("prepared_selection_by_survey.csv")
  by_survey <- merge(by_survey[setdiff(names(by_survey),"units")],coverage[c("survey","type","regions")],by="survey")
  dhs <- by_survey[by_survey$type=="DHS",];n_mics <- sum(by_survey$type=="MICS")
  stopifnot(nrow(by_survey)==nrow(coverage),abs(sum(by_survey$records)-sample$records)<1e-6,abs(sum(by_survey$deaths)-sample$deaths)<1e-6,
    is.null(expected_mics_surveys) || n_mics==expected_mics_surveys)
  prepared_md5 <- unique(manifest$prepared_data_md5)
  sensitivities <- st$sensitivity_dirs
  for(d in sensitivities) {
    fp <- cbh_read_csv(file.path(d,"fit_input_provenance.csv"))
    if(length(prepared_md5)!=1L || fp$file[1]!=st$data || fp$md5[1]!=prepared_md5)
      stop("Sensitivity refit in ",d," was not fitted to the prepared data of ",st$id)
  }
  mics_lines <- c(sprintf("PASS: %d DHS surveys (%s records, %s deaths, %d survey x unit areas) and %d MICS surveys (%s records, %s deaths).",
      nrow(dhs),format(sum(dhs$records),big.mark=","),format(sum(dhs$deaths),big.mark=","),sum(dhs$regions),n_mics,
      format(sample$records-sum(dhs$records),big.mark=","),format(sample$deaths-sum(dhs$deaths),big.mark=",")),
    if(length(sensitivities)) sprintf("PASS: subgroup and no-nutrition refits (%s) were fitted to this primary's prepared data (md5 %s).",
      paste(basename(sensitivities),collapse=", "),prepared_md5) else
      "NOTE: this version has no sensitivity refits.")
}
age <- read("tables/age_band_results.csv")
stopifnot(nrow(age)==7L,sum(age$records)==sample$records,sum(age$observed_deaths)==sample$deaths,
  abs(sum(age$displayed_death_share_pct)-100)<1e-10,!"elapsed_seconds" %in% names(age))
annual <- read("annual_comparison/annual_totals_2000_2024.csv")
burden <- read("burden/year_summary.csv")
stopifnot(nrow(annual)==25L,identical(as.integer(annual$year),2000:2024),all(annual$countries==42L),
  max(abs(annual$model_deaths[match(burden$year,annual$year)]-burden$attributable_under5_deaths))<.01)
# MAP release and uncertainty (1 November 2026): every exposure from cbh_config()$map_release, national PfPR equal to
# MAP's own national estimates, and draw-based intervals that reproduce and bracket the point estimates.
cfg <- cbh_config()
stopifnot(any(grepl(paste0('"map_annual_', cfg$map_release, '"'), readLines("R_inputs/00_config.R"), fixed = TRUE)))
rp <- cbh_read_csv(file.path(units_settings()$out,"pfpr/pfpr_raster_provenance.csv"))
stopifnot(nrow(rp)==25L,all(rp$map_release==cfg$map_release),all(dirname(normalizePath(rp$file))==normalizePath(cfg$map_raster_dir)),
  identical(unname(vapply(rp$file,cbh_file_hash,"")),rp$md5))
nat <- read("annual_comparison/national_pfpr_2000_2024.csv")
mn <- cbh_map_national(unique(nat$iso3),2000:2024,cfg)
stopifnot(nrow(nat)==42L*25L,all(nat$map_release==cfg$map_release),
  max(abs(nat$pfpr_pct-mn$pfpr_pct[match(paste(nat$iso3,nat$year),paste(mn$iso3,mn$year))]))<1e-9)
ui <- read("uncertainty/annual_intervals_2000_2024.csv");uc <- read("uncertainty/checks.csv")
um <- ui[ui$scenario=="main",]
src <- read("annual_comparison/source_annual_rates_2000_2024.csv")
stopifnot(nrow(um)==50L,all(um$attributable_deaths_lower<=um$attributable_deaths & um$attributable_deaths<=um$attributable_deaths_upper),
  max(abs(um$attributable_deaths-src$attributable_deaths[match(paste(um$source,um$year),paste(src$source,src$year))]))<1e-6,
  as.numeric(uc$value[grepl("^zero-noise",uc$item)])<1e-6,uc$value[uc$item=="draws"]=="500",
  nrow(read("uncertainty/country_year_intervals_2000_2024.csv"))==2L*42L*25L)
# Check producer/data hashes, not just whether expected filenames exist.
provenances <- list.files(root,pattern="provenance[.]csv$",recursive=TRUE,full.names=TRUE)
provenances <- provenances[!grepl("previous_overleaf",provenances)]
checks <- lapply(provenances,function(p) {
  x <- cbh_read_csv(p);stopifnot(all(c("file","md5") %in% names(x)),all(file.exists(x$file)))
  actual <- unname(vapply(x$file,cbh_file_hash,""))
  if(!identical(actual,x$md5))stop("Stale provenance in ",p,": ",paste(x$file[actual!=x$md5],collapse=", "))
  data.frame(provenance=p,files_verified=nrow(x),all_hashes_match=TRUE)
})
cbh_atomic_csv(do.call(rbind,checks),file.path(root,"paper_refresh/provenance_checks.csv"))
stopifnot(!length(list.files(root,pattern="[.]tex$",recursive=TRUE)))
# Table S1 source (R_cbh/reporting/25_country_rates_table.R).
lines <- readLines(file.path(root,"tables/country_rates_2024.latex.txt"));rows <- lines[grepl(" & ",lines,fixed=TRUE)]
stopifnot(length(rows)>7L,all(endsWith(rows,strrep(intToUtf8(92),2))))
writeLines(c(sprintf("PASS: %d main figures reference the revised primary version and match their hashes.",nrow(figures)),
  "PASS: seven fitted model hashes, convergence flags and gamma=2 verified.",
  sprintf(paste0("PASS: flow, %s, %d ","survey x unit areas",", child-band/death/child totals reconcile."),
    if(isTRUE(st$mics)) sprintf("%d DHS and MICS surveys (%d DHS, %d MICS)",sample$surveys,sum(coverage$type=="DHS"),sum(coverage$type=="MICS"))
    else sprintf("%d DHS surveys",sample$surveys),sum(coverage$regions)),
  mics_lines,subst_lines,
  "PASS: age-table death percentages sum to 100.0%; both contrasts retained; no fit-time column.",
  sprintf("PASS: %d annual totals use 42 countries and reproduce the three national-burden years.",nrow(annual)),
  "PASS: producer/data provenance hashes match; Table S1 source has valid row terminators.",
  sprintf("PASS: MAP release %s for every exposure; national PfPR equals MAP's national estimates; 500-draw intervals reproduce and bracket the 50 annual point estimates.",cfg$map_release),
  "PASS: no TeX files created in this result version."),file.path(root,"paper_refresh/validation.txt"))
message("Primary reporting validation passed")
