#!/usr/bin/env Rscript
# Primary age-band table (tables/age_band_results.csv, R_cbh/reporting/age_band_table.R): reads aggregates, never fits
# models or prepares exposures. The other primary plots and RESULTS.md, which no paper output used, were removed on
# 1 November 2026 (git history).
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/reporting/age_band_table.R")
settings <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION","snow_merge"));out <- settings$out
writeLines(trimws(readLines(file.path(out,"model_formula.txt")),which="right"),file.path(out,"model_formula.txt"))
ages <- cbh_config()$age_bands$age_band
diag <- cbh_read_csv(file.path(out,"fit_diagnostics.csv"))
stopifnot(nrow(diag)==7,all(diag$series=="map_full"),all(diag$converged),all(diag$input_verified),
  all(diag$gamma==2),all(diag$min_smoothing_hessian_eigenvalue>0))
cbh_primary_age_table(out,ages)
files <- c("pfpr_40_to_20_contrasts.csv","pfpr_20_to_zero_contrasts.csv","tables/age_band_results.csv","fit_diagnostics.csv",
  "primary_sample.csv","pfpr_edf.csv")
paths <- c(file.path(out,files),"R_cbh/primary/03_report.R","R_cbh/primary/settings.R","R_cbh/reporting/age_band_table.R")
cbh_atomic_csv(data.frame(file=paths,md5=vapply(paths,cbh_file_hash,"")),file.path(out,"report_provenance.csv"))
message("Primary age-band table complete")
