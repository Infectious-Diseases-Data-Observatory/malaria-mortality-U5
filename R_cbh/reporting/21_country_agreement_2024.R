#!/usr/bin/env Rscript
# Country agreement statistics for 2024 quoted in the paper's results (main.tex: Spearman correlation
# of country rates with IHME, number of the 42 countries where the model exceeds IHME, median country
# ratio). In the analysis project these were computed only by the 1%-floor sensitivity
# (R_cbh/sensitivity/reference_floor/01_burden.R, floor 0 row of agreement_2024.csv); this script
# computes the same statistics, with the same definitions, from the primary annual comparison.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
suppressPackageStartupMessages(library(data.table))
st <- cbh_primary_settings()
path <- file.path(st$out, "annual_comparison/country_estimates_2000_2024.csv")
c24 <- fread(path)[year == 2024L]
stopifnot(nrow(c24) == 42L, !anyNA(c24[, .(model_deaths, ihme_malaria_deaths, who_cacode_deaths, under5_person_years)]))
c24[, `:=`(model_rate = 1000 * model_deaths / under5_person_years, ihme_rate = 1000 * ihme_malaria_deaths / under5_person_years,
           unigme_rate = 1000 * who_cacode_deaths / under5_person_years)]
agree <- c24[, .(countries = .N,
  countries_above_ihme = sum(model_deaths > ihme_malaria_deaths), median_ratio_ihme = median(model_deaths / ihme_malaria_deaths),
  spearman_rate_ihme = cor(model_rate, ihme_rate, method = "spearman"),
  countries_above_unigme = sum(model_deaths > who_cacode_deaths), median_ratio_unigme = median(model_deaths / who_cacode_deaths),
  spearman_rate_unigme = cor(model_rate, unigme_rate, method = "spearman"))]
out <- file.path(st$out, "annual_comparison")
cbh_atomic_csv(as.data.frame(agree), file.path(out, "country_agreement_2024.csv"))
inputs <- c(path, "R_cbh/reporting/21_country_agreement_2024.R")
cbh_atomic_csv(data.frame(file = inputs, md5 = vapply(inputs, cbh_file_hash, "")), file.path(out, "country_agreement_provenance.csv"))
message(sprintf("2024: model above IHME in %d of %d countries; median ratio %.2f; Spearman %.2f",
                agree$countries_above_ihme, agree$countries, agree$median_ratio_ihme, agree$spearman_rate_ihme))
