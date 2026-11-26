#!/usr/bin/env Rscript
# Distribution of the exposure on the three scales tried for the free-form PfPR curve (05_spacetime_inla.R): PfPR,
# sqrt(PfPR) and log(1 + PfPR). One value per survey-unit and band-entry year of the primary sample (the level at which
# the exposure is defined: MAP PfPR of the unit in that year). Bins have equal width on each panel's scale; the axes
# are labelled in PfPR. Exploratory figure, not for the paper.
# Writes <out>/pfpr_histograms_by_scale.png and pfpr_survey_unit_years.csv (aggregates).
suppressPackageStartupMessages({library(data.table); library(ggplot2); library(patchwork)})
source("R_cbh/primary/settings.R"); source("R_cbh/sensitivity/design/settings.R")
P <- cbh_primary_settings(); S <- cbh_design_settings()
d <- as.data.table(readRDS(P$data)$data)
u <- d[, .(records = .N, deaths = sum(death)), by = .(survey_unit = as.character(region), entry_year, pfpr_pct)]
stopifnot(!anyDuplicated(u[, .(survey_unit, entry_year)]))
fwrite(u[order(survey_unit, entry_year)], file.path(S$out, "pfpr_survey_unit_years.csv"))
panel <- function(transform, binwidth, breaks, xlab, ylab) ggplot(u, aes(pfpr_pct)) +
  geom_histogram(binwidth = binwidth, boundary = 0, fill = "#2a78b5", colour = "white", linewidth = 0.15) +
  scale_x_continuous(transform = transform, breaks = breaks, limits = c(0, 100), expand = expansion(mult = 0.02)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) + labs(x = xlab, y = ylab) +
  theme_bw(base_size = 11) + theme(axis.text = element_text(size = 9), panel.grid.minor = element_blank())
p <- panel("identity", 2, seq(0, 100, 25), expression(italic(Pf) * PR[2-10] ~ "(%)"), "Survey-unit-years") +
  panel("sqrt", 0.2, c(0, 1, 5, 10, 25, 50, 100), expression(italic(Pf) * PR[2-10] ~ "(%), square-root scale"), NULL) +
  panel("log1p", 0.1, c(0, 1, 2, 5, 10, 25, 50, 100), expression(italic(Pf) * PR[2-10] ~ "(%), log(1 + x) scale"), NULL)
ggsave(file.path(S$out, "pfpr_histograms_by_scale.png"), p, width = 7.5, height = 3, dpi = 200)
cat("survey-units", uniqueN(u$survey_unit), "survey-unit-years", nrow(u), "\n")
