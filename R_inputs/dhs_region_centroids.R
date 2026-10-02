#!/usr/bin/env Rscript
# Boundary centroids of the DHS/MIS survey regions, used to define the Sahel subgroup
# (R_cbh/sensitivity/subgroups/settings.R). Spherical (s2) centroid of the made-valid DHS
# boundary polygon, one row per survey region; regkey as in the MAP extraction (rkey()).
# The analysis project kept this table (data/derived_dhs/dhs_region_centroids.csv, 29 July 2026)
# without its producing script; this script reproduces it (all 1,185 regions, coordinates
# within 1e-13 degrees). Same method as R_mics/11_region_centroids.R for the MICS regions.
suppressPackageStartupMessages({ library(sf) })
source("R_inputs/00_config.R")
sf_use_s2(TRUE)
reg <- read.csv(SURVEY_REGISTRY_CSV, stringsAsFactors = FALSE)
rows <- lapply(seq_len(nrow(reg)), function(i) {
  f <- file.path(BOUNDARY_DIR, paste0(reg$SurveyId[i], ".rds"))
  if (!file.exists(f)) return(NULL)
  b <- st_make_valid(readRDS(f))
  xy <- st_coordinates(suppressWarnings(st_centroid(st_geometry(b))))
  data.frame(SurveyId = reg$SurveyId[i], iso3 = reg$iso3[i], year = reg$year[i],
             regkey = rkey(b$DHSREGEN), lon = xy[, "X"], lat = xy[, "Y"])
})
centroids <- do.call(rbind, rows)
stopifnot(!anyDuplicated(centroids[c("SurveyId", "regkey")]), all(is.finite(centroids$lon)),
          all(is.finite(centroids$lat)), all(nzchar(centroids$regkey)))
write.csv(centroids, file.path(DERIVED_DIR, "dhs_region_centroids.csv"), row.names = FALSE)
cat("DHS region centroids:", nrow(centroids), "regions in", length(unique(centroids$SurveyId)), "surveys\n")
