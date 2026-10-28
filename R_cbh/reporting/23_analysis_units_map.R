#!/usr/bin/env Rscript
# Figure 1 (main text): complete birth histories used in the primary analysis, by sub-national polygon of Snow et al.
# (2017) (user request, 12 October 2026). Each sub-Saharan polygon is coloured by the number of complete birth histories
# (interviewed mothers) with at least one child-band record in the final sample, summed over the included surveys. The
# previous Figure 1 (survey map and timing, 03_survey_map.R) moves unchanged to the supplement.
# Rules:
#   Mothers: the analysed child_ids of the prepared dataset (P$data) are mapped to their mother through the child-band
#     shards, as in 03_survey_map.R. A mother whose unit is one polygon counts 1 there. A mother whose unit is a union of
#     polygons is divided among them by the population shares w of her reported location (records_placed.rds), restricted
#     to the union's polygons and renormalised to 1, averaged over her records (so a mother with records in more than
#     one unit would be apportioned by her records). Child-band records and deaths are apportioned the same way, and a
#     polygon's surveys are those with a positive share in it. Polygon totals are checked against the per-survey mothers
#     of 03_survey_map.R (survey_map/mothers_by_survey.csv) and prepared_sample.csv.
#   Units: every analysed record's unit is re-derived from its placement shares with the merge rule of snow_assign()
#     (polygon >= S$whole of the location's population, else the endemic polygons each >= S$link; locations more than
#     S$malaria_free_drop malaria free dropped), so the caption's statement of the rule is checked. The single-polygon
#     units whose polygon holds less than S$whole (the rest being malaria free) are counted and printed.
#   Classes: round-number log-spaced (1-2-5) bins chosen from the distribution of the polygons with data; every class
#     must be used. Endemic polygons with no data: light grey; malaria-free and island polygons: warm grey (not analysed).
#   Underlay: North Africa (admin0) and Western Sahara (the Snow et al. shapefile), outside the study area, in a pale
#     tone, as are islands of the national boundaries without a Snow polygon (the Comoros, Zanzibar and others). Gaps
#     between the Snow polygons and the national boundaries take the class of an adjacent polygon (of the same country
#     where there is one), except gaps mostly covered by the mapped lakes (Snow holes for Lakes Malawi, Tana and Edward),
#     which are drawn as water.
#   Lines: white boundaries between Snow polygons and black national borders, both along shared land boundaries only
#     (no coastlines, no halo), so that small coastal polygons (The Gambia, the Freetown peninsula, Dar es Salaam, the
#     Bijagos) keep their fill; thin grey coasts of the pale areas only, and no lines inside them (the borders within
#     North Africa are not drawn).
#   Lakes: Natural Earth 1:10m lakes and reservoirs of at least 300 km2 inside the map frame, without their islands of
#     less than 200 km2, drawn in light blue with a slightly darker outline over the polygons and the national borders,
#     so lake water is never coloured as data.
#   Caption: interview years are those of the analysed records (interview_cmc of the child-band shards, Gregorian).
#   Every number in CAPTION.md is computed here and checked against the primary's own outputs (prepared_sample.csv and the
#   survey map's mothers_by_survey.csv and survey_coverage.csv); only the fixed counts of the Snow et al. shapefile are
#   asserted as constants. The palette is checked for colour-vision deficiency (Machado et al. 2009 simulation,
#   CIE76 dE in CIELAB) and the legend and scale bar for clearance from land. Planar geometry (sf_use_s2(FALSE)) in the
#   Africa Albers equal-area projection (ESRI:102022). Deterministic; no caches.
# Inputs: P$data; the child-band shard manifests and shards of the included surveys (cbh_config()$output_dir,
#   P$mics_output_dir); <S$private>/records_placed.rds and polygons_551.rds; S$shapefile (Western Sahara only);
#   data/africa_admin0.rds; data/external/natural_earth/ne_10m_lakes.geojson; <P$out>/prepared_sample.csv,
#   survey_map/mothers_by_survey.csv and survey_map/survey_coverage.csv (03_survey_map.R); this script, the settings and
#   the R_cbh helper files it sources.
# Outputs (<P$out>/analysis_units_map/): analysis_units_map.png (156 mm wide, 400 dpi); CAPTION.md;
#   analysis_units_by_polygon.csv (the 551 polygons: surveys, mothers, child-band records and deaths, apportioned as
#   above, and class); provenance.csv (md5 of every input read). Aggregates only.
# Run from the repository root: CBH_PRIMARY_VERSION=snow_merge Rscript R_cbh/reporting/23_analysis_units_map.R
suppressPackageStartupMessages({ library(data.table); library(sf); library(ggplot2) })
sf_use_s2(FALSE)
source("R_cbh/load_pipeline.R"); source("R_cbh/primary/settings.R"); source("R_cbh/snow/R/settings.R")
P <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION", "snow_merge"))
if (!identical(P$unit, "snow")) stop("The analysis-units map needs a Snow-unit primary version; '", P$id, "' has unit '", P$unit, "'.")
S <- snow_settings(P$snow_variant)
if (!identical(S$rule, "merge")) stop("The analysis-units map describes the merge rule; Snow variant '", S$variant, "' uses '", S$rule, "'.")
out <- file.path(P$out, "analysis_units_map"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
cfg <- cbh_config()
rel <- function(p) ifelse(startsWith(p, paste0(cfg$root, "/")), substring(p, nchar(cfg$root) + 2L), p)   # repository-relative
self <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
if (length(self) != 1L || !file.exists(self)) self <- "R_cbh/reporting/23_analysis_units_map.R"
shp_parts <- sub("[.]shp$", "", S$shapefile); shp_parts <- paste0(shp_parts, c(".shp", ".shx", ".dbf", ".prj", ".cpg"))
paths <- c(dataset = P$data, records_placed = file.path(S$private, "records_placed.rds"), polygons = file.path(S$private, "polygons_551.rds"),
           admin0 = "data/africa_admin0.rds", lakes = "data/external/natural_earth/ne_10m_lakes.geojson",
           sample = file.path(P$out, "prepared_sample.csv"), mothers = file.path(P$out, "survey_map", "mothers_by_survey.csv"),
           coverage = file.path(P$out, "survey_map", "survey_coverage.csv"),
           script = self, primary_settings = "R_cbh/primary/settings.R", snow_settings = "R_cbh/snow/R/settings.R",
           load_pipeline = "R_cbh/load_pipeline.R",                     # and the files it sources (cbh_source())
           # This list must track the paths of cbh_source() in R_cbh/load_pipeline.R (every R_cbh/R/*.R file is asserted below).
           setNames(file.path("R_cbh", c("00_config.R", file.path("R", c("utils.R", "geography.R", "child_bands.R", "external_data.R", "build.R", "load.R")))),
                    c("config", "utils", "geography", "child_bands", "external_data", "build", "load")))
assert_helpers <- setdiff(file.path("R_cbh/R", list.files("R_cbh/R", "[.]R$")), paths)
if (length(assert_helpers)) stop("Helper files missing from the provenance list (see cbh_source()): ", paste(assert_helpers, collapse = ", "))
rm(assert_helpers)
shp_parts <- shp_parts[file.exists(shp_parts)]
if (any(!file.exists(paths)) || !length(shp_parts)) stop("Missing input: ", paste(c(paths[!file.exists(paths)], if (!length(shp_parts)) S$shapefile), collapse = ", "))
t0 <- Sys.time(); tick <- function(msg) cat(sprintf("[%6.1f s] %s\n", as.numeric(difftime(Sys.time(), t0, units = "secs")), msg))

# Fixed counts of the Snow et al. shapefile (01_polygons.R). Sample counts are checked against the primary's outputs instead.
expected <- list(polygons = 551L, endemic = 520L, malaria_free = 29L, island = 2L)
check <- function(name, got) {
  if (!isTRUE(all.equal(as.numeric(got), as.numeric(expected[[name]]))))
    stop(sprintf("Check failed: %s = %s, expected %s", name, paste(got, collapse = ","), expected[[name]]), call. = FALSE)
  invisible(got)
}
assert <- function(ok, what) if (!isTRUE(ok)) stop("Check failed: ", what, call. = FALSE)

## 1. Records, units and mothers of the final sample --------------------------------------------------------------------
x <- readRDS(P$data)$data
cols <- c("child_id", "survey", "country", "unit", "n_polygons", "age_band", "death")
assert(all(cols %in% names(x)), "prepared dataset has child_id, survey, country, unit, n_polygons, age_band, death")
d <- data.table(child_id = as.character(x$child_id), survey = as.character(x$survey), country = as.character(x$country),
                unit = as.character(x$unit), n_polygons = as.integer(x$n_polygons), age_band = as.character(x$age_band),
                death = as.integer(x$death))
rm(x); invisible(gc()); tick("prepared dataset read")
smp <- cbh_read_csv(paths[["sample"]]); assert(nrow(smp) == 1L, "prepared_sample.csv has one row")
assert(!anyNA(d) && all(d$death %in% 0:1), "no missing values; deaths are 0/1")
assert(!anyDuplicated(d, by = c("child_id", "age_band")), "one record per child and age band")
assert(nrow(d) == smp$records, "records = prepared_sample")
assert(sum(d$death) == smp$deaths, "deaths = prepared_sample")
A <- unique(d[, .(survey, country, unit, n_polygons)])
assert(!anyDuplicated(A, by = c("survey", "unit")), "one country and polygon count per survey x unit")
assert(all(A$n_polygons == lengths(strsplit(A$unit, "+", fixed = TRUE))), "n_polygons = number of polygons in the unit")
assert(nrow(A) == smp$regions, "areas = prepared_sample regions")
assert(sum(A$n_polygons > 1) == smp$merged_units, "merged areas = prepared_sample")
assert(uniqueN(A$survey) == smp$surveys, "surveys = prepared_sample")
assert(uniqueN(A$country) == smp$countries, "countries = prepared_sample")
used_ids <- unique(unlist(strsplit(A$unit, "+", fixed = TRUE)))
assert(length(used_ids) == smp$polygons, "polygons in units = prepared_sample polygons")

# Child -> mother through the child-band shards (03_survey_map.R).
analysed <- unique(d$child_id); inc <- unique(d$survey)
shard_dirs <- c(cfg$output_dir, P$mics_output_dir)
shard_files <- character()
cm <- rbindlist(lapply(shard_dirs, function(dir) {
  m <- readRDS(file.path(dir, "manifest.rds"))$manifest; m <- m[m$survey %in% inc, ]
  shard_files <<- c(shard_files, file.path(dir, m$file))
  rbindlist(lapply(seq_len(nrow(m)), function(i) { o <- readRDS(file.path(dir, m$file[i])); stopifnot(identical(o$signature, m$signature[i]))
    assert(all(c("child_id", "mother_id", "interview_cmc") %in% names(o$data)), paste("shard of", m$survey[i], "has child_id, mother_id, interview_cmc"))
    k <- as.character(o$data$child_id) %in% analysed
    unique(data.table(survey = m$survey[i], child_id = as.character(o$data$child_id[k]), mother_id = as.character(o$data$mother_id[k]),
                      interview_cmc = as.integer(o$data$interview_cmc[k]))) })) }))
tick(sprintf("%d child-band shards read", length(shard_files)))
assert(!anyDuplicated(cm$child_id) && !anyNA(cm$mother_id) && !anyNA(cm$interview_cmc), "one mother and interview date per analysed child")
# Interview (fieldwork) years of the analysed records, for the caption; checked against the registry years below.
fieldwork <- cm[, .(y0 = 1900L + (min(interview_cmc) - 1L) %/% 12L, y1 = 1900L + (max(interview_cmc) - 1L) %/% 12L), by = survey]
assert(nrow(cm) == length(analysed) && all(analysed %chin% cm$child_id), "every analysed child is in a shard of its survey")
d[cm, on = "child_id", `:=`(mother_id = i.mother_id, shard_survey = i.survey)]
assert(identical(d$survey, d$shard_survey), "child's shard survey = record survey"); d[, shard_survey := NULL]
rm(cm); invisible(gc())
assert(all(d[, uniqueN(survey), by = mother_id]$V1 == 1L), "each mother belongs to one survey")
mb <- d[, .(children = uniqueN(child_id), mothers = uniqueN(mother_id)), by = survey]
mref <- as.data.table(cbh_read_csv(paths[["mothers"]]))
mchk <- merge(mb, mref, by = "survey", suffixes = c("", "_ref"))
assert(nrow(mchk) == nrow(mb) && nrow(mref) == nrow(mb) && all(mchk$mothers == mchk$mothers_ref) && all(mchk$children == mchk$children_ref),
       "mothers and children by survey = survey_map/mothers_by_survey.csv")
n_mothers <- uniqueN(d$mother_id)
mu <- d[, .(units = uniqueN(unit), merged = any(n_polygons > 1)), by = mother_id]
mothers_multi_unit <- sum(mu$units > 1); mothers_merged <- sum(mu$merged); rm(mu)
cat(sprintf("Mothers: %d, %d with records in more than one unit (apportioned by their records), %d in a merged unit\n", n_mothers, mothers_multi_unit, mothers_merged))

# Placement shares of the analysed records (records_placed.rds: endemic polygons only, so 1 - sum(w) is the share of the
# record's location that is malaria free or island).
snow0 <- readRDS(paths[["polygons"]]); ptype <- setNames(as.character(snow0$Type), snow0$Admin_ID)
up <- unique(A[n_polygons > 1, .(unit)])[, .(Admin_ID = strsplit(unit, "+", fixed = TRUE)[[1]]), by = unit]
U <- up[d[n_polygons > 1, .(child_id, age_band, unit)], on = "unit", allow.cartesian = TRUE]
rp <- readRDS(paths[["records_placed"]]); setDT(rp)
assert(all(c("child_id", "age_band", "Admin_ID", "w") %in% names(rp)), "records_placed has child_id, age_band, Admin_ID, w")
rp <- rp[child_id %chin% analysed, .(child_id, age_band = as.character(age_band), Admin_ID = as.character(Admin_ID), w)]; invisible(gc())
rp <- rp[d[, .(child_id, age_band)], on = .(child_id, age_band), nomatch = NULL]; invisible(gc())
tick("records_placed read")
assert(!anyDuplicated(rp, by = c("child_id", "age_band", "Admin_ID")), "one placement row per record x polygon")
assert(all(rp$w > 0) && all(ptype[rp$Admin_ID] %in% "Endemic"), "placement rows: positive shares in malaria-endemic polygons")
# The merge rule re-derived for every analysed record (snow_assign(), R_cbh/snow/R/placement.R), so that the caption's
# statement of it is checked: the polygon holding >= S$whole of the location's population, otherwise the endemic polygons
# each holding >= S$link; locations more than S$malaria_free_drop malaria free are dropped. Where the rest of a location is
# malaria free, "otherwise" can leave a single polygon holding less than S$whole (counted and printed).
rt <- rp[, .(top = max(w), mf = pmax(0, 1 - sum(w))), by = .(child_id, age_band)]
assert(nrow(rt) == nrow(d), "every analysed record has placement rows")
rp[rt, on = .(child_id, age_band), top := i.top]
kept <- rp[(top >= S$whole & w == top) | (top < S$whole & w >= S$link), .(child_id, age_band, Admin_ID)]
E <- rbind(d[n_polygons == 1, .(child_id, age_band, Admin_ID = unit)], U[, .(child_id, age_band, Admin_ID)])
assert(fsetequal(kept, E), "each record's unit = its polygon >= S$whole, else its endemic polygons >= S$link (snow_assign)")
assert(max(rt$mf) <= S$malaria_free_drop, "no analysed record is more than S$malaria_free_drop malaria free")
rm(kept, E); invisible(gc())
low <- d[n_polygons == 1][rt[top < S$whole], on = .(child_id, age_band), nomatch = NULL][
  , .(records = .N, top_min = min(top), top_max = max(top), mf_min = min(mf), mf_max = max(mf)), by = .(survey, unit)]
cat(sprintf("Single-polygon units whose polygon holds < %s of the location (rest malaria free): %s\n", S$whole,
            paste(sprintf("%s %s (top %.3f-%.3f, malaria free %.3f-%.3f)", low$survey, low$unit, low$top_min, low$top_max, low$mf_min, low$mf_max), collapse = "; ")))
rm(rt, low)
rp <- rp[child_id %chin% unique(U$child_id), .(child_id, age_band, Admin_ID, w)]; invisible(gc())
U[rp, on = .(child_id, age_band, Admin_ID), w := i.w]; rm(rp); invisible(gc())
assert(!anyNA(U$w) && all(U$w > 0), "every polygon of a record's union holds a positive share of its location")
U[, share := w / sum(w), by = .(child_id, age_band)]
RP <-rbind(d[n_polygons == 1, .(child_id, age_band, Admin_ID = unit, share = 1)], U[, .(child_id, age_band, Admin_ID, share)])
rm(U); invisible(gc())
RP[d, on = .(child_id, age_band), `:=`(survey = i.survey, mother_id = i.mother_id, death = i.death)]
rs <- RP[, .(s = sum(share)), by = .(child_id, age_band)]
assert(nrow(rs) == nrow(d) && max(abs(rs$s - 1)) < 1e-9, "each record's polygon shares sum to 1"); rm(rs)
nrec <- d[, .(n = .N), by = mother_id]
MP <- RP[, .(share = sum(share)), by = .(survey, mother_id, Admin_ID)]
MP[nrec, on = "mother_id", share := share / i.n]
ms <- MP[, .(s = sum(share)), by = mother_id]
assert(nrow(ms) == n_mothers && max(abs(ms$s - 1)) < 1e-9, "each mother's polygon shares sum to 1"); rm(ms, nrec)
PS <- MP[, .(mothers = sum(share)), by = .(survey, Admin_ID)]; rm(MP)
sv <- merge(PS[, .(mothers = sum(mothers)), by = survey], mref[, .(survey, mothers_ref = mothers)], by = "survey")
assert(nrow(sv) == nrow(mref) && max(abs(sv$mothers - sv$mothers_ref)) < 1e-6, "polygon mothers sum to the per-survey mothers")
agg <- merge(PS[, .(surveys = .N, mothers = sum(mothers)), by = Admin_ID],
             RP[, .(records = sum(share), deaths = sum(death * share)), by = Admin_ID], by = "Admin_ID")
rm(RP, PS); invisible(gc())
assert(setequal(agg$Admin_ID, used_ids) && all(agg$mothers > 0), "every polygon of a unit holds data")
assert(abs(sum(agg$mothers) - n_mothers) < 1e-6 && abs(sum(agg$records) - nrow(d)) < 1e-6 && abs(sum(agg$deaths) - sum(d$death)) < 1e-6,
       "polygon totals = overall mothers, records and deaths")
n_records <- nrow(d); n_deaths <- sum(d$death)
rm(d); invisible(gc()); tick("mothers apportioned to polygons")

## 2. Polygons and classes -------------------------------------------------------------------------------------------
crs <- "ESRI:102022"
prep <- function(x) st_make_valid(st_transform(st_make_valid(x), crs))
snow <- prep(snow0); rm(snow0)
pol <-as.data.table(st_drop_geometry(snow))[, .(Admin_ID, Country_ID, AFR_Admin, Type)]
check("polygons", nrow(pol)); assert(!anyDuplicated(pol$Admin_ID), "unique Admin_ID")
assert(all(pol$Type %in% c("Endemic", "Malaria free", "Island")), "Snow polygon types")
check("endemic", sum(pol$Type == "Endemic")); check("malaria_free", sum(pol$Type == "Malaria free")); check("island", sum(pol$Type == "Island"))
assert(!any(pol$Country_ID %in% S$north_africa), "no North African polygon")
pol <- merge(pol, agg, by = "Admin_ID", all.x = TRUE)
assert(all(pol[!is.na(mothers), Type] == "Endemic"), "every polygon with data is endemic")
breaks <- c(0, 500, 1000, 2000, 5000, 10000, Inf)          # mothers; round 1-2-5 steps (see the distribution printed below)
nb <- length(breaks) - 1L; data_keys <- paste0("c", seq_len(nb))
pol[, key := fcase(Type != "Endemic", "excluded", is.na(mothers), "nodata", default = paste0("c", findInterval(mothers, breaks)))]
for (v in c("surveys", "mothers", "records", "deaths")) set(pol, which(is.na(pol[[v]])), v, 0)
used <- pol[key %in% data_keys]
cat("Mothers per polygon with data:", paste(names(summary(used$mothers)), round(summary(used$mothers)), collapse = ", "), "\n")
n_cls <- table(factor(pol$key, c(data_keys, "nodata", "excluded")))
print(n_cls)
assert(all(n_cls[data_keys] > 0), "every class holds at least one polygon")
assert(n_cls[["nodata"]] == sum(pol$Type == "Endemic") - length(used_ids), "endemic polygons without data = endemic - polygons used")
f0 <- function(v) format(v, big.mark = ",", trim = TRUE, scientific = FALSE)
lab_fig <- c(sprintf("< %s", f0(breaks[2])), sprintf("%s\u2013%s", f0(breaks[2:(nb - 1)]), f0(breaks[3:nb] - 1)), sprintf("\u2265 %s", f0(breaks[nb])))
lab_csv <- c(sprintf("<%d", breaks[2]), sprintf("%d-%d", breaks[2:(nb - 1)], breaks[3:nb] - 1), sprintf(">=%d", breaks[nb]))
names(lab_fig) <- names(lab_csv) <- data_keys
pol[, class := fcase(key %in% data_keys, lab_csv[key], Type == "Malaria free", "malaria free (not analysed)", Type == "Island", "island (not analysed)",
                     default = "no data (endemic)")]
setorder(pol, Admin_ID)

## 3. Geometry: frame, underlay, gaps between the Snow polygons and the national boundaries, lakes -----------------------
adm0 <- prep(readRDS(paths[["admin0"]]))
lyr <- tools::file_path_sans_ext(basename(S$shapefile))
esh <- prep(st_read(S$shapefile, query = sprintf("SELECT Country_ID FROM \"%s\" WHERE Country_ID = 'ESH'", lyr), quiet = TRUE))
assert(nrow(esh) >= 1L && !"ESH" %in% adm0$iso, "Western Sahara from the Snow shapefile, absent from admin0")
assert(!any(c("COM", "STP") %in% snow$Country_ID) && "COM" %in% adm0$iso && !"STP" %in% adm0$iso, "Comoros in admin0 only; Sao Tome and Principe in neither")
fig_w <- 156                                                  # mm; the printed width is 0.95\linewidth = 157 mm
pad <- 60e3; bb <- st_bbox(snow)
xr <- unname(c(bb["xmin"] - pad, bb["xmax"] + pad)); yr <- unname(c(bb["ymin"] - pad, bb["ymax"] + pad))
W <- diff(xr); fig_h <- round(fig_w * diff(yr) / W, 1)         # the map fills the canvas; height rounded to 0.1 mm
yr <- mean(yr) + c(-0.5, 0.5) * W * fig_h / fig_w; H <- diff(yr)
m_per_mm <- W / fig_w; mm <- function(v) v * m_per_mm
npc <- function(x, y) c(xr[1] + x * W, yr[1] + y * H)
box_sf <- function(x0, y0, x1, y1) st_as_sfc(st_bbox(c(xmin = x0, ymin = y0, xmax = x1, ymax = y1), crs = st_crs(crs)))
frame <- box_sf(xr[1], yr[1], xr[2], yr[2])
north <- adm0[adm0$iso %in% S$north_africa, ]; ssa <- adm0[!adm0$iso %in% S$north_africa, ]
assert(nrow(north) >= 1L && nrow(ssa) >= 40L, "admin0 split into North Africa and sub-Saharan Africa")
under <- rbind(st_sf(iso = adm0$iso, geometry = st_geometry(adm0)), st_sf(iso = "ESH", geometry = st_union(st_geometry(esh))))
# Lines are drawn only along shared land boundaries, never along coasts, so that small coastal polygons (The Gambia,
# the Freetown peninsula, Dar es Salaam, the Bijagos) keep their fill: white between Snow polygons, black between
# countries, no halo. shared_lines() keeps the part of each drawn geometry's boundary within tol of a neighbour, each pair
# once (the admin0 boundaries come from several sources and do not always coincide exactly).
shared_lines <- function(g, draw, tol) {
  buf <- st_buffer(g, tol); nb <- st_intersects(buf)
  x <- do.call(c, lapply(which(draw), function(i) {
    J <- setdiff(nb[[i]], i); J <- J[!(draw[J] & J < i)]
    if (!length(J)) return(NULL)
    y <- suppressWarnings(st_intersection(st_boundary(g[i]), st_union(buf[J])))
    if (length(y)) suppressWarnings(st_cast(st_collection_extract(y, "LINESTRING"), "LINESTRING")) }))
  st_sf(geometry = st_line_merge(st_union(x)))
}
# National borders are those of the land parts of at least border_min_km2 that a Snow polygon touches (smaller islands
# and enclaves, such as Likoma and Chizumulu in Lake Malawi, would print as black specks), against the neighbouring
# sub-Saharan countries, North Africa and Western Sahara. Islands without a polygon of at least isle_min_km2 (the
# Comoros, Zanzibar, Pemba, the Dahlak islands) get a thin grey outline, as does the coast of North Africa and Western
# Sahara (exterior rings only, so the slivers between the admin0 and Snow outlines of Morocco and Western Sahara do not
# show), so that the pale areas stay legible against the sea.
border_min_km2 <- 500; isle_min_km2 <- 100; border_tol <- 2000; poly_tol <- 300      # m (2 km = 0.04 mm at the map scale)
bparts <- suppressWarnings(st_cast(st_cast(ssa[, "iso"], "MULTIPOLYGON"), "POLYGON"))
bparts$km2 <- as.numeric(st_area(bparts)) / 1e6
bparts$in_snow <- lengths(st_intersects(bparts, snow)) > 0
borders <- bparts[bparts$in_snow & bparts$km2 >= border_min_km2, ]; isles <- bparts[!bparts$in_snow & bparts$km2 >= isle_min_km2, ]
ring_km2 <- function(r) as.numeric(st_area(st_sfc(st_polygon(list(r)), crs = st_crs(crs)))) / 1e6
drop_holes <- function(g, min_km2) {                               # interior rings smaller than min_km2 removed
  one <- function(r) { if (length(r) > 1L) r <- r[c(TRUE, vapply(r[-1], ring_km2, 0) >= min_km2)]; r }
  if (inherits(g, "MULTIPOLYGON")) st_multipolygon(lapply(unclass(g), one)) else st_polygon(one(unclass(g)))
}
n_holes <- sum(lengths(st_geometry(borders)) - 1L)
st_geometry(borders) <- st_sfc(lapply(st_geometry(borders), drop_holes, border_min_km2), crs = st_crs(crs))
cat(sprintf("Borders: %d land parts (>= %d km2), %d of %d holes kept; %d pale islands (>= %d km2)\n", nrow(borders), border_min_km2,
            sum(lengths(st_geometry(borders)) - 1L), n_holes, nrow(isles), isle_min_km2))
assert(all(intersect(ssa$iso, snow$Country_ID) %in% borders$iso) && "COM" %in% isles$iso && !"COM" %in% borders$iso && "TZA" %in% isles$iso,
       "a border for every country with a polygon; the Comoros and Zanzibar are pale islands")
b_iso <- sort(unique(borders$iso)); o_iso <- under$iso %in% c(S$north_africa, "ESH")
cg <- c(do.call(c, lapply(b_iso, function(i) st_union(st_geometry(borders)[borders$iso == i]))), st_geometry(under)[o_iso])
land_lines <- shared_lines(cg, draw = seq_along(cg) <= length(b_iso), tol = border_tol)
poly_lines <- shared_lines(st_geometry(snow), draw = rep(TRUE, nrow(snow)), tol = poly_tol)
len_km <- function(x) sum(as.numeric(st_length(x))) / 1e3
cat(sprintf("Lines drawn: national land borders %.0f km (tolerance %d m) of %.0f km of land-part boundary; Snow polygon boundaries %.0f km (tolerance %d m) of %.0f km\n",
            len_km(land_lines), border_tol, len_km(st_boundary(st_geometry(borders))), len_km(poly_lines), poly_tol, len_km(st_boundary(st_geometry(snow)))))
assert(len_km(land_lines) > 2e4 && len_km(land_lines) < len_km(st_boundary(st_geometry(borders))) && len_km(poly_lines) > 5e4, "shared boundaries extracted")
oc <- suppressWarnings(st_cast(st_union(c(st_geometry(north), st_geometry(esh))), "POLYGON"))
outside_coast <- st_sfc(lapply(oc, function(g) st_polygon(list(g[[1]]))), crs = st_crs(crs))
outside_coast <- outside_coast[as.numeric(st_area(outside_coast)) / 1e6 >= isle_min_km2]
grey_line <- "#9A9A9A"
# Pale fill: North Africa and Western Sahara dissolved into one shape (no lines or anti-aliasing seams inside it), and the
# sub-Saharan countries, whose fill shows only on islands without a Snow polygon.
under_fill <- rbind(st_sf(iso = ssa$iso, geometry = st_geometry(ssa)),
                    st_sf(iso = "outside", geometry = st_union(c(st_geometry(north), st_geometry(esh)))))

# Lakes: Natural Earth 1:10m, prefiltered in longitude/latitude, then those inside the frame with area >= lake_min_km2.
lake_min_km2 <- 300
lk <- st_read(paths[["lakes"]], quiet = TRUE)
assert(all(c("name", "featurecla", "scalerank") %in% names(lk)), "lakes have name, featurecla, scalerank")
ll <- st_bbox(st_transform(st_segmentize(frame, 50e3), 4326))
ll_box <- st_as_sfc(st_bbox(c(xmin = ll[["xmin"]] - 2, ymin = ll[["ymin"]] - 2, xmax = ll[["xmax"]] + 2, ymax = ll[["ymax"]] + 2), crs = st_crs(4326)))
lk <- st_make_valid(lk[, c("name", "featurecla", "scalerank")])
lk <- suppressMessages(lk[lengths(st_intersects(lk, ll_box)) > 0, ])
lk <- prep(lk); lk <- lk[lengths(st_intersects(lk, frame)) > 0, ]
lk$area_km2 <- as.numeric(st_area(lk)) / 1e6
lakes <- lk[lk$area_km2 >= lake_min_km2, ]; lakes <- lakes[order(-lakes$area_km2), ]
must <- c("Lake Victoria", "Lake Tanganyika", "Lake Malawi", "Lake Turkana", "Lake Albert", "Lake Edward", "Lake Kivu", "Lake Kyoga", "Lac Moeru",
          "Lake Bangweulu", "Lake Tana", "Lake Abaya", "Lake Volta", "Lake Kariba", "Kainji Reservoir", "Lago de Cahora Bassa", "Lake Chad")
assert(all(must %in% lakes$name), paste("lakes drawn include", paste(setdiff(must, lakes$name), collapse = ", ")))
cat(sprintf("Lakes: %d of %d in the frame have >= %d km2: %s\n", nrow(lakes), nrow(lk), lake_min_km2, paste(lakes$name, collapse = "; ")))
# Islands of less than lake_hole_km2 (the Ssese islands and others) are drawn as water: their outlines would print as dark
# specks inside the lakes. Larger islands (Ukerewe, Idjwi and others) keep their fill.
lake_hole_km2 <- 200
assert(all(st_geometry_type(lakes) %in% c("POLYGON", "MULTIPOLYGON")), "lakes are polygons")
lake_holes <- function(g) sum(vapply(if (inherits(g, "MULTIPOLYGON")) unclass(g) else list(unclass(g)), function(p) length(p) - 1L, 0L))
n_lake_holes <- sum(vapply(st_geometry(lakes), lake_holes, 0))
st_geometry(lakes) <- st_sfc(lapply(st_geometry(lakes), drop_holes, lake_hole_km2), crs = st_crs(crs))
cat(sprintf("Lake islands: %d of %d kept (>= %d km2)\n", sum(vapply(st_geometry(lakes), lake_holes, 0)), n_lake_holes, lake_hole_km2))
lake_u <- st_union(st_geometry(lakes))

# Gaps: national land (sub-Saharan admin0) not covered by any Snow polygon. A piece is attached to the polygons it
# touches (or, for numerically detached slivers, comes within 100 m of); it takes the class of an attached polygon of its
# own country where there is one. Pieces touching no polygon are islands without a polygon and keep the pale underlay.
gap <- st_difference(st_union(st_geometry(ssa)), st_union(st_geometry(snow)))
pieces <- st_sf(geometry = suppressWarnings(st_cast(st_collection_extract(gap, "POLYGON"), "POLYGON")))
pieces$area_km2 <- as.numeric(st_area(pieces)) / 1e6
hits <- st_intersects(pieces, snow)
ni <- which(lengths(hits) == 0)
if (length(ni)) hits[ni] <- st_intersects(st_buffer(st_geometry(pieces)[ni], 100), snow)
pieces$attached <- lengths(hits) > 0
pi_iso <- st_intersects(st_point_on_surface(st_geometry(pieces)), ssa)
pieces$iso <- ssa$iso[vapply(pi_iso, function(j) if (length(j)) j[1] else NA_integer_, 1L)]
pieces$lake_cover <- 0
hit <- which(pieces$area_km2 >= 1 & lengths(st_intersects(pieces, lake_u)) > 0)
pieces$lake_cover[hit] <- vapply(hit, function(i) sum(as.numeric(st_area(st_intersection(st_geometry(pieces)[i], lake_u)))) / 1e6 / pieces$area_km2[i], 0)
pieces$role <- fifelse(pieces$lake_cover >= 0.5, "water", fifelse(pieces$attached, "fringe", "no_polygon"))
fi <- which(pieces$role == "fringe")
fr <- pieces[fi, ]
fr$Admin_ID <- vapply(seq_along(fi), function(k) { j <- hits[[fi[k]]]; own <- j[snow$Country_ID[j] %in% fr$iso[k]]
  snow$Admin_ID[if (length(own)) own[1] else j[1]] }, "")
fringe <- do.call(rbind, lapply(split(seq_len(nrow(fr)), fr$Admin_ID), function(i) st_sf(Admin_ID = fr$Admin_ID[i[1]], geometry = st_union(st_geometry(fr)[i]))))
fringe$key <- pol$key[match(fringe$Admin_ID, pol$Admin_ID)]
water <- st_sf(geometry = st_union(c(lake_u, st_geometry(pieces[pieces$role == "water", ]))))
nop <- pieces[pieces$role == "no_polygon", ]
assert(!anyNA(nop$iso), "every island piece without a polygon lies in a country")
nop_area <- tapply(nop$area_km2, nop$iso, sum)
gap_tab <- as.data.table(st_drop_geometry(pieces))[, .(pieces = .N, km2 = round(sum(area_km2), 1), max_km2 = round(max(area_km2), 1)), by = role]
print(gap_tab)
wp <- pieces[pieces$role == "water", ]; wc <- st_coordinates(st_transform(st_point_on_surface(st_geometry(wp)), 4326))
cat("Water gaps (lon, lat, km2, lake cover):", paste(sprintf("(%.1f, %.1f, %.0f, %.2f)", wc[, 1], wc[, 2], wp$area_km2, wp$lake_cover), collapse = " "), "\n")
assert(all(adm0$iso[adm0$iso == "COM"] %in% nop$iso) && isTRUE(nop_area[["TZA"]] > 1000), "the Comoros and Zanzibar have no Snow polygon")
islands <- pol[Type == "Island"]
assert(any(grepl("Bioko", islands$AFR_Admin)) && any(grepl("Annobon", islands$AFR_Admin)), "the island polygons are Bioko and Annobon")
assert(all(pol[Country_ID == "LSO", Type] == "Malaria free"), "Lesotho is wholly malaria free")
snow <- merge(snow[, c("Admin_ID", "geometry")], as.data.frame(pol[, .(Admin_ID, key)]), by = "Admin_ID")
tick("geometry prepared")

## 4. Palette and its colour-vision check (Machado et al. 2009, severity 1; CIE76 dE in CIELAB) ---------------------------
keys <- c(data_keys, "spacer", "nodata", "excluded", "lake", "outside")
fills <- c(setNames(c("#FEE391", "#FEC44F", "#FE9929", "#EC7014", "#CC4C02", "#8C2D04"), data_keys),   # ColorBrewer YlOrBr, palest step dropped
           spacer = NA, nodata = "#D9D9D9", excluded = "#B5AFA3", lake = "#A9CFE8", outside = "#F4F4F2")
assert(length(data_keys) == 6L, "six data colours for six classes")
lake_line <- "#7FB3DD"                                     # light enough that narrow reservoir arms read as light blue
cvd <- list(normal = diag(3),
  protan = matrix(c(0.152286, 1.052583, -0.204868, 0.114503, 0.786281, 0.099216, -0.003882, -0.048116, 1.051998), 3, byrow = TRUE),
  deutan = matrix(c(0.367322, 0.860646, -0.227968, 0.280085, 0.672501, 0.047413, -0.011820, 0.042940, 0.968881), 3, byrow = TRUE),
  tritan = matrix(c(1.255528, -0.076749, -0.178779, -0.078411, 0.930809, 0.147602, 0.004733, 0.691367, 0.303900), 3, byrow = TRUE))
lin <- function(v) ifelse(v <= 0.04045, v / 12.92, ((v + 0.055) / 1.055)^2.4)
enc <- function(v) { v <- pmin(pmax(v, 0), 1); ifelse(v <= 0.0031308, 12.92 * v, 1.055 * v^(1 / 2.4) - 0.055) }
lab_sim <- function(hex, m) grDevices::convertColor(enc(t(m %*% t(lin(t(grDevices::col2rgb(hex)) / 255)))), from = "sRGB", to = "Lab")
pk <- setdiff(keys, "spacer")
dE <- lapply(cvd, function(m) { L <- lab_sim(unname(fills[pk]), m); rownames(L) <- pk; as.matrix(dist(L)) })
adj_min <- min(vapply(dE, function(D) min(D[cbind(data_keys[-nb], data_keys[-1])]), 0))
neutral_min <- min(vapply(dE, function(D) min(D[c("nodata", "excluded", "lake", "outside"), data_keys]), 0))
nodata_excl <- min(vapply(dE, function(D) D["nodata", "excluded"], 0)); nodata_out <- min(vapply(dE, function(D) D["nodata", "outside"], 0))
cat(sprintf("Palette dE76 (worst of normal, protan, deutan, tritan): adjacent classes %.1f; neutral or lake vs class %.1f; no data vs malaria free %.1f; no data vs outside %.1f\n",
            adj_min, neutral_min, nodata_excl, nodata_out))
assert(adj_min >= 10 && neutral_min >= 15 && nodata_excl >= 12 && nodata_out >= 8, "palette separation under colour-vision deficiency")
L_normal <- lab_sim(unname(fills[data_keys]), cvd$normal)[, 1]
assert(all(diff(L_normal) < 0), "data classes darken monotonically")

## 5. Map -------------------------------------------------------------------------------------------------------------
# Sizes meet the paper's printed text-size rule (CLAUDE.md) at the printed width; line widths and the scale bar ticks are
# those of the former 180 mm canvas scaled to 156 mm. The longer legend entries wrap so the legend stays clear of land.
fs <- list(title = 12, legend = 10)                          # pt at final size
leg_xy <- c(0.02, 0.555)                                      # legend top-left (npc)
bar_len <- 1e6; bar_x0 <- xr[1] + 0.76 * W; bar_y <- yr[1] + 0.03 * H
labels <- c(lab_fig, spacer = " ", nodata = "Malaria endemic,\nno data in the analysis", excluded = "Malaria free or island,\nnot analysed",
            lake = "Lake or reservoir", outside = "Outside the study area\nor no polygon")
key_col <- c(rep(NA, nb), NA, "grey55", NA, lake_line, grey_line)
border_lw <- 0.22                                             # ggplot linewidth (x 0.75 = 0.16 mm); national land borders, no halo
mapp <- ggplot() +
  geom_sf(data = under_fill, aes(fill = "outside"), colour = NA) +           # no lines inside the pale areas
  geom_sf(data = fringe, aes(fill = key), colour = NA, show.legend = FALSE) +
  geom_sf(data = snow, aes(fill = key), colour = NA) +
  geom_sf(data = poly_lines, colour = "#FFFFFF", linewidth = 0.13, lineend = "round", linejoin = "round") +
  geom_sf(data = outside_coast, fill = NA, colour = grey_line, linewidth = 0.13) +
  geom_sf(data = isles, fill = NA, colour = grey_line, linewidth = 0.13) +
  geom_sf(data = land_lines, colour = "#1A1A1A", linewidth = border_lw, lineend = "round", linejoin = "round") +
  geom_sf(data = water, aes(fill = "lake"), colour = lake_line, linewidth = 0.1) +
  annotate("segment", x = bar_x0, xend = bar_x0 + bar_len, y = bar_y, yend = bar_y, linewidth = 0.35, lineend = "butt") +
  annotate("segment", x = bar_x0 + c(0, bar_len), xend = bar_x0 + c(0, bar_len), y = bar_y - mm(0.5), yend = bar_y + mm(0.5), linewidth = 0.35, lineend = "butt") +
  annotate("text", x = bar_x0 + bar_len / 2, y = bar_y + mm(1.5), label = paste(f0(bar_len / 1e3), "km"), size = fs$legend / .pt, vjust = 0) +
  scale_fill_manual(values = fills, breaks = keys, limits = keys, labels = labels, drop = FALSE, na.value = NA, na.translate = FALSE,
                    name = "Complete birth\nhistories per\npolygon (mothers)",
                    guide = guide_legend(override.aes = list(colour = key_col, linewidth = 0.22))) +
  coord_sf(xlim = xr, ylim = yr, expand = FALSE, datum = NA) +
  theme_void(base_size = fs$legend) +
  theme(plot.margin = margin(0, 0, 0, 0), plot.background = element_rect(fill = "white", colour = NA),
        legend.position = "inside", legend.position.inside = leg_xy, legend.justification = c(0, 1),
        legend.background = element_blank(), legend.margin = margin(0, 0, 0, 0), legend.box.margin = margin(0, 0, 0, 0),
        legend.key.size = unit(4, "mm"), legend.key.spacing.y = unit(0.6, "mm"),
        legend.title = element_text(size = fs$title, face = "bold", lineheight = 0.95, margin = margin(0, 0, 1.5, 0, "mm")),
        legend.text = element_text(size = fs$legend, margin = margin(0, 0, 0, 1.4, "mm")))

# Measured layout: the legend's size on a device of the final size, and clearance of legend and scale bar from land.
tmp <- tempfile(fileext = ".png"); ragg::agg_png(tmp, width = fig_w, height = fig_h, units = "mm", res = 400)
g <- ggplotGrob(mapp); leg <- g$grobs[[which(g$layout$name == "guide-box-inside")]]
leg_w <- grid::convertWidth(sum(leg$widths), "mm", valueOnly = TRUE); leg_h <- grid::convertHeight(sum(leg$heights), "mm", valueOnly = TRUE)
invisible(dev.off()); unlink(tmp)
assert(leg_w > 20 && leg_w < 90 && leg_h > 20 && leg_h < 90, sprintf("legend size measured (%.1f x %.1f mm)", leg_w, leg_h))
lt <- npc(leg_xy[1], leg_xy[2])
elems <- list(legend = box_sf(lt[1], lt[2] - mm(leg_h), lt[1] + mm(leg_w), lt[2]),
              scale_bar = box_sf(bar_x0, bar_y - mm(0.5), bar_x0 + bar_len, bar_y + mm(1.5 + fs$legend * 0.3528)))
land <- c(st_geometry(snow), st_geometry(under))
clear <- vapply(elems, function(e) min(as.numeric(st_distance(e, land))) / m_per_mm, 0)
inside <- vapply(elems, function(e) isTRUE(st_within(e, frame, sparse = FALSE)[1, 1]), TRUE)
cat(sprintf("Layout: legend %.1f x %.1f mm; clearance from land: %s mm\n", leg_w, leg_h, paste(names(clear), round(clear, 1), collapse = ", ")))
assert(all(clear >= 2.5) && all(inside), "legend and scale bar inside the frame and >= 2.5 mm from land")

png_path <- file.path(out, "analysis_units_map.png")
ggsave(png_path, mapp, width = fig_w, height = fig_h, units = "mm", dpi = 400, device = ragg::agg_png, bg = "white")
tick("figure written")

## 6. Caption ---------------------------------------------------------------------------------------------------------
cov <- as.data.table(cbh_read_csv(paths[["coverage"]]))
assert(setequal(cov$survey, inc) && nrow(cov) == length(inc), "survey_coverage.csv lists the included surveys")
assert(all(cov$type %in% c("DHS", "MIS", "MICS")), "survey programmes")
n_dhs <- sum(cov$type %in% c("DHS", "MIS")); n_mics <- sum(cov$type == "MICS"); assert(n_dhs + n_mics == smp$surveys, "DHS/MIS + MICS surveys = prepared_sample surveys")
dhs_word <- if (any(cov$type == "MIS")) "DHS or MIS" else "DHS"
cn <- setNames(as.character(adm0$name_0), adm0$iso)
cn[c("COG", "GMB", "CPV", "TZA", "COD", "CIV")] <- c("Republic of the Congo", "The Gambia", "Cabo Verde", "Tanzania", "DR Congo", "C\u00F4te d'Ivoire")
and_list <- function(v) if (length(v) <= 1) v else paste(paste(v[-length(v)], collapse = ", "), "and", v[length(v)])
no_survey <- pol[Type == "Endemic" & !Country_ID %in% A$country, .N, by = Country_ID]
nodata_other <- pol[key == "nodata" & !Country_ID %in% no_survey$Country_ID, .N, by = Country_ID]
assert(all(pol[Country_ID %in% no_survey$Country_ID & Type == "Endemic", key] == "nodata"), "no data in countries without a survey")
assert(all(c(A$country, no_survey$Country_ID, nodata_other$Country_ID) %in% names(cn)), "country names")
no_survey <- no_survey[order(cn[Country_ID])]; nodata_other <- nodata_other[order(cn[Country_ID])]
fw <- merge(fieldwork, cov[, .(survey, year)], by = "survey")
assert(nrow(fw) == length(inc) && all(fw$y0 >= fw$year - 1L & fw$y1 <= fw$year + 2L),
       "interview years of each survey within one year before and two after its registry year (Gregorian dates)")
nodata_txt <- and_list(c(sprintf("%d in the %d countries that have malaria-endemic polygons but no included survey (%s)", sum(no_survey$N), nrow(no_survey), and_list(unname(cn[no_survey$Country_ID]))),
                         sprintf("%d in %s", nodata_other$N, cn[nodata_other$Country_ID])))
pct_m <- 100 * mothers_merged / n_mothers
frac_txt <- function(p) if (isTRUE(all.equal(p, 0.5))) "half" else sprintf("%s%%", 100 * p)
src_scale <- sub("^ne_([0-9]+m)_.*$", "1:\\1", basename(paths[["lakes"]]))
# Lines 1-2 are the heading (04_paper_figures.R drops them and adds its own figure label).
caption <- c("# Figure 1 caption", "",
  sprintf(paste0("Complete birth histories used in the primary analysis, by sub-national polygon of Snow et al. (2017). ",
    "Fill: interviewed mothers with at least one child-band record in the analysis, summed over the %d included surveys ",
    "(%d %s and %d MICS; interviews %d–%d) in %d countries; in total %s mothers contribute %s child-band records and %s deaths. ",
    "Records are placed in the polygon holding at least %s%% of the GPW 2020 population of their reported area, otherwise in the malaria-endemic ",
    "polygons each holding at least %s%% (malaria-free parts are left out, and areas more than %s malaria free are dropped). ",
    "In %d of the %s survey × area units this gives a union of two or more polygons; the %s mothers (%.1f%%) in these unions are divided ",
    "among their polygons by population share. ",
    "The %d polygons with data hold a median of %s mothers (range %s–%s) from a median of %s surveys (range %d–%d)."),
    length(inc), n_dhs, dhs_word, n_mics, min(fw$y0), max(fw$y1), uniqueN(A$country), f0(n_mothers), f0(n_records), f0(n_deaths),
    100 * S$whole, 100 * S$link, frac_txt(S$malaria_free_drop), sum(A$n_polygons > 1), f0(nrow(A)), f0(mothers_merged), pct_m,
    nrow(used), f0(round(median(used$mothers))), f0(round(min(used$mothers))), f0(round(max(used$mothers))), f0(median(used$surveys)),
    as.integer(min(used$surveys)), as.integer(max(used$surveys))), "",
  sprintf(paste0("Light grey: the %d malaria-endemic polygons without data, %s. ",
    "Warm grey: the %d malaria-free and %d island polygons (Bioko, Annobón), not analysed. ",
    "Pale: North Africa and Western Sahara, and islands without a polygon such as the Comoros and Zanzibar. ",
    "Light blue: the %d lakes and reservoirs of at least %d km² within the map in Natural Earth (%s), drawn over the polygons and national borders. ",
    "Slivers between the polygons and the national boundaries take the class of the adjacent polygon. ",
    "White lines: polygon boundaries; black lines: national land borders of the sub-Saharan countries. Africa Albers equal-area projection (%s); the scale bar is approximate."),
    n_cls[["nodata"]], nodata_txt, sum(pol$Type == "Malaria free"), sum(pol$Type == "Island"), nrow(lakes), lake_min_km2, src_scale, crs), "",
  "Survey years, inclusion and exclusions by country are shown in the supplementary survey map and timing figure.")
con <- file(file.path(out, "CAPTION.md"), open = "w", encoding = "UTF-8"); writeLines(caption, con); close(con)

## 7. Polygon table and provenance -------------------------------------------------------------------------------------
r9 <- function(v) round(v, 9)                      # apportioned values, written so that their sums check at 1e-6
tab <- pol[, .(Admin_ID, country = Country_ID, snow_name = AFR_Admin, Type, surveys = as.integer(surveys),
               mothers = r9(mothers), records = r9(records), deaths = r9(deaths), class)]
assert(abs(sum(tab$mothers) - n_mothers) < 1e-6 && abs(sum(tab$records) - n_records) < 1e-6 && abs(sum(tab$deaths) - n_deaths) < 1e-6,
       "polygon table sums = mothers, records and deaths at 1e-6")
cbh_atomic_csv(as.data.frame(tab), file.path(out, "analysis_units_by_polygon.csv"))
inputs <- unique(rel(c(unname(paths), shp_parts, file.path(shard_dirs, "manifest.rds"), shard_files)))
assert(all(file.exists(inputs)), "provenance inputs exist")
cbh_atomic_csv(data.frame(file = inputs, md5 = vapply(inputs, cbh_file_hash, ""), row.names = NULL), file.path(out, "provenance.csv"))
cat(sprintf("Figure 1 analysis units map: %d surveys (%d DHS, %d MICS), %d countries, %s areas (%d merged); %d polygons with data, %d no data, %d not analysed; %s mothers; classes %s -> %s\n",
            length(inc), n_dhs, n_mics, uniqueN(A$country), f0(nrow(A)), sum(A$n_polygons > 1), nrow(used), n_cls[["nodata"]], n_cls[["excluded"]],
            f0(n_mothers), paste(sprintf("%s:%d", lab_csv, as.integer(n_cls[data_keys])), collapse = " "), png_path))
tick("done")
