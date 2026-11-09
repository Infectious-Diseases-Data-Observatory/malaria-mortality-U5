# Seasonality sensitivity (user requests, 9 November 2026): the Sahel subset of the subgroup suite and southern
# Africa, refitted for the bands <1, 1-5 and 6-11 months with and without the calendar month in which the child was at
# risk (a cyclic spline), on the children whose birth month was reported, with the band model on all the region's
# children for reference. Regions are selected by the centroid of each record's analysis unit (an admin-1 unit or a
# union of units), from sahel_units.csv of the subgroup suite, which holds every unit's centroid.
cbh_seasonality_settings <- function() {
  id <- "seasonality_gadm_v1"
  list(id = id, primary_version = "gadm", bands = c("<1", "1-5", "6-11"),
       out = file.path("results/cbh", id), private = file.path("data/derived_cbh/models", id),
       # Cyclic cubic spline of the calendar month (1-12): December joins January; knots at the half months.
       month_k = 6L, month_knots = c(0.5, 12.5),
       regions = list(
         sahel = list(label = "Sahel", figure = "sfig_sahel_season",
           definition = "records whose analysis unit has its centroid at or north of 10°N and west of 36°E, excluding the Horn of Africa"),
         southern_africa = list(label = "Southern Africa", figure = "sfig_southern_africa_season", latitude_max = -10,
           definition = "records whose analysis unit has its centroid at or south of 10°S")))
}
# Analysis units of a region, from the subgroup suite's unit table (columns unit, lat, sahel).
cbh_seasonality_units <- function(u, region, S = cbh_seasonality_settings()) {
  if (region == "sahel") u$unit[as.logical(u$sahel)] else u$unit[u$lat <= S$regions[[region]]$latitude_max]
}
