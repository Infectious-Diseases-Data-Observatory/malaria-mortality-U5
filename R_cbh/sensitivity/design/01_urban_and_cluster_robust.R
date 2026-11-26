#!/usr/bin/env Rscript
# Test on one age band (band number 1-7 as the argument; default settings$test_band) of two changes a reviewer asked for in the hazards model:
#   urban:  the primary formula plus the child's urban/rural indicator (the surveys' stratification variable), fitted
#           with the primary's settings (R_cbh/primary/01_fit.R: bam, cloglog, fREML, discrete, gamma = 2, same knots);
#   cluster dependence: cluster-robust (sandwich) standard errors of the PfPR contrasts for the paper's fit and the
#           urban fit, clusters = survey clusters (mothers are nested in them). Bread = the fit's Bayesian covariance
#           Vp; meat = sum over clusters of the outer product of the cluster's summed scores.
# A cluster random effect in bam is not feasible (about 70,000 levels: a dense 70,000 x 70,000 cross-product); it is
# fitted with INLA in 02_cluster_effect_inla.R.
# Writes <out>/band_<k>_contrasts.csv, band_<k>_urban_terms.csv and <private>/urban_fit_band_<k>.rds.
suppressPackageStartupMessages({library(data.table); library(mgcv)})
source("R_cbh/primary/settings.R"); source("R_cbh/primary/specification.R"); source("R_cbh/sensitivity/design/settings.R")
P <- cbh_primary_settings(); S <- cbh_design_settings(); source("R_cbh/00_config.R"); bands <- as.character(cbh_config()$age_bands$age_band)
arg <- commandArgs(trailingOnly = TRUE); k <- if (length(arg)) as.integer(arg[1]) else match(S$test_band, bands)   # band number, 1-7
stopifnot(length(k) == 1, k %in% seq_along(bands)); band <- bands[k]
prepared <- readRDS(P$data); input <- prepared$data
d <- droplevels(input[input$age_band == band, , drop = FALSE]); rm(prepared, input); gc(FALSE)
design <- readRDS(S$design)
i <- match(d$child_id, design$child_id); stopifnot(!anyNA(i))
d$urban <- design$urban[i]; d$psu <- design$psu[i]; stopifnot(!anyNA(d$urban), !anyNA(d$psu), d$urban %in% 0:1)
manifest <- read.csv(file.path(P$out, "fit_manifest.csv"))
saved <- readRDS(manifest$model_file[manifest$age_band == band]); base <- saved$fit; knots <- saved$knots
stopifnot(nrow(base$model) == nrow(d), isTRUE(all.equal(base$model$pfpr_pct, d$pfpr_pct)), all(base$model$death == d$death))

form <- update(cbh_primary_regional_formula(P), . ~ . + urban)
path <- file.path(S$private, paste0("urban_fit_band_", k, ".rds"))
if (file.exists(path)) urban <- readRDS(path) else {
  set.seed(P$seed)
  urban <- bam(form, data = d, knots = knots, family = binomial(link = "cloglog"), method = "fREML", discrete = TRUE, gamma = P$gamma,
    select = FALSE, nthreads = 2, gc.level = 1, na.action = na.fail, control = gam.control(maxit = 100))
  saveRDS(urban, path)
}
stopifnot(urban$converged)

# Cluster-robust covariance: scores x_i (y_i - mu_i) (dmu/deta) / V(mu), summed within clusters, in chunks of whole clusters.
robust <- function(f) {
  o <- order(d$psu); cl <- d$psu[o]
  score_weight <- ((f$y - f$fitted.values) * f$family$mu.eta(f$linear.predictors) / f$family$variance(f$fitted.values))[o]
  starts <- which(!duplicated(cl)); cut <- starts[seq(1, length(starts), by = 1500)]; ends <- c(cut[-1] - 1L, length(o))
  meat <- matrix(0, length(coef(f)), length(coef(f)))
  for (k in seq_along(cut)) {
    r <- cut[k]:ends[k]
    X <- predict(f, d[o[r], , drop = FALSE], type = "lpmatrix", discrete = FALSE)
    meat <- meat + crossprod(rowsum(X * score_weight[r], cl[r], reorder = FALSE))
  }
  G <- length(starts)
  f$Vp %*% meat %*% f$Vp * G / (G - 1)
}
contrasts <- function(f, label, Vr) {
  sm <- f$smooth[[1]]; stopifnot(identical(sm$term, "pfpr_pct")); j <- sm$first.para:sm$last.para
  rows <- lapply(list(c(20, 0), c(40, 20)), function(v) {
    L <- PredictMat(sm, data.frame(pfpr_pct = v[2])) - PredictMat(sm, data.frame(pfpr_pct = v[1]))
    se <- function(V) sqrt(drop(L %*% V[j, j] %*% t(L)))
    data.frame(model = label, age_band = band, contrast = paste0("PfPR ", v[1], " to ", v[2]), log_hazard_ratio = drop(L %*% coef(f)[j]),
      se_model = se(f$Vp), se_frequentist = se(f$Ve), se_cluster_robust = se(Vr))
  })
  do.call(rbind, rows)
}
res <- rbind(contrasts(base, "primary (v19)", robust(base)), contrasts(urban, "primary + urban indicator", robust(urban)))
res$robust_over_model <- res$se_cluster_robust / res$se_model
res$robust_over_frequentist <- res$se_cluster_robust / res$se_frequentist
res$hazard_ratio <- exp(res$log_hazard_ratio)
res$lower_95_model <- exp(res$log_hazard_ratio - 1.96 * res$se_model); res$upper_95_model <- exp(res$log_hazard_ratio + 1.96 * res$se_model)
fwrite(res, file.path(S$out, paste0("band_", k, "_contrasts.csv")))
term <- function(f, label, v) if (v %in% names(coef(f))) data.frame(model = label, term = v, estimate = coef(f)[[v]], se = sqrt(f$Vp[match(v, names(coef(f))), match(v, names(coef(f)))])) else NULL
terms <- rbind(term(base, "primary (v19)", "z_urban_pct"), term(urban, "primary + urban indicator", "z_urban_pct"), term(urban, "primary + urban indicator", "urban"))
terms$hazard_ratio <- exp(terms$estimate)
fwrite(terms, file.path(S$out, paste0("band_", k, "_urban_terms.csv")))
edf <- function(f) sum(f$edf[f$smooth[[1]]$first.para:f$smooth[[1]]$last.para])
cat("records", nrow(d), "deaths", sum(d$death), "clusters", uniqueN(d$psu), "urban share", mean(d$urban), "\n")
cat("PfPR edf: primary", edf(base), " urban", edf(urban), "\n"); print(res, digits = 4); print(terms, digits = 4)
