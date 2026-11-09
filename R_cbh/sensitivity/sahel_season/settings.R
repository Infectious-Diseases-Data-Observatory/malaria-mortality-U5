# Sahel seasonality sensitivity (user request, 9 November 2026): the Sahel subset of the subgroup suite (analysis
# units with centroid >= 10N) refitted for the bands <1, 1-5 and 6-11 months with and without the calendar month in
# which the child was at risk (a cyclic spline), on the children whose birth month was reported.
cbh_sahel_season_settings <- function() {
  id <- "sahel_season_gadm_v1"
  list(id = id, primary_version = "gadm", bands = c("<1", "1-5", "6-11"),
       out = file.path("results/cbh", id), private = file.path("data/derived_cbh/models", id),
       # Cyclic cubic spline of the calendar month (1-12): December joins January; knots at the half months.
       month_k = 6L, month_knots = c(0.5, 12.5))
}
