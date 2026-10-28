#!/usr/bin/env Rscript
# Primary analysis (v9: DHS and MICS surveys, 17 adjustment covariates, MAP PfPR, gamma = 2):
# preparation, the seven age-band fits, effects and national burden, and every primary figure and
# table in the paper. No TeX is written. Normally called by run_pipeline.R (stage "primary").
# Usage: [CBH_PRIMARY_VERSION=snow_merge] Rscript R_cbh/primary/run_regional.R [--resume | --report-only]
#   --resume       reuse verified fit caches
#   --report-only  skip preparation and fitting (use the saved fits)
# The reporting validation (R_cbh/reporting/10_validate_reporting.R) needs the subgroup and
# no-nutrition sensitivities, so run_pipeline.R runs it after them, not here.
source("R_cbh/primary/settings.R")
args <- commandArgs(trailingOnly=TRUE)
if(length(args)>1L || (length(args) && !args %in% c("--resume","--report-only")))
  stop("Use no arguments (fresh fits), --resume (reuse verified fit caches) or --report-only (saved fits).")
# The version comes from CBH_PRIMARY_VERSION (default regional_mics = v9; snow_merge = the Snow-unit primary) and is
# passed to every step, which run as child processes.
Sys.setenv(CBH_PRIMARY_VERSION=Sys.getenv("CBH_PRIMARY_VERSION","regional_mics"))
settings <- cbh_primary_settings()
stages <- c(prepare=settings$prepare,fit="R_cbh/primary/01_fit.R",
  national_inputs="R_cbh/burden/00_national_inputs.R",
  effects="R_cbh/primary/02_effects.R",diagnostics="R_cbh/primary/04_diagnostics.R",
  report="R_cbh/primary/03_report.R",
  flow=if(identical(settings$unit,"snow")) "R_cbh/reporting/01_study_flow_snow.R" else "R_cbh/reporting/01_study_flow.R",
  survey_map="R_cbh/reporting/03_survey_map.R",
  units_map=if(identical(settings$unit,"snow") && identical(settings$snow_variant,"merge")) "R_cbh/reporting/23_analysis_units_map.R" else NA_character_,
  hr_by_age="R_cbh/reporting/26_hazard_ratio_by_age.R",age_fractions="R_cbh/reporting/06_attributable_fraction_by_age.R",
  annual_burden="R_cbh/burden/04_annual_comparison.R",annual_plot="R_cbh/reporting/07_annual_mortality_comparison.R",
  rates_figures="R_cbh/reporting/24_malaria_mortality_rates.R",rates_table="R_cbh/reporting/25_country_rates_table.R",
  model_vs_cause="R_cbh/reporting/27_model_vs_cause_specific.R",
  nigeria_burden="R_cbh/burden/05_nigeria_state_burden.R",nigeria_plot="R_cbh/reporting/08_nigeria_state_comparison.R",
  burden_figure="R_cbh/reporting/11_burden_comparison_figure.R",
  burden_tables="R_cbh/reporting/09_burden_tables.R",agreement="R_cbh/reporting/21_country_agreement_2024.R",
  source_table="R_cbh/reporting/12_source_comparison_table.R",
  u5_probability="R_cbh/reporting/13_under5_death_probability.R",
  malaria_share="R_cbh/reporting/20_malaria_share_vs_pfpr.R",
  paper_manifest="R_cbh/reporting/04_paper_figures.R")
# Figure 1 of the Snow-unit primary (12 October 2026, author request): complete birth histories by analysis unit.
stages <- stages[!is.na(stages)]
if("--report-only" %in% args) stages <- stages[!names(stages) %in% c("prepare","fit")]
dir.create(settings$out,recursive=TRUE,showWarnings=FALSE)
log <- list()
for(stage in names(stages)) {
  started <- Sys.time();message("Primary stage: ",stage)
  trailing <- if(stage=="fit" && !"--resume" %in% args) "--force" else character()
  status <- system2(file.path(R.home("bin"),"Rscript"),c(stages[[stage]],trailing))
  log[[stage]] <- data.frame(stage=stage,started_at=as.character(started),finished_at=as.character(Sys.time()),
    elapsed_seconds=as.numeric(difftime(Sys.time(),started,units="secs")),exit_status=status)
  write.csv(do.call(rbind,log),file.path(settings$out,"pipeline_stages.csv"),row.names=FALSE)
  if(status!=0L)stop("Primary stage failed: ",stage)
}
files <- list.files(settings$out,recursive=TRUE,full.names=TRUE)
files <- files[!grepl("output_manifest[.]csv$",files)]
write.csv(data.frame(file=files,bytes=file.info(files)$size,md5=unname(tools::md5sum(files))),
  file.path(settings$out,"output_manifest.csv"),row.names=FALSE)
message("Primary pipeline complete: ",settings$out,"/RESULTS.md")
