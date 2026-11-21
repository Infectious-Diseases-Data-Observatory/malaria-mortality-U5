#!/usr/bin/env Rscript
# Run the existing child age-band builder (R_cbh/R/build.R) on the MICS surveys, writing to a MICS folder so the DHS
# manifest and shards are untouched. Paths are overridden in memory; no shared builder file is edited. This branch's
# builder makes the bands of 5 years and over too, so the folder is the all-ages one (cbh_allages_dirs(),
# R_cbh/00_config.R); the paper's under-five build in data/derived_mics/cbh_build is left as it is.
source("R_cbh/load_pipeline.R")
cfg <- cbh_config()
d <- file.path(cfg$root, "data/derived_mics")
cfg$output_dir <- file.path(cfg$root, cbh_allages_dirs()$mics)
cfg$registry <- file.path(d, "survey_registry_mics.csv")
cfg$survey_rules <- file.path(d, "survey_rules_mics.csv")
cfg$region_overrides <- file.path(d, "region_overrides_mics.csv")
cfg$boundary_regions <- file.path(d, "map_pfpr_by_survey_region_mics.csv")
cfg$annual_map <- file.path(d, "map_pfpr_window_years_mics.csv")
# MICS regions are mapped upstream (05), so the builder's override table is empty. Every shard
# signature hashes this file: an existing copy is never rewritten, and a missing one is created
# with exactly the bytes of the reviewed header-only file.
if (!file.exists(cfg$region_overrides))
  write.csv(data.frame(svkey = character(), region_var = character(), source_label = character(),
    regkey = character(), region_id = character()), cfg$region_overrides, row.names = FALSE)
dir.create(cfg$output_dir, recursive = TRUE, showWarnings = FALSE)
args <- commandArgs(trailingOnly = TRUE)
# Rewrites manifest.rds even when every shard is cached; its md5 enters the imputation
# sensitivity's signature (imputation_dhsmics/03_prepare.R) and the reporting provenance.
res <- cbh_build(cfg, surveys = NULL, force = "--force" %in% args)
m <- readRDS(file.path(cfg$output_dir, "manifest.rds"))$manifest
cat("MICS build complete:", sum(m$status %in% c("built", "cached")), "built of", nrow(m), "\n")
print(table(m$status))
