# Survey-design sensitivity analyses of the primary hazards model (R_cbh/sensitivity/design/): child-level urban/rural
# indicator and cluster dependence. Exploratory: the paper's primary results are not changed by these scripts.
cbh_design_settings <- function() {
  id <- "design_check_gadm_merge_gamma2_v1"
  private <- file.path("data/derived_cbh/models", id)
  list(id = id, private = private, out = file.path("results/cbh", id),
       design = file.path(private, "design_columns.rds"), test_band = "12-23")
}
# Grids of the free-form PfPR curves (second-order random walks; R_cbh/sensitivity/design/05_spacetime_inla.R defines
# the same scales where it fits them): the node index of PfPR x is the value below, nodes 0, 1, ...; node 0 is the
# reference (PfPR 0, or PfPR below 1% for the *_ref1 model).
cbh_design_walk_scales <- function() list(
  M1_rw2 = function(x) x, M1_rw2_sqrt = function(x) 10 * sqrt(x), M1_rw2_log = function(x) 20 * log1p(x),
  M1_rw2_sqrt_ref1 = function(x) 10 * (sqrt(pmax(x, 1)) - 1))
