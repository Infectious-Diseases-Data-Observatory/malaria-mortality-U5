#!/usr/bin/env Rscript
# National malaria-attributable under-five mortality, 2000-2024, in the 42 burden countries, one figure per all-cause
# source (user request, 27 October 2026): UN IGME for the main text, IHME for the supplement. Panels: A national MAP
# PfPR[2-10] (the same in both figures), B all-cause and C malaria-attributable under-five deaths per 1,000
# child-years from that source's crisis-free deaths and person-years (crisis years: R_cbh/burden/04_annual_comparison.R).
# A and B are stacked on the left and C, twice their size, is square on the right. One line per country coloured by UN
# M49 sub-region (as in Figure 1), with the 42-country population-weighted average in black. Reads the
# R_cbh/burden/04_annual_comparison.R outputs only.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/reporting/labels.R")
library(ggplot2)
library(patchwork)
settings <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION","regional_mics")); root <- settings$out
annual <- file.path(root, "annual_comparison"); out <- file.path(root, "mortality_rates")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
paths <- c(countries = file.path(annual, "source_country_rates_2000_2024.csv"),
  totals = file.path(annual, "source_annual_rates_2000_2024.csv"), split = file.path(annual, "igme_age_split.csv"),
  crises = file.path(annual, "crisis_years.csv"))
x <- cbh_read_csv(paths[["countries"]]); tot <- cbh_read_csv(paths[["totals"]]); split <- cbh_read_csv(paths[["split"]])
crises <- cbh_read_csv(paths[["crises"]])
sources <- c(unigme = "UN IGME", ihme = "IHME"); years <- 2000:2024
stopifnot(setequal(x$source, sources), nrow(x) == 2 * 42 * length(years), setequal(x$year, years),
  setequal(tot$source, sources), nrow(tot) == 2 * length(years), all(tot$countries == 42),
  nrow(crises) == sum(x$crisis_year), nrow(crises) == sum(tot$crisis_years))
# National PfPR does not depend on the mortality source.
stopifnot(all(tapply(x$pfpr_pct, paste(x$iso3, x$year), function(v) diff(range(v))) < 1e-12),
  all(tapply(tot$pfpr_pct_wpp_weighted, tot$year, function(v) diff(range(v))) < 1e-12))
# UN M49 sub-regions as grouped in Figure 1 (R_cbh/reporting/03_survey_map.R; Middle Africa as Central Africa), in the
# colours of the sub-region sensitivity figures.
m49 <- list(`West Africa` = c("BEN","BFA","CIV","CPV","GHA","GIN","GMB","GNB","LBR","MLI","MRT","NER","NGA","SEN","SLE","TGO"),
  `Central Africa` = c("AGO","CAF","CMR","COD","COG","GAB","GNQ","STP","TCD"),
  `East Africa` = c("BDI","COM","DJI","ERI","ETH","KEN","MDG","MOZ","MUS","MWI","RWA","SOM","SSD","TZA","UGA","ZMB","ZWE"),
  `Southern Africa` = c("BWA","LSO","NAM","SWZ","ZAF"))
region_of <- setNames(rep(names(m49), lengths(m49)), unlist(m49))
stopifnot(all(x$iso3 %in% names(region_of)))
x$region <- factor(region_of[x$iso3], levels = names(m49))
colours <- c(`West Africa` = "#0072B2", `Central Africa` = "#CC79A7", `East Africa` = "#009E73", `Southern Africa` = "#E69F00")
total_label <- "Population-weighted average"
cbh_atomic_csv(x[order(x$source, x$region, x$iso3, x$year), c("source", "iso3", "country", "region", "year", "pfpr_pct", "crisis_year",
  "allcause_rate_per1000_reported", "allcause_rate_per1000", "malaria_rate_per1000", "malaria_fraction")], file.path(out, "figure_data.csv"))
# Common y-axis limits in both figures, so the two sources can be compared panel by panel.
limits <- list(allcause_rate_per1000 = c(0, max(x$allcause_rate_per1000)), malaria_rate_per1000 = c(0, max(x$malaria_rate_per1000)),
  pfpr_pct = c(0, max(x$pfpr_pct)))
# Drawn at the printed width (6.5 in), so text sizes are printed sizes and meet the paper's text-size rule (CLAUDE.md);
# lines and margins are those of the earlier 16 in drawing scaled by 6.5/16. The small panels A and B have fewer year ticks.
panel <- function(d, total, y, total_y, ylab, tag, breaks = c(2000, 2005, 2010, 2015, 2020, 2024)) ggplot() +
  geom_line(data = d, aes(year, .data[[y]], group = iso3, colour = region), linewidth = .22, alpha = .8) +
  geom_line(data = total, aes(year, .data[[total_y]], linetype = total_label), colour = "black", linewidth = .7) +
  scale_colour_manual(values = colours, drop = FALSE, name = NULL) +
  scale_linetype_manual(values = setNames("solid", total_label), name = NULL) +
  scale_x_continuous(breaks = breaks, limits = range(years), expand = expansion(mult = c(.015, .03))) +
  scale_y_continuous(limits = limits[[y]], expand = expansion(mult = c(0, .04))) +
  guides(colour = guide_legend(order = 1, override.aes = list(linewidth = .65, alpha = 1)), linetype = guide_legend(order = 2)) +
  labs(x = "Year", y = ylab, tag = tag) +
  theme_minimal(base_size = 12, base_line_size = .33) +
  theme(aspect.ratio = 1, axis.title = element_text(size = 12), axis.text = element_text(size = 10), panel.grid.minor = element_blank(),
    plot.tag = element_text(size = 13, face = "bold", hjust = 0, margin = margin(b = 3)), plot.tag.position = "top",
    legend.text = element_text(size = 10), legend.key.width = grid::unit(.45, "cm"), plot.margin = margin(4, 6, 2.5, 3))
fmt1 <- function(z) formatC(z, format = "f", digits = 1)
pct <- function(z) paste0(fmt1(100 * z), "%")
share_text <- with(split[split$age_band != "<1", ], paste(sub("-", "–", age_band, fixed = TRUE), "months", pct(within_group_share)))
model_label <- cbh_paper_model_label()
for (k in names(sources)) {
  s <- sources[[k]]; d <- x[x$source == s, ]; total <- tot[tot$source == s, ]
  # A and B (one cell each) stacked on the left; C spans the 2 x 2 cells on the right, so it is square.
  p <- panel(d, total, "pfpr_pct", "pfpr_pct_wpp_weighted", expression(italic(Pf)*PR[2-10]~"(%)"), "A", c(2000, 2010, 2020)) +
    panel(d, total, "allcause_rate_per1000", "allcause_rate_per1000", "All-cause under-5\ndeaths per 1,000\nchild-years", "B", c(2000, 2010, 2020)) +
    panel(d, total, "malaria_rate_per1000", "malaria_rate_per1000", "Malaria-attributable under-5 deaths\nper 1,000 child-years", "C") +
    # The collected legend sits in a fixed-height row (D) so that it does not take a share of the panels' height.
    guide_area() + plot_layout(design = "ACC\nBCC\nDDD", heights = grid::unit(c(1, 1, .45), c("null", "null", "in")), guides = "collect") &
    theme(legend.position = "bottom", legend.box = "vertical", legend.margin = margin(0, 0, 0, 0), legend.spacing.y = grid::unit(2, "pt"))
  file <- if (k == "unigme") "fig_malaria_mortality_rates_unigme.png" else "sfig_malaria_mortality_rates_ihme.png"
  ggsave(file.path(out, file), p, device = ragg::agg_png, width = 6.5, height = 4.5, dpi = 600, bg = "white")
  first <- total[total$year == min(years), ]; last <- total[total$year == max(years), ]
  cs <- crises[crises$source == s, ]
  by_country <- split(cs$year, cs$country)
  crisis_text <- if (nrow(cs)) paste0("Crisis years, in which the ", s, " all-cause under-five death rate is more than 25% above its crisis-free trend ",
    "(the log-linear interpolation between the nearest non-crisis years), take that trend in every age band, because the attributable fraction of crisis deaths need not resemble that of other years: ",
    paste(names(by_country), vapply(by_country, paste, "", collapse = ", "), collapse = "; "),
    sprintf(" (%s deaths removed in all).", format(round(sum(cs$crisis_deaths_removed)), big.mark = ","))) else
    paste0("No country-year in the ", s, " series is more than 25% above its crisis-free trend.")
  source_text <- if (k == "unigme")
    paste("All-cause deaths are UN IGME estimates (UNICEF data warehouse, indicators CME_TMM0, CME_TMM1T11 and CME_TMY1T4) and child-years the UN WPP population under 5 (DM_POP_U5), the population UN IGME itself uses.",
      paste0("UN IGME reports deaths at <1 month, 1–11 months and 1–4 years; each group is split across the model's age bands by the primary sample's observed deaths within the group, pooled over countries and years (",
        paste(share_text, collapse = ", "), ")."))
  else
    paste("All-cause deaths are IHME GBD estimates by age (0–6 days and 7–27 days combined for the <1 month band; 1–5 months, 6–11 months and 12–23 months directly; 2–4 years divided equally across the three annual bands), and child-years those implied by IHME's under-five deaths and rates.")
  caption <- c(paste0("# Figure caption — national malaria-attributable under-five mortality, ", s), "",
    paste(sprintf("**Figure. Malaria prevalence and under-five mortality in %d sub-Saharan African countries, 2000–2024, with all-cause mortality from %s.**", nrow(d) / length(years), s),
      "(A) National MAP PfPR[2–10], population-weighted using a fixed GPW 2020 spatial distribution (the same in both versions of this figure).",
      "(B) All-cause under-five deaths per 1,000 child-years, with crisis years replaced (below).",
      paste0("(C) Malaria-attributable under-five deaths per 1,000 child-years: for each of the seven age bands of the ", model_label,
        ", the band's attributable fraction 1 − exp[f_g(0) − f_g(P)] at the national PfPR[2–10] times the band's all-cause deaths, summed over bands and divided by the same child-years."),
      source_text,
      crisis_text,
      "Thin lines are countries, coloured by UN M49 sub-region (Middle Africa as Central Africa); the black line is the population-weighted average over the 42 countries (PfPR[2–10] weighted by the UN WPP population under 5; mortality rates weighted by child-years, that is total deaths divided by total child-years).",
      sprintf("The average malaria-attributable rate fell from %s to %s deaths per 1,000 child-years between %d and %d (%s and %s of all-cause under-five deaths).",
        fmt1(first$malaria_rate_per1000), fmt1(last$malaria_rate_per1000), min(years), max(years), pct(first$malaria_fraction), pct(last$malaria_fraction)),
      "Panels B and C use the same axis limits in both versions. Point estimates only; zero prevalence lies below the observed exposure support, so the counterfactual requires extrapolation."))
  writeLines(caption, file.path(out, if (k == "unigme") "CAPTION_unigme.md" else "CAPTION_ihme.md"))
}
provenance <- c(unname(paths), "R_cbh/reporting/24_malaria_mortality_rates.R", "R_cbh/reporting/labels.R")
cbh_atomic_csv(data.frame(file = provenance, md5 = vapply(provenance, cbh_file_hash, "")), file.path(out, "provenance.csv"))
message("Saved malaria mortality rate figures (UN IGME main, IHME supplementary): ", out)
