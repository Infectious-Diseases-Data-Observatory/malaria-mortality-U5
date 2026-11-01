#!/usr/bin/env Rscript
# Place every eligible child-band record in the 520 Snow polygons (rules in R_cbh/snow/R/placement.R; ported from the
# analysis project's R_cbh/snow_units/05_placement.R). Eligible records are the shards' rows whose survey-region is
# matched; national covariates come from the shards and the child HIV incidence panel of the primary settings, as in v9.
# Writes: <out>/placement/finer_unit_shares.csv and placement_summary.csv (aggregates);
#         <private>/records_placed.rds (record level; private, under the ignored data/).
suppressPackageStartupMessages({ library(data.table); library(sf); library(terra); library(exactextractr); library(haven) })
sf_use_s2(FALSE)
source("R_cbh/load_pipeline.R"); source("R_cbh/analysis/model.R"); source("R_cbh/primary/settings.R")
source("R_cbh/snow/R/settings.R"); source("R_cbh/snow/R/placement.R")
S <- snow_dirs(snow_settings(), "placement"); pout <- file.path(S$out, "placement")
settings <- cbh_primary_settings("snow_merge")   # child HIV incidence panel
registry <- fread("data/derived_dhs/survey_registry.csv"); setup <- fread("data/derived_mics/survey_setup.csv")
cls <- fread(file.path(S$out, "feasibility", "region_classification.csv"))
surveys <- intersect(snow_all_shards(), cls$survey)

# 1. Population shares of finer units that are themselves split ("geometry: split").
snow <- readRDS(file.path(S$private, "polygons_551.rds"))[, c("Admin_ID", "Country_ID", "Type", "in520")]
dens <- crop(rast("data/pop/gpw_v4_population_density_rev11_2020_2.5m.tif"), ext(-26, 60, -36, 28))
popc <- dens * cellSize(dens, unit = "km")
cw <- fread(file.path(S$out, "feasibility", "finer_unit_crosswalk.csv"))
gs <- cw[method == "geometry: split" & survey %in% surveys]
fs <- rbindlist(lapply(unique(gs$survey), function(s) {
  bf <- unique(gs[survey == s, boundary]); stopifnot(length(bf) == 1L)
  b <- st_make_valid(readRDS(file.path("data/dhs_boundaries", bf))); b$key <- cbh_rkey(b$DHSREGEN)
  b <- st_transform(b[b$key %in% gs[survey == s, key] & !duplicated(b$key), "key"], 4326)
  b <- suppressWarnings(st_cast(st_collection_extract(b, "POLYGON"), "MULTIPOLYGON"))
  iso <- cls[survey == s, country[1]]   # own-country polygons only (see placement.R)
  pcs <- suppressWarnings(st_intersection(b, snow[snow$Country_ID == iso, ])); pcs <- pcs[st_dimension(pcs) == 2, ]
  pcs$pop <- exact_extract(popc, pcs, "sum", progress = FALSE)
  p <- as.data.table(st_drop_geometry(pcs))[, .(pop = sum(pop)), by = .(key, Admin_ID, in520)][, share := pop / sum(pop), by = key]
  snow_shares(p[, .(unit = key, Admin_ID, in520, share)], S)[, .(survey = s, key = unit, Admin_ID, w)]
}))
if (!nrow(fs)) fs <- data.table(survey = character(), key = character(), Admin_ID = character(), w = numeric())
fwrite(fs, file.path(pout, "finer_unit_shares.csv"))
R <- snow_rules(S)

# 2. Base records: eligible rows of the shards, with the national covariates of v9.
hiv <- cbh_read_csv(settings$hiv_panel)
keep <- c("child_id", "survey", "country", "survey_year", "age_band", "age_band_index", "death", "band_years", "calendar_year",
          "entry_year", "regkey", "region", "log_gdp_pc", "log_health_expenditure_pc", "political_stability", "log_hiv_incidence",
          "hiv_incidence_status")
finer_key <- function(s, rows) {   # chosen finer variable of a split survey, at the records' recode rows
  v <- R$choice[survey == s, variable]
  if (!length(v)) return(rep(NA_character_, length(rows)))
  x <- if (startsWith(s, "MC_")) { z <- read_sav(file.path("data/raw/MICS_extracted", setup[svkey == s, folder], "bh.sav"), col_select = all_of(v))[[1]]
    if (is.labelled(z)) as.character(as_factor(z)) else as.character(z) } else as.character(readRDS(registry[svkey == s, local_recode][1])[[v]])
  snow_clean_key(x[rows])
}
pieces <- list(); summ <- list()
for (s in surveys) {
  d <- as.data.table(cbh_attach_incidence(readRDS(snow_shard_path(s))$data, hiv))
  d <- d[snow_eligible(d), ..keep]
  d[, c("survey", "country", "region", "regkey") := lapply(.SD, as.character), .SDcols = c("survey", "country", "region", "regkey")]
  kids <- unique(d[, .(child_id, survey, regkey)])
  kids[, `:=`(id = child_id, finer_key = finer_key(s, as.integer(sub(".*:c:", "", child_id))))]
  pl <- snow_place(kids[, .(id, survey, regkey, finer_key)], R)
  stopifnot(all(pl$w > 0 & pl$w <= 1), pl[, sum(w), by = id]$V1 <= 1 + 1e-9)
  x <- merge(d, pl, by.x = "child_id", by.y = "id", allow.cartesian = TRUE)
  pieces[[s]] <- x
  summ[[s]] <- data.table(survey = s, records = nrow(d), deaths = sum(d$death), weighted_records = sum(x$w), weighted_deaths = sum(x$w * x$death),
    rows = nrow(x), polygons = uniqueN(x$Admin_ID), excluded_records = nrow(d) - nrow(d[child_id %in% pl$id]),
    x[, .(r = sum(w)), by = rule][, setNames(as.list(r), rule)])
  if (match(s, surveys) %% 20 == 0) message(match(s, surveys), "/", length(surveys), " surveys placed")
}
recs <- rbindlist(pieces); summ <- rbindlist(summ, fill = TRUE)
for (v in names(summ)) if (is.numeric(summ[[v]])) summ[is.na(get(v)), (v) := 0]
saveRDS(recs, file.path(S$private, "records_placed.rds"))
fwrite(summ, file.path(pout, "placement_summary.csv"))
tot <- summ[, lapply(.SD, sum), .SDcols = is.numeric]
cat(sprintf("%s, %d surveys: %s eligible records (%s deaths); placed weight %s records (%.1f%%), %s deaths; %s rows in %d polygons\n", S$variant,
  length(surveys), format(tot$records, big.mark = ","), format(tot$deaths, big.mark = ","), format(round(tot$weighted_records), big.mark = ","),
  100 * tot$weighted_records / tot$records, format(round(tot$weighted_deaths), big.mark = ","), format(tot$rows, big.mark = ","), uniqueN(recs$Admin_ID)))
