#!/usr/bin/env Rscript
# Make the committed UNICEF immunisation extract from the full UNICEF data dump.
# The dump (fusion_GLOBAL_DATAFLOW_UNICEF_1.0_all.csv, 563 MB, data/unicef/original/, not committed)
# is too large for git. Every script that reads it uses only immunisation indicators (codes IM_*:
# R_inputs/02b_extract_unicef_immunisation.R, R_cbh/covariates/07_prepare_unicef.R,
# R_mics/09_regional_covariates.R), so the extract keeps the header and, unchanged and in order,
# every line containing "IM_". It is a byte-for-byte subset of the original.
original <- "data/unicef/original/fusion_GLOBAL_DATAFLOW_UNICEF_1.0_all.csv"
extract <- "data/unicef/fusion_GLOBAL_DATAFLOW_UNICEF_1.0_immunisation_subset.csv"
stopifnot(file.exists(original))
lines <- readLines(original, warn = FALSE, encoding = "UTF-8")
n <- nrow(data.table::fread(original, select = 1L, showProgress = FALSE))
stopifnot(n == length(lines) - 1L)   # no record spans more than one line
keep <- c(TRUE, grepl("IM_", lines[-1], fixed = TRUE))
con <- file(extract, "wb"); writeLines(lines[keep], con, sep = "\n", useBytes = TRUE); close(con)
sizes <- file.size(c(original, extract))
write.csv(data.frame(file = c(original, extract), bytes = sizes, lines = c(length(lines), sum(keep)),
  md5 = unname(tools::md5sum(c(original, extract)))), "data/unicef/CHECKSUMS.csv", row.names = FALSE)
cat(sprintf("UNICEF extract: %d of %d lines (%.1f of %.1f MB)\n", sum(keep), length(lines), sizes[2] / 1e6, sizes[1] / 1e6))
