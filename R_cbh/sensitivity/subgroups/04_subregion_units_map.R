#!/usr/bin/env Rscript
# Supplementary figure (author request, 1 November 2026): the GADM 4.1 admin-1 polygons in each regional sub-analysis
# of the subgroup refits: A West Africa, B Central Africa, C East Africa (the Sahel subset and its panel were removed
# on 18 November 2026, author request: not in the paper). Drawn in the
# style of Figure 1, from the map layers that R_cbh/reporting/23_analysis_units_map.R saves (projection, frame,
# slivers, lakes, borders; the polygons under the list element "layer").
# Membership (R_cbh/sensitivity/subgroups/01_fit.R): by the record's source survey-region and its country
# (region_selection.csv); a polygon holds the record if it is in the record's analysis unit (a polygon or a union of
# polygons), and is in the sub-analysis when all its records are. Polygon counts are checked against the primary's
# Figure 1 table and the subgroup sample sizes against sample_summary.csv.
# Outputs (<subgroups out>/): sfig_subregion_units_map.png (165 mm wide, 400 dpi), CAPTION_sfig_subregion_units_map.md,
# subregion_units_by_polygon.csv, subregion_units_map_provenance.csv. Aggregates only.
# Run from the repository root: Rscript R_cbh/sensitivity/subgroups/04_subregion_units_map.R
suppressPackageStartupMessages({ library(data.table); library(sf); library(ggplot2); library(patchwork) })
sf_use_s2(FALSE)
source("R_cbh/load_pipeline.R"); source("R_cbh/primary/settings.R"); source("R_cbh/sensitivity/subgroups/settings.R")
st <- cbh_subgroup_settings(); P <- cbh_primary_settings(st$primary_version)
if (!identical(P$unit, "gadm")) stop("The sub-region map needs the GADM-unit primary (CBH_PRIMARY_VERSION=gadm).")
panels <- c(west_africa = "A", central_africa = "B", east_africa = "C")
stopifnot(all(names(panels) %in% st$subgroups))
paths <- c(dataset = P$data, regions = file.path(st$out, "region_selection.csv"), samples = file.path(st$out, "sample_summary.csv"),
  definitions = file.path(st$out, "subgroup_definitions.csv"), layers = file.path(P$out, "analysis_units_map/map_layers.rds"),
  figure1 = file.path(P$out, "analysis_units_map/analysis_units_by_polygon.csv"),
  script = "R_cbh/sensitivity/subgroups/04_subregion_units_map.R", settings = "R_cbh/sensitivity/subgroups/settings.R")
stopifnot(all(file.exists(paths)))

## Records, their source survey-regions and their polygons -------------------------------------------------------------
x <- readRDS(P$data)$data
d <- data.table(src_region = paste(as.character(x$country), as.character(x$survey), as.character(x$regkey), sep = ":"),
                unit = as.character(x$unit), death = as.integer(x$death))
rm(x); invisible(gc())
reg <- as.data.table(cbh_read_csv(paths[["regions"]]))
stopifnot(!anyDuplicated(reg$region), all(d$src_region %in% reg$region))
ru <- d[, .(records = .N, deaths = sum(death)), by = .(src_region, unit)]
up <- unique(ru[, .(unit)])[, .(Admin_ID = strsplit(unit, "+", fixed = TRUE)[[1]]), by = unit]
rp <- up[ru, on = "unit", allow.cartesian = TRUE]   # every polygon of each record's unit holds the record
fig1 <- as.data.table(cbh_read_csv(paths[["figure1"]]))
stopifnot(setequal(unique(rp$Admin_ID), fig1[records > 0, Admin_ID]))
total <- rp[, .(records_all = sum(records)), by = Admin_ID]
samples <- as.data.table(cbh_read_csv(paths[["samples"]]))

L <- readRDS(paths[["layers"]])
poly <- as.data.table(L$polygons)
in_sub <- function(s, z) z$src_region %in% reg$region[as.logical(reg[[s]])]
tab <- rbindlist(lapply(names(panels), function(s) {
  k <- rp[in_sub(s, rp), .(records_in = sum(records)), by = Admin_ID]
  z <- merge(poly, total, by = "Admin_ID", all.x = TRUE)[k, on = "Admin_ID", records_in := i.records_in]
  z[is.na(records_all), records_all := 0][is.na(records_in), records_in := 0]
  z[, `:=`(subgroup = s, share_in = fifelse(records_all > 0, records_in / records_all, 0))]
  z[, class := fcase(Type != "Endemic", "not_analysed", records_all == 0, "not_analysed", share_in >= 1 - 1e-12, "in",
                     share_in > 0, "partly", default = "other")]
  # Records of the sub-analysis = sample_summary.csv (counted once per record, not per polygon).
  stopifnot(d[in_sub(s, d), .N] == samples[subgroup == s, records], d[in_sub(s, d), sum(death)] == samples[subgroup == s, deaths])
  z
}))
stopifnot(all(tab$class != "partly"))   # every polygon is wholly in or out of a sub-region
cbh_atomic_csv(as.data.frame(tab[order(subgroup, Admin_ID), .(subgroup, Admin_ID, country = Country_ID, Type, records_in_unit = records_in,
  records_all = records_all, share_in = round(share_in, 9), class)]), file.path(st$out, "subregion_units_by_polygon.csv"))

## Map ----------------------------------------------------------------------------------------------------------------
# Figure 1's neutral tones for the context; the sub-analysis in its colour of the subgroup figures (st$colours). Saved
# 165 mm wide and assumed printed at \linewidth
# (165 mm), so sizes are printed sizes: legend title 11 pt, legend and panel labels 9.5 pt, tags 12 pt (CLAUDE.md).
neutral <- c(other = "#BDBDBD", not_analysed = "#E4E4E4", outside = "#F4F4F2", lake = "#A9CFE8")
label <- c(west_africa = st$labels[["west_africa"]], central_africa = st$labels[["central_africa"]], east_africa = st$labels[["east_africa"]])
fig_w <- 165; W <- diff(L$xr); H <- diff(L$yr); panel_w <- (fig_w - 4) / 2; panel_h <- panel_w * H / W
draw <- function(s) {
  z <- tab[subgroup == s]; key <- setNames(z$class, z$Admin_ID)
  fills <- c(neutral, `in` = st$colours[[s]])
  layer <- L$layer; layer$class <- key[layer$Admin_ID]; fringe <- L$fringe; fringe$class <- key[fringe$Admin_ID]
  stopifnot(!anyNA(layer$class), !anyNA(fringe$class))
  p <- ggplot() +
    geom_sf(data = L$under_fill, fill = neutral[["outside"]], colour = NA) +
    geom_sf(data = fringe, aes(fill = class), colour = NA, show.legend = FALSE) +
    geom_sf(data = layer, aes(fill = class), colour = NA, show.legend = FALSE) +
    geom_sf(data = L$poly_lines, colour = "#FFFFFF", linewidth = 0.09, lineend = "round", linejoin = "round") +
    geom_sf(data = L$outside_coast, fill = NA, colour = L$grey_line, linewidth = 0.1) +
    geom_sf(data = L$isles, fill = NA, colour = L$grey_line, linewidth = 0.1) +
    geom_sf(data = L$land_lines, colour = "#1A1A1A", linewidth = 0.16, lineend = "round", linejoin = "round") +
    geom_sf(data = L$water, fill = neutral[["lake"]], colour = "#7FB3DD", linewidth = 0.08) +
    annotate("text", x = L$xr[1] + 0.03 * W, y = L$yr[1] + 0.30 * H, label = label[[s]], hjust = 0, vjust = 1, size = 9.5 / .pt,
             colour = st$colours[[s]], fontface = "bold") +
    scale_fill_manual(values = fills, drop = FALSE, na.value = NA) +
    coord_sf(xlim = L$xr, ylim = L$yr, expand = FALSE, datum = NA) +
    labs(tag = panels[[s]]) +
    theme_void(base_size = 9.5) +
    theme(plot.tag = element_text(size = 12, face = "bold"), plot.tag.position = c(0.02, 0.98), plot.margin = margin(1, 1, 1, 1, "mm"))
  stopifnot(is.null(p$labels$title), is.null(p$labels$subtitle), is.null(p$labels$caption))
  p
}
# One legend for the three panels, in the fourth cell of the grid: the neutral classes and, as an example of a panel's
# colour, West Africa's.
keys <- c("in", "other", "not_analysed", "lake")
key_lab <- c(`in` = "Polygon in the sub-analysis\n(colour of the panel)", other = "Other polygons in the\nprimary analysis",
             not_analysed = "Not analysed (no data,\nmalaria free or island)", lake = "Lake or reservoir")[keys]
key_fill <- c(`in` = st$colours[["west_africa"]], neutral[c("other", "not_analysed", "lake")])[keys]
legend <- ggplot(data.frame(k = factor(keys, keys), x = seq_along(keys), y = 1)) +
  geom_tile(aes(x, y, fill = k), width = 0, height = 0) +
  scale_fill_manual(values = key_fill, labels = key_lab, name = NULL, drop = FALSE,
                    guide = guide_legend(ncol = 1, override.aes = list(width = 1, height = 1))) +
  theme_void(base_size = 9.5) +
  theme(legend.position = "inside", legend.position.inside = c(0.5, 0.5), legend.text = element_text(size = 9.5),
        legend.key.size = unit(3.6, "mm"), legend.key.spacing.y = unit(2.2, "mm"))
p <- (draw("west_africa") | draw("central_africa")) / (draw("east_africa") | legend) +
  plot_layout(heights = unit(c(panel_h, panel_h), "mm"))
fig_h <- round(2 * panel_h + 4, 1)
png_path <- file.path(st$out, "sfig_subregion_units_map.png")
ggsave(png_path, p, width = fig_w, height = fig_h, units = "mm", dpi = 400, device = ragg::agg_png, bg = "white")

## Caption and provenance -----------------------------------------------------------------------------------------
f0 <- function(v) format(v, big.mark = ",", trim = TRUE, scientific = FALSE)
and_list <- function(v) if (length(v) <= 1) v else paste(paste(v[-length(v)], collapse = ", "), "and", v[length(v)])
cnt <- tab[, .(in_polygons = sum(class == "in"), partly = sum(class == "partly")), by = subgroup]
smp <- samples[match(names(panels), subgroup)]
panel_text <- vapply(names(panels), function(s) {
  k <- cnt[subgroup == s]; m <- smp[subgroup == s]
  sprintf("(%s) %s: %s polygons%s; %s child-band records and %s deaths from %d surveys in %d countries.", panels[[s]], label[[s]],
    f0(k$in_polygons), if (k$partly > 0) sprintf(" (and %d partly)", k$partly) else "", f0(m$records), f0(m$deaths), as.integer(m$surveys),
    as.integer(m$countries))
}, "")
caption <- c("# Supplementary figure caption: polygons of the regional sub-analyses", "",
  paste0("GADM 4.1 admin-1 polygons in each regional sub-analysis of the subgroup refits, in the style of Figure 1. ",
    "West, Central and East Africa hold the surveys of the UN M49 sub-regions of Figure 1 (Middle Africa as Central Africa). ",
    "A polygon is coloured when its records are in the sub-analysis; ",
    "mid grey marks the other polygons of the primary analysis. ",
    paste(panel_text, collapse = " "),
    " Southern Africa is not refitted (too few deaths and too little prevalence), so it has no panel."))
con <- file(file.path(st$out, "CAPTION_sfig_subregion_units_map.md"), open = "w", encoding = "UTF-8"); writeLines(caption, con); close(con)
cbh_atomic_csv(data.frame(file = unname(paths), md5 = vapply(paths, cbh_file_hash, ""), row.names = NULL),
               file.path(st$out, "subregion_units_map_provenance.csv"))
print(cnt); message("Sub-region map written: ", png_path)
