#!/usr/bin/env Rscript
# Neighbourhood graph of the primary sample's geographic units, for spatial random effects (reviewer comment on
# space-time random effects). A unit is a GADM admin-1 polygon or a union of them (ids joined by "+"; R_cbh/units/).
# Polygons are neighbours when they share a border (queen contiguity, 0.01 degree snap, national borders included).
# Two units are neighbours when a polygon of one borders, or is, a polygon of the other (units of different surveys can
# overlap). A group of polygons not connected to the rest is joined to the nearest polygon outside the group (between centroids), so the
# graph is one component.
# Writes <private>/unit_graph.rds (unit names and sparse adjacency matrix) and <out>/unit_graph_summary.csv.
suppressPackageStartupMessages({library(data.table); library(sf); library(spdep); library(Matrix)})
source("R_cbh/primary/settings.R"); source("R_cbh/sensitivity/design/settings.R"); source("R_cbh/units/R/settings.R")
P <- cbh_primary_settings(); S <- cbh_design_settings(); sf_use_s2(FALSE)
units <- sort(unique(as.character(readRDS(P$data)$data$unit)))
parts <- strsplit(units, "+", fixed = TRUE); ids <- sort(unique(unlist(parts)))
g <- st_read(units_settings()$shapefile, quiet = TRUE); stopifnot(all(ids %in% g$Admin_ID), !anyDuplicated(g$Admin_ID))
g <- suppressWarnings(st_make_valid(g[match(ids, g$Admin_ID), ]))
nb <- suppressWarnings(poly2nb(g, queen = TRUE, snap = 0.01))
A <- as(nb2mat(nb, style = "B", zero.policy = TRUE), "CsparseMatrix"); dimnames(A) <- list(ids, ids)
# Join components: each smaller component to the nearest polygon outside it.
added <- list()
repeat {
  comp <- n.comp.nb(mat2listw(as.matrix(A), style = "B", zero.policy = TRUE)$neighbours)
  if (comp$nc == 1) break
  main <- as.integer(names(which.max(table(comp$comp.id))))
  k <- setdiff(unique(comp$comp.id), main)[1]; inside <- which(comp$comp.id == k); outside <- which(comp$comp.id != k)
  sf_use_s2(TRUE); D <- suppressMessages(st_distance(st_centroid(st_geometry(g[inside, ])), st_centroid(st_geometry(g[outside, ])))); sf_use_s2(FALSE); w <- which(D == min(D), arr.ind = TRUE)[1, ]
  i <- inside[w[1]]; j <- outside[w[2]]; A[i, j] <- A[j, i] <- 1
  added[[length(added) + 1]] <- data.frame(polygon = ids[i], joined_to = ids[j], distance_km = as.numeric(min(D)) / 1000)
}
# Units: membership matrix M (unit x polygon); units are neighbours when M (A + I) M' > 0.
M <- sparseMatrix(i = rep(seq_along(units), lengths(parts)), j = match(unlist(parts), ids), x = 1, dims = c(length(units), length(ids)))
U <- M %*% (A + Diagonal(length(ids))) %*% t(M); U <- as(U > 0, "dMatrix"); diag(U) <- 0; U <- drop0(U); dimnames(U) <- list(units, units)
stopifnot(isSymmetric(U), n.comp.nb(mat2listw(as.matrix(U), style = "B")$neighbours)$nc == 1)
saveRDS(list(units = units, adjacency = U, polygons = ids, polygon_adjacency = A), file.path(S$private, "unit_graph.rds"))
deg <- rowSums(U); pdeg <- rowSums(A)
fwrite(data.frame(units = length(units), polygons = length(ids), unit_links = sum(U) / 2, polygon_links = sum(A) / 2,
  links_added_to_connect = length(added), unit_neighbours_min = min(deg), unit_neighbours_median = median(deg), unit_neighbours_max = max(deg),
  polygon_neighbours_min = min(pdeg), polygon_neighbours_median = median(pdeg), polygon_neighbours_max = max(pdeg)), file.path(S$out, "unit_graph_summary.csv"))
if (length(added)) { fwrite(rbindlist(added), file.path(S$out, "unit_graph_added_links.csv")); print(rbindlist(added)) }
print(fread(file.path(S$out, "unit_graph_summary.csv")))
