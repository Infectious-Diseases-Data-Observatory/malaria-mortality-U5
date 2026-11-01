#!/usr/bin/env Rscript
# Survey coverage of the primary: included surveys with their year, programme and mothers (survey_coverage.csv), and
# mothers and children by survey (mothers_by_survey.csv), read by Figure 1 (23_analysis_units_map.R) and the reporting
# validation. The survey map and timing figure, its caption and the timeline tables were dropped on 1 November 2026
# (not in the paper). Aggregate counts only; no downloads.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
st <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION","snow_merge")); root <- st$out; mics <- isTRUE(st$mics)
out <- file.path(root,"survey_map")
dir.create(out,recursive=TRUE,showWarnings=FALSE)
paths <- c(coverage=file.path(root,"survey_coverage.csv"),
  registry=cbh_config()$registry,selection=file.path(root,"study_flow/survey_selection.csv"))
x <- cbh_read_csv(paths[["coverage"]]);r <- cbh_read_csv(paths[["registry"]]);sel <- cbh_read_csv(paths[["selection"]])
if(mics) {
  # MICS surveys with a complete birth history join the registry.
  paths <- c(paths,mics_registry="data/derived_mics/survey_registry_mics.csv")
  cols <- c("svkey","iso3","year","SurveyType")
  r <- rbind(r[cols],cbh_read_csv(paths[["mics_registry"]])[cols])
}
cbh_unique(x,"survey","Primary survey coverage")
cbh_unique(r,"svkey","Survey registry")
sample <- cbh_read_csv(file.path(root,"primary_sample.csv"))
stopifnot(nrow(x)==sample$surveys,length(unique(x$country))==sample$countries,
  setequal(x$survey,sel$survey[sel$complete_case_rows>0]))
j <- match(x$survey,r$svkey)
stopifnot(!anyNA(j),all(x$country==r$iso3[j]))
x$year <- r$year[j];x$type <- r$SurveyType[j]
stopifnot(!anyNA(x),all(x$type %in% c("DHS","MIS","MICS")))
# Mothers (complete birth histories) contributing at least one child-band record to the primary
# analysis, per included survey: children in the prepared sample matched to their shard's mother id.
analysed <- unique(as.character(readRDS(st$data)$data$child_id))
shard_dirs <- c(cbh_config()$output_dir,if(mics) st$mics_output_dir)
mothers <- do.call(rbind,lapply(shard_dirs,function(dir) {
  m <- readRDS(file.path(dir,"manifest.rds"))$manifest; m <- m[m$survey %in% x$survey,]
  do.call(rbind,lapply(seq_len(nrow(m)),function(i) { o <- readRDS(file.path(dir,m$file[i])); stopifnot(identical(o$signature,m$signature[i]))
    d <- o$data[as.character(o$data$child_id) %in% analysed,,drop=FALSE]
    data.frame(survey=m$survey[i],children=length(unique(d$child_id)),mothers=length(unique(d$mother_id))) })) }))
cbh_unique(mothers,"survey","Mothers by survey")
stopifnot(setequal(mothers$survey,x$survey),sum(mothers$children)==sample$distinct_children,all(mothers$mothers>0))
x$mothers <- mothers$mothers[match(x$survey,mothers$survey)]
cbh_atomic_csv(x,file.path(out,"survey_coverage.csv"))
cbh_atomic_csv(mothers,file.path(out,"mothers_by_survey.csv"))
inputs <- unique(c(unname(paths),file.path(root,"primary_sample.csv"),st$data,file.path(shard_dirs,"manifest.rds"),
  "R_cbh/reporting/03_survey_map.R","R_cbh/primary/settings.R"))
cbh_atomic_csv(data.frame(file=inputs,md5=vapply(inputs,cbh_file_hash,"")),file.path(out,"provenance.csv"))
message("Survey coverage: ",nrow(x)," included surveys, ",sum(mothers$mothers)," mothers")
