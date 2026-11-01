#!/usr/bin/env Rscript
# Restore the frozen copies of internet-fetched inputs (data/frozen/<path>) to the paths the scripts
# read (<path>): the DHS survey registry (repository-relative paths), the DHS API indicator list and national
# indicator pages, and the StatCompiler indicators (data/INPUTS_MANIFEST.csv role frozen_restore).
# File times are kept: the DHS API scripts record a page's retrieval date from its file time.
stopifnot(!length(commandArgs(trailingOnly = TRUE)))
m <- read.csv("data/INPUTS_MANIFEST.csv", stringsAsFactors = FALSE)
use <- m$role == "frozen_restore"
for (f in m$file[use]) {
  to <- sub("^data/frozen/", "", f)
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(f, to, overwrite = TRUE, copy.date = TRUE),
            identical(unname(tools::md5sum(to)), m$md5[m$file == f]))
}
cat("Restored", sum(use), "frozen files\n")
