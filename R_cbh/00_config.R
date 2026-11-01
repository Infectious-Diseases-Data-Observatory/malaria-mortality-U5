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
    entry_lookback_months = 60L,
    first_entry_year = 2000L,
    last_entry_year = 2024L,
    exposure_timing = "band_entry_calendar_year",
    age_bands = data.frame(
      age_band = c("<1", "1-5", "6-11", "12-23", "24-35", "36-47", "48-59"),
      age_lo = c(0L, 1L, 6L, 12L, 24L, 36L, 48L),
      age_hi = c(1L, 6L, 12L, 24L, 36L, 48L, 60L)),
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
