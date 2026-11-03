# Primary specification used in the paper (v15, version "gadm"; author decision, 3 November 2026): seven age-band models
# on DHS and MICS surveys placed in the GADM 4.1 admin-1 units (KEMRI-Wellcome merge; national boundaries for Botswana,
# Ghana, Kenya, Madagascar, Malawi, mainland Tanzania and Uganda; R_cbh/units/), MAP PfPR2-10 (release 202608),
# 17 adjustment covariates, gamma = 2. Every MAP-eligible DHS and MICS survey with a complete birth history (the 136
# surveys of R_cbh/primary/survey_set.csv); a record's unit is the unit holding >= 90% of its smallest reported admin
# unit, else the union of the units each holding >= 5%; units typed malaria-free or island (more than half of their
# population in those areas of Snow et al. 2017, or no MAP PfPR estimate) are left out, and a record more than half in
# them is dropped; exposure = MAP PfPR of the unit; the 13 regional covariates of v9 (with its 28 September 2026
# derivation corrections) computed per (survey, unit) from the recodes; complete-case selection keeps only MICS surveys
# with anthropometry. Declared national rules: South Sudan takes Sudan's values before 2011 (national_substitutions.R);
# political stability in 2001 and health expenditure in 2024 are filled (national_interpolations.R); Liberia's child HIV
# incidence comes from UNAIDS counts (R_cbh/hiv/03_add_liberia_aidsinfo.R). Burden on MAP's national (admin-0)
# estimates with 500 joint draws (R_cbh/burden/06_uncertainty_draws.R).
# The Snow-unit primary (v11-v14) was replaced by GADM units in v15 (author decision, 3 November 2026; code in git
# history up to f2db98e); earlier versions (v1-v9) are history in the analysis project and in git.
cbh_primary_settings <- function(version = Sys.getenv("CBH_PRIMARY_VERSION", "gadm")) {
  if (!identical(version, "gadm")) stop("Unknown primary version: ", version, " (gadm)")
  id <- "primary_gadm_merge_dhsmics_gamma2_v15"
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
    # Expected counts are set from a verified run; NULL = not yet fixed.
    expected_records = NULL, expected_deaths = NULL, expected_regions = NULL,
    mics_output_dir = "data/derived_mics/cbh_build", expected_mics_surveys = NULL,
    sensitivity_dirs = c(subgroups = "results/cbh/subgroups_gadm_merge_gamma2_v9",
                         nutrition = "results/cbh/nutrition_adjustment_gadm_merge_gamma2_v9"),
    unit = "gadm",
    # The surveys of the sample (survey, country): 00_prepare.R stops unless the prepared sample has exactly these.
    survey_reference = "R_cbh/primary/survey_set.csv",
    prepare = "R_cbh/primary/00_prepare.R")
}
