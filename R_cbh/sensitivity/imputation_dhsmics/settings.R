# Imputed-covariate sensitivity of the GADM-unit primary (v16 on primary v15; the Snow-unit v12 and v15 on primary
# v11-v14 were replaced with it, author decision 3 November 2026; code in git history up to f2db98e). Liberia's child
# HIV incidence comes from UNAIDS counts (R_cbh/hiv/03_add_liberia_aidsinfo.R). The 17 covariates, formula, reference
# knots and gamma are the primary's; every placed record is retained after imputing all remaining covariate gaps.
# Units take the primary's covariate table (after the WUENIC and within-survey fallbacks) and PfPR of the unit at the
# survey year.
cbh_imputed_dhsmics_settings <- function() {
  source("R_cbh/primary/settings.R", local = TRUE)
  primary <- cbh_primary_settings("gadm")
  st <- primary[c("knots", "years", "gamma", "seed", "nthreads", "regional", "nutrition", "mics_output_dir")]
  st$id <- "primary_gadm_merge_imputed_gamma2_v16"
  st$out <- file.path("results/cbh", st$id); st$private <- file.path("data/derived_cbh/models", st$id)
  st$data <- file.path(st$private, "complete_case_dataset.rds")
  st$reference <- primary$out; st$reference_data <- primary$data
  st$imputed <- TRUE; st$mics <- TRUE
  st$imputation_private <- "data/derived_cbh/regional_adjustment/imputed_gadm_v16"
  st$imputation_results <- "results/cbh/covariate_imputation_gadm_v16"
  st$imputed_overlay <- file.path(st$imputation_private, "regional_covariates_wide.csv")
  st$imputed_national <- file.path(st$imputation_private, "national_covariates_imputed.csv")
  st$dhs_manifest <- "data/derived_cbh/survey_manifest.csv"
  st$mics_manifest <- file.path(st$mics_output_dir, "survey_manifest.csv")
  st$registries <- c("data/derived_dhs/survey_registry.csv", "data/derived_mics/survey_registry_mics.csv")
  st$hiv_panel <- "data/derived_cbh/hiv_incidence/child_incidence_country_year_extended_lbr.csv"
  st$hiv_draws <- "data/derived_cbh/hiv_incidence/child_incidence_draws_extended.rds"
  st$comparison_labels <- c("Complete-case covariates, GADM units", "Imputed covariates, GADM units")
  st$m <- 10L; st$maxit <- 20L; st$imputation_seed <- 20260918L
  st$unit <- "gadm"
  st$unit_overlay <- file.path(primary$private, "regional_covariates_wide.csv")
  st$unit_records <- "data/derived_cbh/units/records_units.rds"
  st$unit_pfpr <- "results/cbh/units/pfpr/pfpr_polygon_year.csv"
  st
}
