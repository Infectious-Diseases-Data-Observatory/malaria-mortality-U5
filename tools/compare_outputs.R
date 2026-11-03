#!/usr/bin/env Rscript
# Compare this repository's pipeline outputs with the analysis project's (opened read-only).
#   Rscript tools/compare_outputs.R --reference="<analysis project>" --checkpoint=NAME [--overleaf="<dir>"]
# Checkpoints follow the pipeline: inputs, hiv, dhs_bands, covariates, mics, primary (national burden inputs), paper; for
# the GADM-unit primary also units, unit_primary and sensitivities (reference: a saved copy of this repository).
# The v9 checkpoints (the v9 fits, its sensitivities) were removed with v9 on 1 November 2026, and the verification
# records of earlier runs on the same day (git history keeps them).
# Each file is classed as
#   identical   byte-for-byte
#   equivalent  same after removing volatile columns (hashes, paths, timings) and normalising paths
#   numeric     numeric columns agree within |a-b| <= 1e-12 + 1e-9|b| (counts and text exact)
#   DIFFERENT   anything else (details in the CSV)
#   missing     produced by one side only
# Results go to verification/<checkpoint>.csv; the exit status is 1 if any file is DIFFERENT or missing.
args <- commandArgs(trailingOnly = TRUE)
opt <- function(n) { a <- grep(paste0("^--", n, "="), args, value = TRUE); if (length(a)) sub("^[^=]+=", "", a[1]) else NULL }
ref <- opt("reference"); cp <- opt("checkpoint"); overleaf <- opt("overleaf")
stopifnot(!is.null(ref), dir.exists(ref), !is.null(cp))
ref <- normalizePath(ref); tgt <- normalizePath(getwd())
suppressPackageStartupMessages(library(data.table))
v15 <- "results/cbh/primary_gadm_merge_dhsmics_gamma2_v15"
# Paths that differ only because of this repository's layout.
renames <- c("/Users/jameswatson/.rdhs_cache/datasets_reformatted/" = "data/raw/dhs/", "~/.rdhs_cache/datasets_reformatted/" = "data/raw/dhs/",
  "data/dhs/" = "data/raw/dhs/", "data/MICS_extracted" = "data/raw/MICS_extracted", "data/MICS_Datasets" = "data/raw/MICS_Datasets",
  "results/cbh/age_band_separate_v1" = "results/cbh/national_burden_inputs",
  "fusion_GLOBAL_DATAFLOW_UNICEF_1.0_all.csv" = "unicef/fusion_GLOBAL_DATAFLOW_UNICEF_1.0_immunisation_subset.csv",
  "results/dhs_rebuild/" = "results/inputs/", "R_dhs/" = "R_inputs/",
  "/Users/jameswatson/Documents/Claude Projects/Prevalence Model/Snow Prevalence Data/shape files/" = "data/external/snow_admin1/")
norm <- function(x) {
  x <- gsub(paste0(ref, "/"), "", x, fixed = TRUE); x <- gsub(paste0(tgt, "/"), "", x, fixed = TRUE)
  x <- gsub(ref, ".", x, fixed = TRUE); x <- gsub(tgt, ".", x, fixed = TRUE)
  for (k in names(renames)) x <- gsub(k, renames[[k]], x, fixed = TRUE)
  x <- gsub("data/raw/raw/", "data/raw/", gsub("data/data/", "data/", x, fixed = TRUE), fixed = TRUE)
  sub("^cached$", "built", x)   # shard status: reused from an earlier run of the same code
}
volatile <- "md5|sha256|hash|signature|elapsed|started|finished|retrieved|session|^seconds$|_seconds$|^time$|timestamp|generated"
sets <- list(
  inputs = c("data/derived_dhs/map_pfpr_by_survey_region.csv", "data/derived_dhs/map_pfpr_window_years.csv",
             "data/derived_dhs/dhs_region_centroids.csv"),
  hiv = c("data/derived_cbh/hiv_incidence", "results/cbh/hiv_incidence"),
  dhs_bands = c("data/derived_cbh/survey_manifest.csv", "data/derived_cbh/child_checks.csv", "data/derived_cbh/eligibility_flow.csv",
                "data/derived_cbh/region_crosswalk.csv", "data/derived_cbh/child_bands"),
  covariates = "data/derived_cbh/regional_adjustment",
  mics = c("data/derived_mics", "results/mics_inventory"),
  primary = "results/cbh/national_burden_inputs",
  # GADM-unit primary: checked against a saved copy of this repository's own earlier outputs (--reference=<copy>).
  units = c("results/cbh/units", "data/derived_cbh/units"),
  unit_primary = c(v15, file.path("data/derived_cbh/models", basename(v15), "pfpr_components.rds")),
  sensitivities = c("results/cbh/subgroups_gadm_merge_gamma2_v9", "results/cbh/nutrition_adjustment_gadm_merge_gamma2_v9",
                    "results/cbh/country_fixed_effects_gadm_merge_gamma2_v3",
                    "results/cbh/primary_gadm_merge_imputed_gamma2_v16", "results/cbh/covariate_imputation_gadm_v16"),
  paper = "paper")
stopifnot(cp %in% names(sets))
skip <- "previous_overleaf|paper_refresh/export_|pipeline_stages[.]csv$|output_manifest[.]csv$|[.]log$|\\.DS_Store$|_cache/|/cache[.]rds$"
# Reference location of a target file (layout differences only).
ref_path <- function(f) {
  if (cp == "paper") return(file.path(overleaf, sub("^paper/", "", f)))
  f <- sub("^results/cbh/national_burden_inputs/", "results/cbh/age_band_separate_v1/", f)
  f <- sub("^results/inputs/", "results/dhs_rebuild/", f)
  file.path(ref, f)
}
files_under <- function(root, p) {
  full <- file.path(root, p)
  if (file.exists(full) && !dir.exists(full)) return(p)
  if (!dir.exists(full)) return(character())
  file.path(p, list.files(full, recursive = TRUE, all.files = FALSE))
}
targets <- unique(unlist(lapply(sets[[cp]], files_under, root = tgt)))
targets <- targets[!grepl(skip, targets)]
if (cp == "primary") targets <- targets[!grepl("^results/cbh/national_burden_inputs/.*(country_age_inputs|ihme_under5_totals|provenance)", targets)]
read_any <- function(p) tryCatch(fread(p, colClasses = "character", na.strings = NULL, showProgress = FALSE), error = function(e) NULL)
compare_csv <- function(a, b) {
  x <- read_any(a); y <- read_any(b)
  if (is.null(x) || is.null(y)) return(list(class = "DIFFERENT", detail = "unreadable"))
  keep <- function(d) d[, !grepl(volatile, names(d), ignore.case = TRUE), with = FALSE]
  x <- keep(x); y <- keep(y)
  if (!identical(names(x), names(y))) return(list(class = "DIFFERENT", detail = paste("columns:", paste(setdiff(union(names(x), names(y)), intersect(names(x), names(y))), collapse = " "))))
  if (nrow(x) != nrow(y)) return(list(class = "DIFFERENT", detail = sprintf("rows %d vs %d", nrow(x), nrow(y))))
  cls <- "equivalent"; worst <- 0; bad <- character()
  for (v in names(x)) {
    a1 <- norm(x[[v]]); b1 <- norm(y[[v]])
    if (identical(a1, b1)) next
    na <- suppressWarnings(as.numeric(a1)); nb <- suppressWarnings(as.numeric(b1))
    num <- !is.na(na) & !is.na(nb)
    if (all(num | (a1 == b1))) {
      d <- abs(na - nb); tol <- 1e-12 + 1e-9 * abs(nb)
      ok <- !num | d <= tol
      if (all(ok)) { cls <- "numeric"; worst <- max(worst, max(d[num] / pmax(abs(nb[num]), 1e-300))); next }
    }
    bad <- c(bad, v)
  }
  if (length(bad)) return(list(class = "DIFFERENT", detail = paste("columns differ:", paste(head(bad, 8), collapse = " "))))
  list(class = cls, detail = if (cls == "numeric") sprintf("max relative difference %.2g", worst) else "")
}
compare_text <- function(a, b) {
  x <- norm(readLines(a, warn = FALSE)); y <- norm(readLines(b, warn = FALSE))
  if (identical(x, y)) return(list(class = "equivalent", detail = ""))
  i <- which(x[seq_len(min(length(x), length(y)))] != y[seq_len(min(length(x), length(y)))])[1]
  list(class = "DIFFERENT", detail = sprintf("lines %d vs %d; first difference at line %s", length(x), length(y), i))
}
compare_rds <- function(a, b) {
  x <- readRDS(a); y <- readRDS(b)
  strip <- function(o) {
    if (is.list(o) && !is.data.frame(o)) { o[intersect(names(o), c("signature", "source_files", "source_hashes", "created", "session_info", "elapsed_seconds", "model_md5"))] <- NULL; lapply(o, strip) } else o
  }
  if (isTRUE(all.equal(strip(x), strip(y), tolerance = 1e-9, check.attributes = TRUE))) return(list(class = "equivalent", detail = ""))
  # Child-band shards: compare the data only.
  if (is.list(x) && !is.null(x$data) && !is.null(y$data) && isTRUE(all.equal(x$data, y$data, tolerance = 1e-12)))
    return(list(class = "equivalent", detail = "data identical; metadata differ"))
  list(class = "DIFFERENT", detail = paste(head(all.equal(strip(x), strip(y), tolerance = 1e-9), 2), collapse = "; "))
}
compare_png <- function(a, b) {
  if (!requireNamespace("png", quietly = TRUE)) return(list(class = "DIFFERENT", detail = "image bytes differ (png package unavailable)"))
  x <- png::readPNG(a); y <- png::readPNG(b)
  if (identical(dim(x), dim(y)) && max(abs(x - y)) == 0) return(list(class = "equivalent", detail = "pixels identical"))
  list(class = "DIFFERENT", detail = if (identical(dim(x), dim(y))) sprintf("max pixel difference %.3g", max(abs(x - y))) else "image size differs")
}
rows <- lapply(targets, function(f) {
  r <- ref_path(f)
  if (!file.exists(r)) return(data.table(file = f, class = "missing", detail = "not in reference"))
  if (identical(unname(tools::md5sum(f)), unname(tools::md5sum(r)))) return(data.table(file = f, class = "identical", detail = ""))
  ext <- tolower(tools::file_ext(f))
  res <- if (ext == "csv") compare_csv(f, r) else if (ext %in% c("md", "txt", "json", "stan", "tex")) compare_text(f, r) else
    if (ext == "rds" && file.size(f) < 4e8) compare_rds(f, r) else if (ext == "png") compare_png(f, r) else list(class = "DIFFERENT", detail = "bytes differ")
  data.table(file = f, class = res$class, detail = res$detail)
})
out <- rbindlist(rows)
dir.create("verification", showWarnings = FALSE)
fwrite(out, file.path("verification", paste0(cp, ".csv")))
cat(sprintf("Checkpoint %s: %d files: %s\n", cp, nrow(out), paste(sprintf("%s %d", names(table(out$class)), table(out$class)), collapse = ", ")))
bad <- out[class %in% c("DIFFERENT", "missing")]
if (nrow(bad)) { print(head(bad, 30)); quit(status = 1) }
