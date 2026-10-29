# Primary specification used in the paper: seven age-band models on DHS and MICS surveys, MAP PfPR,
# 17 adjustment covariates, gamma = 2 (version id v9). The earlier versions (v1-v7) are history in the
# analysis project and are not carried into this repository. Prepared data and national inputs are fixed.
#
# v9 (decided 27-28 September 2026): DHS and MICS surveys with complete birth histories; regional
# covariates with the 28 September derivation corrections (Uganda 2016 wealth decoding; MICS vaccination
# under the DHS tabulation rules with all DTP/pentavalent and measles-containing columns; MICS education,
# facility delivery, water and sanitation coding; Mozambique MICS 2008; published-value joins; Sierra Leone
# 2013 from its recodes); Uganda 2016's north and south Buganda regions admitted; Liberia's child HIV
# incidence derived from UNAIDS counts (R_cbh/hiv/03_add_liberia_aidsinfo.R). Complete-case selection keeps
# only MICS surveys with anthropometry.
#
# snow_merge (user decisions, 11 October 2026): the same seven age-band models, covariate definitions, knots, family
# and gamma, with the Snow et al. (2017) polygons as the unit of analysis (R_cbh/snow/): every MAP-eligible DHS and
# MICS survey; a record's unit is the Snow polygon holding >= 90% of its smallest reported admin unit, else the union
# of the polygons each holding >= 5%; units more than half malaria-free dropped; exposure = MAP PfPR of the unit;
# the 13 regional covariates recomputed per (survey, unit) from the recodes. snow_split_repro rebuilds the analysis
# project's population-share split dataset on the v9 surveys to verify the port (prepared data only; not fitted).
# snow_merge v12 (author decision, 29 October 2026): political stability in 2001, a year without a WGI round, is the
# mean of the country's 2000 and 2002 values (R_cbh/primary/national_interpolations.R), so records entering a band in
# 2001 are no longer lost to complete-case selection; sensitivities v6. v11 (sensitivities v5) is kept as history.
cbh_primary_settings <-function(version=Sys.getenv("CBH_PRIMARY_VERSION","regional_mics")) {
  if (version %in% c("snow_merge", "snow_split_repro")) return(cbh_snow_primary_settings(version))
  if (!identical(version, "regional_mics"))
    stop("Unknown primary version: ", version, " (regional_mics = v9, snow_merge, snow_split_repro)")
  id <- "primary_map_regional17_dhsmics_gamma2_v9"
  private <- file.path("data/derived_cbh/models", id)
  list(
    id = id,
    out = file.path("results/cbh", id),
    private = private,
    data = file.path(private, "complete_case_dataset.rds"),
    knots = "R_cbh/primary/reference_knots.csv",
    years = c(2005L, 2015L, 2024L), gamma = 2, seed = 20260907L,
    nthreads = 2L, regional = TRUE, nutrition = TRUE, imputed = FALSE, mics = TRUE,
    hiv_panel = "data/derived_cbh/hiv_incidence/child_incidence_country_year_lbr.csv",
    expected_records = 7621617L, expected_deaths = 104143L, expected_regions = 1229L,
    mics_output_dir = "data/derived_mics/cbh_build",
    mics_overlay = "data/derived_mics/regional_covariates_wide_mics.csv",
    expected_dhs_records = 5588463L, expected_dhs_deaths = 77587L, expected_dhs_regions = 934L,
    dhs_part_note = "the v7 DHS part plus Uganda 2016's north and south Buganda regions",
    sensitivity_dirs = c(subgroups = "results/cbh/subgroups_dhsmics_map_gamma2_v4",
                         nutrition = "results/cbh/nutrition_adjustment_dhsmics_map_gamma2_v4"),
    attribution_dir = "results/cbh/planned17_covariate_missingness_lbr",
    unit = "region", prepare = "R_cbh/primary/00_prepare_regional.R")
}
cbh_snow_primary_settings <- function(version) {
  id <- if (identical(version, "snow_merge")) "primary_snow520_merge_dhsmics_gamma2_v12" else "snow_split_repro"
  private <- file.path("data/derived_cbh/models", id)
  list(
    id = id, version = version,
    out = file.path("results/cbh", id),
    private = private,
    data = file.path(private, "complete_case_dataset.rds"),
    knots = "R_cbh/primary/reference_knots.csv",
    years = c(2005L, 2015L, 2024L), gamma = 2, seed = 20260907L,
    nthreads = 2L, regional = TRUE, nutrition = TRUE, imputed = FALSE, mics = TRUE,
    hiv_panel = "data/derived_cbh/hiv_incidence/child_incidence_country_year_lbr.csv",
    # Expected counts are set from the verified run (verification/reference_key_numbers.csv); NULL = not yet fixed.
    expected_records = NULL, expected_deaths = NULL, expected_regions = NULL,
    mics_output_dir = "data/derived_mics/cbh_build", expected_mics_surveys = NULL,
    sensitivity_dirs = c(subgroups = "results/cbh/subgroups_snow520_merge_gamma2_v6",
                         nutrition = "results/cbh/nutrition_adjustment_snow520_merge_gamma2_v6"),
    unit = "snow", snow_variant = if (identical(version, "snow_merge")) "merge" else "split_repro",
    prepare = "R_cbh/primary/00_prepare_snow.R")
}
