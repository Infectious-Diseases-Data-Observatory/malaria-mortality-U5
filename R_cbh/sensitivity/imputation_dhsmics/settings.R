# Imputed-covariate sensitivity of the Snow-unit primary (v15 on primary v14; v12 was on v11). The survey-region
# versions (v10 on v9, v8 on v7, v6 on v5) were removed with v9 on 1 November 2026. Liberia's child HIV incidence comes
# from UNAIDS counts (R_cbh/hiv/03_add_liberia_aidsinfo.R). The 17 covariates, formula, reference knots and gamma are
# the primary's; every placed record is retained after imputing all remaining covariate gaps. Units take the Snow
# primary's covariate table (after the WUENIC and within-survey fallbacks) and PfPR of the unit at the survey year.
cbh_imputed_dhsmics_settings <- function() {
  source("R_cbh/primary/settings.R", local = TRUE)
  snow <- cbh_primary_settings("snow_merge")
  st <- snow[c("knots", "years", "gamma", "seed", "nthreads", "regional", "nutrition", "mics_output_dir")]
  st$id <- "primary_snow520_merge_imputed_gamma2_v15"
  st$out <- file.path("results/cbh", st$id); st$private <- file.path("data/derived_cbh/models", st$id)
  st$data <- file.path(st$private, "complete_case_dataset.rds")
  st$reference <- snow$out; st$reference_data <- snow$data
  st$imputed <- TRUE; st$mics <- TRUE
  st$imputation_private <- "data/derived_cbh/regional_adjustment/imputed_snow_v15"
  st$imputation_results <- "results/cbh/covariate_imputation_snow_v15"
  st$imputed_overlay <- file.path(st$imputation_private, "regional_covariates_wide.csv")
  st$imputed_national <- file.path(st$imputation_private, "national_covariates_imputed.csv")
  st$dhs_manifest <- "data/derived_cbh/survey_manifest.csv"
  st$mics_manifest <- file.path(st$mics_output_dir, "survey_manifest.csv")
  st$registries <- c("data/derived_dhs/survey_registry.csv", "data/derived_mics/survey_registry_mics.csv")
  st$hiv_panel <- "data/derived_cbh/hiv_incidence/child_incidence_country_year_extended_lbr.csv"
  st$hiv_draws <- "data/derived_cbh/hiv_incidence/child_incidence_draws_extended.rds"
  st$comparison_labels <- c("Complete-case covariates, Snow units", "Imputed covariates, Snow units")
  st$m <- 10L; st$maxit <- 20L; st$imputation_seed <- 20260918L
  st$unit <- "snow"; st$snow_variant <- snow$snow_variant
  st$snow_overlay <- file.path(snow$private, "regional_covariates_wide_snow.csv")
  st$snow_records <- file.path("data/derived_cbh/snow", snow$snow_variant, "records_units.rds")
  st$snow_pfpr <- file.path("results/cbh/snow_units", snow$snow_variant, "pfpr", "pfpr_polygon_year.csv")
  st
}
