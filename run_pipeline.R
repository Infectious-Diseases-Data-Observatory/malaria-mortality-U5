#!/usr/bin/env Rscript
# Run the whole analysis for the paper, from raw survey microdata and the committed inputs, in order.
#
#   Rscript run_pipeline.R --list                 show the stages and whether each has completed
#   Rscript run_pipeline.R --all                  run every stage not yet completed, in order
#   Rscript run_pipeline.R --from=STAGE           run STAGE and every later stage (re-running them)
#   Rscript run_pipeline.R --only=STAGE           run one stage (re-running it)
#   Rscript run_pipeline.R --to=STAGE             with --all or --from: stop after STAGE
#   options: --map=frozen  use the frozen survey-region MAP tables instead of recomputing them
#            --hiv=refit   use today's refitted HIV panels instead of the paper's frozen panels (default frozen)
#            --ignore-versions  run with package versions that differ from the recorded ones
#
# The full run takes about 5.5 hours (the imputed-covariate sensitivity alone about 2.5 hours);
# run it detached: ./run_detached.sh --all   (logs in logs/, completion markers in logs/state/).
# No stage downloads anything: network access is blocked for every step (fetch scripts are in
# R_inputs/fetch/ and are run by hand). Only one pipeline process may run at a time, because the
# prepared dataset needs about 3 GB of memory per process.
args <- commandArgs(trailingOnly = TRUE)
opt <- function(name) { a <- grep(paste0("^--", name, "="), args, value = TRUE); if (length(a)) sub("^[^=]+=", "", a[1]) else NULL }
known <- "^--(list|all|ignore-versions|from=.+|only=.+|to=.+|map=(recompute|frozen)|hiv=(frozen|refit))$"
if (!length(args) || any(!grepl(known, args))) {
  cat("Usage: Rscript run_pipeline.R --list | --all | --from=STAGE | --only=STAGE [--to=STAGE] [--map=frozen] [--hiv=refit] [--ignore-versions]\n")
  quit(status = if (!length(args)) 0 else 1)
}
if (!file.exists("run_pipeline.R") || !file.exists("R_cbh/00_config.R")) stop("Run from the repository root.")
if (grepl("MIS:DHS malaria prevalence", getwd(), fixed = TRUE)) stop("This is the analysis project, not this repository.")
map_frozen <- identical(opt("map"), "frozen")
hiv_refit <- identical(opt("hiv"), "refit")

R <- function(script, ...) list(cmd = file.path(R.home("bin"), "Rscript"), args = c(script, ...), script = script)
PY <- function(script, ...) list(cmd = "python3", args = c(script, ...), script = script)
stages <- list(
  restore = list(R("tools/restore_frozen.R", if (map_frozen) "--map")),
  inputs = c(if (!map_frozen) list(R("R_inputs/02_extract_map_pfpr.R"), R("R_inputs/41_extract_map_window_years.R")),
             list(R("R_inputs/02b_extract_unicef_immunisation.R"), R("R_inputs/dhs_region_centroids.R"),
                  R("R_inputs/who_wmr2025_tables.R"))),
  # The HIV model is refitted as a check; by default the paper's frozen panels are then used (stage hiv_panels).
  hiv = list(R("R_cbh/hiv/01_fit_incidence.R"), R("R_cbh/hiv/01_fit_incidence.R", "--extended")),
  hiv_panels = c(if (!hiv_refit) list(R("tools/use_frozen_hiv.R")), list(R("R_cbh/hiv/03_add_liberia_aidsinfo.R"))),
  dhs_bands = list(R("R_cbh/01_make_analysis_data.R")),
  covariates = list(R("R_cbh/covariates/01_fetch_published.R"), PY("R_cbh/covariates/12_fetch_nutrition.py"),
                    R("R_cbh/covariates/run.R"), R("R_cbh/covariates/11_extract_first_birth_age.R"),
                    R("R_cbh/covariates/13_audit_planned17.R"), R("R_cbh/covariates/14_exclusion_attribution.R"),
                    R("R_cbh/covariates/14_exclusion_attribution.R", "--liberia")),
  mics = lapply(c("00a_extract.R", "00_dump_metadata.R", "01_inventory.R", "04_boundaries_gnb_caf.R", "05_region_map.R",
                  "06_polygons_pfpr_registry.R", "07_make_recodes.R", "08_build_child_bands.R", "09_regional_covariates.R",
                  "10_exclusion_attribution_mics.R", "11_region_centroids.R"), function(f) R(file.path("R_mics", f))),
  primary = list(R("R_cbh/primary/run_regional.R")),
  subgroups = list(R("R_cbh/sensitivity/subgroups/01_fit.R"), R("R_cbh/sensitivity/subgroups/02_report.R")),
  nutrition = list(R("R_cbh/sensitivity/nutrition/01_fit.R"), R("R_cbh/sensitivity/nutrition/02_report.R")),
  imputation = lapply(c("01_impute_national.R", "02_impute_regional.R", "03_prepare.R", "04_fit.R", "05_propagate.R",
                        "06_report.R"), function(f) R(file.path("R_cbh/sensitivity/imputation_dhsmics", f))),
  validate = list(R("R_cbh/reporting/10_validate_reporting.R")),
  export = list(PY("R_cbh/reporting/export_paper.py", "--destination", "paper", "--copy")))
minutes <- c(restore = 1, inputs = 12, hiv = 30, hiv_panels = 1, dhs_bands = 6, covariates = 25, mics = 30, primary = 25,
             subgroups = 15, nutrition = 50, imputation = 150, validate = 1, export = 1)

state_dir <- "logs/state"; dir.create(state_dir, recursive = TRUE, showWarnings = FALSE)
done <- function(s) file.exists(file.path(state_dir, paste0(s, ".done")))
if ("--list" %in% args) {
  for (s in names(stages)) cat(sprintf("%-11s %-9s ~%3d min  %s\n", s, if (done(s)) "done" else "-", minutes[[s]],
                                       paste(vapply(stages[[s]], `[[`, "", "script"), collapse = ", ")))
  quit(status = 0)
}
pick <- function(name) { if (!name %in% names(stages)) stop("Unknown stage: ", name); match(name, names(stages)) }
if (!is.null(opt("only"))) run <- names(stages)[pick(opt("only"))] else {
  first <- if (!is.null(opt("from"))) pick(opt("from")) else {
    pending <- which(!vapply(names(stages), done, logical(1)))
    if (!length(pending)) { message("Every stage has completed; use --from or --only to re-run."); quit(status = 0) }
    min(pending)
  }
  last <- if (!is.null(opt("to"))) pick(opt("to")) else length(stages)
  stopifnot(first <= last)
  run <- names(stages)[first:last]
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
       Sys.getlocale("LC_COLLATE"), ". Set LANG=en_GB.UTF-8.")
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
# Block network access for every step, so that a missing cache fails instead of downloading.
Sys.setenv(http_proxy = "http://127.0.0.1:9", https_proxy = "http://127.0.0.1:9", HTTP_PROXY = "http://127.0.0.1:9",
           HTTPS_PROXY = "http://127.0.0.1:9", ALL_PROXY = "http://127.0.0.1:9", no_proxy = "", NO_PROXY = "",
           CBH_PRIMARY_VERSION = "regional_mics")
commit <- tryCatch(system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE), error = function(e) NA_character_)
dirty <- length(tryCatch(system2("git", c("status", "--porcelain", "--untracked-files=no"), stdout = TRUE, stderr = FALSE),
                         error = function(e) character())) > 0

## Run --------------------------------------------------------------------------------------------------
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
    status <- system2(step$cmd, shQuote(step$args), stdout = log, stderr = log)
    row <- data.frame(run = stamp, stage = s, step = paste(step$args, collapse = " "), started = format(t0),
                      elapsed_minutes = round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 2), exit_status = status,
                      commit = commit, dirty = dirty)
    write.table(row, times, sep = ",", row.names = FALSE, col.names = !file.exists(times), append = file.exists(times))
    if (status != 0L) {
      writeLines(c(paste("failed step:", paste(step$args, collapse = " ")), paste("log:", log)), file.path(state_dir, paste0(s, ".failed")))
      stop("Stage ", s, " failed at ", paste(step$args, collapse = " "), "; see ", log)
    }
  }
  scripts <- unique(vapply(stages[[s]], `[[`, "", "script"))
  writeLines(c(paste("finished:", format(Sys.time())), paste("minutes:", round(as.numeric(difftime(Sys.time(), started, units = "mins")), 1)),
               paste("commit:", commit), paste("uncommitted_changes:", dirty),
               paste0("script_md5: ", scripts, " ", unname(tools::md5sum(scripts)))), file.path(state_dir, paste0(s, ".done")))
  message(format(Sys.time(), "%H:%M:%S"), " stage ", s, " done")
}
tryCatch(for (s in run) run_stage(s), finally = unlink(lock))
message("Pipeline finished: ", paste(run, collapse = ", "))
