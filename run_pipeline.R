#!/usr/bin/env Rscript
# Run the whole analysis for the paper, from raw survey microdata and the committed inputs, in order.
#
#   Rscript run_pipeline.R --list                 show the stages and whether each has completed
#   Rscript run_pipeline.R --all                  run every stage not yet completed, in order
#   Rscript run_pipeline.R --from=STAGE           run STAGE and every later stage (re-running them)
#   Rscript run_pipeline.R --only=STAGE           run one stage (re-running it)
#   Rscript run_pipeline.R --to=STAGE             with --all or --from: stop after STAGE
#   Rscript run_pipeline.R --only=hiv             optional check (not part of --all): refit the child HIV incidence model
#                                                 (after edits to the HIV code the base fit stops on its old cache:
#                                                 refit it by hand with Rscript R_cbh/hiv/01_fit_incidence.R --force)
#   options: --hiv=refit   use the panels refitted by --only=hiv instead of the paper's frozen panels (default frozen)
#            --ignore-versions  run with package versions that differ from the recorded ones
#
# The primary analysis uses the GADM 4.1 admin-1 units (KEMRI-Wellcome merge) as its unit (stages units,
# unit_covariates, primary; R_cbh/units/README.md). The Snow-unit primary (v11-v14) was replaced by GADM units in v15
# (author decision, 3 November 2026; code in git history up to f2db98e); the v9 survey-region primary and the outputs
# main.tex does not use were removed on 1 November 2026 (git history keeps them).
# The full run takes about 5 hours;
# run it detached: ./run_detached.sh --all   (logs in logs/, completion markers in logs/state/).
# No stage downloads anything: network access is blocked for every step (fetch scripts are in
# R_inputs/fetch/ and are run by hand). Only one pipeline process may run at a time, because the
# prepared dataset needs about 3 GB of memory per process.
args <- commandArgs(trailingOnly = TRUE)
opt <- function(name) { a <- grep(paste0("^--", name, "="), args, value = TRUE); if (length(a)) sub("^[^=]+=", "", a[1]) else NULL }
known <- "^--(list|all|ignore-versions|from=.+|only=.+|to=.+|hiv=(frozen|refit))$"
if (!length(args) || any(!grepl(known, args))) {
  cat("Usage: Rscript run_pipeline.R --list | --all | --from=STAGE | --only=STAGE [--to=STAGE] [--hiv=refit] [--ignore-versions]\n")
  quit(status = if (!length(args)) 0 else 1)
}
if (!file.exists("run_pipeline.R") || !file.exists("R_cbh/00_config.R")) stop("Run from the repository root.")
if (grepl("MIS:DHS malaria prevalence", getwd(), fixed = TRUE)) stop("This is the analysis project, not this repository.")
hiv_refit <- identical(opt("hiv"), "refit")

R <- function(script, ..., env = character()) list(cmd = file.path(R.home("bin"), "Rscript"), args = c(script, ...), script = script, env = env)
PY <- function(script, ..., env = character()) list(cmd = "python3", args = c(script, ...), script = script, env = env)
# The version is passed to each step (child processes): the primary, on the GADM admin-1 units.
GADM <- c("CBH_PRIMARY_VERSION=gadm")
unit_steps <- lapply(c("00_gadm_layer.R", "01_polygons.R", "02_pfpr_polygons.R", "03_feasibility.R", "04_location_variables.R",
  "05_finer_units.R", "07_placement.R", "08_units.R", "09_covariates_dhs.R", "10_covariates_mics.R"),
  function(f) R(file.path("R_cbh/units", f), env = GADM))
stages <- list(
  restore = list(R("tools/restore_frozen.R")),
  inputs = list(R("R_inputs/02_extract_map_pfpr.R"), R("R_inputs/41_extract_map_window_years.R"),
                R("R_inputs/dhs_region_centroids.R")),
  # The HIV model refit is an optional check; the paper's frozen panels are used by default (stage hiv_panels).
  hiv = list(R("R_cbh/hiv/01_fit_incidence.R"), R("R_cbh/hiv/01_fit_incidence.R", "--extended")),
  hiv_panels = c(if (!hiv_refit) list(R("tools/use_frozen_hiv.R")), list(R("R_cbh/hiv/03_add_liberia_aidsinfo.R"))),
  dhs_bands = list(R("R_cbh/01_make_analysis_data.R")),
  covariates = list(R("R_cbh/covariates/01_fetch_published.R"), R("R_cbh/covariates/07_prepare_unicef.R")),
  mics = lapply(c("00a_extract.R", "00_dump_metadata.R", "01_inventory.R", "04_boundaries_gnb_caf.R", "05_region_map.R",
                  "06_polygons_pfpr_registry.R", "07_make_recodes.R", "08_build_child_bands.R",
                  "11_region_centroids.R"), function(f) R(file.path("R_mics", f))),
  units = unit_steps[1:8],
  unit_covariates = unit_steps[9:10],
  primary = list(R("R_cbh/primary/run_regional.R", env = GADM)),
  subgroups = list(R("R_cbh/sensitivity/subgroups/01_fit.R", env = GADM), R("R_cbh/sensitivity/subgroups/02_report.R", env = GADM),
                   R("R_cbh/sensitivity/subgroups/03_survival_by_subregion.R", env = GADM),
                   R("R_cbh/sensitivity/subgroups/04_subregion_units_map.R", env = GADM),
                   R("R_cbh/sensitivity/subgroups/05_sahel_10n_country_table.R", env = GADM)),
  nutrition = list(R("R_cbh/sensitivity/nutrition/01_fit.R", env = GADM), R("R_cbh/sensitivity/nutrition/02_report.R", env = GADM)),
  country_fe = list(R("R_cbh/sensitivity/country_fe/01_fit.R", env = GADM), R("R_cbh/sensitivity/country_fe/02_report.R", env = GADM)),
  imputation = lapply(c("01_impute_national.R", "02_impute_regional.R", "03_prepare.R", "04_fit.R", "05_propagate.R",
                        "06_report.R"), function(f) R(file.path("R_cbh/sensitivity/imputation_dhsmics", f), env = GADM)),
  validate = list(R("R_cbh/reporting/10_validate_reporting.R", env = GADM)),
  export = list(PY("R_cbh/reporting/export_paper.py", "--destination", "paper", "--copy", env = GADM)))
optional <- "hiv"   # run only when named with --only
minutes <- c(restore = 1, inputs = 30, hiv = 30, hiv_panels = 1, dhs_bands = 6, covariates = 2, mics = 30,
             units = 25, unit_covariates = 12, primary = 25, subgroups = 45, nutrition = 20, country_fe = 20, imputation = 90, validate = 1,
             export = 1)
# A stage's dependency set: its scripts, the other code and config in their folders, and the shared helpers. A completion
# marker whose recorded md5s differ from the current files is stale, so the stage is pending again.
helpers <- c(list.files("R_cbh/R", "[.]R$", full.names = TRUE), "R_cbh/00_config.R", "R_cbh/load_pipeline.R",
  "R_cbh/analysis/model.R", "R_cbh/sensitivity/model.R", "R_cbh/primary/settings.R", "R_cbh/primary/specification.R",
  "R_cbh/primary/national_substitutions.R",
  list.files("R_cbh/units/R", "[.]R$", full.names = TRUE), list.files("R_cbh/units/config", "[.]csv$", full.names = TRUE))
deps <- function(s) {
  scripts <- unique(vapply(stages[[s]], `[[`, "", "script"))
  dirs <- unique(c(dirname(scripts), if (any(grepl("run_regional", scripts))) c("R_cbh/reporting", "R_cbh/burden")))
  sort(unique(c(scripts, unlist(lapply(dirs, list.files, pattern = "[.](R|py|csv|stan)$", full.names = TRUE)), helpers)))
}

state_dir <- "logs/state"; dir.create(state_dir, recursive = TRUE, showWarnings = FALSE)
marker_md5 <- function(s) {
  f <- file.path(state_dir, paste0(s, ".done")); if (!file.exists(f)) return(NULL)
  x <- sub("^script_md5: ", "", grep("^script_md5: ", readLines(f, warn = FALSE), value = TRUE))
  setNames(sub(".* ", "", x), sub(" [0-9a-f]{32}$", "", x))
}
done <- function(s) {
  r <- marker_md5(s); if (is.null(r)) return(FALSE)
  d <- deps(s); identical(sort(names(r)), d) && all(unname(tools::md5sum(d)) == r[d])
}
if ("--list" %in% args) {
  for (s in names(stages)) cat(sprintf("%-15s %-9s ~%3d min  %s\n", s,
    if (done(s)) "done" else if (!is.null(marker_md5(s))) "stale" else if (s %in% optional) "optional" else "-", minutes[[s]],
    paste(unique(vapply(stages[[s]], `[[`, "", "script")), collapse = ", ")))
  quit(status = 0)
}
pick <- function(name) { if (!name %in% names(stages)) stop("Unknown stage: ", name); match(name, names(stages)) }
main <- setdiff(names(stages), optional)
if (!is.null(opt("only"))) run <- names(stages)[pick(opt("only"))] else {
  first <- if (!is.null(opt("from"))) pick(opt("from")) else {
    pending <- which(!vapply(names(stages), done, logical(1)) & names(stages) %in% main)
    if (!length(pending)) { message("Every stage has completed; use --from or --only to re-run."); quit(status = 0) }
    min(pending)
  }
  last <- if (!is.null(opt("to"))) pick(opt("to")) else length(stages)
  stopifnot(first <= last)
  run <- intersect(names(stages)[first:last], main)
}

## Preflight ------------------------------------------------------------------------------------------
lock <- "logs/pipeline.lock"
if (file.exists(lock)) {
  pid <- suppressWarnings(as.integer(readLines(lock, warn = FALSE)[1]))
  alive <- !is.na(pid) && identical(suppressWarnings(system2("kill", c("-0", pid), stdout = FALSE, stderr = FALSE)), 0L)
  if (alive) stop("Another pipeline run is active (process ", pid, "). One run at a time.")
}
writeLines(as.character(Sys.getpid()), lock)
if (!identical(Sys.getlocale("LC_COLLATE"), "en_GB"))
  stop("The paper's results were produced with collation locale en_GB (sorting and factor levels depend on it); got ",
       Sys.getlocale("LC_COLLATE"), ". Leave LANG and LC_ALL unset on a Mac whose region is the UK (R then uses en_GB; LANG=en_GB alone breaks Python),",
       " or set LANG=en_GB.UTF-8 LC_COLLATE=en_GB.")
recorded <- c(R = "4.6.0", mgcv = "1.9.4", rstan = "2.32.7", StanHeaders = "2.32.10", terra = "1.9.34", sf = "1.1.1",
  exactextractr = "0.10.1", mice = "3.19.0", data.table = "1.18.4", haven = "2.5.5", ragg = "1.5.2", ggplot2 = "4.0.3",
  patchwork = "1.3.2", ggrepel = "0.9.8", countrycode = "1.8.0", readxl = "1.4.5", MASS = "7.3.65", dplyr = "1.2.1")
installed <- c(R = paste(R.version$major, R.version$minor, sep = "."),
  vapply(names(recorded)[-1], function(p) tryCatch(as.character(packageVersion(p)), error = function(e) "missing"), ""))
off <- names(recorded)[installed != recorded]
if (length(off)) {
  msg <- paste(sprintf("%s %s (recorded %s)", off, installed[off], recorded[off]), collapse = "; ")
  if (!"--ignore-versions" %in% args) stop("Versions differ from those used for the paper: ", msg, ". Use --ignore-versions to run anyway.")
  warning("Versions differ from those used for the paper: ", msg)
}
inputs <- read.csv("data/INPUTS_MANIFEST.csv", stringsAsFactors = FALSE)
raw <- read.csv("data/raw_manifest.csv", stringsAsFactors = FALSE)
miss <- c(inputs$file[!file.exists(inputs$file)], raw$file[!file.exists(raw$file) & raw$role != "unicef_original"])
if (length(miss)) stop(length(miss), " input files are missing, e.g. ", paste(head(miss, 3), collapse = ", "),
                       ". See data/README.md (raw microdata go in data/raw/).")
bad <- inputs$file[unname(tools::md5sum(inputs$file)) != inputs$md5]
if (length(bad)) stop("Committed inputs differ from data/INPUTS_MANIFEST.csv: ", paste(head(bad, 5), collapse = ", "))
size_bad <- raw$file[file.exists(raw$file) & file.size(raw$file) != raw$bytes]
if (length(size_bad)) stop("Raw files differ in size from data/raw_manifest.csv: ", paste(head(size_bad, 5), collapse = ", "))
# The GADM 4.1 admin-1 layer (KEMRI-Wellcome merge) is not committed (GADM licence) and not in either manifest; stage
# units reads it (R_cbh/units/00_gadm_layer.R), later stages read the unit layer that stage writes.
source("R_cbh/units/R/settings.R")
if ("units" %in% run && !file.exists(units_settings()$source))
  stop("The GADM admin-1 layer is missing: ", units_settings()$source, ". See data/README.md.")
# Block network access for every step, so that a missing cache fails instead of downloading.
Sys.setenv(http_proxy = "http://127.0.0.1:9", https_proxy = "http://127.0.0.1:9", HTTP_PROXY = "http://127.0.0.1:9",
           HTTPS_PROXY = "http://127.0.0.1:9", ALL_PROXY = "http://127.0.0.1:9", no_proxy = "", NO_PROXY = "",
           CBH_PRIMARY_VERSION = "gadm")
commit <- tryCatch(system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE), error = function(e) NA_character_)
dirty <- length(tryCatch(system2("git", c("status", "--porcelain", "--untracked-files=no"), stdout = TRUE, stderr = FALSE),
                         error = function(e) character())) > 0

## Run --------------------------------------------------------------------------------------------------
dir.create("paper", showWarnings = FALSE)   # export destination (export_paper.py requires an existing folder)
stamp <- format(Sys.time(), "%Y%m%dT%H%M%S")
times <- "logs/stage_times.csv"
message(sprintf("Running %s (about %d minutes); commit %s%s", paste(run, collapse = ", "), sum(minutes[run]),
                substr(commit, 1, 7), if (dirty) " with uncommitted changes" else ""))
run_stage <- function(s) {
  unlink(file.path(state_dir, paste0(s, c(".done", ".failed"))))
  started <- Sys.time(); message(format(started, "%H:%M:%S"), " stage ", s)
  for (k in seq_along(stages[[s]])) {
    step <- stages[[s]][[k]]
    log <- sprintf("logs/%s_%s_%02d_%s.log", stamp, s, k, sub("[.](R|py)$", "", basename(step$script)))
    t0 <- Sys.time()
    status <- system2(step$cmd, shQuote(step$args), stdout = log, stderr = log, env = step$env)
    row <- data.frame(run = stamp, stage = s, step = paste(step$args, collapse = " "), started = format(t0),
                      elapsed_minutes = round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 2), exit_status = status,
                      commit = commit, dirty = dirty)
    write.table(row, times, sep = ",", row.names = FALSE, col.names = !file.exists(times), append = file.exists(times))
    if (status != 0L) {
      writeLines(c(paste("failed step:", paste(step$args, collapse = " ")), paste("log:", log)), file.path(state_dir, paste0(s, ".failed")))
      stop("Stage ", s, " failed at ", paste(step$args, collapse = " "), "; see ", log)
    }
  }
  d <- deps(s)
  writeLines(c(paste("finished:", format(Sys.time())), paste("minutes:", round(as.numeric(difftime(Sys.time(), started, units = "mins")), 1)),
               paste("commit:", commit), paste("uncommitted_changes:", dirty),
               paste0("script_md5: ", d, " ", unname(tools::md5sum(d)))), file.path(state_dir, paste0(s, ".done")))
  message(format(Sys.time(), "%H:%M:%S"), " stage ", s, " done")
}
tryCatch(for (s in run) run_stage(s), finally = unlink(lock))
message("Pipeline finished: ", paste(run, collapse = ", "))
