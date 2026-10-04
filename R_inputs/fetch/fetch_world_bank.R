#!/usr/bin/env Rscript
# NETWORK SCRIPT, NOT RUN BY THE PIPELINE. Fetches the two World Bank / WGI panels used as national
# covariates (current health expenditure per capita, SH.XPD.CHEX.PC.CD; political stability,
# GOV_WGI_PV_EST) if the files are absent, exactly as the analysis project's legacy builder
# (R_dhs/03_build_analysis_dataset.R, attach_national_covariates) did as a side effect.
# GDP per capita (data/wb_gdp_pc.csv) comes from R_inputs/fetch/01_fetch_data.R.
# The committed files in data/ are the vintages used for the paper; delete one to refetch it.
source("R_inputs/00_config.R")
invisible(read_or_fetch_wb("wb_hexp_pc.csv", "SH.XPD.CHEX.PC.CD", "hexp_pc"))
invisible(read_or_fetch_wb("wb_polstab.csv", "GOV_WGI_PV_EST", "polstab"))
