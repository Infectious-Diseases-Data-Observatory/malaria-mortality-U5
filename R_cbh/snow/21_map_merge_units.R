#!/usr/bin/env Rscript
# One map per country where survey data cannot be aligned with single Snow et al. polygons (user request, 11 October
# 2026): the countries with at least one merged unit (a union of Snow polygons, 08_units.R). One panel per survey with
# merged units. Snow polygons are coloured by how the survey's units use them (own unit; part of a merged unit only;
# both), with merged units outlined; survey-region boundaries are drawn in white. Ported from the map section of the
# analysis project's 19_merge_rule_all.R. Aggregates only.
# Output: <out>/maps/merge_units/<ISO3>_merge_units.png, merge_units_by_country.csv
suppressPackageStartupMessages({ library(data.table); library(sf); library(ggplot2) })
sf_use_s2(FALSE)
source("R_cbh/R/geography.R"); source("R_cbh/snow/R/settings.R")
S <- snow_settings(); stopifnot(identical(S$rule, "merge"))
mout <- file.path(S$out, "maps", "merge_units"); dir.create(mout, recursive = TRUE, showWarnings = FALSE)
units <- fread(file.path(S$out, "units", "units.csv"))
bys <- fread(file.path(S$out, "units", "units_by_survey.csv"))
snow <- st_transform(readRDS(file.path(S$private, "polygons_551.rds")), "ESRI:102022")
recs <- readRDS(file.path(S$private, "records_units.rds"))[, .(survey, survey_year, regkey)]
yr <- recs[, .(year = as.integer(names(which.max(table(survey_year))))), by = survey]
regions_of <- unique(recs[, .(survey, regkey)]); rm(recs); invisible(gc())
registry <- fread("data/derived_dhs/survey_registry.csv")
region_lines <- function(s) {
  f <- if (startsWith(s, "MC_")) sprintf("data/derived_mics/boundaries/%s.rds", s) else registry[svkey == s, boundary_file][1]
  b <- st_make_valid(readRDS(f)); b$regkey <- cbh_rkey(b$DHSREGEN)
  st_sf(survey = s, geometry = st_geometry(st_transform(b[b$regkey %in% regions_of[survey == s, regkey], ], "ESRI:102022")))
}
levels_k <- c("Snow polygon is a unit", "Part of merged unit(s) only", "Both: own unit and part of a merged unit",
              "No records", "Malaria-free or island unit")
fills <- setNames(c("#1B7A5A", "#F2B134", "#9FD3B6", "#F4F4F4", "#D9D5CC"), levels_k)
ct <- bys[, .(surveys = .N, surveys_merged = sum(merged_units > 0), records = sum(records), records_in_merged = sum(records_in_merged),
              units = sum(units), merged_units = sum(merged_units)), by = country][, pct_in_merged := 100 * records_in_merged / records]
fwrite(ct[order(-pct_in_merged)], file.path(mout, "merge_units_by_country.csv"))
for (iso in ct[merged_units > 0, sort(country)]) {
  ss <- merge(bys[country == iso & merged_units > 0], yr, by = "survey")[order(year, survey)]
  ss[, panel := sprintf("%s %d (%s)\n%d units, %d merged\n%.0f%% of records in merged units",
                        fifelse(startsWith(survey, "MC_"), "MICS", "DHS"), year, survey, units, merged_units, 100 * records_in_merged / records)]
  sc <- snow[snow$Country_ID == iso, ]
  panels <- lapply(seq_len(nrow(ss)), function(i) {
    s <- ss$survey[i]; u <- units[survey == s]; ps <- strsplit(u$unit, "+", fixed = TRUE)
    own <- unique(unlist(ps[u$n_polygons == 1])); inm <- unique(unlist(ps[u$n_polygons > 1]))
    k <- fcase(!sc$in520, levels_k[5], sc$Admin_ID %in% own & sc$Admin_ID %in% inm, levels_k[3],
               sc$Admin_ID %in% own, levels_k[1], sc$Admin_ID %in% inm, levels_k[2], default = levels_k[4])
    g <- sc; g$kind <- factor(k, levels_k); g$panel <- ss$panel[i]
    mu <- u[n_polygons > 1]
    outl <- do.call(rbind, lapply(seq_len(nrow(mu)), function(j)
      st_sf(panel = ss$panel[i], geometry = st_union(sc[sc$Admin_ID %in% strsplit(mu$unit[j], "+", fixed = TRUE)[[1]], ]))))
    list(fill = g, outline = outl, regions = transform(region_lines(s), panel = ss$panel[i]))
  })
  G <- do.call(rbind, lapply(panels, `[[`, "fill")); O <- do.call(rbind, lapply(panels, `[[`, "outline")); Rl <- do.call(rbind, lapply(panels, `[[`, "regions"))
  for (z in c("G", "O", "Rl")) { x <- get(z); x$panel <- factor(x$panel, ss$panel); assign(z, x) }
  n <- nrow(ss); ncol <- min(n, 4L); nr <- ceiling(n / ncol)
  bb <- st_bbox(sc); asp <- unname((bb["ymax"] - bb["ymin"]) / (bb["xmax"] - bb["xmin"]))
  p <- ggplot() +
    geom_sf(data = G, aes(fill = kind), colour = "grey40", linewidth = 0.12, show.legend = TRUE) +
    geom_sf(data = Rl, fill = NA, colour = "white", linewidth = 0.35) +
    geom_sf(data = O, fill = NA, colour = "black", linewidth = 0.5) +
    facet_wrap(~panel, ncol = ncol) +
    scale_fill_manual(values = fills, drop = FALSE, name = "Snow polygon") +
    coord_sf(datum = NA) +
    labs(title = sprintf("%s: analysis units (merge rule)", iso),
         caption = paste0("Thick black: merged units (unions of Snow polygons; units of a survey can overlap). White: survey-region boundaries. ",
                          "Thin grey: Snow polygons.\nA unit is one Snow polygon if it holds >= 90% of the record's smallest reported unit, ",
                          "else every polygon holding >= 5%; units more than half malaria-free are dropped.")) +
    theme_void(base_size = 8.5) +
    theme(legend.position = "bottom", legend.title = element_text(size = 7.5), legend.text = element_text(size = 7),
          legend.key.size = unit(3.2, "mm"), strip.text = element_text(size = 7.2, margin = margin(2, 0, 2, 0)),
          plot.title = element_text(size = 9.5, face = "bold", margin = margin(0, 0, 4, 0)),
          plot.caption = element_text(size = 6.6, colour = "grey30", hjust = 0),
          plot.background = element_rect(fill = "white", colour = NA), plot.margin = margin(6, 6, 6, 6)) +
    guides(fill = guide_legend(nrow = 3, title.position = "top"))
  w <- 180; pw <- (w - 12) / ncol
  ggsave(file.path(mout, sprintf("%s_merge_units.png", iso)), p, width = w, height = min(240, nr * (pw * asp + 16) + 36),
         units = "mm", dpi = 300, device = ragg::agg_png, bg = "white")
}
pngs <- list.files(mout, "_merge_units[.]png$", full.names = TRUE)
cat(sprintf("%s: %d countries with merged units\n", S$variant, length(pngs)))
