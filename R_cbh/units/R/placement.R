# Placement of survey records in the endemic GADM admin-1 units, and their analysis units. Source from the repository
# root after R_cbh/R/geography.R (cbh_rkey), data.table and R_cbh/units/R/settings.R. Rules of 6 October 2026;
# thresholds come from units_settings():
#   - a survey-region with >= 90% of its GPW 2020 population in one endemic unit goes wholly to it, as does a reviewed
#     survey-region of S$region_overrides (03_feasibility.R);
#   - in a split survey-region, a record goes wholly to the polygon of its finer location unit when that unit is
#     placed (geometry, name, name part or alias; see 05_finer_units.R);
#   - otherwise the record's location is a set of population shares: of its finer unit when that unit has a
#     polygon ("geometry: split"), else of its survey-region. Shares under 2% (digitising slivers) are dropped
#     and the rest renormalised; the share in malaria-free or island units is then dropped, not renormalised;
#     only units of the survey's own country count;
#   - records in malaria-free or island units, or outside the layer (Comoros, Zanzibar, Sao Tome), are excluded.
# units_assign() turns a placement into analysis units under the merge rule: one admin-1 unit if it holds >= 90% of the
# location unit's population, else the union of the admin-1 units each holding >= 5% (w = 1; dropped if more than half
# malaria-free).
units_clean_key <- function(v) {   # as in 05_finer_units.R: drop urban/rural words and zone prefixes, then cbh_rkey
  v <- tolower(as.character(v))
  v <- gsub("\\b(rural|urban|urbain|urbaine|rurale|urb|rur)\\b", " ", v)
  v <- gsub("^(nw|ne|nc|se|ss|sw) ", "", trimws(v))
  cbh_rkey(v)
}

units_shares <- function(p, S) {   # p: unit, Admin_ID, endemic, share -> unit, Admin_ID, w
  p <- p[share >= S$sliver][, share := share / sum(share), by = unit]
  p[endemic == TRUE, .(unit, Admin_ID, w = share)]
}

# Rules from the feasibility outputs of the unit settings S (and the finer-unit shares written by 07_placement.R).
units_rules <- function(S) {
  f <- function(x) fread(file.path(S$out, "feasibility", x))
  cls <- f("region_classification.csv"); ov <- f("region_unit_overlap.csv")
  ch <- f("finer_variable_choice.csv"); cw <- f("finer_unit_crosswalk.csv")
  region <- cls[, .(survey, regkey, class, top_admin)]
  # A survey's records lie in its own country: pieces in a neighbouring country's unit (boundary digitising
  # differences) are dropped before the shares are renormalised.
  ov <- merge(ov, unique(cls[, .(survey, regkey, country)]), by = c("survey", "regkey"))[Country_ID == country]
  ov[, share := pop / sum(pop), by = .(survey, regkey)]
  rs <- ov[paste(survey, regkey) %in% region[class == "split across units", paste(survey, regkey)],
           .(unit = paste(survey, regkey, sep = "|"), Admin_ID, endemic, share)]
  region_shares <- units_shares(rs, S)[, c("survey", "regkey") := tstrsplit(unit, "|", fixed = TRUE)][, unit := NULL]
  fs_path <- file.path(S$out, "placement", "finer_unit_shares.csv")
  finer_shares <- if (file.exists(fs_path)) fread(fs_path) else data.table(survey = character(), key = character(), Admin_ID = character(), w = numeric())
  # Several raw values can share a cleaned key (e.g. "river gee - rural"/"- urban"); they must agree.
  finer <- unique(cw[, .(survey, key, method, Admin_ID)])
  if (anyDuplicated(finer[, .(survey, key)])) stop("Finer values with one key but different placements: ",
    paste(head(finer[duplicated(finer[, .(survey, key)]), paste(survey, key)], 5), collapse = ", "))
  list(region = region, region_shares = region_shares, choice = ch[!is.na(variable) & nzchar(variable), .(survey, variable)],
       finer = finer, finer_shares = finer_shares)
}

# d: data.table with id, survey, regkey and finer_key (units_clean_key of the chosen finer variable, NA if none).
# Returns id, Admin_ID, w, rule; ids that are excluded do not appear.
units_place <- function(d, R) {
  d <- merge(d, R$region, by = c("survey", "regkey"), all.x = TRUE)
  if (anyNA(d$class)) stop("Records in survey-regions without a feasibility class: ",
                           paste(head(unique(d[is.na(class), paste(survey, regkey)]), 5), collapse = ", "))
  whole <- d[class %like% "^inside one unit", .(id, Admin_ID = top_admin, w = 1, rule = "survey-region")]
  sp <- d[class == "split across units"]
  sp <- merge(sp, R$finer, by.x = c("survey", "finer_key"), by.y = c("survey", "key"), all.x = TRUE)
  placed <- sp[method %in% c("geometry", "name", "name part", "alias"), .(id, Admin_ID, w = 1, rule = paste("finer unit:", method))]
  fsplit <- merge(sp[method %in% "geometry: split", .(id, survey, finer_key)], R$finer_shares,
                  by.x = c("survey", "finer_key"), by.y = c("survey", "key"), allow.cartesian = TRUE)[, .(id, Admin_ID, w, rule = "finer unit shares")]
  rest <- sp[is.na(method) | method %in% "unmatched" | (method %in% "geometry: split" & !id %in% fsplit$id)]
  rsplit <- merge(rest[, .(id, survey, regkey)], R$region_shares, by = c("survey", "regkey"), allow.cartesian = TRUE)[, .(id, Admin_ID, w, rule = "survey-region shares")]
  rbindlist(list(whole, placed, fsplit, rsplit))
}

# Analysis units of placed ids. pl: id, Admin_ID, w, rule (from units_place). Returns id, unit, w, rule, n_polygons,
# malaria_free (share of the location unit's population in malaria-free or island units); ids dropped (malaria-free
# share > 0.5) do not appear. Units are Admin_IDs joined by "+" in C-locale (radix) order, so the strings do not depend
# on the collation locale (ids NGA.1_1 and NGA.10_1 sort differently in en_GB).
units_assign <- function(pl, S) {
  if (!nrow(pl)) return(data.table(id = pl$id, unit = character(), w = numeric(), rule = character(), n_polygons = integer(), malaria_free = numeric()))
  pl[, `:=`(mf = pmax(0, 1 - sum(w)), top = max(w)), by = id]
  u <- pl[, {
    keep <- if (top[1] >= S$whole) Admin_ID[which.max(w)] else if (any(w >= S$link)) Admin_ID[w >= S$link] else Admin_ID
    .(unit = paste(sort(keep, method = "radix"), collapse = "+"), n_polygons = length(keep), malaria_free = mf[1], rule = rule[1])
  }, by = id]
  pl[, c("mf", "top") := NULL]
  u[malaria_free <= S$malaria_free_drop, .(id, unit, w = 1, rule, n_polygons, malaria_free)]
}
