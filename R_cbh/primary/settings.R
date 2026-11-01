# Primary specification used in the paper: the Snow-unit primary (snow_merge): seven age-band models on DHS and MICS
# surveys placed in the Snow et al. (2017) polygons, MAP PfPR, 17 adjustment covariates, gamma = 2. Earlier versions
# (v1-v7) are history in the analysis project; the v9 survey-region primary (primary_map_regional17_dhsmics_gamma2_v9,
# refitted on MAP 202608 as _v9_map202608) was removed from this repository on 1 November 2026 (author decision; code
# in git history up to 0a9a198). Prepared data and national inputs are fixed.
#
# v9 (decided 27-28 September 2026; removed 1 November 2026): DHS and MICS surveys with complete birth histories;
# regional covariates with the 28 September derivation corrections (Uganda 2016 wealth decoding; MICS vaccination
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
# snow_merge v13 (author decision, 29 October 2026): health expenditure in 2024, not yet published for any country in
# the analysis, is the country's 2023 value (same file), so 2024 band entries are kept; sensitivities v7. v12 (v6) is history.
# snow_merge v14 (author decision, 1 November 2026): MAP PfPR2-10 release 202608 in place of 202508 for every exposure
# (cbh_config()$map_release), and MAP's own national (admin-0) and Nigerian state (admin-1) estimates in the burden in
# place of the GPW-weighted raster means; burden uncertainty from 500 joint draws (R_cbh/burden/06_uncertainty_draws.R);
# sensitivities v8, country fixed effects v2, imputation v15. v13 (v7) is history; v9 was refitted on 202608
# (..._v9_map202608) and then removed (1 November 2026).
cbh_primary_settings <- function(version = Sys.getenv("CBH_PRIMARY_VERSION", "snow_merge")) {
  if (!version %in% c("snow_merge", "snow_split_repro"))
    stop("Unknown primary version: ", version, " (snow_merge, snow_split_repro)")
  cbh_snow_primary_settings(version)
}
cbh_snow_primary_settings <- function(version) {
  id <- if (identical(version, "snow_merge")) "primary_snow520_merge_dhsmics_gamma2_v14" else "snow_split_repro"
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
    sensitivity_dirs = c(subgroups = "results/cbh/subgroups_snow520_merge_gamma2_v8",
                         nutrition = "results/cbh/nutrition_adjustment_snow520_merge_gamma2_v8"),
    unit = "snow", snow_variant = if (identical(version, "snow_merge")) "merge" else "split_repro",
    prepare = "R_cbh/primary/00_prepare_snow.R")
}
