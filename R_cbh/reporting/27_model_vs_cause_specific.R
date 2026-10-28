#!/usr/bin/env Rscript
# Figure 5 (user request, 28 October 2026): country malaria-attributable under-five mortality per 1,000 child-years in
# 2024, PfPR-ACM against the cause-specific estimate of the same all-cause source. A: PfPR-ACM with UN IGME all-cause
# mortality against UN IGME (CA-CODE) malaria deaths over the UN WPP population under 5. B: PfPR-ACM with IHME
# all-cause mortality against IHME malaria deaths over IHME person-years. One point per country, coloured by UN M49
# sub-region as in Figure 4; dashed line: equality; both panels share axis limits. Countries at 2.5 or more per
# 1,000 on either axis are labelled (ISO3 codes). Reads the rates of R_cbh/reporting/25_country_rates_table.R.
# Sizes meet the paper's printed text-size rule (CLAUDE.md) at 6.5 in; no title or caption in the figure.
# Outputs (<out>/model_vs_cause_specific/): fig5_model_vs_cause_specific_2024.png, figure_data.csv, CAPTION.md, provenance.csv
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/reporting/labels.R")
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork) })
st <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION", "regional_mics")); root <- st$out
out <- file.path(root, "model_vs_cause_specific"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
fig_year <- 2024L
paths <- c(rates = file.path(root, sprintf("tables/country_rates_%d.csv", fig_year)))
stopifnot(all(file.exists(paths)))
w <- fread(paths[["rates"]])
stopifnot(nrow(w) == 42L, !anyDuplicated(w$iso3))
m49 <- list(`West Africa` = c("BEN","BFA","CIV","CPV","GHA","GIN","GMB","GNB","LBR","MLI","MRT","NER","NGA","SEN","SLE","TGO"),
  `Central Africa` = c("AGO","CAF","CMR","COD","COG","GAB","GNQ","STP","TCD"),
  `East Africa` = c("BDI","COM","DJI","ERI","ETH","KEN","MDG","MOZ","MUS","MWI","RWA","SOM","SSD","TZA","UGA","ZMB","ZWE"),
  `Southern Africa` = c("BWA","LSO","NAM","SWZ","ZAF"))
region_of <- setNames(rep(names(m49), lengths(m49)), unlist(m49))
colours <- c(`West Africa` = "#0072B2", `Central Africa` = "#CC79A7", `East Africa` = "#009E73", `Southern Africa` = "#E69F00")
d <- rbind(
  w[, .(panel = "A", iso3, country, model = malaria_rate_per1000_unigme, cause_specific = cacode_malaria_rate)],
  w[, .(panel = "B", iso3, country, model = malaria_rate_per1000_ihme, cause_specific = ihme_malaria_rate)])
d[, region := factor(region_of[iso3], levels = names(m49))]
stopifnot(!anyNA(d))
# Labels are ISO3 codes, as in panel A of the burden comparison figure; full names overlap at this size.
label_min <- 2.5
d[, label := fifelse(pmax(model, cause_specific) >= label_min, iso3, "")]
cbh_atomic_csv(d, file.path(out, "figure_data.csv"))
lim <- c(0, max(d$model, d$cause_specific) * 1.04)
panel <- function(p, source_label, tag) ggplot(d[panel == p], aes(model, cause_specific)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey55", linewidth = .35) +
  geom_point(aes(colour = region), size = 1.7) +
  ggrepel::geom_text_repel(aes(label = label), size = 9 / .pt, colour = "grey20", seed = 20261028L, max.overlaps = Inf,
    min.segment.length = 0, segment.colour = "grey60", segment.size = .25, box.padding = .2, point.padding = .12) +
  scale_colour_manual(values = colours, drop = FALSE, name = NULL) +
  scale_x_continuous(limits = lim, breaks = seq(0, 8, 2), expand = expansion(mult = c(0, .02))) +
  scale_y_continuous(limits = lim, breaks = seq(0, 8, 2), expand = expansion(mult = c(0, .02))) +
  coord_equal() +
  labs(x = "Malaria-attributable deaths\nper 1,000 child-years (PfPR-ACM)",
       y = sprintf("Malaria-attributable deaths\nper 1,000 child-years (%s)", source_label), tag = tag) +
  theme_minimal(base_size = 9, base_line_size = .3) +
  theme(axis.title = element_text(size = 11), axis.text = element_text(size = 9), legend.text = element_text(size = 9),
    plot.tag = element_text(size = 12, face = "bold"), panel.grid.minor = element_blank(), plot.margin = margin(4, 8, 4, 4))
p <- panel("A", "UN IGME", "A") + panel("B", "IHME", "B") +
  plot_layout(nrow = 1, guides = "collect") & theme(legend.position = "bottom")
for (q in p$patches$plots) stopifnot(is.null(q$labels$title), is.null(q$labels$subtitle), is.null(q$labels$caption))
ggsave(file.path(out, sprintf("fig5_model_vs_cause_specific_%d.png", fig_year)), p, device = ragg::agg_png,
  width = 6.5, height = 4.1, dpi = 400, bg = "white")
rho <- d[, .(rho = cor(model, cause_specific, method = "spearman"), above = sum(model > cause_specific)), by = panel]
writeLines(c("# Figure 5 caption — PfPR-ACM against cause-specific malaria mortality, by country", "",
  paste0(sprintf("**Figure. Malaria-attributable under-five mortality in %d: PfPR-ACM model against cause-specific estimates.** ", fig_year),
    "Each point is a country; rates are deaths per 1,000 child-years under 5. ",
    "(A) PfPR-ACM estimates using UN IGME all-cause mortality against UN IGME (CA-CODE) malaria deaths, both over the UN WPP population under 5. ",
    "(B) PfPR-ACM estimates using IHME all-cause mortality against IHME malaria deaths, both over IHME person-years. ",
    "The PfPR-ACM estimate counts all deaths averted if prevalence fell to zero (direct and indirect); the cause-specific estimates count deaths assigned to malaria as the underlying cause. ",
    "The dashed line is equality; countries are coloured by UN M49 sub-region (Middle Africa as Central Africa), and those at ", label_min, " or more per 1,000 on either axis are labelled with their ISO 3166-1 alpha-3 codes. ",
    sprintf("Spearman correlation: %.2f (A) and %.2f (B); the PfPR-ACM estimate is higher in %d (A) and %d (B) of %d countries. ",
      rho[panel == "A", rho], rho[panel == "B", rho], rho[panel == "A", above], rho[panel == "B", above], nrow(w)),
    "CA-CODE takes malaria from WHO estimates in 13 low-burden countries; South Sudan's IHME all-cause mortality is its crisis-free value. Point estimates only.")),
  file.path(out, "CAPTION.md"))
provenance <- c(unname(paths), "R_cbh/reporting/27_model_vs_cause_specific.R", "R_cbh/reporting/labels.R")
cbh_atomic_csv(data.frame(file = provenance, md5 = vapply(provenance, cbh_file_hash, "")), file.path(out, "provenance.csv"))
print(rho)
message("Figure 5 saved: ", out)
