#!/usr/bin/env Rscript
# MAP PfPR2-10 for each endemic unit (the 535 endemic GADM admin-1 units) and each year 2000-2024: the mean prevalence
# of the unit's whole population. Exact fractional polygon coverage of the MAP grid; weights are GPW v4 2020 population
# counts (density x cell area), resampled bilinearly to the MAP grid. A cell without a MAP value in a year lies outside
# MAP's limits of transmission for that year and counts as zero prevalence: its population stays in the denominator.
# This is the convention of MAP's own national estimates, which the burden uses (cbh_map_national): the national
# all-population mean of these rasters reproduces them, the mean over cells with a value does not (Eswatini 2000: MAP
# 0.32%, all population 0.28%, cells with a value 10.9%).
# Until 23 November 2026 (results v15) the mean was taken over the cells with a value in the 2024 raster, in every
# year. That dropped cells that had a value in earlier years, left out the population outside MAP's limits (68 units
# have under 90% of their population inside them in some year) and so overstated the prevalence of partly endemic
# units, while the burden applied the fitted curves to whole-population national prevalence.
# The weight written with each value is the unit's whole population, so that the PfPR of a union of units is
# sum(weight * PfPR) / sum(weight), identical to an extraction over the union.
# Output: <out>/pfpr/pfpr_polygon_year.csv (unit-year aggregates), pfpr_raster_provenance.csv
suppressPackageStartupMessages({ library(data.table); library(sf); library(terra) })
sf_use_s2(FALSE)
source("R_cbh/units/R/settings.R")
S <- units_dirs(units_settings(), "pfpr")
p <- readRDS(units_polygons_path(S)); p <- p[p$endemic, ]
stopifnot(nrow(p) == S$counts[["endemic"]], !anyDuplicated(p$Admin_ID))
source("R_cbh/00_config.R")   # cbh_config()$map_raster_dir: the MAP release of every exposure
rf <- list.files(cbh_config()$map_raster_dir, pattern = "pfpr2_10_[0-9]{4}[.]tif$", full.names = TRUE)
ry <- as.integer(regmatches(basename(rf), regexpr("[0-9]{4}", basename(rf))))
keep <- ry %in% 2000:2024; rf <- rf[keep]; ry <- ry[keep]   # the years of the band entries, whatever else the folder holds
stopifnot(identical(sort(ry), 2000:2024))
stk <- rast(rf[order(ry)]); names(stk) <- as.character(sort(ry))
w <- resample(crop(rast("data/pop/gpw_v4_population_density_rev11_2020_2.5m.tif"), stk[[1]]), stk[[1]], method = "bilinear")
w <- w * cellSize(w, unit = "km")   # every populated cell of the unit, with or without a MAP value
v <- makeValid(vect(st_transform(p, crs(stk))))
den <- extract(w, v, fun = sum, na.rm = TRUE, exact = TRUE, ID = FALSE)[[1]]
num <- extract(stk * w, v, fun = sum, na.rm = TRUE, exact = TRUE, ID = FALSE)   # cells without a value add nothing
stopifnot(all(den > 0))
res <- rbindlist(lapply(seq_len(nlyr(stk)), function(j) data.table(Admin_ID = p$Admin_ID, Country_ID = p$Country_ID,
  AFR_Admin = p$AFR_Admin, year = as.integer(names(stk)[j]), pfpr2_10 = 100 * num[[j]] / den, population_weight = den)))
fwrite(res, file.path(S$out, "pfpr", "pfpr_polygon_year.csv"))
# Which rasters were read (the MAP release is otherwise invisible downstream).
fwrite(data.table(file = rf[order(ry)], md5 = unname(tools::md5sum(rf[order(ry)])), map_release = cbh_config()$map_release),
       file.path(S$out, "pfpr", "pfpr_raster_provenance.csv"))
cat(sprintf("%s (density x area weights): %d units x %d years; PfPR %.1f-%.1f%%; units without a value: %d\n", S$units,
            uniqueN(res$Admin_ID), uniqueN(res$year), min(res$pfpr2_10, na.rm = TRUE), max(res$pfpr2_10, na.rm = TRUE),
            uniqueN(res[!is.finite(pfpr2_10), Admin_ID])))
