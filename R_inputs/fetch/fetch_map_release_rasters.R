#!/usr/bin/env Rscript
# Download annual MAP PfPR2-10 rasters for one release at the Africa extent, keeping band 1 (the estimate), exactly as
# get_map_raster() in R_inputs/02_extract_map_pfpr.R does, into data/map_annual_<release>/pfpr2_10_YYYY.tif.
# Idempotent: years already present are skipped. Usage: Rscript R_inputs/fetch/fetch_map_release_rasters.R 202608 2000 2025
args <- commandArgs(trailingOnly = TRUE); stopifnot(length(args) == 3L)
release <- args[1]; years <- seq(as.integer(args[2]), as.integer(args[3]))
suppressPackageStartupMessages({ library(malariaAtlas); library(terra) })
dataset_id <- sprintf("Malaria__%s_Global_Pf_Parasite_Rate", release)
extent <- matrix(c(-18, -35, 52, 38), nrow = 2)                                    # as MAP_AFRICA_EXTENT
out_dir <- file.path("data", paste0("map_annual_", release)); dir.create(out_dir, showWarnings = FALSE)
for (year in years) {
  output <- file.path(out_dir, sprintf("pfpr2_10_%d.tif", year))
  if (file.exists(output)) { message(year, ": present"); next }
  download_dir <- file.path(tempdir(), paste0("map_", release, "_", year)); dir.create(download_dir, showWarnings = FALSE)
  t0 <- Sys.time()
  invisible(tryCatch(getRaster(dataset_id = dataset_id, year = year, extent = extent, file_path = download_dir),
                     error = function(e) message(year, ": ", conditionMessage(e))))
  tif <- list.files(download_dir, pattern = "\\.tiff?$", full.names = TRUE, recursive = TRUE)
  if (!length(tif)) stop("no raster returned for ", year)
  r <- rast(tif)
  band <- grep("_1$", names(r)); stopifnot(length(band) >= 1L, grepl(release, names(r)[band[1]]))
  writeRaster(r[[band[1]]], output, overwrite = TRUE)
  message(sprintf("%d: %d bands downloaded (%s), band 1 saved, %.0f s", year, nlyr(r), paste(names(r), collapse = " | "),
                  as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  unlink(download_dir, recursive = TRUE)
}
