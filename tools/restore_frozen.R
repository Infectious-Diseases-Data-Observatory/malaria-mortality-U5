#!/usr/bin/env Rscript
# Restore the frozen copies of internet-fetched inputs (data/frozen/<path>) to the paths the scripts
# read (<path>): the DHS survey registry (repository-relative paths), DHS API indicator pages
# (published regional indicators and nutrition), StatCompiler indicators and the legacy national HIV
# prevalence panel (kept so that child-band files match the paper's; not a model covariate).
# With --map, also the survey-region MAP PfPR tables (instead of recomputing them in stage "inputs").
# File times are kept: the DHS API scripts record a page's retrieval date from its file time.
args <- commandArgs(trailingOnly = TRUE); stopifnot(all(args %in% "--map"))
m <- read.csv("data/INPUTS_MANIFEST.csv", stringsAsFactors = FALSE)
use <- m$role == "frozen_restore" | ("--map" %in% args & m$role == "frozen_fallback" & grepl("map_pfpr", m$file))
for (f in m$file[use]) {
  to <- sub("^data/frozen/", "", f)
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(f, to, overwrite = TRUE, copy.date = TRUE),
            identical(unname(tools::md5sum(to)), m$md5[m$file == f]))
}
cat("Restored", sum(use), "frozen files\n")
