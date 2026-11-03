#!/usr/bin/env Rscript
# Overlay of every survey-region of the eligible child-band records on the GADM admin-1 units. For each survey-region
# (DHS boundary file, DHSREGEN; MICS analysis-region file), the share of its population (GPW v4 2020 density x cell
# area) in each of the 568 units (535 endemic + 31 malaria-free + 2 island), and its class: inside one unit (>= 90% of
# its population in one endemic unit), inside a malaria-free/island unit, split across units, or no polygon (Comoros,
# Zanzibar, Sao Tome and Principe, outside the layer). Reviewed survey-regions split only by digitising differences are
# placed wholly in the unit they name (S$region_overrides). Regions: every survey-region with eligible records in the
# child-band shards (all 166 MAP-eligible surveys).
# Output: <out>/feasibility/{region_unit_overlap,region_classification,survey_feasibility}.csv (aggregates)
suppressPackageStartupMessages({ library(data.table); library(sf); library(terra); library(exactextractr) })
sf_use_s2(FALSE)
source("R_cbh/R/geography.R"); source("R_cbh/units/R/settings.R")
S <- units_dirs(units_settings(), "feasibility"); out <- file.path(S$out, "feasibility")
layer <- readRDS(units_polygons_path(S))[, c("Admin_ID", "Country_ID", "AFR_Admin", "Type", "endemic")]

# Survey-regions and their eligible records. Feasibility covers every built shard so that the unit construction
# does not depend on which surveys a sample later keeps.
reg <- rbindlist(lapply(units_all_shards(), function(s) {
  d <- as.data.table(readRDS(units_shard_path(s))$data[, c("survey", "country", "region", "regkey", "death")])
  d <- d[units_eligible(d)]
  d[, c("survey", "country", "region", "regkey") := lapply(.SD, as.character), .SDcols = c("survey", "country", "region", "regkey")]
  d[, .(records = .N, deaths = sum(death)), by = .(survey, country, region, regkey)]
}))
registry <- fread("data/derived_dhs/survey_registry.csv")
reg[, programme := ifelse(startsWith(survey, "MC_"), "MICS", "DHS")]

# Polygon of each survey-region: DHS boundary file (DHSREGEN) or the MICS analysis-region file.
polys <- do.call(rbind, lapply(unique(reg$survey), function(s) {
  f <- if (startsWith(s, "MC_")) sprintf("data/derived_mics/boundaries/%s.rds", s) else registry[svkey == s, boundary_file][1]
  b <- st_make_valid(readRDS(f)); b$regkey <- cbh_rkey(b$DHSREGEN); b$survey <- s
  want <- reg[survey == s, regkey]
  b <- b[b$regkey %in% want, ]
  if (!all(want %in% b$regkey)) warning(s, ": regions without a polygon: ", paste(setdiff(want, b$regkey), collapse = ", "))
  b <- st_sf(survey = s, regkey = b$regkey, geometry = st_geometry(st_transform(b, 4326)))
  suppressWarnings(st_cast(st_collection_extract(b, "POLYGON"), "MULTIPOLYGON"))
}))
stopifnot(!anyDuplicated(paste(polys$survey, polys$regkey)))
reg[, has_polygon := paste(survey, regkey) %in% paste(polys$survey, polys$regkey)]

# Population counts: GPW density x cell area.
dens <- rast("data/pop/gpw_v4_population_density_rev11_2020_2.5m.tif")
dens <- crop(dens, ext(-26, 60, -36, 28))
popc <- dens * cellSize(dens, unit = "km")
pieces <- suppressWarnings(st_intersection(polys, layer))
pieces <- pieces[st_dimension(pieces) == 2, ]
pieces$pop <- exact_extract(popc, pieces, "sum", progress = FALSE)
pieces$area_km2 <- as.numeric(st_area(st_transform(pieces, "ESRI:102022"))) / 1e6
polys$pop_total <- exact_extract(popc, polys, "sum", progress = FALSE)
pc <- as.data.table(st_drop_geometry(pieces))[, .(survey, regkey, Admin_ID, Country_ID, AFR_Admin, Type, endemic, pop, area_km2)]
pc <- merge(pc, as.data.table(st_drop_geometry(polys))[, .(survey, regkey, pop_total)], by = c("survey", "regkey"))
pc[, share := pop / sum(pop), by = .(survey, regkey)]
pc[, covered := sum(pop) / pop_total, by = .(survey, regkey)]
setorder(pc, survey, regkey, -share)
fwrite(pc, file.path(out, "region_unit_overlap.csv"))

# Per survey-region classification.
top <- pc[, .(top_admin = Admin_ID[1], top_name = AFR_Admin[1], top_type = Type[1], top_endemic = endemic[1], top_share = share[1],
              n_polygons_5pct = sum(share >= 0.05), covered = covered[1]), by = .(survey, regkey)]
reg <- merge(reg, top, by = c("survey", "regkey"), all.x = TRUE)
reg[, class := fcase(!has_polygon | is.na(top_share), "no polygon",
                     top_share >= 0.95 & top_endemic, "inside one unit (>=95%)",
                     top_share >= S$whole & top_endemic, "inside one unit (90-95%)",
                     top_share >= S$whole & !top_endemic, "inside a malaria-free/island unit",
                     default = "split across units")]
# Reviewed overrides (S$region_overrides): a survey-region that names a unit whose boundary has not changed, but is
# split by digitising differences between the survey's boundary file and the layer, is placed wholly in that unit. The
# class keeps the "inside one unit" key that the placement matches.
ovr <- fread(S$region_overrides); reg[, override := ""]
k <- match(paste(ovr$survey, ovr$regkey), paste(reg$survey, reg$regkey))
stopifnot(!anyNA(k), !anyDuplicated(k), all(ovr$Admin_ID %in% layer$Admin_ID[layer$endemic]),
          all(reg$class[k] == "split across units"), all(reg$country[k] == substr(ovr$Admin_ID, 1, 3)))
# The named unit must hold a real share of the region (not a unit elsewhere in the country).
sh <- pc[, .(survey, regkey, Admin_ID, share)][ovr[, .(survey, regkey, Admin_ID)], on = c("survey", "regkey", "Admin_ID")]
stopifnot(all(sh$share >= 0.15))
reg[k, `:=`(top_admin = ovr$Admin_ID, top_name = layer$AFR_Admin[match(ovr$Admin_ID, layer$Admin_ID)], top_type = "Endemic",
            top_endemic = TRUE, top_share = sh$share, class = "inside one unit (reviewed override)", override = ovr$note)]
fwrite(reg[order(survey, regkey)], file.path(out, "region_classification.csv"))
by_survey <- reg[, .(programme = programme[1], country = country[1], survey_regions = .N, records = sum(records),
                     pct_records_assignable = round(100 * sum(records[class %like% "^inside one unit"]) / sum(records), 1),
                     pct_records_split = round(100 * sum(records[class == "split across units"]) / sum(records), 1),
                     pct_records_malaria_free = round(100 * sum(records[class == "inside a malaria-free/island unit"]) / sum(records), 1),
                     units_reached = uniqueN(top_admin[class %like% "^inside one unit"])), by = survey][order(pct_records_assignable)]
fwrite(by_survey, file.path(out, "survey_feasibility.csv"))
print(reg[, .(survey_regions = .N, records = sum(records)), by = class][order(-records)])
cat(sprintf("%s: %d surveys, %d survey-regions\n", S$units, uniqueN(reg$survey), nrow(reg)))
