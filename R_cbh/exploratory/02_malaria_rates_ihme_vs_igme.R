#!/usr/bin/env Rscript
# Exploratory plot (user request, 27 October 2026): country PfPR-ACM malaria-attributable under-five mortality per
# 1,000 child-years in 2024, from IHME all-cause deaths against UN IGME all-cause deaths, for the 42 burden countries.
# Not part of the pipeline; reads the crisis-free rates of R_cbh/burden/04_annual_comparison.R (Snow-unit primary).
#   Point: one country, coloured by UN M49 sub-region as in the mortality-rate figures; dashed line: equality.
#   Labels: countries at 1.5 or more per 1,000 in either source.
#   Text sizes meet the paper's printed text-size rule (CLAUDE.md) at 6.5 in.
# Outputs (results/cbh/exploratory/malaria_rates_ihme_vs_igme/; results/ is not committed):
#   malaria_rates_ihme_vs_igme_2024.png, CAPTION.md, country_rates_2024.csv
suppressPackageStartupMessages({ library(data.table); library(ggplot2) })
source("R_cbh/load_pipeline.R"); source("R_cbh/primary/settings.R")
settings <- cbh_primary_settings("snow_merge")
out <- "results/cbh/exploratory/malaria_rates_ihme_vs_igme"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
year_shown <- 2024L
x <- fread(file.path(settings$out, "annual_comparison/source_country_rates_2000_2024.csv"))[year == year_shown]
w <- dcast(x, iso3 + country ~ source, value.var = c("malaria_rate_per1000", "crisis_year"))
setnames(w, c("malaria_rate_per1000_IHME", "malaria_rate_per1000_UN IGME", "crisis_year_IHME", "crisis_year_UN IGME"),
  c("ihme", "unigme", "ihme_crisis", "unigme_crisis"))
stopifnot(nrow(w) == 42, !anyNA(w))
m49 <- list(`West Africa` = c("BEN","BFA","CIV","CPV","GHA","GIN","GMB","GNB","LBR","MLI","MRT","NER","NGA","SEN","SLE","TGO"),
  `Central Africa` = c("AGO","CAF","CMR","COD","COG","GAB","GNQ","STP","TCD"),
  `East Africa` = c("BDI","COM","DJI","ERI","ETH","KEN","MDG","MOZ","MUS","MWI","RWA","SOM","SSD","TZA","UGA","ZMB","ZWE"),
  `Southern Africa` = c("BWA","LSO","NAM","SWZ","ZAF"))
region_of <- setNames(rep(names(m49), lengths(m49)), unlist(m49))
w[, region := factor(region_of[iso3], levels = names(m49))]
stopifnot(!anyNA(w$region))
colours <- c(`West Africa` = "#0072B2", `Central Africa` = "#CC79A7", `East Africa` = "#009E73", `Southern Africa` = "#E69F00")
# Short names for the longest labels, as in the paper's country figures.
w[, label := fcase(iso3 == "CAF", "CAR", iso3 == "COD", "DRC", iso3 == "COG", "RC", iso3 == "GNQ", "Eq. Guinea",
  iso3 == "CIV", "Côte d'Ivoire", iso3 == "SWZ", "Eswatini", iso3 == "TZA", "Tanzania", default = country)]
w[, ratio := unigme / ihme]
cbh_atomic_csv(w[order(-unigme)], file.path(out, "country_rates_2024.csv"))
rho <- cor(w$ihme, w$unigme, method = "spearman")
crisis <- w[ihme_crisis | unigme_crisis, label]
# Countries with low malaria mortality (below 1.5 per 1,000 in both sources) are drawn but not labelled (user request).
label_min <- 1.5
w[, labelled := pmax(ihme, unigme) >= label_min]
lim <- c(0, max(w$ihme, w$unigme) * 1.05)
note <- sprintf("Spearman ρ = %.2f\nUN IGME / IHME: median %.2f\n(range %.2f–%.2f)", rho, median(w$ratio), min(w$ratio), max(w$ratio))
p <- ggplot(w, aes(ihme, unigme)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey55", linewidth = .4) +
  geom_point(aes(colour = region), size = 2.2) +
  ggrepel::geom_text_repel(aes(label = ifelse(labelled, label, "")), size = 9 / .pt, colour = "grey20", seed = 20261027L, max.overlaps = Inf,
    min.segment.length = 0, segment.colour = "grey60", segment.size = .3, box.padding = .3, point.padding = .2) +
  annotate("text", x = 0, y = lim[2], label = note, hjust = 0, vjust = 1, size = 9 / .pt, lineheight = .95, colour = "grey25") +
  scale_colour_manual(values = colours, name = NULL) +
  scale_x_continuous(limits = lim, expand = expansion(mult = c(0, .02))) +
  scale_y_continuous(limits = lim, expand = expansion(mult = c(0, .02))) +
  coord_equal() +
  labs(x = sprintf("IHME all-cause: malaria-attributable deaths\nper 1,000 child-years, %d", year_shown),
       y = sprintf("UN IGME all-cause: malaria-attributable deaths\nper 1,000 child-years, %d", year_shown)) +
  theme_minimal(base_size = 10.8) +
  theme(axis.title = element_text(size = 11), axis.text = element_text(size = 9), legend.text = element_text(size = 9),
    legend.position = "bottom", panel.grid.minor = element_blank(), plot.margin = margin(6, 10, 6, 6))
# No title, subtitle or caption in the figure (CLAUDE.md); the notes go in CAPTION.md.
stopifnot(is.null(p$labels$title), is.null(p$labels$subtitle), is.null(p$labels$caption))
ggsave(file.path(out, sprintf("malaria_rates_ihme_vs_igme_%d.png", year_shown)), p, device = ragg::agg_png,
  width = 6.5, height = 6.7, dpi = 300, bg = "white")
writeLines(c("# Figure caption — malaria-attributable mortality, IHME against UN IGME all-cause", "",
  paste0(sprintf("Country PfPR-ACM malaria-attributable under-five deaths per 1,000 child-years in %d, using IHME (x) and UN IGME (y) all-cause deaths, for the %d burden countries; dashed line: equality. ", year_shown, nrow(w)),
    sprintf("Countries below %g per 1,000 in both sources (%d) are not labelled. ", label_min, sum(!w$labelled)),
    if (length(crisis)) paste0("Crisis-free values are used for ", paste(crisis, collapse = ", "), " (a crisis year in one source). ") else "",
    sprintf("Spearman ρ = %.2f; the UN IGME / IHME ratio has median %.2f (range %.2f–%.2f).", rho, median(w$ratio), min(w$ratio), max(w$ratio)))),
  file.path(out, "CAPTION.md"))
print(w[order(-abs(log(ratio)))][1:8, .(country, ihme = round(ihme, 2), unigme = round(unigme, 2), ratio = round(ratio, 2))])
message(sprintf("Spearman rho %.3f; median UN IGME / IHME %.2f", rho, median(w$ratio)))
