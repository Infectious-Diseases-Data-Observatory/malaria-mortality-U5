#!/usr/bin/env Rscript
# The units of the variant's layer outside North Africa (snow_settings()$shapefile): for the primary (merge), the Snow
# et al. (2017) polygons of the committed shapefile (data/external/snow_admin1/): 551 features, of which 520 are
# "Endemic" (the units of analysis), 29 "Malaria free" and 2 "Island" (excluded); for the gadm variant, the GADM
# admin-1 units written by 00_gadm_layer.R, with the same columns and types. The counts are fixed in snow_settings().
# Writes the polygons (private folder of the variant; regenerated, not committed) and a table with area,
# point-on-surface centroid and population (GPW 2020 density x cell area).
# Output: <private>/polygons_<count>.rds; <out>/polygons/polygons.csv
suppressPackageStartupMessages({ library(data.table); library(sf); library(terra); library(exactextractr) })
sf_use_s2(FALSE)
source("R_cbh/snow/R/settings.R")
S <- snow_dirs(snow_settings(), "polygons")
snow <- st_read(S$shapefile, quiet = TRUE)
st_geometry(snow) <- "geometry"   # a geopackage names it "geom"
snow <- st_make_valid(snow[!snow$Country_ID %in% S$north_africa, c("Admin_ID", "Country_ID", "AFR_Admin", "Type")])
snow <- st_transform(snow, 4326)
n <- c(polygons = nrow(snow), endemic = sum(snow$Type == "Endemic"), malaria_free = sum(snow$Type == "Malaria free"),
       island = sum(snow$Type == "Island"))
if (!identical(n, S$counts)) stop("Unit counts (", paste(names(n), n, collapse = ", "), ") differ from snow_settings()$counts")
stopifnot(!anyDuplicated(snow$Admin_ID), setequal(unique(snow$Type), c("Endemic", "Malaria free", "Island")))
snow$in520 <- snow$Type == "Endemic"   # in the units of analysis (the name dates from the 520 Snow polygons)
saveRDS(snow, snow_polygons_path(S))
dens <- crop(rast("data/pop/gpw_v4_population_density_rev11_2020_2.5m.tif"), ext(-26, 60, -36, 28))
popc <- dens * cellSize(dens, unit = "km")
pts <- suppressWarnings(st_coordinates(st_point_on_surface(snow)))
tab <- data.table(st_drop_geometry(snow)[, c("Admin_ID", "Country_ID", "AFR_Admin", "Type", "in520")],
  area_km2 = as.numeric(st_area(st_transform(snow, "ESRI:102022"))) / 1e6, lon = pts[, 1], lat = pts[, 2],
  population_2020 = exact_extract(popc, snow, "sum", progress = FALSE))
fwrite(tab[order(Admin_ID)], file.path(S$out, "polygons", "polygons.csv"))
cat(sprintf("%s: %d polygons (%d endemic, %d malaria-free, %d island) in %d countries\n", S$variant, nrow(tab), sum(tab$in520),
            sum(tab$Type == "Malaria free"), sum(tab$Type == "Island"), uniqueN(tab$Country_ID)))
