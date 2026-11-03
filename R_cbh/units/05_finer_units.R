#!/usr/bin/env Rscript
# Can a finer location variable place the records of split survey-regions inside single units? For each survey with
# records in split survey-regions (03_feasibility.R), every finer candidate variable from 04_location_variables.R (more
# values than the survey has regions, values with names) is matched:
#   geometry: to the region polygons of any local DHS boundary file of the same country (keys as in the child-band
#             builder); a matched unit is placed if >= 90% of its GPW 2020 population lies in one endemic unit;
#   names:    otherwise, to a unit name in the same country, whole name ("name") or one part of a combined name split at
#             ",", "&", " and " or "/" ("name part"), then to the reviewed spelling aliases (S$aliases,
#             config/name_aliases.csv; "alias"; an alias to a malaria-free unit counts as malaria-free).
# The variable placing the most records is kept. Records are the eligible child-band records of the shards, linked to
# their recode row through child_id (survey:c:<row>), which holds for DHS and MICS.
# Reviewed fixes: variables describing a previous residence or a health facility are never location variables
# (config/finer_variable_exclusions.csv: UG7BFL s104; MZ41FL s321, s321d, s321p), and a variable that places no record
# is not chosen (its records use their survey-region).
# Output: <out>/feasibility/finer_{variable_choice,unit_crosswalk}.csv, record_placement_by_region.csv,
#         survey_feasibility_final_all.csv (aggregates)
suppressPackageStartupMessages({ library(data.table); library(sf); library(terra); library(exactextractr); library(haven) })
sf_use_s2(FALSE)
source("R_cbh/R/geography.R"); source("R_cbh/units/R/settings.R"); source("R_cbh/units/R/placement.R")
S <- units_settings(); out <- file.path(S$out, "feasibility")
layer <- readRDS(units_polygons_path(S))[, c("Admin_ID", "Country_ID", "AFR_Admin", "Type", "endemic")]
cls <- fread(file.path(out, "region_classification.csv"))
inv <- fread(file.path(out, "location_variables.csv"))
registry <- fread("data/derived_dhs/survey_registry.csv")
setup <- fread("data/derived_mics/survey_setup.csv")
dens <- crop(rast("data/pop/gpw_v4_population_density_rev11_2020_2.5m.tif"), ext(-26, 60, -36, 28))
popc <- dens * cellSize(dens, unit = "km")
excl <- fread("R_cbh/units/config/finer_variable_exclusions.csv")

# Population share of each finer-unit polygon in each unit of the layer; returns the largest share and its unit.
overlay <- function(p) {
  p <- suppressWarnings(st_cast(st_collection_extract(st_make_valid(p), "POLYGON"), "MULTIPOLYGON"))
  pcs <- suppressWarnings(st_intersection(p, layer)); pcs <- pcs[st_dimension(pcs) == 2, ]
  pcs$pop <- exact_extract(popc, pcs, "sum", progress = FALSE)
  x <- as.data.table(st_drop_geometry(pcs))[, share := pop / sum(pop), by = key]
  x[order(-share), .(top_admin = Admin_ID[1], top_endemic = endemic[1], top_share = share[1]), by = key]
}
unit_names <- as.data.table(st_drop_geometry(layer))[, .(Admin_ID, Country_ID, endemic, whole = cbh_rkey(AFR_Admin), AFR_Admin)]
parts <- unit_names[, .(part = cbh_rkey(trimws(unlist(strsplit(AFR_Admin, ",|&| and |/"))))), by = .(Admin_ID, Country_ID, endemic)][nzchar(part)]
aliases <- fread(S$aliases)
aliases <- merge(aliases, unit_names[, .(country = Country_ID, unit_name = AFR_Admin, Admin_ID, endemic)], by = c("country", "unit_name"))
stopifnot(nrow(aliases) == nrow(fread(S$aliases)))

# Eligible records of every shard (one row per child: records = number of its child-band records).
rd <- rbindlist(lapply(cls[, unique(survey)], function(s) {
  d <- as.data.table(readRDS(units_shard_path(s))$data[, c("survey", "regkey", "region", "child_id")])
  d <- d[units_eligible(d)]
  d[, c("survey", "regkey", "child_id") := lapply(.SD, as.character), .SDcols = c("survey", "regkey", "child_id")]
  d[, .(records = .N), by = .(survey, regkey, child_id)]
}))
setorder(rd, child_id)   # child_id order, as when the v9 counts were merged in (keeps the crosswalk's row order)
rd[, row := as.integer(sub(".*:c:", "", child_id))]
rd <- merge(rd, cls[, .(survey, regkey, class)], by = c("survey", "regkey"))
split_surveys <- cls[class == "split across units", unique(survey)]
skip <- "lived before|circumcis|fistula|unicef|cluster|ward|locality|parish|moved|previous|lived in"

choice <- list(); crosswalk <- list(); placement <- list()
for (s in split_surveys) {
  iso <- cls[survey == s, country[1]]
  cand <- inv[survey == s & n_values > survey_regions & n_values <= 400 & !grepl(skip, label, ignore.case = TRUE) &
              grepl("[a-z]", examples, ignore.case = TRUE) & !variable %in% excl[survey == s, variable]]
  cand <- cand[!duplicated(variable)]
  if (!nrow(cand)) { choice[[s]] <- data.table(survey = s, variable = NA_character_, note = "no finer named variable"); next }
  x <- rd[survey == s]
  # A MICS variable inventoried only in hh.sav cannot be linked to the bh.sav records (MC_SEN2015DKR CT4D).
  bh <- if (startsWith(s, "MC_")) file.path("data/raw/MICS_extracted", setup[svkey == s, folder], "bh.sav") else NULL
  rec <- if (is.null(bh)) readRDS(registry[svkey == s, local_recode][1]) else NULL
  cand <- cand[variable %in% (if (is.null(bh)) names(rec) else names(read_sav(bh, n_max = 0)))]
  if (!nrow(cand)) { choice[[s]] <- data.table(survey = s, variable = NA_character_, note = "no finer named variable in the records' file"); next }
  if (!is.null(bh)) {
    src <- read_sav(bh, col_select = all_of(cand$variable))
    src <- as.data.frame(lapply(src, function(z) if (is.labelled(z)) as.character(as_factor(z)) else as.character(z)))
  } else { src <- as.data.frame(lapply(rec[cand$variable], as.character)); rm(rec) }
  stopifnot(max(x$row) <= nrow(src))
  # Boundary files of the same country (DHS spatial data repository), keyed as in the builder.
  bfiles <- unique(registry[iso3 == iso & file.exists(boundary_file), boundary_file])
  bkeys <- lapply(bfiles, function(f) cbh_rkey(readRDS(f)$DHSREGEN)); names(bkeys) <- bfiles
  res <- lapply(cand$variable, function(v) {
    val <- src[[v]][x$row]
    u <- x[, .(records = sum(records), split_records = sum(records[class == "split across units"])), by = .(value = val)]
    u[, key := units_clean_key(value)]
    cover <- vapply(bkeys, function(k) sum(u$records[u$key %in% k]) / sum(u$records), 0)
    best <- if (length(cover) && max(cover) >= 0.9) names(which.max(cover)) else NA_character_
    u[, `:=`(boundary = best, method = NA_character_, Admin_ID = NA_character_, share = NA_real_)]
    if (!is.na(best)) {
      b <- st_make_valid(readRDS(best)); b$key <- cbh_rkey(b$DHSREGEN)
      b <- b[b$key %in% u$key & !duplicated(b$key), "key"]
      o <- overlay(st_transform(b, 4326))
      u <- merge(u, o, by = "key", all.x = TRUE)
      u[!is.na(top_share), `:=`(method = fifelse(top_share >= S$whole & top_endemic, "geometry", "geometry: split"),
                                 Admin_ID = top_admin, share = top_share)]
      u[, c("top_admin", "top_endemic", "top_share") := NULL]
    }
    sn <- unit_names[Country_ID == iso & endemic == TRUE]; sp <- parts[Country_ID == iso & endemic == TRUE]
    u[is.na(method) & key %in% sn$whole, `:=`(method = "name", Admin_ID = sn$Admin_ID[match(key, sn$whole)])]
    ambiguous <- sp$part[duplicated(sp$part)]   # a part shared by several polygons cannot place a unit
    u[is.na(method) & key %in% sp$part & !key %in% ambiguous,
      `:=`(method = "name part", Admin_ID = sp$Admin_ID[match(key, sp$part)])]
    al <- aliases[country == iso]
    u[is.na(method) & key %in% al$value_key, `:=`(method = fifelse(al$endemic[match(key, al$value_key)], "alias", "malaria-free (alias)"),
                                                 Admin_ID = al$Admin_ID[match(key, al$value_key)])]
    u[is.na(method), method := "unmatched"]
    u[, `:=`(survey = s, variable = v)]
    list(u = u, val = val)
  })
  placed_methods <- c("geometry", "name", "name part", "alias")
  # A finer unit that is itself split ("geometry: split") still narrows the record's location.
  informative <- c(placed_methods, "geometry: split")
  score <- vapply(res, function(r) sum(r$u$split_records[r$u$method %in% placed_methods]), 0)
  info <- vapply(res, function(r) sum(r$u$split_records[r$u$method %in% informative]), 0)
  k <- which.max(score)
  if (info[k] == 0 && max(info) == 0) {
    choice[[s]] <- data.table(survey = s, variable = NA_character_, note = "no finer variable places or narrows a record"); next
  }
  if (score[k] == 0) k <- which.max(info)
  u <- res[[k]]$u
  crosswalk[[s]] <- u
  x[, finer_method := u$method[match(res[[k]]$val, u$value)]]
  placement[[s]] <- x[, .(survey, child_id, regkey, class, finer_method, records)]
  choice[[s]] <- data.table(survey = s, variable = cand$variable[k], label = cand$label[k], n_values = cand$n_values[k],
    boundary = basename(u$boundary[1]), split_records = sum(u$split_records),
    pct_split_placed_geometry = round(100 * sum(u$split_records[u$method == "geometry"]) / sum(u$split_records), 1),
    pct_split_placed_name = round(100 * sum(u$split_records[u$method == "name"]) / sum(u$split_records), 1),
    pct_split_placed_name_part = round(100 * sum(u$split_records[u$method == "name part"]) / sum(u$split_records), 1),
    pct_split_placed_alias = round(100 * sum(u$split_records[u$method == "alias"]) / sum(u$split_records), 1),
    pct_split_still_split = round(100 * sum(u$split_records[u$method == "geometry: split"]) / sum(u$split_records), 1),
    pct_split_unmatched = round(100 * sum(u$split_records[u$method == "unmatched"]) / sum(u$split_records), 1), note = "")
  cat(sprintf("%-11s %-9s placed %5.1f%% of split records\n", s, cand$variable[k], 100 * score[k] / sum(u$split_records)))
}
choice <- rbindlist(choice, fill = TRUE); crosswalk <- rbindlist(crosswalk, fill = TRUE)
fwrite(choice, file.path(out, "finer_variable_choice.csv"))
fwrite(crosswalk[, .(survey, variable, value, key, records, split_records, method, Admin_ID, share, boundary = basename(boundary))],
       file.path(out, "finer_unit_crosswalk.csv"))

# Final placement of every record: by its survey-region, or (in split regions) by the chosen finer variable.
pl <- rbindlist(placement)
rd <- merge(rd, pl[, .(child_id, finer_method)], by = "child_id", all.x = TRUE)
rd[, placed := fcase(class %like% "^inside one unit", "assignable (survey-region)",
                     class == "split across units" & finer_method %in% c("geometry", "name", "name part", "alias"), "assignable (finer variable)",
                     class == "inside a malaria-free/island unit" | finer_method %in% "malaria-free (alias)", "malaria-free or island unit",
                     class == "no polygon", "outside the layer (Comoros, Zanzibar, Sao Tome)",
                     default = "not assignable (split, no finer location)")]
fwrite(rd[, .(records = sum(records)), by = .(survey, regkey, class, finer_method, placed)],
       file.path(out, "record_placement_by_region.csv"))
meta <- cls[, .(programme = programme[1], country = country[1]), by = survey]
f <- rd[records > 0, .(records = sum(records)), by = .(survey, placed)]
wide <- dcast(f, survey ~ placed, value.var = "records", fill = 0)
wide <- merge(meta, wide, by = "survey")
num <- setdiff(names(wide), names(meta)); wide[, total := rowSums(.SD), .SDcols = num]
for (cc in c("assignable (survey-region)", "assignable (finer variable)")) if (!cc %in% names(wide)) wide[, (cc) := 0]
wide[, pct_assignable := round(100 * (get("assignable (survey-region)") + get("assignable (finer variable)")) / total, 1)]
wide <- merge(wide, choice[, .(survey, finer_variable = variable)], by = "survey", all.x = TRUE)
fwrite(wide[order(pct_assignable)], file.path(out, "survey_feasibility_final_all.csv"))
tot <- f[, .(records = sum(records)), by = placed][, pct := round(100 * records / sum(records), 1)][order(-records)]
cat(sprintf("\n== all: %d surveys, %s records ==\n", uniqueN(f$survey), format(sum(f$records), big.mark = ",")))
print(tot)
