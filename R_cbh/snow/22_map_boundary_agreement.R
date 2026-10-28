#!/usr/bin/env Rscript
# Supplementary map: agreement between the survey-regions of the DHS and MICS files and the Snow et al. (2017)
# polygons, for the most recent survey of the Snow primary sample in each country (ported from the analysis project's
# 16_map_boundary_agreement.R). Survey-regions are classified with GPW 2020 population (03_feasibility.R overlay):
#   a = share of the region's population in its best-matching Snow polygon p; b = share of p's population in the region.
#   Same area: a >= 0.9 and b >= 0.9. Region inside a larger Snow polygon: a >= 0.9, b < 0.9. Snow polygons nested in
#   the region: a < 0.9 and every polygon holding >= 5% of the region has >= 90% of its population in it. Boundaries
#   cross: the other a < 0.9 cases. Malaria-free or island unit; no Snow polygon (Comoros, Zanzibar, Sao Tome).
# Output: <out>/maps/boundary_agreement_map.png, boundary_agreement_regions.csv, CAPTION_boundary_agreement_map.md
suppressPackageStartupMessages({ library(data.table); library(sf); library(terra); library(exactextractr); library(ggplot2) })
sf_use_s2(FALSE)
source("R_cbh/R/geography.R"); source("R_cbh/snow/R/settings.R"); source("R_cbh/primary/settings.R")
S <- snow_settings(); P <- cbh_primary_settings("snow_merge")
out <- file.path(S$out, "maps"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
fea <- file.path(S$out, "feasibility")
north <- c("DZA", "EGY", "LBY", "MAR", "TUN", "ESH")
snow <- readRDS(file.path(S$private, "polygons_551.rds"))
snow <- st_make_valid(snow[!snow$Country_ID %in% north, c("Admin_ID", "Country_ID", "AFR_Admin", "Type")])
stopifnot(nrow(snow) == 551L, sum(snow$Type == "Endemic") == 520L)

## Classification of every survey-region of the sample ----------------------------------------------------------------------
# Survey-regions of the surveys in the Snow primary sample.
sample_surveys <- fread(file.path(P$out, "prepared_selection_by_survey.csv"))[records > 0, survey]
rc <- fread(file.path(fea, "region_classification.csv"))[survey %in% sample_surveys | country %in% c("COM")]
ov <- fread(file.path(fea, "region_snow_overlap.csv"))[paste(survey, regkey) %in% paste(rc$survey, rc$regkey)]
snow_pop <- fread(file.path(S$out, "polygons", "polygons.csv"))[, .(Admin_ID, poly_pop = population_2020)]   # 01_polygons.R
ov <- merge(ov, snow_pop, by = "Admin_ID")
ov[, b := pop / poly_pop]
setorder(ov, survey, regkey, -share)
cls <- ov[, {
  a <- share[1]; nested <- all(b[share >= 0.05] >= 0.9)
  .(top_admin = Admin_ID[1], top_name = AFR_Admin[1], a = a, b_top = b[1], n_polygons_5pct = sum(share >= 0.05),
    class = fcase(a >= 0.9 & !in520[1], "Malaria-free or island unit",
                  a >= 0.9 & b[1] >= 0.9, "Same area",
                  a >= 0.9, "Region inside a larger Snow polygon",
                  nested, "Snow polygons nested in the region",
                  default = "Boundaries cross"))
}, by = .(survey, regkey)]
rc <- merge(rc[, .(survey, regkey, country, region, programme, records_v10 = records)], cls, by = c("survey", "regkey"), all.x = TRUE)
rc[is.na(class), class := "No Snow polygon"]
stopifnot(all(rc[class == "No Snow polygon", country %in% c("COM", "STP") | regkey == "zanzibar"]))   # no polygon in the shapefile
pop_r <- unique(fread(file.path(fea, "region_snow_overlap.csv"))[, .(survey, regkey, pop_total)])
rc <- merge(rc, pop_r, by = c("survey", "regkey"), all.x = TRUE)
# Records of the Snow primary sample by source survey-region.
d <- as.data.table(readRDS(P$data)$data[, c("survey", "regkey")])
d <- d[, .(records_sample = .N), by = .(survey = as.character(survey), regkey)]; invisible(gc())
rc <- merge(rc, d, by = c("survey", "regkey"), all.x = TRUE)[is.na(records_sample), records_sample := 0L]

# Most recent sample survey per country (DHS year from the registry; MICS year from the survey id).
registry <- fread("data/derived_dhs/survey_registry.csv")
yr <- registry[, .(year = max(year)), by = .(survey = svkey)]
sv <- unique(rc[, .(survey, country, programme)])
sv <- merge(sv, yr, by = "survey", all.x = TRUE)
sv[programme == "MICS", year := as.integer(regmatches(survey, regexpr("[0-9]{4}", survey)))]
stopifnot(!anyNA(sv$year))
latest <- sv[order(country, -year, -(programme == "DHS"))][, .SD[1], by = country]
rc[, mapped := survey %in% latest$survey]
fwrite(rc[order(country, survey, regkey)], file.path(out, "boundary_agreement_regions.csv"))

## Geometries of the mapped surveys --------------------------------------------------------------------------------
polys <- do.call(rbind, lapply(latest$survey, function(s) {
  f <- if (startsWith(s, "MC_")) sprintf("data/derived_mics/boundaries/%s.rds", s) else registry[svkey == s, boundary_file][1]
  b <- st_make_valid(readRDS(f)); b$regkey <- cbh_rkey(b$DHSREGEN)
  want <- rc[survey == s, regkey]
  stopifnot(all(want %in% b$regkey))   # regions of the boundary file outside the Snow primary sample are kept and shown as such
  b <- st_sf(survey = s, regkey = b$regkey, geometry = st_geometry(st_transform(b, 4326)))
  suppressWarnings(st_cast(st_collection_extract(b, "POLYGON"), "MULTIPOLYGON"))
}))
polys <- merge(polys, rc[, .(survey, regkey, class)], by = c("survey", "regkey"), all.x = TRUE)
not_in <- as.data.table(st_drop_geometry(polys))[is.na(class), .(survey, regkey)]
print(not_in)
polys$class[is.na(polys$class)] <- "Survey-region not in the sample"
levels_all <- c("Same area", "Region inside a larger Snow polygon", "Snow polygons nested in the region", "Boundaries cross",
                "Malaria-free or island unit", "No Snow polygon", "Survey-region not in the sample")
polys$class <- factor(polys$class, levels_all)
fills <- setNames(c("#1B7A5A", "#9FD3B6", "#F2B134", "#C8553D", "#BDB8AD", "#8C8C8C", "#FFFFFF"), levels_all)

adm0 <- st_make_valid(readRDS("data/africa_admin0.rds")); adm0 <- adm0[adm0$iso %in% snow$Country_ID, ]
crs_aea <- "ESRI:102022"
snow_p <- st_transform(snow, crs_aea); adm0_p <- st_transform(adm0, crs_aea); polys_p <- st_transform(polys, crs_aea)
bb <- st_bbox(snow_p)
lines <- c(region = "Survey-region boundary\n(most recent survey)", snow = "Snow et al. polygon boundary")
fig <- ggplot() +
  geom_sf(data = adm0_p, fill = "#E4E4E4", colour = NA) +   # countries without a sample survey
  geom_sf(data = polys_p, aes(fill = class), colour = NA) +
  geom_sf(data = polys_p, aes(colour = lines[["region"]]), fill = NA, linewidth = 0.55, key_glyph = "path") +
  geom_sf(data = snow_p, aes(colour = lines[["snow"]]), fill = NA, linewidth = 0.12, key_glyph = "path") +
  geom_sf(data = adm0_p, fill = NA, colour = "grey10", linewidth = 0.3) +
  scale_fill_manual(values = fills, drop = FALSE, name = "Survey-region against\nSnow polygons") +
  scale_colour_manual(values = setNames(c("white", "grey15"), lines), breaks = unname(lines), name = NULL,   # region line first
                      guide = guide_legend(order = 2, override.aes = list(linewidth = c(1.2, 0.4)),
                                           theme = theme(legend.key = element_rect(fill = "grey70", colour = NA)))) +
  guides(fill = guide_legend(order = 1, override.aes = list(colour = c(rep(NA, 6), "grey45"), linewidth = 0.3))) +   # outline the white key
  coord_sf(xlim = bb[c("xmin", "xmax")], ylim = bb[c("ymin", "ymax")], expand = FALSE, datum = NA) +
  # Sizes meet the paper's printed text-size rule (CLAUDE.md) at 6.5 in: printed = size x 165 / 160; legend in the
  # Atlantic, bottom left.
  theme_void(base_size = 10) +
  theme(legend.position = "inside", legend.position.inside = c(0.01, 0.01), legend.justification.inside = c(0, 0),
        legend.title = element_text(size = 12), legend.text = element_text(size = 10),
        legend.key.size = unit(4.6, "mm"), legend.spacing.y = unit(2, "mm"),
        plot.caption = element_text(size = 7, colour = "grey30", hjust = 0.5),
        plot.background = element_rect(fill = "white", colour = NA))
ggsave(file.path(out, "boundary_agreement_map.png"), fig, width = 160, height = 170, units = "mm", dpi = 600,
       device = ragg::agg_png, bg = "white")

## Caption -------------------------------------------------------------------------------------------------------
tab <- function(z, w) z[, .(regions = .N, w = sum(get(w), na.rm = TRUE)), by = class][, pct := 100 * w / sum(w)][
  match(levels_all, class)][!is.na(class)]
tm <- tab(rc[mapped == TRUE], "pop_total"); ta <- tab(rc, "records_sample")   # population for one survey per country; records across surveys
fmt <- function(t, what) paste(sprintf("%s %d%s", sub("snow", "Snow", tolower(t$class)), t$regions,
  fifelse(t$w > 0, sprintf(" (%.0f%% of %s)", t$pct, what), "")), collapse = "; ")
print(tm); print(ta)
writeLines(c("# Survey-regions against the Snow et al. polygons", "",
  sprintf(paste("Agreement between the survey-regions used in the analysis and the Snow et al. (2017) polygons, for the most recent survey of the Snow primary sample in each of %d countries (%d survey-regions; DHS boundary files and MICS analysis regions).",
    "Survey-regions are coloured by how they relate to the Snow polygons, using GPW 2020 population.",
    "Same area: at least 90%% of the region's population lies in one Snow polygon, and at least 90%% of that polygon's population lies in the region.",
    "Region inside a larger Snow polygon: at least 90%% of the region lies in one polygon that also covers other regions.",
    "Snow polygons nested in the region: the region spans several polygons, each lying (at least 90%%) within it.",
    "Boundaries cross: the region spans several polygons and at least one of them extends well beyond it.",
    "White lines are survey-region boundaries and thin dark lines Snow polygon boundaries; country borders are black.",
    "Malaria-free and island units are the 31 Snow units outside the 520; the shapefile has no polygon for the Comoros, Zanzibar or São Tomé and Príncipe. Countries without a survey in the sample are light grey; white areas are regions of a mapped survey that are not in the sample (%s).",
    "Mapped survey-regions: %s.",
    "Across the %d survey-regions of all %d sample surveys: %s.",
    "Mapped surveys: %s."),
    nrow(latest), sum(rc$mapped), paste(not_in[, sprintf("%s %s", survey, regkey)], collapse = ", "), fmt(tm, "population"), nrow(rc), uniqueN(rc$survey), fmt(ta, "child-band records"),
    paste(sprintf("%s %s %d", latest$country, latest$programme, latest$year), collapse = ", "))),
  file.path(out, "CAPTION_boundary_agreement_map.md"))
