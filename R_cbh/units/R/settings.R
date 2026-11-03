# Settings of the sub-national units. Source from the repository root. The units are the GADM 4.1 admin-1 units of the
# 44 sub-Saharan countries (KEMRI-Wellcome merge; national boundaries for Botswana, Ghana, Kenya, Madagascar, Malawi,
# mainland Tanzania and Uganda), written by 00_gadm_layer.R. Every MAP-eligible survey is placed; a record's unit is the
# admin-1 unit holding >= 90% of the population of its smallest reported admin unit, else the union of the units each
# holding >= 5% (merge rule, user decisions of 11 October 2026); units more than half malaria-free are dropped; no
# splitting, no weights. Malaria-free and island areas are those of Snow et al. (2017); units without a MAP PfPR estimate
# are malaria free too (author decision, 3 November 2026). The Snow-unit primary (v11-v14) was replaced by the GADM units
# in v15 (author decision, 3 November 2026; code in git history up to f2db98e).
units_settings <- function() list(
  variant = "gadm",   # fixed label, kept for signatures and provenance
  rule = "merge",
  units = "GADM admin-1 units",
  source = "data/Africa GADM 0-2 (040226)/Africa_GADM1_(040226).shp",   # not committed (GADM licence, size)
  shapefile = "data/external/gadm_admin1/gadm1_units.gpkg",             # written by 00_gadm_layer.R; git-ignored
  # Reference input (committed): the Snow et al. (2017) polygons, for the study countries and unit types
  # (00_gadm_layer.R) and the Western Sahara outline of Figure 1 (R_cbh/reporting/23_analysis_units_map.R).
  snow_shapefile = "data/external/snow_admin1/Africa_New_Admin.shp",
  # Fixed counts of the layer outside North Africa (01_polygons.R): all units, endemic, malaria free, island.
  counts = c(polygons = 568L, endemic = 535L, malaria_free = 31L, island = 2L),
  aliases = "R_cbh/units/config/name_aliases.csv",                # spellings of finer locations (05_finer_units.R)
  region_overrides = "R_cbh/units/config/region_overrides.csv",   # survey-regions placed wholly in the unit they name (03)
  unit_ids = "R_cbh/units/config/unit_ids.csv",                   # pinned unit ids (00_gadm_layer.R)
  whole = 0.90, link = 0.05, sliver = 0.02, malaria_free_drop = 0.5,
  north_africa = c("DZA", "EGY", "LBY", "MAR", "TUN", "ESH"),
  out = "results/cbh/units",
  private = "data/derived_cbh/units")
# The layer's polygons as read by 01_polygons.R (private; regenerated, not committed).
units_polygons_path <- function(S) file.path(S$private, "polygons.rds")
units_dirs <- function(S, ...) { for (d in c(S$out, S$private, file.path(S$out, c(...)))) dir.create(d, recursive = TRUE, showWarnings = FALSE); invisible(S) }
# Child-band shards (one per built survey) and the eligible rows.
units_shard_path <- function(s) if (startsWith(s, "MC_")) file.path("data/derived_mics/cbh_build/child_bands", paste0(s, ".rds")) else
  file.path("data/derived_cbh/child_bands", paste0(s, ".rds"))
units_all_shards <- function() sort(c(sub("[.]rds$", "", list.files("data/derived_cbh/child_bands", "[.]rds$")),
                                     sub("[.]rds$", "", list.files("data/derived_mics/cbh_build/child_bands", "[.]rds$"))))
# Eligible rows: every row whose survey-region is matched (the unit exposure does not need the survey-region MAP value).
units_eligible <- function(d) !is.na(d$region) & !is.na(d$regkey)
