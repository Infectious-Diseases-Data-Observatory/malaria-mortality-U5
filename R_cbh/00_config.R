# Configuration only. No reads, downloads, installs or fits when sourced.
cbh_config <- function(root = getwd()) {
  root <- normalizePath(root, mustWork = TRUE)
  list(
    root = root,
    output_dir = file.path(root, "data", "derived_cbh"),
    registry = file.path(root, "data/derived_dhs/survey_registry.csv"),
    boundary_regions = file.path(root, "data/derived_dhs/map_pfpr_by_survey_region.csv"),
    annual_map = file.path(root, "data/derived_dhs/map_pfpr_window_years.csv"),
    # MAP PfPR2-10 release for every exposure: 202608 from 1 November 2026 (author request; was 202508). Annual 2.5'
    # rasters, band 1 = the estimate, 2000-2024 (R_inputs/fetch/fetch_map_release_rasters.R), and MAP's own national
    # (admin-0) estimates with interval bounds (R_inputs/fetch/fetch_map_national_pfpr.R). R_inputs/00_config.R names
    # the same raster folder.
    map_release = "202608",
    map_raster_dir = file.path(root, "data/map_annual_202608"),
    map_national = file.path(root, "data/map_pfpr_admin0_202608.csv"),
    # Countries of the IHME all-cause export that stay out of the burden although MAP now gives them national values:
    # the paper's 42-country set is kept (author decision, 1 November 2026). Lesotho has no MAP national value.
    burden_excluded = c("CPV", "STP"),
    survey_rules = file.path(root, "R_cbh/config/survey_rules.csv"),
    region_overrides = file.path(root, "R_cbh/config/region_overrides.csv"),
    first_entry_year = 2000L,
    last_entry_year = 2024L,
    exposure_timing = "band_entry_calendar_year",
    # Age bands in completed months, and the months before the interview within which a band must be entered
    # (entry_lookback_months). The seven under-five bands use 60 months. The older bands (author requests, 20 November
    # 2026) use 120 months. The 5-9 and 10-14 year bands (60-119 and 120-179 months) are five years wide and must end
    # before the interview: the child turned 5 (or 10) in the 120 months before the interview and would have turned 10
    # (or 15) by it. The band of 15 years and over (180+) is open-ended (age_hi = Inf): the child turned 15 in the
    # 120 months before the interview and is followed to the interview, so it covers ages 15 to 24 and its width is the
    # record's own time from the 15th birthday to the interview.
    age_bands = data.frame(
      age_band = c("<1", "1-5", "6-11", "12-23", "24-35", "36-47", "48-59", "60-119", "120-179", "180+"),
      age_lo = c(0L, 1L, 6L, 12L, 24L, 36L, 48L, 60L, 120L, 180L),
      age_hi = c(1, 6, 12, 24, 36, 48, 60, 120, 180, Inf),
      entry_lookback_months = c(rep(60L, 7), 120L, 120L, 120L)),
    # Candidate X variables are retained, not selected or imputed here.
    # An unavailable optional panel produces NA and a source-status flag. The legacy HIV prevalence and immunisation
    # panels, which fed no model, were removed on 1 November 2026 (author decision).
    annual_panels = list(
      gdp = list(path = file.path(root, "data/wb_gdp_pc.csv"),
                 columns = c(gdp_pc = "gdp_pc")),
      health_spending = list(path = file.path(root, "data/wb_hexp_pc.csv"),
                             columns = c(health_expenditure_pc = "hexp_pc")),
      governance = list(path = file.path(root, "data/wb_polstab.csv"),
                        columns = c(political_stability = "polstab"))
    ),
    statcompiler = file.path(root, "data/derived_dhs/statcompiler_covariates.csv"),
    # Output is local, access-controlled microdata. Do not put it in results/.
    schema_version = "cbh-band-entry-v1"
  )
}

# Folders of the all-ages build (author request, 21 November 2026). The paper's under-five build (seven bands, made on
# the paper branch) keeps data/derived_cbh, data/derived_mics/cbh_build, data/derived_cbh/units and results/cbh/units,
# and the paper's result files record checksums of those files. This branch's builder makes ten bands, so everything
# it writes that depends on the bands goes to folders of its own and the paper's files are never overwritten:
#   dhs, mics  the DHS and MICS child-band builds (R_cbh/01_make_analysis_data.R, R_mics/08_build_child_bands.R);
#   records    the placed records and their units (R_cbh/units/07_placement.R, 08_units.R), read by the preparation;
#   units_out  the placement and unit summaries of those records.
# The units themselves, their PfPR and the survey-unit covariates do not depend on the bands and stay the paper's
# (R_cbh/units/R/settings.R). All four folders are under git-ignored folders.
cbh_allages_dirs <- function() list(
  dhs = "data/derived_cbh/allages",
  mics = "data/derived_mics/cbh_build_allages",
  records = "data/derived_cbh/allages/units",
  units_out = "results/cbh/units_allages")
