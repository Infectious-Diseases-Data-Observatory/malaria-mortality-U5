# Local paths of the DHS Household Member Recode (PR) and WHO height/weight recode (HW) of a survey, from
# R_cbh/snow/config/dhs_pr_hw_files.csv (file names frozen by tools/freeze_pr_hw_table.R; files in data/raw/dhs/,
# imported by tools/import_pr_hw.R). A PR can carry a different recode version from the BR (BF43 BR / BF44 PR,
# NG4B / NG4C, ...). The HW file exists only for older surveys; NA otherwise.
snow_pr_hw <- local({ cache <- NULL; function() {
  if (is.null(cache)) cache <<- data.table::fread("R_cbh/snow/config/dhs_pr_hw_files.csv", na.strings = "")
  cache } })
snow_raw <- function(stem) if (is.na(stem) || !nzchar(stem)) NA_character_ else {
  p <- file.path("data/raw/dhs", paste0(stem, ".rds")); if (file.exists(p)) p else stop("Missing raw recode: ", p, " (tools/import_pr_hw.R)") }
snow_pr_path <- function(sv) { x <- snow_pr_hw()[svkey == sv]; if (nrow(x) != 1L) stop("No PR entry for ", sv); snow_raw(x$pr_stem) }
snow_hw_path <- function(sv) { x <- snow_pr_hw()[svkey == sv]; if (nrow(x) != 1L) stop("No PR/HW entry for ", sv); snow_raw(x$hw_stem) }
