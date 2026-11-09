#!/usr/bin/env Rscript
# Seasonality sensitivity, step 2: for each region and band (<1, 1-5, 6-11 months), three fits of the primary
# specification (formula, gamma = 2, knots at quantiles of the distinct PfPR and calendar-time values of the region's
# band, as in the subgroup refits): (ref) the band model on all the region's children; on the children whose birth month
# was reported (01_prepare.R), (A) without and (B) with a cyclic cubic spline of the calendar month at risk (1-12).
# The 1-5 and 6-11 month A and B fits use child-month records with the month of age as a factor.
# Outputs: <out>/fit_diagnostics.csv, pfpr_curves.csv (hazard ratios relative to zero, with 95% intervals),
# month_curves.csv (B: hazard ratio by calendar month relative to the average month), month_tests.csv, sample.csv,
# fit_input_provenance.csv; private: the fits.
suppressPackageStartupMessages({ library(data.table); library(mgcv) })
source("R_cbh/load_pipeline.R"); source("R_cbh/primary/settings.R"); source("R_cbh/primary/specification.R")
source("R_cbh/sensitivity/model.R"); source("R_cbh/sensitivity/seasonality/settings.R")
args <- commandArgs(trailingOnly = TRUE); stopifnot(all(args %in% "--force"))
S <- cbh_seasonality_settings(); P <- cbh_primary_settings(S$primary_version)
data_path <- file.path(S$private, "model_data.rds")
code <- c("R_cbh/sensitivity/seasonality/02_fit.R", "R_cbh/sensitivity/seasonality/settings.R", "R_cbh/sensitivity/model.R",
          "R_cbh/primary/specification.R", "R_cbh/primary/settings.R")
files <- c(data_path, code)
provenance <- data.frame(file = files, md5 = vapply(files, cbh_file_hash, ""))
cbh_atomic_csv(provenance, file.path(S$out, "fit_input_provenance.csv"))
md <- readRDS(data_path)
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
# Hazard ratio relative to zero prevalence, from the PfPR smooth (pointwise 95% conditional intervals), up to the
# 97.5th percentile of the fit's PfPR values.
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
as_model_frame <- function(z, infant_month = FALSE) {
  d <- as.data.frame(z)
  for (v in c("survey", "country", "region")) d[[v]] <- droplevels(factor(d[[v]]))
  if (infant_month) d$age_month <- factor(d$age_month)
  d
}

diags <- pf <- mo <- tests <- samples <- list()
for (r in names(S$regions)) for (b in S$bands) {
  all_children <- as_model_frame(md[[r]][[b]]$band)
  stopifnot(nlevels(all_children$region) > 50L)   # the survey x unit areas, not the seasonality region
  infant <- b != "<1"
  reported <- as_model_frame(md[[r]][[b]]$month[(month_reported)], infant)
  # Knots as in the subgroup refits: quantiles of the distinct values of the region's band (all children).
  knots <- list(pfpr_pct = as.numeric(quantile(unique(all_children$pfpr_pct), seq(0, 1, length.out = 5))),
                calendar_year = as.numeric(quantile(unique(all_children$calendar_year), seq(0, 1, length.out = 6))), month = S$month_knots)
  stopifnot(all(diff(knots$pfpr_pct) > 0), all(diff(knots$calendar_year) > 0))
  fA <- if (infant) update(form0, . ~ . + age_month) else form0
  fB <- update(fA, as.formula(sprintf(". ~ . + s(month, bs = 'cc', k = %d)", S$month_k)))
  allm <- md[[r]][[b]]$month
  samples[[paste(r, b)]] <- data.table(region = r, age_band = b, children_all = nrow(all_children), deaths_all = sum(all_children$death),
    surveys = nlevels(all_children$survey), countries = nlevels(all_children$country), survey_units = nlevels(all_children$region),
    rows = nrow(reported), children = uniqueN(reported$child_id), deaths = sum(reported$death),
    dropped_children = uniqueN(allm[!(month_reported), child_id]), dropped_deaths = allm[!(month_reported), sum(death)])
  for (m in c("ref", "A", "B")) {
    d <- if (m == "ref") all_children else reported
    form <- switch(m, ref = form0, A = fA, B = fB)
    id <- sprintf("%s_%s_%s", r, c(`<1` = "neonatal", `1-5` = "m1_5", `6-11` = "m6_11")[[b]], m)
    path <- file.path(S$private, paste0(id, ".rds"))
    sig <- cbh_hash(list(provenance, S[c("bands", "month_k", "month_knots")], r, deparse(form), knots, as.character(packageVersion("mgcv"))))
    saved <- if (file.exists(path) && !"--force" %in% args) readRDS(path) else NULL
    if (is.null(saved) || !identical(saved$signature, sig)) {
      message("Fitting ", id, ": ", nrow(d), " rows, ", sum(d$death), " deaths")
      saved <- run(form, d, knots); saved$signature <- sig
      g <- cbh_sensitivity_diagnostics(saved, d, id)
      if (!ok(g)) { message("Strict restart for ", id); s2 <- run(form, d, knots, coef(saved$fit), TRUE)
        s2$signature <- sig; if (ok(cbh_sensitivity_diagnostics(s2, d, id))) saved <- s2 }
      cbh_atomic_rds(saved, path)
    }
    f <- saved$fit; g <- cbh_sensitivity_diagnostics(saved, d, id); g$region <- r; g$age_band <- b; g$model <- m
    stopifnot(ok(g)); diags[[id]] <- g
    pf[[id]] <- pf_curve(f, d)[, `:=`(region = r, age_band = b, model = m)]
    if (m == "B") {
      mo[[id]] <- month_curve(f)[, `:=`(region = r, age_band = b)]
      sm <- summary(f)$s.table; i <- match("s(month)", rownames(sm))
      tests[[id]] <- data.table(region = r, age_band = b, edf = sm[i, "edf"], chi_sq = sm[i, "Chi.sq"], p_value = sm[i, "p-value"])
    }
    rm(saved, f); gc(FALSE)
  }
}
cbh_atomic_csv(as.data.frame(rbindlist(diags, fill = TRUE)), file.path(S$out, "fit_diagnostics.csv"))
cbh_atomic_csv(as.data.frame(rbindlist(pf)), file.path(S$out, "pfpr_curves.csv"))
cbh_atomic_csv(as.data.frame(rbindlist(mo)), file.path(S$out, "month_curves.csv"))
cbh_atomic_csv(as.data.frame(rbindlist(tests)), file.path(S$out, "month_tests.csv"))
cbh_atomic_csv(as.data.frame(rbindlist(samples)), file.path(S$out, "sample.csv"))
message("Seasonality fits complete: ", S$out)
