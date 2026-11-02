#!/usr/bin/env Rscript
# Supplementary figure (user request, 27 October 2026; moved from R_cbh/exploratory/02_malaria_rates_ihme_vs_igme.R into
# the pipeline on 1 November 2026): country PfPR-ACM malaria-attributable under-five mortality per 1,000 child-years in
# 2024, from IHME all-cause deaths against UN IGME all-cause deaths, for the 42 burden countries. Reads the crisis-free
# rates of R_cbh/burden/04_annual_comparison.R. It supplies the UN IGME / IHME ratio range quoted in the Results.
#   Point: one country, coloured by UN M49 sub-region as in the mortality-rate figures; dashed line: equality.
#   Labels: countries at 1.5 or more per 1,000 in either source, at fixed positions beside their points.
# Sizes meet the paper's printed text-size rule (CLAUDE.md) at 6.5 in. The in-panel correlation and ratio summary is
# kept as in the Overleaf version (moving it to CAPTION.md is for the author to decide); no title or caption.
# Outputs (<out>/ihme_vs_unigme/): sfig_malaria_rates_ihme_vs_unigme_2024.png, malaria_rates_ihme_vs_unigme_2024.csv,
#   CAPTION.md, provenance.csv
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
suppressPackageStartupMessages({ library(data.table); library(ggplot2) })
st <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION", "snow_merge")); root <- st$out
out <- file.path(root, "ihme_vs_unigme"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
year_shown <- 2024L
paths <- c(rates = file.path(root, "annual_comparison/source_country_rates_2000_2024.csv"))
stopifnot(all(file.exists(paths)))
x <- fread(paths[["rates"]])[year == year_shown]
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
cbh_atomic_csv(w[order(-unigme)], file.path(out, sprintf("malaria_rates_ihme_vs_unigme_%d.csv", year_shown)))
rho <- cor(w$ihme, w$unigme, method = "spearman")
crisis <- w[ihme_crisis | unigme_crisis, label]
# Countries with low malaria mortality (below 1.5 per 1,000 in both sources) are drawn but not labelled (user request).
label_min <- 1.5
w[, labelled := pmax(ihme, unigme) >= label_min]
# Fixed label positions: offset from the point to the label centre, in rates per 1,000. ggrepel's own layout put labels
# beside other countries' points in the crowded middle (with MAP 202608, Côte d'Ivoire on Mali's point), so the
# positions were chosen by a placement search on these data (2 November 2026): each label is nearer its own point than
# any other point and each labelled point nearer its own label than any other, and no label touches a point, another
# label, the equality line, the note or the panel edge. The script stops if the labelled set changes.
offsets <- fread(text = "iso3,dx,dy
AGO,0.303,-0.110
BDI,0.329,0.110
BEN,-0.258,0.110
BFA,-0.526,0.110
CAF,-0.222,0.110
CIV,0.532,-0.140
CMR,0.428,0.110
COD,-0.226,0.110
COG,0.168,0.110
GHA,0.294,0.110
GIN,0.312,0.110
GNQ,-0.455,0.110
LBR,-0.324,0.140
MDG,-0.495,0.110
MLI,0.199,-0.110
MOZ,0.534,0.000
MWI,0.302,-0.110
NER,0.244,0.110
NGA,0.307,0.110
SLE,0.000,0.131
SSD,0.518,0.110
TCD,-0.244,0.110
TGO,-0.226,0.110
UGA,0.355,0.000
ZMB,0.320,0.110")
stopifnot(setequal(offsets$iso3, w[labelled == TRUE, iso3]))
w[, c("dx", "dy") := 0][offsets, on = "iso3", c("dx", "dy") := .(i.dx, i.dy)]
lim <- c(0, max(w$ihme, w$unigme) * 1.05)
note <- sprintf("Spearman ρ = %.2f\nUN IGME / IHME: median %.2f\n(range %.2f–%.2f)", rho, median(w$ratio), min(w$ratio), max(w$ratio))
p <- ggplot(w, aes(ihme, unigme)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey55", linewidth = .4) +
  geom_point(aes(colour = region), size = 2.2) +
  ggrepel::geom_text_repel(aes(label = ifelse(labelled, label, "")), size = 9 / .pt, colour = "grey20", seed = 20261027L, max.overlaps = Inf,
    nudge_x = w$dx, nudge_y = w$dy, max.iter = 0, point.size = 2.2, min.segment.length = 0, segment.colour = "grey60", segment.size = .3, box.padding = .3, point.padding = .2) +
  annotate("text", x = 0, y = lim[2], label = note, hjust = 0, vjust = 1, size = 9 / .pt, lineheight = .95, colour = "grey25") +
  scale_colour_manual(values = colours, name = NULL) +
  scale_x_continuous(limits = lim, expand = expansion(mult = c(0, .02))) +
  scale_y_continuous(limits = lim, expand = expansion(mult = c(0, .02))) +
  coord_equal(clip = "off") +   # the countries at the origin are drawn whole
  labs(x = sprintf("IHME all-cause: malaria-attributable deaths\nper 1,000 child-years, %d", year_shown),
       y = sprintf("UN IGME all-cause: malaria-attributable deaths\nper 1,000 child-years, %d", year_shown)) +
  theme_minimal(base_size = 10.8) +
  theme(axis.title = element_text(size = 11), axis.text = element_text(size = 9), legend.text = element_text(size = 9),
    legend.position = "bottom", panel.grid.minor = element_blank(), plot.margin = margin(6, 10, 6, 6))
stopifnot(is.null(p$labels$title), is.null(p$labels$subtitle), is.null(p$labels$caption))
ggsave(file.path(out, sprintf("sfig_malaria_rates_ihme_vs_unigme_%d.png", year_shown)), p, device = ragg::agg_png,
  width = 6.5, height = 6.7, dpi = 300, bg = "white")
writeLines(c("# Supplementary figure caption — malaria-attributable mortality, IHME against UN IGME all-cause", "",
  paste0(sprintf("Country PfPR-ACM malaria-attributable under-five deaths per 1,000 child-years in %d, using IHME (x) and UN IGME (y) all-cause deaths, for the %d burden countries; dashed line: equality. ", year_shown, nrow(w)),
    sprintf("Countries below %g per 1,000 in both sources (%d) are not labelled. ", label_min, sum(!w$labelled)),
    if (length(crisis)) paste0("Crisis-free values are used for ", paste(crisis, collapse = ", "), " (a crisis year in one source). ") else "",
    sprintf("Spearman ρ = %.2f; the UN IGME / IHME ratio has median %.2f (range %.2f–%.2f).", rho, median(w$ratio), min(w$ratio), max(w$ratio)))),
  file.path(out, "CAPTION.md"))
provenance <- c(unname(paths), "R_cbh/reporting/28_malaria_rates_ihme_vs_unigme.R")
cbh_atomic_csv(data.frame(file = provenance, md5 = vapply(provenance, cbh_file_hash, "")), file.path(out, "provenance.csv"))
print(w[order(-abs(log(ratio)))][1:8, .(country, ihme = round(ihme, 2), unigme = round(unigme, 2), ratio = round(ratio, 2))])
message(sprintf("IHME vs UN IGME figure saved: %s (Spearman rho %.3f; median UN IGME / IHME %.2f)", out, rho, median(w$ratio)))
