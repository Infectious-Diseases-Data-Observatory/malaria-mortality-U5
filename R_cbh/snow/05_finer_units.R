#!/usr/bin/env Rscript
# Can a finer location variable place the records of split survey-regions inside single Snow polygons? (Ported from
# the analysis project's R_cbh/snow_units/03_finer_units.R.) For each survey with records in split survey-regions
# (03_feasibility.R), every finer candidate variable from 04_location_variables.R (more values than the survey has
# regions, values with names) is matched:
#   geometry: to the region polygons of any local DHS boundary file of the same country (keys as in the child-band
#             builder); a matched unit is placed if >= 90% of its GPW 2020 population lies in one of the 520 polygons;
#   names:    otherwise, to a Snow polygon name in the same country, whole name ("name") or one part of a combined
#             name such as "Trarza & Nouakchott" ("name part"), then to the documented spelling aliases in
#             R_cbh/snow/config/name_aliases.csv ("alias"; an alias to a malaria-free unit counts as malaria-free).
# The variable placing the most records is kept. Records are the eligible child-band records of the shards, linked to
# their recode row through child_id (survey:c:<row>), which holds for DHS and MICS.
# Reviewed fixes (primary only, settings rule_fixes): variables describing a previous residence are never location
# variables (R_cbh/snow/config/finer_variable_exclusions.csv; UG7BFL s104), and a variable that places no record is
# not chosen (its records use their survey-region, as before).
# Output: <out>/feasibility/finer_{variable_choice,unit_crosswalk}.csv, record_placement_by_region.csv,
#         survey_feasibility_final_all.csv (aggregates)
suppressPackageStartupMessages({ library(data.table); library(sf); library(terra); library(exactextractr); library(haven) })
sf_use_s2(FALSE)
source("R_cbh/R/geography.R"); source("R_cbh/snow/R/settings.R"); source("R_cbh/snow/R/placement.R")
S <- snow_settings(); out <- file.path(S$out, "feasibility")
snow <- readRDS(file.path(S$private, "polygons_551.rds"))[, c("Admin_ID", "Country_ID", "AFR_Admin", "Type", "in520")]
cls <- fread(file.path(out, "region_classification.csv"))
inv <- fread(file.path(out, "location_variables.csv"))
registry <- fread("data/derived_dhs/survey_registry.csv")
setup <- fread("data/derived_mics/survey_setup.csv")
dens <- crop(rast("data/pop/gpw_v4_population_density_rev11_2020_2.5m.tif"), ext(-26, 60, -36, 28))
popc <- dens * cellSize(dens, unit = "km")
excl <- if (S$rule_fixes) fread("R_cbh/snow/config/finer_variable_exclusions.csv") else data.table(survey = character(), variable = character())

# Population share of each polygon in each Snow polygon; returns the largest share and its polygon.
overlay <- function(p) {
  p <- suppressWarnings(st_cast(st_collection_extract(st_make_valid(p), "POLYGON"), "MULTIPOLYGON"))
  pcs <- suppressWarnings(st_intersection(p, snow)); pcs <- pcs[st_dimension(pcs) == 2, ]
  pcs$pop <- exact_extract(popc, pcs, "sum", progress = FALSE)
  x <- as.data.table(st_drop_geometry(pcs))[, share := pop / sum(pop), by = key]
  x[order(-share), .(top_admin = Admin_ID[1], top_in520 = in520[1], top_share = share[1]), by = key]
}
snow_names <- as.data.table(st_drop_geometry(snow))[, .(Admin_ID, Country_ID, in520, whole = cbh_rkey(AFR_Admin), AFR_Admin)]
parts <- snow_names[, .(part = cbh_rkey(trimws(unlist(strsplit(AFR_Admin, ",|&| and |/"))))), by = .(Admin_ID, Country_ID, in520)][nzchar(part)]
aliases <- fread("R_cbh/snow/config/name_aliases.csv")
aliases <- merge(aliases, snow_names[, .(country = Country_ID, snow_name = AFR_Admin, Admin_ID, in520)], by = c("country", "snow_name"))
stopifnot(nrow(aliases) == nrow(fread("R_cbh/snow/config/name_aliases.csv")))

# Eligible records of every shard (one row per child: records = number of its child-band records).
rd <- rbindlist(lapply(cls[, unique(survey)], function(s) {
  d <- as.data.table(readRDS(snow_shard_path(s))$data[, c("survey", "regkey", "region", "child_id", "model_ready")])
  d <- d[snow_eligible(d, S)]
  d[, c("survey", "regkey", "child_id") := lapply(.SD, as.character), .SDcols = c("survey", "regkey", "child_id")]
  d[, .(records = .N), by = .(survey, regkey, child_id)]
}))
setorder(rd, child_id)   # child_id order, as when the v9 counts were merged in (keeps the crosswalk's row order)
rd[, row := as.integer(sub(".*:c:", "", child_id))]
rd <- merge(rd, cls[, .(survey, regkey, class)], by = c("survey", "regkey"))
split_surveys <- cls[class == "split across Snow polygons", unique(survey)]
skip <- paste0("lived before|circumcis|fistula|unicef|cluster|ward|locality|parish|moved", if (S$rule_fixes) "|previous|lived in" else "")

choice <- list(); crosswalk <- list(); placement <- list()
for (s in split_surveys) {
  iso <- cls[survey == s, country[1]]
  cand <- inv[survey == s & n_values > survey_regions & n_values <= 400 & !grepl(skip, label, ignore.case = TRUE) &
              grepl("[a-z]", examples, ignore.case = TRUE) & !variable %in% excl[survey == s, variable]]
  cand <- cand[!duplicated(variable)]
  if (!nrow(cand)) { choice[[s]] <- data.table(survey = s, variable = NA_character_, note = "no finer named variable"); next }
  x <- rd[survey == s]
  if (startsWith(s, "MC_")) {
    src <- read_sav(file.path("data/raw/MICS_extracted", setup[svkey == s, folder], "bh.sav"), col_select = any_of(cand$variable))
    src <- as.data.frame(lapply(src, function(z) if (is.labelled(z)) as.character(as_factor(z)) else as.character(z)))
  } else src <- as.data.frame(lapply(readRDS(registry[svkey == s, local_recode][1])[cand$variable], as.character))
  stopifnot(max(x$row) <= nrow(src))
  # Boundary files of the same country (DHS spatial data repository), keyed as in the builder.
  bfiles <- unique(registry[iso3 == iso & file.exists(boundary_file), boundary_file])
  bkeys <- lapply(bfiles, function(f) cbh_rkey(readRDS(f)$DHSREGEN)); names(bkeys) <- bfiles
  res <- lapply(cand$variable, function(v) {
    val <- src[[v]][x$row]
    u <- x[, .(records = sum(records), split_records = sum(records[class == "split across Snow polygons"])), by = .(value = val)]
    u[, key := snow_clean_key(value)]
    cover <- vapply(bkeys, function(k) sum(u$records[u$key %in% k]) / sum(u$records), 0)
    best <- if (length(cover) && max(cover) >= 0.9) names(which.max(cover)) else NA_character_
    u[, `:=`(boundary = best, method = NA_character_, Admin_ID = NA_character_, share = NA_real_)]
    if (!is.na(best)) {
      b <- st_make_valid(readRDS(best)); b$key <- cbh_rkey(b$DHSREGEN)
      b <- b[b$key %in% u$key & !duplicated(b$key), "key"]
      o <- overlay(st_transform(b, 4326))
      u <- merge(u, o, by = "key", all.x = TRUE)
      u[!is.na(top_share), `:=`(method = fifelse(top_share >= S$whole & top_in520, "geometry", "geometry: split"),
                                 Admin_ID = top_admin, share = top_share)]
      u[, c("top_admin", "top_in520", "top_share") := NULL]
    }
    sn <- snow_names[Country_ID == iso & in520 == TRUE]; sp <- parts[Country_ID == iso & in520 == TRUE]
    u[is.na(method) & key %in% sn$whole, `:=`(method = "name", Admin_ID = sn$Admin_ID[match(key, sn$whole)])]
    ambiguous <- sp$part[duplicated(sp$part)]   # a part shared by several polygons cannot place a unit
    u[is.na(method) & key %in% sp$part & !key %in% ambiguous,
      `:=`(method = "name part", Admin_ID = sp$Admin_ID[match(key, sp$part)])]
    al <- aliases[country == iso]
    u[is.na(method) & key %in% al$value_key, `:=`(method = fifelse(al$in520[match(key, al$value_key)], "alias", "malaria-free (alias)"),
                                                 Admin_ID = al$Admin_ID[match(key, al$value_key)])]
    u[is.na(method), method := "unmatched"]
    u[, `:=`(survey = s, variable = v)]
    list(u = u, val = val)
  })
  placed_methods <- c("geometry", "name", "name part", "alias")
  # A finer unit that is itself split ("geometry: split") still narrows the record's location.
  informative <- c(placed_methods, if (S$rule_fixes) "geometry: split")
  score <- vapply(res, function(r) sum(r$u$split_records[r$u$method %in% placed_methods]), 0)
  info <- vapply(res, function(r) sum(r$u$split_records[r$u$method %in% informative]), 0)
  k <- which.max(score)
  if (S$rule_fixes && info[k] == 0 && max(info) == 0) {
    choice[[s]] <- data.table(survey = s, variable = NA_character_, note = "no finer variable places or narrows a record"); next
  }
  if (S$rule_fixes && score[k] == 0) k <- which.max(info)
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
rd[, placed := fcase(class %like% "^inside one of the 520", "assignable (survey-region)",
                     class == "split across Snow polygons" & finer_method %in% c("geometry", "name", "name part", "alias"), "assignable (finer variable)",
                     class == "inside a malaria-free/island unit" | finer_method %in% "malaria-free (alias)", "malaria-free or island unit",
                     class == "no polygon", "outside the shapefile (Comoros, Zanzibar, Sao Tome)",
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
