# Seasonality sensitivity (user requests, 9 November 2026): the Sahel subset of the subgroup suite and southern
# Africa, refitted for the bands <1, 1-5 and 6-11 months with and without the calendar month in which the child was at
# risk (a cyclic spline), on the children whose birth month was reported, with the band model on all the region's
# children for reference. Regions are selected by the centroid of each record's analysis unit (an admin-1 unit or a
# union of units), from sahel_units.csv of the subgroup suite, which holds every unit's centroid.
# Variant "mwi_districts" (CBH_SEASONALITY_VARIANT; user request, 9 November 2026): southern Africa only, the same
# children (selected by their v15 analysis unit), on the finer-units sensitivity data, where Malawi's 3 regions are
# replaced by 26 district units (GADM admin-2; Likoma joined to Nkhata Bay, Kasungu to Mzimba); other southern units are
# unchanged. That data is built by R_cbh/sensitivity/finer_units/run.sh on branch gadm-finer-mwi-uga (it also splits
# Uganda, which lies outside southern Africa). Run by run_mwi_districts.sh; compared with the main run in its report.
cbh_seasonality_settings <- function(variant = Sys.getenv("CBH_SEASONALITY_VARIANT", "gadm")) {
  id <- "seasonality_gadm_v1"
  S <- list(id = id, variant = "gadm", primary_version = "gadm", bands = c("<1", "1-5", "6-11"),
       out = file.path("results/cbh", id), private = file.path("data/derived_cbh/models", id),
       data = NULL,           # model records; NULL: the primary's (cbh_primary_settings()$data)
       compare_with = NULL,   # a run whose results the report compares with
       # Cyclic cubic spline of the calendar month (1-12): December joins January; knots at the half months.
       month_k = 6L, month_knots = c(0.5, 12.5),
       regions = list(
         sahel = list(label = "Sahel", figure = "sfig_sahel_season",
           definition = "records whose analysis unit has its centroid at or north of 10°N and west of 36°E, excluding the Horn of Africa"),
         southern_africa = list(label = "Southern Africa", figure = "sfig_southern_africa_season", latitude_max = -10,
           definition = "records whose analysis unit has its centroid at or south of 10°S")))
  if (identical(variant, "gadm")) return(S)
  if (!identical(variant, "mwi_districts")) stop("Unknown seasonality variant: ", variant, " (gadm, mwi_districts)")
  id <- "seasonality_gadm_mwi_districts_v1"
  S$regions <- S$regions["southern_africa"]
  S$regions$southern_africa$figure <- "sfig_southern_africa_season_mwi_districts"
  S$regions$southern_africa$definition <- paste("records whose analysis unit has its centroid at or south of 10°S; Malawi's 3 regions",
    "divided into 26 district units, the GADM admin-2 districts with Likoma joined to Nkhata Bay and Kasungu to Mzimba")
  modifyList(S, list(id = id, variant = variant, out = file.path("results/cbh", id), private = file.path("data/derived_cbh/models", id),
    data = "data/derived_cbh/models/primary_gadm_fine_merge_dhsmics_gamma2_test1/complete_case_dataset.rds",
    compare_with = list(out = S$out, label = "Malawi's 3 regions (main run)", this = "Malawi's 26 districts")))
}
# Analysis units of a region, from the subgroup suite's unit table (columns unit, lat, sahel).
cbh_seasonality_units <- function(u, region, S = cbh_seasonality_settings()) {
  if (region == "sahel") u$unit[as.logical(u$sahel)] else u$unit[u$lat <= S$regions[[region]]$latitude_max]
}
