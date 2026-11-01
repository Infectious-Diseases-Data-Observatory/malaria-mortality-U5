#!/usr/bin/env Rscript
# Download MAP's own admin-0 (national) and admin-1 PfPR2-10 estimates, with lower and upper interval bounds, for one
# release from MAP's platform API (the backend of https://data.malariaatlas.org/trends), and save them as tidy CSVs:
#   data/map_pfpr_admin0_<release>.csv: iso3, year, mean, lci, uci (proportions 0-1)
#   data/map_pfpr_admin1_<release>.csv: admin unit id and names, year, mean, lci, uci
# The responses are JSON-stat (dimension ids, sizes and category indexes; values flattened with the last dimension
# varying fastest). MAP does not state the interval level. Usage: Rscript R_inputs/fetch/fetch_map_national_pfpr.R 202608
args <- commandArgs(trailingOnly = TRUE); stopifnot(length(args) == 1L)
release <- args[1]
base <- "https://data.malariaatlas.org"
get_json <- function(path) {
  r <- httr::GET(paste0(base, path), httr::timeout(120))
  if (httr::status_code(r) != 200) stop("HTTP ", httr::status_code(r), " for ", path)
  jsonlite::fromJSON(rawToChar(r$content), simplifyVector = FALSE)
}
# Flatten a JSON-stat dataset into a data frame with one column per dimension plus the value.
jsonstat <- function(j, value_name) {
  ids <- unlist(j$id); sizes <- unlist(j$size)
  cats <- lapply(ids, function(d) unlist(j$dimension[[d]]$category$index))
  stopifnot(identical(lengths(cats), as.integer(sizes)))
  grid <- expand.grid(rev(cats), stringsAsFactors = FALSE)[, rev(seq_along(ids)), drop = FALSE]   # last dimension fastest
  names(grid) <- ids
  v <- rep(NA_real_, prod(sizes))
  if (is.null(names(j$value))) v[seq_along(j$value)] <- vapply(j$value, function(x) if (is.null(x)) NA_real_ else as.numeric(x), 0)
  else v[as.integer(names(j$value)) + 1L] <- vapply(j$value, function(x) if (is.null(x)) NA_real_ else as.numeric(x), 0)
  grid[[value_name]] <- v
  grid
}
fetch_level <- function(level) {
  parts <- lapply(c("mean", "lci", "uci"), function(s) {
    j <- get_json(sprintf("/map-platform-app-backend/api/v1/trends/malaria/Pf_PR-rate/%s/%s?version=%s", level, s, release))
    stopifnot(grepl(paste0("version=", release), j$label), grepl("PfPRRate", j$label))
    jsonstat(j, s)
  })
  keys <- setdiff(names(parts[[1]]), "mean")
  d <- Reduce(function(a, b) merge(a, b, by = keys), parts)
  names(d)[names(d) == "Year"] <- "year"; d$year <- as.integer(d$year)
  d
}
a0 <- fetch_level("admin0")
names(a0)[names(a0) == "ISO"] <- "iso3"
stopifnot(!anyNA(a0$mean), !anyDuplicated(a0[, c("iso3", "year")]))
a0 <- a0[order(a0$iso3, a0$year), c("iso3", "year", "mean", "lci", "uci")]
write.csv(a0, file.path("data", sprintf("map_pfpr_admin0_%s.csv", release)), row.names = FALSE)
message(sprintf("admin0: %d countries, years %d-%d", length(unique(a0$iso3)), min(a0$year), max(a0$year)))

a1 <- fetch_level("admin1")
unit_dim <- setdiff(names(a1), c("year", "mean", "lci", "uci"))
stopifnot(length(unit_dim) == 1L)
units <- get_json("/admin-unit-metadata/admin-units/ADMIN1?mapAdmin=2023_mg_5k")
meta <- data.frame(id = vapply(units, function(u) as.character(u$id), ""), name = vapply(units, function(u) as.character(u$name), ""),
                   country = vapply(units, function(u) as.character(u$countryName), ""),
                   iso3 = vapply(units, function(u) as.character(u$iso3), ""), stringsAsFactors = FALSE)
names(a1)[names(a1) == unit_dim] <- "admin1_id"
a1 <- merge(a1, meta, by.x = "admin1_id", by.y = "id", all.x = TRUE)
message(sprintf("admin1: %d units (%d without names), years %d-%d", length(unique(a1$admin1_id)),
                length(unique(a1$admin1_id[is.na(a1$name)])), min(a1$year), max(a1$year)))
a1 <- a1[order(a1$iso3, a1$admin1_id, a1$year), c("admin1_id", "iso3", "country", "name", "year", "mean", "lci", "uci")]
write.csv(a1, file.path("data", sprintf("map_pfpr_admin1_%s.csv", release)), row.names = FALSE)
