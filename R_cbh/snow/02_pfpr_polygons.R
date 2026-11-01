#!/usr/bin/env Rscript
# MAP PfPR2-10 for each of the 520 endemic Snow polygons and each year 2000-2024 (ported from the analysis project's
# R_cbh/snow_units/06_pfpr_polygons.R): exact fractional polygon coverage of the MAP grid, GPW v4 2020 population as
# weights resampled bilinearly to the MAP grid, masked to cells with a MAP value. The weight is GPW density (as the
# survey-region extraction of R_inputs/41, used for the reproduction) or density x cell area (population counts,
# the primary). The weight sum is written with each value, so that the PfPR of a union of polygons is
# sum(weight * PfPR) / sum(weight), identical to an extraction over the union.
# Output: <out>/pfpr/pfpr_polygon_year.csv (polygon-year aggregates)
suppressPackageStartupMessages({ library(data.table); library(sf); library(terra) })
sf_use_s2(FALSE)
source("R_cbh/snow/R/settings.R")
S <- snow_dirs(snow_settings(), "pfpr")
p <- readRDS(file.path(S$private, "polygons_551.rds")); p <- p[p$in520, ]
if (nzchar(S$polygons_gpkg)) {   # reproduction: the analysis project's 520-polygon file, read in place
  g <- st_make_valid(st_read(S$polygons_gpkg, quiet = TRUE)); stopifnot(setequal(g$Admin_ID, p$Admin_ID)); p <- g
}
stopifnot(nrow(p) == 520L, !anyDuplicated(p$Admin_ID))
source("R_cbh/00_config.R")   # cbh_config()$map_raster_dir: the MAP release of every exposure
rf <- list.files(cbh_config()$map_raster_dir, pattern = "pfpr2_10_[0-9]{4}[.]tif$", full.names = TRUE)
ry <- as.integer(regmatches(basename(rf), regexpr("[0-9]{4}", basename(rf))))
keep <- ry %in% 2000:2024; rf <- rf[keep]; ry <- ry[keep]   # the years of the band entries, whatever else the folder holds
stopifnot(identical(sort(ry), 2000:2024))
stk <- rast(rf[order(ry)]); names(stk) <- as.character(sort(ry))
w <- resample(crop(rast("data/pop/gpw_v4_population_density_rev11_2020_2.5m.tif"), stk[[1]]), stk[[1]], method = "bilinear")
if (identical(S$pfpr_weight, "density_area")) w <- w * cellSize(w, unit = "km") else stopifnot(identical(S$pfpr_weight, "density"))
w <- mask(w, stk[[nlyr(stk)]])
v <- makeValid(vect(st_transform(p, crs(stk))))
den <- extract(w, v, fun = sum, na.rm = TRUE, exact = TRUE, ID = FALSE)[[1]]
num <- extract(stk * w, v, fun = sum, na.rm = TRUE, exact = TRUE, ID = FALSE)
res <- rbindlist(lapply(seq_len(nlyr(stk)), function(j) data.table(Admin_ID = p$Admin_ID, Country_ID = p$Country_ID,
  AFR_Admin = p$AFR_Admin, year = as.integer(names(stk)[j]), pfpr2_10 = 100 * num[[j]] / den, population_weight = den)))
fwrite(res, file.path(S$out, "pfpr", "pfpr_polygon_year.csv"))
# Which rasters were read (the MAP release is otherwise invisible downstream).
fwrite(data.table(file = rf[order(ry)], md5 = unname(tools::md5sum(rf[order(ry)])), map_release = cbh_config()$map_release),
       file.path(S$out, "pfpr", "pfpr_raster_provenance.csv"))
cat(sprintf("%s (%s weights): %d polygons x %d years; PfPR %.1f-%.1f%%; polygons without a value: %d\n", S$variant, S$pfpr_weight,
            uniqueN(res$Admin_ID), uniqueN(res$year), min(res$pfpr2_10, na.rm = TRUE), max(res$pfpr2_10, na.rm = TRUE),
            uniqueN(res[!is.finite(pfpr2_10), Admin_ID])))
