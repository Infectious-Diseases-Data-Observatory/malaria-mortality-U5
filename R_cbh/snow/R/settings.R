# Settings of the sub-national units. Source from the repository root. Two variants:
#   merge  (the primary; user decisions, 11 October 2026): the Snow et al. (2017) polygons; every MAP-eligible survey;
#          a record's unit is the Snow polygon holding >= 90% of its smallest reported admin unit, else the union of the
#          polygons each holding >= 5%; units more than half malaria-free or island are dropped; no splitting, no weights.
#   gadm   (branch gadm-admin1, author request 3 November 2026): the GADM 4.1 admin-1 units of the same 44 countries
#          (00_gadm_layer.R) with the same placement and merge rules; Snow's malaria-free and island areas stay
#          excluded, units without a MAP PfPR estimate are excluded too, and the same surveys are processed.
# The split_repro variant (a check that reproduced the analysis project's population-share split dataset on the v9
# surveys) was removed on 1 November 2026 (author decision). Unit-construction outputs go to variant folders.
snow_settings <- function(variant = Sys.getenv("SNOW_VARIANT", "merge")) {
  if (!variant %in% c("merge", "gadm")) stop("Unknown Snow variant: ", variant)
  S <- list(
    variant = variant,
    rule = "merge",
    units = "Snow et al. polygons",
    # Polygons: derived from the committed shapefile.
    shapefile = "data/external/snow_admin1/Africa_New_Admin.shp",
    # Fixed counts of the layer outside North Africa (01_polygons.R): all units, endemic, malaria free, island.
    counts = c(polygons = 551L, endemic = 520L, malaria_free = 29L, island = 2L),
    aliases = "R_cbh/snow/config/name_aliases.csv",
    # Reviewed survey-regions placed wholly in the unit they name (03_feasibility.R); none for the Snow polygons.
    region_overrides = NULL,
    whole = 0.90, link = 0.05, sliver = 0.02, malaria_free_drop = 0.5,
    north_africa = c("DZA", "EGY", "LBY", "MAR", "TUN", "ESH"),
    out = file.path("results/cbh/snow_units", variant),
    private = file.path("data/derived_cbh/snow", variant))
  if (identical(variant, "gadm")) S <- modifyList(S, list(
    units = "GADM admin-1 units",
    source = "data/Africa GADM 0-2 (040226)/Africa_GADM1_(040226).shp",   # not committed (GADM licence, size)
    shapefile = "data/external/gadm_admin1/gadm1_units.gpkg",             # written by 00_gadm_layer.R; git-ignored
    counts = c(polygons = 568L, endemic = 535L, malaria_free = 31L, island = 2L),   # 00_gadm_layer.R, 3 November 2026
    aliases = "R_cbh/snow/config/gadm_name_aliases.csv",
    region_overrides = "R_cbh/snow/config/gadm_region_overrides.csv"))
  S
}
# The layer's polygons as read by 01_polygons.R (private; regenerated, not committed).
snow_polygons_path <- function(S) file.path(S$private, sprintf("polygons_%d.rds", S$counts[["polygons"]]))
snow_dirs <- function(S, ...) { for (d in c(S$out, S$private, file.path(S$out, c(...)))) dir.create(d, recursive = TRUE, showWarnings = FALSE); invisible(S) }
# Child-band shards (one per built survey) and the eligible rows.
snow_shard_path <- function(s) if (startsWith(s, "MC_")) file.path("data/derived_mics/cbh_build/child_bands", paste0(s, ".rds")) else
  file.path("data/derived_cbh/child_bands", paste0(s, ".rds"))
snow_all_shards <- function() sort(c(sub("[.]rds$", "", list.files("data/derived_cbh/child_bands", "[.]rds$")),
                                     sub("[.]rds$", "", list.files("data/derived_mics/cbh_build/child_bands", "[.]rds$"))))
# Eligible rows: every row whose survey-region is matched (the Snow exposure does not need the survey-region MAP value).
snow_eligible <- function(d) !is.na(d$region) & !is.na(d$regkey)
