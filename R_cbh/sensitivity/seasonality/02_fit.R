#!/usr/bin/env Rscript
# Sahel seasonality sensitivity, step 2: for each band (<1, 1-5, 6-11 months), the Sahel model of the subgroup suite
# refitted on the children whose birth month was reported (01_prepare.R), (A) as it is and (B) with a cyclic cubic
# spline of the calendar month at risk (1-12). The 1-5 and 6-11 month fits use child-month records with the month of
# age as a factor in both A and B (A on these records is the band model with hazards free to vary within the band).
# Same specification as the subgroup refits otherwise (formula, gamma = 2, the Sahel knots of PfPR and calendar time).
# Outputs: <out>/fit_diagnostics.csv, pfpr_curves.csv (hazard ratios relative to zero, with 95% intervals),
# month_curves.csv (B: hazard ratio by calendar month relative to the average month), month_tests.csv, sample.csv,
# fit_input_provenance.csv; private: the fits.
suppressPackageStartupMessages({ library(data.table); library(mgcv) })
source("R_cbh/load_pipeline.R"); source("R_cbh/primary/settings.R"); source("R_cbh/primary/specification.R")
source("R_cbh/sensitivity/model.R"); source("R_cbh/sensitivity/subgroups/settings.R"); source("R_cbh/sensitivity/sahel_season/settings.R")
args <- commandArgs(trailingOnly = TRUE); stopifnot(all(args %in% "--force"))
S <- cbh_sahel_season_settings(); P <- cbh_primary_settings(S$primary_version); st <- cbh_subgroup_settings()
data_path <- file.path(S$private, "model_data.rds"); knots_path <- file.path(st$out, "knots.csv")
code <- c("R_cbh/sensitivity/sahel_season/02_fit.R", "R_cbh/sensitivity/sahel_season/settings.R", "R_cbh/sensitivity/model.R",
          "R_cbh/primary/specification.R", "R_cbh/primary/settings.R")
files <- c(data_path, knots_path, code)
provenance <- data.frame(file = files, md5 = vapply(files, cbh_file_hash, ""))
cbh_atomic_csv(provenance, file.path(S$out, "fit_input_provenance.csv"))
md <- readRDS(data_path)
kn <- fread(knots_path)[subgroup == "sahel"]
form0 <- cbh_primary_regional_formula(P)

run <- function(form, d, knots, initial = NULL, strict = FALSE) {
  warnings <- character(); set.seed(P$seed)
  control <- if (strict) gam.control(epsilon = 1e-9, mgcv.tol = 1e-9, efs.tol = .001, maxit = 200) else gam.control(maxit = 100)
  timing <- system.time(f <- withCallingHandlers(bam(form, data = d, knots = knots, family = binomial(link = "cloglog"),
    method = "fREML", discrete = TRUE, gamma = P$gamma, select = FALSE, nthreads = P$nthreads, gc.level = 1, na.action = na.fail,
    coef = initial, control = control),
    warning = function(w) { warnings <<- unique(c(warnings, conditionMessage(w))); invokeRestart("muffleWarning") }))
  list(fit = f, elapsed_seconds = unname(timing["elapsed"]), warnings = warnings)
}
ok <- function(g) isTRUE(g$converged) && g$finite_coefficients && g$finite_covariance && g$rank == g$coefficients &&
  is.finite(g$min_smoothing_hessian_eigenvalue) && g$min_smoothing_hessian_eigenvalue > 0
smooth_of <- function(f, label) f$smooth[[match(label, vapply(f$smooth, `[[`, "", "label"))]]
# Hazard ratio relative to zero prevalence, from the PfPR smooth (pointwise 95% conditional intervals).
pf_curve <- function(f, d) {
  s <- smooth_of(f, "s(pfpr_pct)"); ix <- s$first.para:s$last.para
  q <- quantile(d$pfpr_pct, c(.025, .975), names = FALSE); grid <- sort(unique(c(seq(0, 80, by = .5), q)))
  grid <- grid[grid <= q[2]]
  L <- PredictMat(s, data.frame(pfpr_pct = grid)) - PredictMat(s, data.frame(pfpr_pct = rep(0, length(grid))))
  est <- drop(L %*% coef(f)[ix]); se <- sqrt(pmax(rowSums((L %*% f$Vp[ix, ix]) * L), 0))
  data.table(pfpr_pct = grid, hazard_ratio = exp(est), lower_95 = exp(est - 1.96 * se), upper_95 = exp(est + 1.96 * se),
             pfpr_p025 = q[1], pfpr_p975 = q[2])
}
# Hazard ratio by calendar month relative to the average month (the cyclic smooth sums to zero over the data).
month_curve <- function(f) {
  s <- smooth_of(f, "s(month)"); ix <- s$first.para:s$last.para
  grid <- seq(S$month_knots[1], S$month_knots[2], by = .05)
  X <- PredictMat(s, data.frame(month = grid)); est <- drop(X %*% coef(f)[ix]); se <- sqrt(pmax(rowSums((X %*% f$Vp[ix, ix]) * X), 0))
  data.table(month = grid, hazard_ratio = exp(est), lower_95 = exp(est - 1.96 * se), upper_95 = exp(est + 1.96 * se))
}

diags <- pf <- mo <- tests <- samples <- list()
for (b in S$bands) {
  d <- as.data.frame(md[[b]][(month_reported)])
  for (v in c("survey", "country", "region")) d[[v]] <- droplevels(factor(d[[v]]))
  infant <- b != "<1"
  if (infant) d$age_month <- factor(d$age_month)
  knots <- list(pfpr_pct = kn[age_band == b & variable == "pfpr_pct", value], calendar_year = kn[age_band == b & variable == "calendar_year", value],
                month = S$month_knots)
  stopifnot(length(knots$pfpr_pct) == 5L, length(knots$calendar_year) == 6L)
  fA <- if (infant) update(form0, . ~ . + age_month) else form0
  fB <- update(fA, as.formula(sprintf(". ~ . + s(month, bs = 'cc', k = %d)", S$month_k)))
  samples[[b]] <- data.table(age_band = b, rows = nrow(d), children = uniqueN(d$child_id), deaths = sum(d$death),
    surveys = nlevels(d$survey), survey_units = nlevels(d$region),
    dropped_children = uniqueN(md[[b]][!(month_reported), child_id]), dropped_deaths = md[[b]][!(month_reported), sum(death)])
  for (m in c("A", "B")) {
    id <- sprintf("%s_%s", c(`<1` = "neonatal", `1-5` = "m1_5", `6-11` = "m6_11")[[b]], m)
    path <- file.path(S$private, paste0(id, ".rds"))
    sig <- cbh_hash(list(provenance, S, if (m == "A") deparse(fA) else deparse(fB), knots, as.character(packageVersion("mgcv"))))
    saved <- if (file.exists(path) && !"--force" %in% args) readRDS(path) else NULL
    if (is.null(saved) || !identical(saved$signature, sig)) {
      message("Fitting ", id, ": ", nrow(d), " rows, ", sum(d$death), " deaths")
      saved <- run(if (m == "A") fA else fB, d, knots); saved$signature <- sig
      g <- cbh_sensitivity_diagnostics(saved, d, id)
      if (!ok(g)) { message("Strict restart for ", id); r <- run(if (m == "A") fA else fB, d, knots, coef(saved$fit), TRUE)
        r$signature <- sig; gr <- cbh_sensitivity_diagnostics(r, d, id); if (ok(gr)) saved <- r }
      cbh_atomic_rds(saved, path)
    }
    f <- saved$fit; g <- cbh_sensitivity_diagnostics(saved, d, id); g$age_band <- b; g$model <- m
    stopifnot(ok(g)); diags[[id]] <- g
    pf[[id]] <- pf_curve(f, d)[, `:=`(age_band = b, model = m)]
    if (m == "B") {
      mo[[id]] <- month_curve(f)[, age_band := b]
      sm <- summary(f)$s.table; r <- match("s(month)", rownames(sm))
      tests[[id]] <- data.table(age_band = b, edf = sm[r, "edf"], chi_sq = sm[r, "Chi.sq"], p_value = sm[r, "p-value"])
    }
    rm(saved, f); gc(FALSE)
  }
}
cbh_atomic_csv(as.data.frame(rbindlist(diags, fill = TRUE)), file.path(S$out, "fit_diagnostics.csv"))
cbh_atomic_csv(as.data.frame(rbindlist(pf)), file.path(S$out, "pfpr_curves.csv"))
cbh_atomic_csv(as.data.frame(rbindlist(mo)), file.path(S$out, "month_curves.csv"))
cbh_atomic_csv(as.data.frame(rbindlist(tests)), file.path(S$out, "month_tests.csv"))
cbh_atomic_csv(as.data.frame(rbindlist(samples)), file.path(S$out, "sample.csv"))
message("Sahel seasonality fits complete: ", S$out)
