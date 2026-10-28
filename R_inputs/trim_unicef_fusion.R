#!/usr/bin/env Rscript
# Make the committed UNICEF extracts from the full UNICEF data dump.
# The dump (fusion_GLOBAL_DATAFLOW_UNICEF_1.0_all.csv, 563 MB, data/unicef/original/, not committed)
# is too large for git. Two extracts are kept, each a byte-for-byte subset of the original (the header and,
# unchanged and in order, the selected lines):
#   immunisation: every line containing "IM_", read by R_inputs/02b_extract_unicef_immunisation.R,
#     R_cbh/covariates/07_prepare_unicef.R and R_mics/09_regional_covariates.R;
#   igme_wpp (added 27 October 2026): UN IGME all-cause deaths under 5 and by age group (neonatal, 1-11 months,
#     1-4 years) and UN WPP population under 5, both sexes, 2000-2024, African countries (countrycode continent;
#     the World Bank's sub-Saharan region would omit Djibouti), read by R_cbh/burden/04_annual_comparison.R.
original <- "data/unicef/original/fusion_GLOBAL_DATAFLOW_UNICEF_1.0_all.csv"
extract <- "data/unicef/fusion_GLOBAL_DATAFLOW_UNICEF_1.0_immunisation_subset.csv"
igme_extract <- "data/unicef/fusion_GLOBAL_DATAFLOW_UNICEF_1.0_igme_wpp_subset.csv"
stopifnot(file.exists(original))
lines <- readLines(original, warn = FALSE, encoding = "UTF-8")
fields <- data.table::fread(original, select = c("REF_AREA", "INDICATOR", "SEX", "TIME_PERIOD"),
  colClasses = "character", showProgress = FALSE)
stopifnot(nrow(fields) == length(lines) - 1L)   # no record spans more than one line
keep <- c(TRUE, grepl("IM_", lines[-1], fixed = TRUE))
con <- file(extract, "wb"); writeLines(lines[keep], con, sep = "\n", useBytes = TRUE); close(con)
africa <- countrycode::codelist$iso3c[countrycode::codelist$continent %in% "Africa"]
igme_indicators <- c("CME_TMY0T4", "CME_TMM0", "CME_TMM1T11", "CME_TMY1T4", "DM_POP_U5")
keep_igme <- c(TRUE, fields$INDICATOR %in% igme_indicators & fields$SEX == "_T" & fields$REF_AREA %in% africa &
  fields$TIME_PERIOD %in% as.character(2000:2024))
con <- file(igme_extract, "wb"); writeLines(lines[keep_igme], con, sep = "\n", useBytes = TRUE); close(con)
files <- c(original, extract, igme_extract)
sizes <- file.size(files)
write.csv(data.frame(file = files, bytes = sizes, lines = c(length(lines), sum(keep), sum(keep_igme)),
  md5 = unname(tools::md5sum(files))), "data/unicef/CHECKSUMS.csv", row.names = FALSE)
cat(sprintf("UNICEF extracts: immunisation %d and IGME/WPP %d of %d lines (%.1f and %.1f of %.1f MB)\n",
  sum(keep), sum(keep_igme), length(lines), sizes[2] / 1e6, sizes[3] / 1e6, sizes[1] / 1e6))
