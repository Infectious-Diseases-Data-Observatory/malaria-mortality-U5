#!/usr/bin/env Rscript
# Copies the DHS PR and HW recodes listed in R_cbh/units/config/dhs_pr_hw_files.csv from the local rdhs cache into
# data/raw/dhs/<UPPER-CASE STEM>.rds (git-ignored; microdata), md5-checked, and APPENDS their rows to
# data/raw_manifest.csv (role raw_dhs_recode). Rows already in the manifest are left unchanged; nothing else is
# rewritten. Run from the repository root:  Rscript tools/import_pr_hw.R
suppressPackageStartupMessages(library(data.table))
stopifnot(file.exists("R_cbh/00_config.R"))
cfg <- fread("R_cbh/units/config/dhs_pr_hw_files.csv", na.strings = "")
stems <- unique(c(cfg$pr_stem, cfg$hw_stem)); stems <- stems[!is.na(stems) & nzchar(stems)]
cache <- path.expand("~/.rdhs_cache/datasets_reformatted")
held <- list.files(cache, full.names = TRUE)
man <- fread("data/raw_manifest.csv")
new <- rbindlist(lapply(stems, function(st) {
  to <- file.path("data/raw/dhs", paste0(st, ".rds"))
  from <- held[toupper(sub("[.]rds$", "", basename(held), ignore.case = TRUE)) == st]
  if (!length(from)) stop("Not in the rdhs cache: ", st)
  from <- from[1]
  if (!file.exists(to) || !identical(unname(tools::md5sum(to)), unname(tools::md5sum(from))))
    stopifnot(file.copy(from, to, overwrite = TRUE, copy.date = TRUE))
  m <- unname(tools::md5sum(to)); stopifnot(identical(m, unname(tools::md5sum(from))))
  data.table(role = "raw_dhs_recode", file = to, bytes = file.size(to), md5 = m,
             source = file.path("~/.rdhs_cache/datasets_reformatted", basename(from)))
}))
old <- man[file %in% new$file]
if (nrow(old)) {   # rows already listed (e.g. SLPR61FL) must describe the same file
  chk <- merge(old[, .(file, md5_old = md5)], new[, .(file, md5)], by = "file")
  stopifnot(all(chk$md5_old == chk$md5))
}
add <- new[!file %in% man$file]
fwrite(rbind(man, add), "data/raw_manifest.csv", quote = TRUE)
cat(sprintf("%d PR/HW files in data/raw/dhs (%.0f MB); %d manifest rows added, %d already listed\n",
            nrow(new), sum(new$bytes) / 1e6, nrow(add), nrow(old)))
