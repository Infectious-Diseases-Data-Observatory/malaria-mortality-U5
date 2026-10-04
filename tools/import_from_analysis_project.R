#!/usr/bin/env Rscript
# One-off import of the inputs this repository needs from the analysis project in which the paper's
# analysis was developed. Run from the repository root:
#   Rscript tools/import_from_analysis_project.R "<path to analysis project>"
# Copies (with file times kept, and md5-checked):
#   * raw DHS/MIS recodes named in the survey registry, plus the Sierra Leone 2013 PR recode
#     -> data/raw/dhs/ (ignored by git); MICS downloads -> data/raw/MICS_Datasets/ (ignored)
#   * the full UNICEF data dump -> data/unicef/original/ (ignored; the committed extract is made from it)
#   * public inputs -> data/ (committed)
#   * frozen copies of internet-fetched inputs -> data/frozen/ (committed; restored by run_pipeline.R)
# Writes data/raw_manifest.csv (names, sizes and md5s of the raw files; no contents) and
# data/INPUTS_MANIFEST.csv (every other imported file). The analysis project is only read.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, dir.exists(args[1]), file.exists("R_cbh/00_config.R"))
src <- normalizePath(args[1])
stopifnot(!identical(src, normalizePath(getwd())))
rdhs_cache <- path.expand("~/.rdhs_cache/datasets_reformatted")
log <- list()
put <- function(from, to, role) {
  stopifnot(file.exists(from))
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  if (!file.exists(to) || !identical(unname(tools::md5sum(to)), unname(tools::md5sum(from))))
    stopifnot(file.copy(from, to, overwrite = TRUE, copy.date = TRUE))
  m <- unname(tools::md5sum(to)); stopifnot(identical(m, unname(tools::md5sum(from))))
  log[[length(log) + 1L]] <<- data.frame(role = role, file = to, bytes = file.size(to), md5 = m,
                                         source = sub(path.expand("~"), "~", sub(src, "<analysis project>", from, fixed = TRUE), fixed = TRUE))
}
S <- function(...) file.path(src, ...)

## Raw DHS/MIS recodes (microdata; ignored) ------------------------------------------------------
reg <- read.csv(S("data/derived_dhs/survey_registry.csv"), stringsAsFactors = FALSE, check.names = FALSE)
for (i in seq_len(nrow(reg))) put(reg$local_recode[i], file.path("data/raw/dhs", paste0(reg$no_extension[i], ".rds")), "raw_dhs_recode")
put(file.path(rdhs_cache, "SLPR61FL.rds"), "data/raw/dhs/SLPR61FL.rds", "raw_dhs_recode")
for (f in list.files(S("data/MICS_Datasets"), recursive = TRUE, all.files = FALSE))
  if (!grepl("(^|/)\\.DS_Store$", f)) put(S("data/MICS_Datasets", f), file.path("data/raw/MICS_Datasets", f), "raw_mics_download")
put(S("data/fusion_GLOBAL_DATAFLOW_UNICEF_1.0_all.csv"), "data/unicef/original/fusion_GLOBAL_DATAFLOW_UNICEF_1.0_all.csv", "unicef_original")

## Public inputs (committed) ---------------------------------------------------------------------
public <- c(
  list.files(S("data"), pattern = "2026-09-09 10-58-22[.]csv$", full.names = FALSE),
  "ihme_malaria_u5_deaths_by_age_country_year.csv",
  "external/figure5/unicef_cacode_u5_malaria_2000_2024.csv", "external/figure5/source.json",
  "external/cacode/unicef_cacode_u5_malaria_fraction_2000_2024.csv", "external/cacode/source.json",
  file.path("external/nigeria_states", list.files(S("data/external/nigeria_states"))),
  "HIV_Epidemiology_Children_Adolescents_2025.xlsx", "unaids_aidsinfo/liberia_new_hiv_infections_children_0_14.csv",
  "wb_gdp_pc.csv", "wb_hexp_pc.csv", "wb_polstab.csv", "igme_u5mr_by_country.csv", "pfpr_admin1_ng_cd_2024.csv",
  "pfpr_2to10_africa_2024.tif", file.path("map_annual", sprintf("pfpr2_10_%d.tif", 2000:2024)),
  "pop/gpw_v4_population_density_rev11_2020_2.5m.tif", "africa_admin0.rds",
  file.path("dhs_boundaries", list.files(S("data/dhs_boundaries"), pattern = "[.]rds$")))
for (f in public) put(S("data", f), file.path("data", f), "public_input")
snow <- "/Users/jameswatson/Documents/Claude Projects/Prevalence Model/Snow Prevalence Data/shape files"
for (f in list.files(snow, pattern = "^Africa_New_Admin")) put(file.path(snow, f), file.path("data/external/snow_admin1", f), "public_input")

## Frozen copies of fetched inputs (committed; restored to data/derived_*/ by run_pipeline.R) ------
ra <- "data/derived_cbh/regional_adjustment"
frozen <- c(file.path(ra, list.files(S(ra), pattern = "_page[0-9]+[.]json$")),
  file.path(ra, "planned17_audit", list.files(S(ra, "planned17_audit"), pattern = "_page[0-9]+[.]json$")),
  "data/derived_dhs/statcompiler_covariates.csv",
  "data/derived_dhs/hiv_prevalence_country_year.csv")
for (f in frozen) put(S(f), file.path("data/frozen", f), "frozen_restore")
# The survey registry with repository-relative paths (recodes in data/raw/dhs, boundaries in data/dhs_boundaries).
reg$local_recode <- file.path("data/raw/dhs", paste0(reg$no_extension, ".rds"))
reg$boundary_file <- ifelse(is.na(reg$boundary_file) | reg$boundary_file == "", reg$boundary_file,
                            file.path("data/dhs_boundaries", paste0(reg$SurveyId, ".rds")))
stopifnot(all(file.exists(reg$local_recode)), all(file.exists(reg$boundary_file[nzchar(reg$boundary_file)])))
dir.create("data/frozen/data/derived_dhs", recursive = TRUE, showWarnings = FALSE)
write.csv(reg, "data/frozen/data/derived_dhs/survey_registry.csv", row.names = FALSE, na = "")
f <- "data/frozen/data/derived_dhs/survey_registry.csv"
log[[length(log) + 1L]] <- data.frame(role = "frozen_restore", file = f, bytes = file.size(f), md5 = unname(tools::md5sum(f)),
                                      source = "<analysis project>/data/derived_dhs/survey_registry.csv (paths made repository-relative)")

## Fallbacks for checkpoints (committed; used only with run_pipeline.R --map=frozen / --hiv=frozen) --
fallback <- c("data/derived_dhs/map_pfpr_by_survey_region.csv", "data/derived_dhs/map_pfpr_window_years.csv",
  "data/derived_cbh/hiv_incidence/child_incidence_country_year_lbr.csv",
  "data/derived_cbh/hiv_incidence/child_incidence_country_year_extended_lbr.csv")
for (f in fallback) put(S(f), file.path("data/frozen", f), "frozen_fallback")
# The child HIV incidence panels and draws used by the paper (base panel fitted 8 September 2026, extended
# panel 18 September 2026). The analysis project froze the base panel: the current Stan code does not
# reproduce it, and refits differ in imputed country-years by MCMC error. run_pipeline.R restores these
# (stage hiv_panels) after refitting the model as a check; the Liberia panels are then rebuilt from them.
hiv_frozen <- file.path("data/derived_cbh/hiv_incidence", c("child_incidence_country_year.csv",
  "child_incidence_country_year_extended.csv", "child_incidence_draws.rds", "child_incidence_draws_extended.rds"))
for (f in hiv_frozen) put(S(f), file.path("data/frozen", f), "frozen_hiv")

all <- do.call(rbind, log)
raw <- all$role %in% c("raw_dhs_recode", "raw_mics_download", "unicef_original")
write.csv(all[raw, ], "data/raw_manifest.csv", row.names = FALSE)
write.csv(all[!raw, ], "data/INPUTS_MANIFEST.csv", row.names = FALSE)
cat(sprintf("Imported %d files (%.2f GB): %s\n", nrow(all), sum(all$bytes) / 1e9,
            paste(sprintf("%s %d", names(table(all$role)), table(all$role)), collapse = ", ")))
