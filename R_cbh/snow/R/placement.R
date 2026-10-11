# Placement of survey records in the 520 Snow polygons, and their analysis units. Source from the repository root
# after R_cbh/R/geography.R (cbh_rkey), data.table and R_cbh/snow/R/settings.R. Ported from the analysis project
# (R_cbh/snow_units/placement.R, decisions of 6 October 2026); thresholds come from snow_settings():
#   - a survey-region with >= 90% of its GPW 2020 population in one of the 520 polygons goes wholly to it;
#   - in a split survey-region, a record goes wholly to the polygon of its finer location unit when that unit is
#     placed (geometry, name, name part or alias; see 05_finer_units.R);
#   - otherwise the record's location is a set of population shares: of its finer unit when that unit has a
#     polygon ("geometry: split"), else of its survey-region. Shares under 2% (digitising slivers) are dropped
#     and the rest renormalised; the share in malaria-free or island units is then dropped, not renormalised;
#     only polygons of the survey's own country count;
#   - records in malaria-free or island units, or with no Snow polygon at all (Comoros, Zanzibar, Sao Tome), are excluded.
# snow_assign() turns a placement into analysis units: under the merge rule (primary) one polygon if it holds >= 90% of
# the location unit's population, else the union of the polygons each holding >= 5% (w = 1; dropped if more than half
# malaria-free); under the split rule (reproduction only) one unit per polygon with weight = share.
snow_clean_key <- function(v) {   # as in 05_finer_units.R: drop urban/rural words and zone prefixes, then cbh_rkey
  v <- tolower(as.character(v))
  v <- gsub("\\b(rural|urban|urbain|urbaine|rurale|urb|rur)\\b", " ", v)
  v <- gsub("^(nw|ne|nc|se|ss|sw) ", "", trimws(v))
  cbh_rkey(v)
}

snow_shares <- function(p, S) {   # p: unit, Admin_ID, in520, share -> unit, Admin_ID, w
  p <- p[share >= S$sliver][, share := share / sum(share), by = unit]
  p[in520 == TRUE, .(unit, Admin_ID, w = share)]
}

# Rules from the feasibility outputs of variant S (and the finer-unit shares written by 07_placement.R).
snow_rules <- function(S) {
  f <- function(x) fread(file.path(S$out, "feasibility", x))
  cls <- f("region_classification.csv"); ov <- f("region_snow_overlap.csv")
  ch <- f("finer_variable_choice.csv"); cw <- f("finer_unit_crosswalk.csv")
  region <- cls[, .(survey, regkey, class, top_admin)]
  # A survey's records lie in its own country: pieces in a neighbouring country's polygon (boundary digitising
  # differences) are dropped before the shares are renormalised.
  ov <- merge(ov, unique(cls[, .(survey, regkey, country)]), by = c("survey", "regkey"))[Country_ID == country]
  ov[, share := pop / sum(pop), by = .(survey, regkey)]
  rs <- ov[paste(survey, regkey) %in% region[class == "split across Snow polygons", paste(survey, regkey)],
           .(unit = paste(survey, regkey, sep = "|"), Admin_ID, in520, share)]
  region_shares <- snow_shares(rs, S)[, c("survey", "regkey") := tstrsplit(unit, "|", fixed = TRUE)][, unit := NULL]
  fs_path <- file.path(S$out, "placement", "finer_unit_shares.csv")
  finer_shares <- if (file.exists(fs_path)) fread(fs_path) else data.table(survey = character(), key = character(), Admin_ID = character(), w = numeric())
  # Several raw values can share a cleaned key (e.g. "river gee - rural"/"- urban"); they must agree.
  finer <- unique(cw[, .(survey, key, method, Admin_ID)])
  if (anyDuplicated(finer[, .(survey, key)])) stop("Finer values with one key but different placements: ",
    paste(head(finer[duplicated(finer[, .(survey, key)]), paste(survey, key)], 5), collapse = ", "))
  list(region = region, region_shares = region_shares, choice = ch[!is.na(variable) & nzchar(variable), .(survey, variable)],
       finer = finer, finer_shares = finer_shares)
}

# d: data.table with id, survey, regkey and finer_key (snow_clean_key of the chosen finer variable, NA if none).
# Returns id, Admin_ID, w, rule; ids that are excluded do not appear.
snow_place <- function(d, R) {
  d <- merge(d, R$region, by = c("survey", "regkey"), all.x = TRUE)
  if (anyNA(d$class)) stop("Records in survey-regions without a feasibility class: ",
                           paste(head(unique(d[is.na(class), paste(survey, regkey)]), 5), collapse = ", "))
  whole <- d[class %like% "^inside one of the 520", .(id, Admin_ID = top_admin, w = 1, rule = "survey-region")]
  sp <- d[class == "split across Snow polygons"]
  sp <- merge(sp, R$finer, by.x = c("survey", "finer_key"), by.y = c("survey", "key"), all.x = TRUE)
  placed <- sp[method %in% c("geometry", "name", "name part", "alias"), .(id, Admin_ID, w = 1, rule = paste("finer unit:", method))]
  fsplit <- merge(sp[method %in% "geometry: split", .(id, survey, finer_key)], R$finer_shares,
                  by.x = c("survey", "finer_key"), by.y = c("survey", "key"), allow.cartesian = TRUE)[, .(id, Admin_ID, w, rule = "finer unit shares")]
  rest <- sp[is.na(method) | method %in% "unmatched" | (method %in% "geometry: split" & !id %in% fsplit$id)]
  rsplit <- merge(rest[, .(id, survey, regkey)], R$region_shares, by = c("survey", "regkey"), allow.cartesian = TRUE)[, .(id, Admin_ID, w, rule = "survey-region shares")]
  rbindlist(list(whole, placed, fsplit, rsplit))
}

# Analysis units of placed ids. pl: id, Admin_ID, w, rule (from snow_place). Returns id, unit, w, rule, n_polygons,
# malaria_free (share of the location unit's population in malaria-free or island units); ids dropped under the merge
# rule (malaria-free share > 0.5) do not appear. Units are Admin_IDs joined by "+" in sorted order.
snow_assign <- function(pl, S) {
  if (!nrow(pl)) return(data.table(id = pl$id, unit = character(), w = numeric(), rule = character(), n_polygons = integer(), malaria_free = numeric()))
  if (identical(S$rule, "split"))
    return(pl[, .(id, unit = Admin_ID, w, rule, n_polygons = 1L, malaria_free = NA_real_)])
  pl[, `:=`(mf = pmax(0, 1 - sum(w)), top = max(w)), by = id]
  u <- pl[, {
    keep <- if (top[1] >= S$whole) Admin_ID[which.max(w)] else if (any(w >= S$link)) Admin_ID[w >= S$link] else Admin_ID
    .(unit = paste(sort(keep), collapse = "+"), n_polygons = length(keep), malaria_free = mf[1], rule = rule[1])
  }, by = id]
  pl[, c("mf", "top") := NULL]
  u[malaria_free <= S$malaria_free_drop, .(id, unit, w = 1, rule, n_polygons, malaria_free)]
}
