# Local paths of the DHS Household Member Recode (PR) and WHO height/weight recode (HW) of a survey, from
# R_cbh/units/config/dhs_pr_hw_files.csv (file names frozen from the analysis project's recode list; files in
# data/raw/dhs/, imported by tools/import_pr_hw.R). A PR can carry a different recode version from the BR (BF43 BR / BF44 PR,
# NG4B / NG4C, ...). The HW file exists only for older surveys; NA otherwise.
units_pr_hw <- local({ cache <- NULL; function() {
  if (is.null(cache)) cache <<- data.table::fread("R_cbh/units/config/dhs_pr_hw_files.csv", na.strings = "")
  cache } })
units_raw <- function(stem) if (is.na(stem) || !nzchar(stem)) NA_character_ else {
  p <- file.path("data/raw/dhs", paste0(stem, ".rds")); if (file.exists(p)) p else stop("Missing raw recode: ", p, " (tools/import_pr_hw.R)") }
units_pr_path <- function(sv) { x <- units_pr_hw()[svkey == sv]; if (nrow(x) != 1L) stop("No PR entry for ", sv); units_raw(x$pr_stem) }
units_hw_path <- function(sv) { x <- units_pr_hw()[svkey == sv]; if (nrow(x) != 1L) stop("No PR/HW entry for ", sv); units_raw(x$hw_stem) }
