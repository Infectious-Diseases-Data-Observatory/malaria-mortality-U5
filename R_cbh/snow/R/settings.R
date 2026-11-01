# Settings of the Snow et al. (2017) polygon units. Source from the repository root. One variant, the primary:
#   merge  (user decisions, 11 October 2026): every MAP-eligible survey; a record's unit is the Snow polygon holding
#          >= 90% of its smallest reported admin unit, else the union of the polygons each holding >= 5%; units more
#          than half malaria-free or island are dropped; no splitting, no weights.
# The split_repro variant (a check that reproduced the analysis project's population-share split dataset on the v9
# surveys) was removed on 1 November 2026 (author decision). Unit-construction outputs go to variant folders.
snow_settings <- function(variant = Sys.getenv("SNOW_VARIANT", "merge")) {
  if (!identical(variant, "merge")) stop("Unknown Snow variant: ", variant)
  list(
    variant = variant,
    rule = "merge",
    # Polygons: derived from the committed shapefile.
    shapefile = "data/external/snow_admin1/Africa_New_Admin.shp",
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
# Eligible rows: every row whose survey-region is matched (the Snow exposure does not need the survey-region MAP value).
snow_eligible <- function(d) !is.na(d$region) & !is.na(d$regkey)
