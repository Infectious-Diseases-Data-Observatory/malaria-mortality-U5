#!/usr/bin/env Rscript
# GADM admin-1 units for the GADM variant of the unit construction (SNOW_VARIANT=gadm; branch gadm-admin1, author
# request 3 November 2026). Source: GADM 4.1 admin 1 as merged with island layers by KEMRI-Wellcome
# (S$source, 4 February 2026; not committed: GADM licence and size). Writes the layer with the columns of the Snow
# shapefile (Admin_ID, Country_ID, AFR_Admin, Type), so that 01_polygons.R onwards run unchanged, for the 44 countries
# the Snow shapefile covers outside North Africa:
#   - left out, as the Snow shapefile has no polygon for them: Zanzibar and Pemba, and the island states (the Comoros,
#     Sao Tome and Principe, Cape Verde, Mauritius, Mayotte, Reunion, the Seychelles); also Tanzania's "Lakes" feature
#     (lake water, not an admin unit) and the second copy of Bamako (no GID_1; the outline of MLI.1_1);
#   - Addis Ababa, Niamey and Bamako, which the source leaves inside Oromia, Tillaberi and Koulikoro, are cut out of them;
#   - Admin_ID: GADM's GID_1 where the file has one; Zambia's Lusaka and Southern take the two codes missing from
#     GADM's alphabetical numbering (ZMB.5_1, ZMB.9_1); the units of Kenya, Ghana and mainland Tanzania, which have
#     none, take the country code and the normalised name (KEN.baringo). config/gadm_unit_ids.csv pins the ids;
#   - Type: "Island" for a unit with more than half of its GPW 2020 population in Snow island polygons (Bioko,
#     Annobon); "Malaria free" for one with more than half in Snow malaria-free polygons (Snow's exclusions), or
#     without a MAP PfPR estimate (no population in cells of the 2024 layer, the mask of 02_pfpr_polygons.R; author
#     decision 3 November 2026); otherwise "Endemic".
# Output: S$shapefile (geopackage, git-ignored) and <out>/polygons/gadm_layer.csv (one row per unit; aggregates).
suppressPackageStartupMessages({ library(data.table); library(sf); library(terra); library(exactextractr) })
sf_use_s2(FALSE)
source("R_cbh/R/geography.R"); source("R_cbh/snow/R/settings.R"); source("R_cbh/00_config.R")
S <- snow_dirs(snow_settings("gadm"), "polygons")
dir.create(dirname(S$shapefile), recursive = TRUE, showWarnings = FALSE)
snow <- st_make_valid(st_read(snow_settings("merge")$shapefile, quiet = TRUE))
countries <- setdiff(unique(snow$Country_ID), S$north_africa)
stopifnot(length(countries) == 44L)

g <- st_read(S$source, quiet = TRUE)
stopifnot(!anyDuplicated(g$OBJECTID_1), setequal(intersect(unique(g$GID_0), countries), countries))
g <- g[g$GID_0 %in% countries & g$COUNTRY != "Zanzibar", ]
drop <- (g$GID_0 == "TZA" & g$NAME_1 == "Lakes") | (g$GID_0 == "MLI" & g$NAME_1 == "Bamako" & is.na(g$GID_1))
stopifnot(sum(drop) == 2L)
g <- st_make_valid(g[!drop, c("OBJECTID_1", "GID_0", "COUNTRY", "GID_1", "NAME_1")])

# Capitals cut out of the regions that contain them in the source.
for (k in list(c("ETH.8_1", "ETH.1_1"), c("NER.7_1", "NER.5_1"), c("MLI.5_1", "MLI.1_1"))) {
  i <- which(g$GID_1 == k[1]); j <- which(g$GID_1 == k[2]); stopifnot(length(i) == 1L, length(j) == 1L)
  st_geometry(g)[i] <- st_difference(st_geometry(g)[i], st_geometry(g)[j])
}
# One MULTIPOLYGON per unit (repairs can leave collections with line or point parts).
st_geometry(g) <- st_sfc(lapply(st_geometry(st_make_valid(g)), function(x) {
  if (inherits(x, "GEOMETRYCOLLECTION")) x <- st_union(st_sfc(Filter(function(p) inherits(p, c("POLYGON", "MULTIPOLYGON")), x)))[[1]]
  st_cast(x, "MULTIPOLYGON") }), crs = st_crs(g))
g <- g[order(g$OBJECTID_1), ]
ea <- "ESRI:102022"   # Africa Albers equal area
ov <- suppressWarnings(st_intersection(g[, "OBJECTID_1"], g[, "OBJECTID_1"]))
ov <- ov[ov$OBJECTID_1 < ov$OBJECTID_1.1 & st_dimension(ov) == 2, ]
ov_km2 <- as.numeric(st_area(st_transform(ov, ea))) / 1e6
ov <- as.data.table(st_drop_geometry(ov))[, km2 := ov_km2][km2 > 1]
ov[, `:=`(a = g$GID_0[match(OBJECTID_1, g$OBJECTID_1)], b = g$GID_0[match(OBJECTID_1.1, g$OBJECTID_1)])]
# Overlaps left: border digitising between countries (Lake Malawi, the Zambezi); none within a country.
stopifnot(all(ov$a != ov$b), sum(ov$km2) < 500)

# Ids: GID_1; Zambia's gaps in GADM's alphabetical numbering; country code + normalised name for the rest.
g$id_source <- ifelse(is.na(g$GID_1), NA_character_, "GADM GID_1")
z <- g$GID_0 == "ZMB"
zo <- sort(g$NAME_1[z], method = "radix")
stopifnot(identical(sprintf("ZMB.%d_1", match(g$NAME_1[z & !is.na(g$GID_1)], zo)), g$GID_1[z & !is.na(g$GID_1)]))
zi <- which(z & is.na(g$GID_1)); stopifnot(setequal(g$NAME_1[zi], c("Lusaka", "Southern")))
g$GID_1[zi] <- sprintf("ZMB.%d_1", match(g$NAME_1[zi], zo)); g$id_source[zi] <- "GADM numbering (gap filled)"
nk <- is.na(g$GID_1); stopifnot(setequal(unique(g$GID_0[nk]), c("KEN", "GHA", "TZA")))
g$GID_1[nk] <- paste0(g$GID_0[nk], ".", cbh_rkey(g$NAME_1[nk])); g$id_source[nk] <- "country + name"
stopifnot(!anyDuplicated(g$GID_1), !anyNA(g$GID_1), !any(grepl("[+:|, ]", g$GID_1)))
ids <- data.table(OBJECTID_1 = as.integer(g$OBJECTID_1), GID_0 = g$GID_0, NAME_1 = g$NAME_1, Admin_ID = g$GID_1, id_source = g$id_source)
pin <- "R_cbh/snow/config/gadm_unit_ids.csv"
if (file.exists(pin)) {
  old <- fread(pin, encoding = "UTF-8")
  if (!isTRUE(all.equal(old, ids, check.attributes = FALSE))) stop("Unit ids differ from ", pin, "; review the source file")
} else { fwrite(ids, pin); message("Wrote ", pin, " (new; review and commit)") }

# Type: Snow's malaria-free and island exclusions (own-country pieces, GPW 2020 population), then the MAP mask.
dens <- crop(rast("data/pop/gpw_v4_population_density_rev11_2020_2.5m.tif"), ext(-26, 60, -36, 28))
popc <- dens * cellSize(dens, unit = "km")
g$pop <- exact_extract(popc, g, "sum", progress = FALSE)
pcs <- suppressWarnings(st_intersection(g[, c("GID_0", "GID_1")], snow[, c("Country_ID", "Type")]))
pcs <- pcs[st_dimension(pcs) == 2 & pcs$GID_0 == pcs$Country_ID, ]
pcs$pop <- exact_extract(popc, pcs, "sum", progress = FALSE)
sh <- dcast(as.data.table(st_drop_geometry(pcs))[, .(pop = sum(pop)), by = .(GID_1, Type)][, share := pop / sum(pop), by = GID_1],
            GID_1 ~ Type, value.var = "share", fill = 0)
setnames(sh, c("Endemic", "Malaria free", "Island"), c("snow_endemic", "snow_malaria_free", "snow_island"))
stopifnot(setequal(sh$GID_1, g$GID_1))
rf <- list.files(cbh_config()$map_raster_dir, pattern = "pfpr2_10_2024[.]tif$", full.names = TRUE); stopifnot(length(rf) == 1L)
m24 <- rast(rf)
w <- resample(crop(rast("data/pop/gpw_v4_population_density_rev11_2020_2.5m.tif"), m24), m24, method = "bilinear")
w <- w * cellSize(w, unit = "km")
v <- makeValid(vect(st_transform(g, crs(m24))))
all_w <- extract(w, v, fun = sum, na.rm = TRUE, exact = TRUE, ID = FALSE)[[1]]
map_w <- extract(mask(w, m24), v, fun = sum, na.rm = TRUE, exact = TRUE, ID = FALSE)[[1]]
tab <- merge(data.table(GID_1 = g$GID_1, OBJECTID_1 = as.integer(g$OBJECTID_1), GID_0 = g$GID_0, NAME_1 = g$NAME_1,
                        id_source = g$id_source, area_km2 = as.numeric(st_area(st_transform(g, ea))) / 1e6, population_2020 = g$pop,
                        map_population_share = map_w / all_w), sh, by = "GID_1")
tab[, no_map := !(fcoalesce(map_population_share, 0) > 0)]   # the extraction gives NA where no cell has a value
tab[, Type := fcase(snow_island > 0.5, "Island", snow_malaria_free > 0.5 | no_map, "Malaria free", default = "Endemic")]
tab[, type_reason := fcase(Type == "Island", "Snow island", Type == "Endemic", "",
  snow_malaria_free > 0.5 & no_map, "Snow malaria free; no MAP estimate", snow_malaria_free > 0.5, "Snow malaria free",
  default = "no MAP estimate")]
g$Type <- tab$Type[match(g$GID_1, tab$GID_1)]
out <- st_sf(Admin_ID = g$GID_1, Country_ID = g$GID_0, AFR_Admin = g$NAME_1, Type = g$Type, geometry = st_geometry(g))
if (file.exists(S$shapefile)) file.remove(S$shapefile)
st_write(out, S$shapefile, quiet = TRUE)
fwrite(tab[order(GID_0, GID_1)], file.path(S$out, "polygons", "gadm_layer.csv"))
cat(sprintf("%s: %d units in %d countries (%d endemic, %d malaria free [%d Snow, %d no MAP estimate only], %d island); ids: %s\n",
  S$variant, nrow(tab), uniqueN(tab$GID_0), sum(tab$Type == "Endemic"), sum(tab$Type == "Malaria free"),
  sum(tab$type_reason %like% "^Snow malaria"), sum(tab$type_reason == "no MAP estimate"), sum(tab$Type == "Island"),
  paste(tab[, .N, by = id_source][, sprintf("%s %d", id_source, N)], collapse = ", ")))
