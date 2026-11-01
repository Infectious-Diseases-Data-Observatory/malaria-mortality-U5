#!/usr/bin/env Rscript
# Sensitivity (author request, 31 October 2026): country fixed effects in place of the country random intercept.
# Most of the variation in PfPR lies between countries, and the country random intercept is shrunk towards zero, so
# part of the PfPR effect may be estimated from between-country contrasts that the four national covariates do not
# fully adjust. With a fixed effect for each country, the PfPR effect is estimated from variation within countries
# only. This refits the seven primary age-band models of the Snow primary on the SAME complete-case sample with the
# same 17 covariates, reference knots, gamma = 2, offset and survey and survey x unit random intercepts; the only
# change is s(country, bs = "re") -> country. No data rebuild, no HIV refit, no TeX writes.
# Outputs (results/cbh/<id>/): fit_input_provenance.csv, covariate_scaling.csv, model_formula.txt, fit_diagnostics.csv,
# pfpr_curves.csv (log HR relative to PfPR 20%), smooth_summaries.csv, fit_manifest.csv, session_info.txt; and
# data/derived_cbh/models/<id>/countryfe_age_<i>.rds and pfpr_components.rds (PfPR basis for the burden in 02_report.R).
source("R_cbh/load_pipeline.R")
source("R_cbh/analysis/model.R")
source("R_cbh/sensitivity/model.R")
source("R_cbh/primary/settings.R")
source("R_cbh/primary/specification.R")
library(mgcv); library(data.table)
args <- commandArgs(trailingOnly = TRUE); stopifnot(all(args %in% "--force"))
# Snow primary only (the paper's primary since October 2026).
stopifnot(identical(Sys.getenv("CBH_PRIMARY_VERSION"), "snow_merge"))
st <- list(id = "country_fixed_effects_snow520_merge_gamma2_v2", replaced = "s(country, bs = \"re\")", by = "country")
st$out <- file.path("results/cbh", st$id); st$private <- file.path("data/derived_cbh/models", st$id)
primary <- cbh_primary_settings("snow_merge"); stopifnot(isTRUE(primary$nutrition))
for (p in c(st$out, st$private)) dir.create(p, recursive = TRUE, showWarnings = FALSE)
write_csv <- function(d, name) cbh_atomic_csv(d, file.path(st$out, name))

code <- c("R_cbh/sensitivity/country_fe/01_fit.R", "R_cbh/sensitivity/model.R",
          "R_cbh/analysis/model.R", "R_cbh/primary/settings.R", "R_cbh/primary/specification.R")
files <- c(primary$data, primary$knots, code)
provenance <- data.frame(file = files, md5 = vapply(files, cbh_file_hash, ""))
reference <- cbh_read_csv(file.path(primary$out, "fit_manifest.csv"))
stopifnot(nrow(reference) == 7L, all(reference$prepared_data_md5 == provenance$md5[1]))
write_csv(provenance, "fit_input_provenance.csv")

prepared <- readRDS(primary$data)
input <- as.data.table(prepared$data); input_signature <- prepared$signature
write_csv(prepared$scaling, "covariate_scaling.csv"); rm(prepared); gc(FALSE)
if (!is.null(primary$expected_records)) stopifnot(nrow(input) == primary$expected_records, sum(input$death) == primary$expected_deaths,
          uniqueN(input$region) == primary$expected_regions)

# Same formula as the primary with the country random intercept replaced by a country factor.
full_form <- cbh_primary_regional_formula(primary)
labels <- attr(terms(full_form), "term.labels")
stopifnot(sum(labels == st$replaced) == 1L)
form <- reformulate(c(setdiff(labels, st$replaced), st$by, "offset(log(band_years))"), response = "death")
writeLines(deparse(form), file.path(st$out, "model_formula.txt"))

knot_table <- cbh_read_csv(primary$knots)
ages <- cbh_config()$age_bands$age_band; widths <- c(1, 5, 6, 12, 12, 12, 12) / 12
input <- as.data.frame(input[, unique(c(all.vars(form), "age_band", "region")), with = FALSE])
stopifnot(!anyNA(input), is.factor(input$country))

run <- function(d, knots, initial = NULL, strict = FALSE) {
  warnings <- character(); set.seed(primary$seed)
  control <- if (strict) gam.control(epsilon = 1e-9, mgcv.tol = 1e-9, efs.tol = .001, maxit = 200) else gam.control(maxit = 100)
  timing <- system.time(f <- withCallingHandlers(bam(form, data = d, knots = knots,
    family = binomial(link = "cloglog"), method = "fREML", discrete = TRUE,
    gamma = primary$gamma, select = FALSE, nthreads = primary$nthreads, gc.level = 1,
    na.action = na.fail, coef = initial, control = control),
    warning = function(w) { warnings <<- unique(c(warnings, conditionMessage(w))); invokeRestart("muffleWarning") }))
  list(fit = f, elapsed_seconds = unname(timing["elapsed"]), warnings = warnings, session_info = sessionInfo())
}

diags <- curves <- manifests <- smooths <- restarts <- components <- list()
for (i in seq_along(ages)) {
  age <- ages[i]; id <- paste0("countryfe_age_", i)
  d <- droplevels(input[input$age_band == age, , drop = FALSE])
  stopifnot(nrow(d) > 0, all(d$death %in% 0:1), max(abs(d$band_years - widths[i])) < 1e-12)
  knots <- setNames(lapply(c("pfpr_pct", "calendar_year"), function(v) {
    k <- knot_table[knot_table$age_band == age & knot_table$variable == v, ]
    k$value[order(k$index)] }), c("pfpr_pct", "calendar_year"))
  stopifnot(length(knots$pfpr_pct) == 5L, length(knots$calendar_year) == 6L)
  sig <- cbh_hash(list(provenance, st, primary$gamma, knots, deparse(form),
                       R.version.string, as.character(packageVersion("mgcv"))))
  path <- file.path(st$private, paste0(id, ".rds"))
  saved <- if (file.exists(path) && !"--force" %in% args) readRDS(path) else NULL
  message("Starting ", id, ": ", nrow(d), " records, ", sum(d$death), " deaths, ", nlevels(d$country), " countries")
  if (is.null(saved) || !identical(saved$signature, sig)) {
    saved <- run(d, knots)
    saved$signature <- sig; saved$input_signature <- input_signature
    saved$gamma <- primary$gamma; saved$knots <- knots
    cbh_atomic_rds(saved, path)
  }
  diag <- cbh_sensitivity_diagnostics(saved, d, id); version <- "original"
  if (!diag$converged || !is.finite(diag$min_smoothing_hessian_eigenvalue) ||
      diag$min_smoothing_hessian_eigenvalue <= 0) {
    message("Checking strict numerical restart for ", id)
    spath <- file.path(st$private, paste0(id, "_strict.rds"))
    strict <- if (file.exists(spath) && !"--force" %in% args) readRDS(spath) else NULL
    if (is.null(strict) || !identical(strict$signature, sig)) {
      strict <- run(d, knots, coef(saved$fit), TRUE)
      strict$signature <- sig; strict$input_signature <- input_signature
      strict$gamma <- primary$gamma; strict$knots <- knots
      cbh_atomic_rds(strict, spath)
    }
    sd <- cbh_sensitivity_diagnostics(strict, d, id)
    take <- sd$converged && sd$finite_covariance && sd$rank == sd$coefficients &&
      is.finite(sd$min_smoothing_hessian_eigenvalue) && sd$min_smoothing_hessian_eigenvalue > 0 &&
      strict$fit$gcv.ubre <= saved$fit$gcv.ubre
    restarts[[id]] <- data.frame(fit_id = id,
      original_min_hessian = diag$min_smoothing_hessian_eigenvalue,
      strict_min_hessian = sd$min_smoothing_hessian_eigenvalue,
      original_fREML = unname(saved$fit$gcv.ubre), strict_fREML = unname(strict$fit$gcv.ubre),
      strict_selected = take)
    write_csv(do.call(rbind, restarts), "restarts.csv")
    if (take) { saved <- strict; diag <- sd; version <- "strict_restart"; path <- spath }
    rm(strict)
  }
  f <- saved$fit
  stopifnot(diag$converged, diag$finite_coefficients, diag$finite_covariance,
    diag$rank == diag$coefficients, diag$min_smoothing_hessian_eigenvalue > 0,
    all(f$prior.weights == 1), f$family$link == "cloglog",
    inherits(f$smooth[[1]], "cr.smooth"), inherits(f$smooth[[2]], "cr.smooth"),
    identical(f$smooth[[1]]$xp, knots$pfpr_pct), identical(f$smooth[[2]]$xp, knots$calendar_year),
    !any(vapply(f$smooth, function(s) identical(s$term, "country"), logical(1))),
    sum(grepl("^country", names(coef(f)))) == nlevels(d$country) - 1L)
  for (v in names(f$model)) {
    want <- if (v == "offset(log(band_years))") log(d$band_years) else d[[v]]
    stopifnot(isTRUE(all.equal(f$model[[v]], want, check.attributes = FALSE)))
  }
  diag$age_band <- age; diag$gamma <- primary$gamma; diag$input_verified <- TRUE
  diags[[id]] <- diag
  cc <- cbh_sensitivity_curves(f, d, id); cc$age_band <- age; curves[[id]] <- cc
  sm <- as.data.frame(summary(f)$s.table); sm$term <- rownames(sm); sm$age_band <- age; smooths[[id]] <- sm
  # Compact PfPR basis, as in R_cbh/primary/01_fit.R, for the burden in 02_report.R.
  s <- f$smooth[[1]]; ix <- s$first.para:s$last.para
  components[[id]] <- list(fit_id = id, age_band = age, smooth = s, coef = coef(f)[ix], covariance = f$Vp[ix, ix],
    model_md5 = cbh_file_hash(path), support = quantile(d$pfpr_pct, c(0, .025, .975, 1), names = FALSE))
  manifests[[id]] <- data.frame(fit_id = id, age_band = age, model_file = path,
    md5 = cbh_file_hash(path), selected_version = version, prepared_data_md5 = provenance$md5[1])
  write_csv(do.call(rbind, diags), "fit_diagnostics.csv")
  write_csv(do.call(rbind, curves), "pfpr_curves.csv")
  write_csv(do.call(rbind, smooths), "smooth_summaries.csv")
  write_csv(do.call(rbind, manifests), "fit_manifest.csv")
  cbh_atomic_rds(components, file.path(st$private, "pfpr_components.rds"))
  message("Completed ", id, "; ", round(diag$elapsed_seconds, 1), " fit seconds; Hessian minimum ",
          signif(diag$min_smoothing_hessian_eigenvalue, 3))
  rm(saved, f, d); gc(FALSE)
}
stopifnot(length(diags) == 7L)
writeLines(trimws(capture.output(sessionInfo()), which = "right"), file.path(st$out, "session_info.txt"))
message("All seven country fixed-effects gamma=2 fits completed")
