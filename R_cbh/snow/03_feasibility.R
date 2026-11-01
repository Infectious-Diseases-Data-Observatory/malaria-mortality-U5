#!/usr/bin/env Rscript
# Overlay of every survey-region of the eligible child-band records on the Snow et al. polygons (ported from the
# analysis project's R_cbh/snow_units/01_feasibility.R). For each survey-region (DHS boundary file, DHSREGEN; MICS
# analysis-region file), the share of its population (GPW v4 2020 density x cell area) in each of the 551
# sub-Saharan Snow polygons (520 endemic + 29 malaria-free + 2 island), and its class: inside one of the 520
# (>= 90% of its population in one polygon), inside a malaria-free/island unit, split across polygons, or no
# polygon (Comoros, Zanzibar, Sao Tome and Principe). Regions: every survey-region with eligible records in the
# child-band shards of the variant's survey universe (all 166 MAP-eligible surveys; the reproduction uses the
# model_ready rows, as the analysis project did with its v10 sample). The in_v9 column (regions of the v9 primary) was
# dropped with v9 on 1 November 2026.
# Output: <out>/feasibility/{region_snow_overlap,region_classification,survey_feasibility}.csv (aggregates)
suppressPackageStartupMessages({ library(data.table); library(sf); library(terra); library(exactextractr) })
sf_use_s2(FALSE)
source("R_cbh/R/geography.R"); source("R_cbh/snow/R/settings.R")
S <- snow_dirs(snow_settings(), "feasibility"); out <- file.path(S$out, "feasibility")
snow <- readRDS(file.path(S$private, "polygons_551.rds"))[, c("Admin_ID", "Country_ID", "AFR_Admin", "Type", "in520")]

# Survey-regions and their eligible records. Feasibility covers every built shard so that the unit construction
# does not depend on which surveys a sample later keeps (the reproduction as in the analysis project).
reg <- rbindlist(lapply(snow_all_shards(), function(s) {
  d <- as.data.table(readRDS(snow_shard_path(s))$data[, c("survey", "country", "region", "regkey", "death", "model_ready")])
  d <- d[snow_eligible(d, S)]
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
pieces <- suppressWarnings(st_intersection(polys, snow))
pieces <- pieces[st_dimension(pieces) == 2, ]
pieces$pop <- exact_extract(popc, pieces, "sum", progress = FALSE)
pieces$area_km2 <- as.numeric(st_area(st_transform(pieces, "ESRI:102022"))) / 1e6
polys$pop_total <- exact_extract(popc, polys, "sum", progress = FALSE)
pc <- as.data.table(st_drop_geometry(pieces))[, .(survey, regkey, Admin_ID, Country_ID, AFR_Admin, Type, in520, pop, area_km2)]
pc <- merge(pc, as.data.table(st_drop_geometry(polys))[, .(survey, regkey, pop_total)], by = c("survey", "regkey"))
pc[, share := pop / sum(pop), by = .(survey, regkey)]
pc[, covered := sum(pop) / pop_total, by = .(survey, regkey)]
setorder(pc, survey, regkey, -share)
fwrite(pc, file.path(out, "region_snow_overlap.csv"))

# Per survey-region classification.
top <- pc[, .(top_admin = Admin_ID[1], top_name = AFR_Admin[1], top_type = Type[1], top_in520 = in520[1], top_share = share[1],
              n_polygons_5pct = sum(share >= 0.05), covered = covered[1]), by = .(survey, regkey)]
reg <- merge(reg, top, by = c("survey", "regkey"), all.x = TRUE)
reg[, class := fcase(!has_polygon | is.na(top_share), "no polygon",
                     top_share >= 0.95 & top_in520, "inside one of the 520 (>=95%)",
                     top_share >= S$whole & top_in520, "inside one of the 520 (90-95%)",
                     top_share >= S$whole & !top_in520, "inside a malaria-free/island unit",
                     default = "split across Snow polygons")]
fwrite(reg[order(survey, regkey)], file.path(out, "region_classification.csv"))
by_survey <- reg[, .(programme = programme[1], country = country[1], survey_regions = .N, records = sum(records),
                     pct_records_assignable = round(100 * sum(records[class %like% "^inside one of the 520"]) / sum(records), 1),
                     pct_records_split = round(100 * sum(records[class == "split across Snow polygons"]) / sum(records), 1),
                     pct_records_malaria_free = round(100 * sum(records[class == "inside a malaria-free/island unit"]) / sum(records), 1),
                     snow_polygons_reached = uniqueN(top_admin[class %like% "^inside one of the 520"])), by = survey][order(pct_records_assignable)]
fwrite(by_survey, file.path(out, "survey_feasibility.csv"))
print(reg[, .(survey_regions = .N, records = sum(records)), by = class][order(-records)])
cat(sprintf("%s: %d surveys, %d survey-regions\n", S$variant, uniqueN(reg$survey), nrow(reg)))
