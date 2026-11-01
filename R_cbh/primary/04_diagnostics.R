#!/usr/bin/env Rscript
# Survey coverage of the primary fits (survey_coverage.csv, read by the study flow), from the verified stored models.
# The aggregate in-sample outcome checks, read only by a removed plot, were dropped on 1 November 2026 (git history).
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
# Require an explicit version (run_regional.R sets it), so that a direct run cannot write into the wrong result folder.
if(!nzchar(Sys.getenv("CBH_PRIMARY_VERSION"))) stop("Set CBH_PRIMARY_VERSION (snow_merge for the Snow-unit primary), or run R_cbh/primary/run_regional.R.",call.=FALSE)
library(data.table)
settings <- cbh_primary_settings();out <- settings$out
manifest <- cbh_read_csv(file.path(out,"fit_manifest.csv"))
provenance <- cbh_read_csv(file.path(out,"fit_input_provenance.csv"))
stopifnot(nrow(manifest)==7,all(manifest$series=="map_full"),
  identical(cbh_file_hash(settings$data),provenance$md5[provenance$file==settings$data]))
coverage <- list()
for(i in seq_len(nrow(manifest))) {
  m <- manifest[i,]
  stopifnot(identical(cbh_file_hash(m$model_file),m$md5))
  saved <- readRDS(m$model_file);f <- saved$fit
  coverage[[i]] <- unique(f$model[c("survey","country","region")])
  p <- f$fitted.values
  stopifnot(saved$gamma==2,all(is.finite(p)),all(p>0 & p<1),length(p)==nrow(f$model))
  message("Verified stored model and fitted outcomes for ",m$age_band," months")
  rm(saved,f,p);gc(FALSE)
}
coverage <- unique(rbindlist(coverage))
coverage <- coverage[,.(regions=uniqueN(region)),by=.(survey,country)]
sample <- cbh_read_csv(file.path(out,"primary_sample.csv"))
stopifnot(nrow(coverage)==sample$surveys,uniqueN(coverage$country)==sample$countries)
cbh_atomic_csv(as.data.frame(coverage),file.path(out,"survey_coverage.csv"))
cbh_atomic_csv(data.frame(file=c(manifest$model_file,"R_cbh/primary/04_diagnostics.R"),
  md5=vapply(c(manifest$model_file,"R_cbh/primary/04_diagnostics.R"),cbh_file_hash,"")),
  file.path(out,"diagnostic_provenance.csv"))
