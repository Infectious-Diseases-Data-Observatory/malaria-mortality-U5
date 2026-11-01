#!/usr/bin/env Rscript
# Three-source summary of under-five malaria mortality in the 42 countries in 2000, 2004, 2015 and 2024, with
# declines to 2024: the source of the comparator declines quoted in the Discussion. The three sources share one
# denominator. Reads saved aggregates only; no refitting and no downloads. The World Malaria Report rows, the
# Markdown table and the LaTeX fragment were dropped on 1 November 2026 (not used by the paper).
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
settings <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION", "snow_merge"))
out <- file.path(settings$out, "burden_comparison")
years <- c(2000L, 2004L, 2015L, 2024L)

annual <- cbh_read_csv(file.path(settings$out, "annual_comparison/annual_totals_2000_2024.csv"))
annual <- annual[match(years, annual$year), ]

row <- function(source, scope, unit, v)
  data.frame(source = source, scope = scope, unit = unit,
             y2000 = v[1], y2004 = v[2], y2015 = v[3], y2024 = v[4],
             decline_from_2000 = 100 * (1 - v[4] / v[1]),
             decline_from_2004 = 100 * (1 - v[4] / v[2]),
             decline_from_2015 = 100 * (1 - v[4] / v[3]), row.names = NULL)

u5 <- "under-5, 42 countries"
tab <- rbind(
  row("PfPR-ACM model", u5, "deaths", annual$model_deaths),
  row("IHME",           u5, "deaths", annual$ihme_malaria_deaths),
  row("UN IGME",        u5, "deaths", annual$who_cacode_deaths),
  row("PfPR-ACM model", u5, "deaths per 1000 child-years", annual$model_rate_per100000 / 100),
  row("IHME",           u5, "deaths per 1000 child-years", annual$ihme_malaria_rate_per100000 / 100),
  row("UN IGME",        u5, "deaths per 1000 child-years", annual$who_cacode_rate_per100000 / 100))
cbh_atomic_csv(tab, file.path(out, "source_comparison_2000_2024.csv"))

inputs <- c(file.path(settings$out, "annual_comparison/annual_totals_2000_2024.csv"),
  "R_cbh/reporting/12_source_comparison_table.R")
cbh_atomic_csv(data.frame(file = inputs, md5 = vapply(inputs, cbh_file_hash, "")),
  file.path(out, "source_comparison_provenance.csv"))
cat("Source comparison table written:", file.path(out, "source_comparison_2000_2024.csv"), "\n")
