#!/usr/bin/env Rscript
# Check that R_inputs/00_config.R is an unchanged subset of the analysis project's R_dhs/00_config.R.
# Usage (from the repository root): Rscript tools/check_trimmed_config.R "<path to analysis project>"
# Every definition in the trimmed file must equal the original (functions compared by their deparsed
# code; path constants after replacing each project's root), except the documented deliberate edits.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, file.exists(file.path(args[1], "R_dhs/00_config.R")))
src <- normalizePath(args[1]); tgt <- normalizePath(getwd())
load_config <- function(root, file) {
  env <- new.env()
  env$dir.create <- function(...) invisible(FALSE)   # sourcing must not create folders
  old <- setwd(root); on.exit(setwd(old))
  sys.source(file, envir = env)
  rm("dir.create", envir = env)
  env
}
a <- load_config(src, "R_dhs/00_config.R")
b <- load_config(tgt, "R_inputs/00_config.R")
deliberate <- c("RESULTS_DIR", "DHS_LOCAL_DIR", "UNICEF_GLOBAL_CSV", "UNICEF_IMMUNISATION_SUMMARY_CSV",
                "MAP_STATUS_CSV", "local_recode_path", "REPO_ROOT",
                "MAP_RASTER_DIR", "MAP_REGION_DIR", "MAP_DATASET_ID")   # MAP release 202608 (1 November 2026)
same <- function(x, y) {
  if (is.function(x)) return(identical(deparse(x), deparse(y)))
  if (is.character(x)) return(identical(sub(src, "<ROOT>", x, fixed = TRUE), sub(tgt, "<ROOT>", y, fixed = TRUE)))
  identical(x, y)
}
names_b <- ls(b, all.names = TRUE)
missing <- setdiff(names_b, ls(a, all.names = TRUE))
if (length(missing)) stop("Not in the original config: ", paste(missing, collapse = ", "))
changed <- Filter(function(n) !same(get(n, a), get(n, b)), setdiff(names_b, deliberate))
if (length(changed)) stop("Definitions differ from the original: ", paste(changed, collapse = ", "))
cat(sprintf("Trimmed config OK: %d definitions kept unchanged, %d deliberate edits (%s); %d original definitions not kept.\n",
            length(setdiff(names_b, deliberate)), length(intersect(names_b, deliberate)),
            paste(intersect(names_b, deliberate), collapse = ", "), length(setdiff(ls(a, all.names = TRUE), names_b))))
