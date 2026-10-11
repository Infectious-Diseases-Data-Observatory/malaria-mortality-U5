# Settings of the Snow et al. (2017) polygon units. Source from the repository root. Two variants:
#   merge        the primary (user decisions, 11 October 2026): every MAP-eligible survey; a record's unit is the Snow
#                polygon holding >= 90% of its smallest reported admin unit, else the union of the polygons each
#                holding >= 5%; units more than half malaria-free or island are dropped; no splitting, no weights.
#   split_repro  verification only: reproduces the analysis project's population-share split variant
#                (R_cbh/snow_units/, 6 October 2026) on the 135 v9 surveys, to check the ported placement and
#                covariate code. It is not a result of the paper.
# Unit-construction outputs depend on the variant and are written to variant folders.
snow_settings <- function(variant = Sys.getenv("SNOW_VARIANT", "merge")) {
  if (!variant %in% c("merge", "split_repro")) stop("Unknown Snow variant: ", variant)
  repro <- identical(variant, "split_repro")
  list(
    variant = variant,
    rule = if (repro) "split" else "merge",
    # Surveys: the v9 list (reproduction) or every MAP-eligible child-band shard (all built DHS and MICS surveys).
    universe = if (repro) "v9" else "all",
    v9_surveys = "R_cbh/snow/config/v9_surveys.csv",
    # Records: v9's model_ready rows (region matched and survey-region MAP PfPR present), or every row whose
    # survey-region is matched (the Snow exposure does not need the survey-region MAP value).
    eligibility = if (repro) "model_ready" else "region_matched",
    # Polygons: derived from the committed shapefile; the reproduction may read the analysis project's
    # polygons_520.gpkg in place (SNOW_POLYGONS_GPKG) so that polygon PfPR can match exactly.
    shapefile = "data/external/snow_admin1/Africa_New_Admin.shp",
    polygons_gpkg = if (repro) Sys.getenv("SNOW_POLYGONS_GPKG", "") else "",
    # Population weights of the polygon PfPR: GPW density (the convention of the survey-region extraction,
    # R_inputs/41) for the reproduction; density x cell area (population counts) for the primary.
    pfpr_weight = if (repro) "density" else "density_area",
    # Reviewed fixes applied after the reproduction (R_cbh/snow/config/finer_variable_exclusions.csv).
    rule_fixes = !repro,
    whole = 0.90, link = 0.05, sliver = 0.02, malaria_free_drop = 0.5,
    north_africa = c("DZA", "EGY", "LBY", "MAR", "TUN", "ESH"),
    out = file.path("results/cbh/snow_units", variant),
    private = file.path("data/derived_cbh/snow", variant))
}
snow_dirs <- function(S, ...) { for (d in c(S$out, S$private, file.path(S$out, c(...)))) dir.create(d, recursive = TRUE, showWarnings = FALSE); invisible(S) }
# Child-band shards (one per built survey) and the eligible rows.
snow_shard_path <- function(s) if (startsWith(s, "MC_")) file.path("data/derived_mics/cbh_build/child_bands", paste0(s, ".rds")) else
  file.path("data/derived_cbh/child_bands", paste0(s, ".rds"))
snow_all_shards <- function() sort(c(sub("[.]rds$", "", list.files("data/derived_cbh/child_bands", "[.]rds$")),
                                     sub("[.]rds$", "", list.files("data/derived_mics/cbh_build/child_bands", "[.]rds$"))))
snow_surveys <- function(S) if (identical(S$universe, "v9")) data.table::fread(S$v9_surveys)$svkey else snow_all_shards()
snow_eligible <- function(d, S) if (identical(S$eligibility, "model_ready")) d$model_ready %in% TRUE else !is.na(d$region) & !is.na(d$regkey)
