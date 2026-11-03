#!/usr/bin/env Rscript
# The GADM admin-1 units outside North Africa (units_settings()$shapefile, written by 00_gadm_layer.R): 568 units, of
# which 535 are "Endemic" (the units of analysis), 31 "Malaria free" and 2 "Island" (excluded). The counts are fixed in
# units_settings(). Writes the polygons (private; regenerated, not committed) and a table with area, point-on-surface
# centroid and population (GPW 2020 density x cell area).
# Output: <private>/polygons.rds (units_polygons_path); <out>/polygons/polygons.csv
suppressPackageStartupMessages({ library(data.table); library(sf); library(terra); library(exactextractr) })
sf_use_s2(FALSE)
source("R_cbh/units/R/settings.R")
S <- units_dirs(units_settings(), "polygons")
layer <- st_read(S$shapefile, quiet = TRUE)
st_geometry(layer) <- "geometry"   # a geopackage names it "geom"
layer <- st_make_valid(layer[!layer$Country_ID %in% S$north_africa, c("Admin_ID", "Country_ID", "AFR_Admin", "Type")])
layer <- st_transform(layer, 4326)
n <- c(polygons = nrow(layer), endemic = sum(layer$Type == "Endemic"), malaria_free = sum(layer$Type == "Malaria free"),
       island = sum(layer$Type == "Island"))
if (!identical(n, S$counts)) stop("Unit counts (", paste(names(n), n, collapse = ", "), ") differ from units_settings()$counts")
stopifnot(!anyDuplicated(layer$Admin_ID), setequal(unique(layer$Type), c("Endemic", "Malaria free", "Island")))
layer$endemic <- layer$Type == "Endemic"   # a unit of analysis
saveRDS(layer, units_polygons_path(S))
dens <- crop(rast("data/pop/gpw_v4_population_density_rev11_2020_2.5m.tif"), ext(-26, 60, -36, 28))
popc <- dens * cellSize(dens, unit = "km")
pts <- suppressWarnings(st_coordinates(st_point_on_surface(layer)))
tab <- data.table(st_drop_geometry(layer)[, c("Admin_ID", "Country_ID", "AFR_Admin", "Type", "endemic")],
  area_km2 = as.numeric(st_area(st_transform(layer, "ESRI:102022"))) / 1e6, lon = pts[, 1], lat = pts[, 2],
  population_2020 = exact_extract(popc, layer, "sum", progress = FALSE))
fwrite(tab[order(Admin_ID)], file.path(S$out, "polygons", "polygons.csv"))
cat(sprintf("%s: %d units (%d endemic, %d malaria-free, %d island) in %d countries\n", S$units, nrow(tab), sum(tab$endemic),
            sum(tab$Type == "Malaria free"), sum(tab$Type == "Island"), uniqueN(tab$Country_ID)))
