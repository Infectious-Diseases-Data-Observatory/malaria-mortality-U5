#!/usr/bin/env Rscript
# Test on one age band (band number 1-7 as the first argument; default settings$test_band) of space-time random effects
# in the hazards model, fitted with INLA. Models (second argument onwards; default M0 M1):
#   M0: death ~ PfPR basis + calendar-year basis + 17 covariates + urban + iid(survey) + iid(country) + iid(survey-unit)
#   M1: M0 with the calendar-year basis replaced by a first-order random walk over integer calendar years, plus a BYM2
#       spatial effect over the geographic units (graph of 04_unit_graph.R; the same place in two surveys is one node)
#   M2: M1 + an unstructured unit-by-year interaction (Knorr-Held type I)
#   M1_rw2, M1_rw2_sqrt, M1_rw2_log: M1 with the PfPR spline replaced by a free-form, penalised curve: a second-order
#       random walk over a regular grid of PfPR (1-point steps), of sqrt(PfPR) or of log(1 + PfPR) (about 100 nodes
#       each; a record takes its nearest node). The walk penalises curvature on the scale of its grid, and its SD (how
#       far the curve may depart from a straight line on that scale) is estimated.
#   M1_rw2_sqrt_ref1: M1_rw2_sqrt with every PfPR below 1% at one level, the reference: the walk runs over
#       sqrt(max(PfPR, 1)), so the curve is not extrapolated from 1% down to 0, and hazard ratios "against 0" are
#       against PfPR below 1%.
#   M3...: the M1 model of the same name (M3 for M1, M3_rw2_sqrt_ref1 for M1_rw2_sqrt_ref1, and so on) plus
#       country-specific year trends: each country's departure from the common year walk is its own first-order walk
#       over the same years (INLA replicate), summing to zero over years, and the walks share one SD, so a country
#       with few years of data is pulled towards the common trend. Its year effects (the common walk and each
#       country's departure) are written to band_<k>_spacetime_year_effects.csv.
#   M3c..., M3y..., M3cy...: the M3 model of the same name plus an independent effect for each survey cluster (c),
#       for each geographic unit in each calendar year (y: Knorr-Held type I interaction, the level at which PfPR
#       varies), or both (cy).
# Binomial, cloglog link, offset log(band_years); the primary's cubic regression spline bases (same knots), entered
# unpenalised; records with the same cluster and covariates collapsed to binomial counts. No cluster effect (it does
# not change the PfPR contrasts: 02_cluster_effect_inla.R) except in the M3c and M3cy models. PC priors: P(sd > 1) = 0.01 for every SD, P(phi < 0.5) =
# 0.5 for the BYM2 mixing parameter. By default int.strategy = "eb" (hyperparameters at their mode: a feasibility test).
# With --integrate anywhere in the arguments, the fit integrates over the hyperparameters (INLA's default strategy, a
# central composite design) and its rows are named <model>_int. --threads=<n> sets INLA's threads (default 6). With --draws, 500 posterior draws of a walk model's
# node values are also written to <private>/curve_draws_band_<k>_<model>.rds (R_cbh/sensitivity/design/10_burden_draws.R).
# Writes <out>/band_<k>_spacetime_contrasts.csv, band_<k>_spacetime_hyperparameters.csv and
# band_<k>_spacetime_pfpr_curves.csv (log hazard ratio against PfPR 0 on a 1-point grid) (rows of models already
# there and not refitted are kept).
suppressPackageStartupMessages({library(data.table); library(mgcv); library(INLA); library(Matrix)})
source("R_cbh/primary/settings.R"); source("R_cbh/primary/specification.R"); source("R_cbh/sensitivity/design/settings.R")
P <- cbh_primary_settings(); S <- cbh_design_settings(); source("R_cbh/00_config.R"); bands <- as.character(cbh_config()$age_bands$age_band)
arg <- commandArgs(trailingOnly = TRUE); integrate <- "--integrate" %in% arg; draws <- "--draws" %in% arg
threads <- sub("^--threads=", "", grep("^--threads=", arg, value = TRUE)); threads <- if (length(threads)) as.integer(threads[1]) else 6L
stopifnot(!is.na(threads), threads >= 1L); arg <- setdiff(arg[!grepl("^--threads=", arg)], c("--integrate", "--draws"))
k <- if (length(arg)) as.integer(arg[1]) else match(S$test_band, bands)
models <- if (length(arg) > 1) arg[-1] else c("M0", "M1"); tag <- if (integrate) "_int" else ""
known <- c("M0", "M1", "M2", "M1_rw2", "M1_rw2_sqrt", "M1_rw2_log", "M1_rw2_sqrt_ref1"); m3_kinds <- c("M3", "M3c", "M3y", "M3cy"); known <- c(known, unlist(lapply(m3_kinds, function(p) sub("^M1", p, grep("^M1", known, value = TRUE)))))
stopifnot(length(k) == 1, k %in% seq_along(bands), models %in% known); band <- bands[k]
input <- readRDS(P$data)$data
d <- as.data.table(droplevels(input[input$age_band == band, , drop = FALSE])); rm(input); gc(FALSE)
design <- readRDS(S$design); i <- match(d$child_id, design$child_id); stopifnot(!anyNA(i))
d[, `:=`(urban = design$urban[i], psu = design$psu[i], unit = as.character(unit))]
manifest <- read.csv(file.path(P$out, "fit_manifest.csv"))
base <- readRDS(manifest$model_file[manifest$age_band == band])$fit
covs <- c(paste0("z_", cbh_primary_regional_spec(P)$covariates), "urban")
keys <- c("psu", "survey", "country", "region", "unit", "pfpr_pct", "calendar_year", "band_years", covs)
a <- d[, .(y = sum(death), n = .N), by = keys]
stopifnot(sum(a$n) == nrow(d), sum(a$y) == sum(d$death))
basis <- function(j, prefix) { B <- PredictMat(base$smooth[[j]], as.data.frame(a)); colnames(B) <- paste0(prefix, seq_len(ncol(B))); B }
Bp <- basis(1, "pf"); By <- basis(2, "yr"); a <- cbind(a, Bp, By); pf <- colnames(Bp)
# Linear combinations: the two contrasts, and the PfPR curve (log hazard ratio against PfPR 0 on a 1-point grid over the
# band's observed range). w(x) gives the weights of the curve's value at PfPR x on a model's PfPR coefficients.
grid <- 1:floor(max(a$pfpr_pct)); n_contrasts <- 2L
build_lc <- function(w, mk) {
  v <- lapply(grid, function(x) w(x) - w(0)); use <- vapply(v, function(z) any(abs(z) > 1e-12), NA)   # FALSE: at the reference level
  lc <- do.call(c, c(list(mk(w(0) - w(20)), mk(w(20) - w(40))), lapply(v[use], mk)))
  names(lc) <- c("PfPR 20 to 0", "PfPR 40 to 20", sprintf("curve%03d", grid[use])); lc
}
spline_lc <- build_lc(function(x) drop(PredictMat(base$smooth[[1]], data.frame(pfpr_pct = x))), function(v) do.call(inla.make.lincomb, as.list(setNames(v, pf))))
# Random-walk grids: nodes 0, 1, ... on the transformed scale; the curve at PfPR x is interpolated between its two nodes.
scales <- list(M1_rw2 = function(x) x, M1_rw2_sqrt = function(x) 10 * sqrt(x), M1_rw2_log = function(x) 20 * log1p(x),
  M1_rw2_sqrt_ref1 = function(x) 10 * (sqrt(pmax(x, 1)) - 1))
walk_lc <- walk_term <- list()
for (m in names(scales)) {   # w and mk are used within the iteration that defines them
  g <- scales[[m]]; name <- paste0("pf_", m); nodes <- ceiling(g(max(a$pfpr_pct))) + 2L
  a[, (name) := as.integer(round(g(pfpr_pct)))]
  w <- function(x) { z <- g(x); lo <- floor(z); v <- numeric(nodes); v[lo + 1] <- 1 - (z - lo); if (z > lo) v[lo + 2] <- z - lo; v }
  mk <- function(v) { v[abs(v) < 1e-12] <- NA; do.call(inla.make.lincomb, setNames(list(v), name)) }
  walk_lc[[m]] <- build_lc(w, mk)
  walk_term[[m]] <- sprintf("f(%s, model = 'rw2', values = 0:%d, scale.model = TRUE, constr = TRUE, hyper = list(prec = list(prior = 'pc.prec', param = c(1, 0.01))))", name, nodes - 1L)
}
graph <- readRDS(file.path(S$private, "unit_graph.rds")); stopifnot(all(a$unit %in% graph$units))
W <- graph$adjacency
years <- floor(min(a$calendar_year)):floor(max(a$calendar_year))
a[, `:=`(unit_id = match(unit, graph$units), year_id = match(floor(calendar_year), years))]
a[, unit_year_id := as.integer(factor(paste(unit_id, year_id)))]
country_levels <- levels(factor(a$country))
for (v in c("survey", "country", "region")) a[, (v) := as.integer(factor(get(v)))]
a[, `:=`(year_c = year_id, country_rep = country)]   # copies: INLA needs a separate index for each f() term
a[, psu_id := as.integer(factor(paste(survey, psu)))]
sd_prior <- "list(prec = list(prior = 'pc.prec', param = c(1, 0.01)))"
iid <- function(v) sprintf("f(%s, model = 'iid', hyper = %s)", v, sd_prior)
common <- c(covs, iid("survey"), iid("country"), iid("region"))
spatial <- "f(unit_id, model = 'bym2', graph = W, scale.model = TRUE, constr = TRUE, hyper = list(prec = list(prior = 'pc.prec', param = c(1, 0.01)), phi = list(prior = 'pc', param = c(0.5, 0.5))))"
walk <- sprintf("f(year_id, model = 'rw1', values = seq_along(years), scale.model = TRUE, constr = TRUE, hyper = %s)", sd_prior)
country_walk <- sprintf("f(year_c, model = 'rw1', values = seq_along(years), replicate = country_rep, scale.model = TRUE, constr = TRUE, hyper = %s)", sd_prior)
terms <- c(list(M0 = c(pf, common, colnames(By)), M1 = c(pf, common, walk, spatial), M2 = c(pf, common, walk, spatial, iid("unit_year_id"))),
  lapply(walk_term, function(term) c(term, common, walk, spatial)))
m1 <- grep("^M1", names(terms), value = TRUE)
extra <- list(M3 = country_walk, M3c = c(country_walk, iid("psu_id")), M3y = c(country_walk, iid("unit_year_id")), M3cy = c(country_walk, iid("psu_id"), iid("unit_year_id")))
for (p in m3_kinds) terms[sub("^M1", p, m1)] <- lapply(terms[m1], c, extra[[p]])
stopifnot(setequal(names(terms), known))
country_years <- a[, .(records = sum(n), deaths = sum(y)), by = .(country, year_id)]
fit <- function(label) {
  trends <- grepl("^M3", label); curve_of <- sub("^M3[cy]*", "M1", label)   # an M3 model has the PfPR curve of its M1 model
  lc <- if (curve_of %in% names(walk_lc)) walk_lc[[curve_of]] else spline_lc
  t <- system.time(m <- inla(as.formula(paste("y ~", paste(terms[[label]], collapse = " + "))), family = "binomial", Ntrials = a$n, data = as.data.frame(a),
    offset = log(a$band_years), control.family = list(control.link = list(model = "cloglog")), lincomb = lc,
    control.inla = list(int.strategy = if (integrate) "auto" else "eb"), control.compute = list(waic = TRUE, config = draws), num.threads = paste0(threads, ":1"), verbose = FALSE))
  walk_name <- if (curve_of %in% names(walk_lc)) paste0("pf_", curve_of) else NULL
  label <- paste0(label, tag); stopifnot(isTRUE(m$ok))
  if (draws && !is.null(walk_name)) {   # posterior draws of the walk's node values (draws x nodes), for the burden's uncertainty
    nodes <- nrow(m$summary.random[[walk_name]])
    smp <- inla.posterior.sample(500L, m, selection = setNames(list(seq_len(nodes)), walk_name), seed = 20261125L, num.threads = "1:1", parallel.configs = FALSE)
    cbh_draws <- t(vapply(smp, function(z) drop(z$latent), numeric(nodes)))
    saveRDS(list(model = label, age_band = band, nodes = m$summary.random[[walk_name]]$ID, node_mean = m$summary.random[[walk_name]]$mean,
      node_sd = m$summary.random[[walk_name]]$sd, draws = cbh_draws), file.path(S$private, sprintf("curve_draws_band_%d_%s.rds", k, label)))
  }
  ld <- m$summary.lincomb.derived; stopifnot(identical(rownames(ld), names(lc)))
  cv <- ld[-seq_len(n_contrasts), ]; ld <- ld[seq_len(n_contrasts), ]
  at <- match(as.integer(sub("curve", "", rownames(cv))), c(0, grid)); stopifnot(!anyNA(at))
  full <- function(col) { z <- numeric(length(grid) + 1); z[at] <- cv[[col]]; z }   # 0 at the reference level
  h <- m$summary.hyperpar; prec <- grepl("^Precision", rownames(h))
  year_effects <- if (!trends) NULL else {   # log hazard: the common walk, then each country's departure from it
    g <- m$summary.random$year_id; dc <- m$summary.random$year_c; nc <- length(country_levels)
    stopifnot(identical(as.integer(g$ID), seq_along(years)), identical(as.integer(dc$ID), rep(seq_along(years), nc)))
    cell <- country_years[data.table(country = rep(seq_len(nc), each = length(years)), year_id = as.integer(dc$ID)), on = c("country", "year_id")]
    one <- function(z, country, records, deaths) data.table(model = label, age_band = band, country = country, year = years[z$ID], log_hazard = z$mean, sd = z$sd,
      lower_95 = z$`0.025quant`, upper_95 = z$`0.975quant`, records = records, deaths = deaths)
    rbind(one(g, "All", NA_integer_, NA_integer_), one(dc, rep(country_levels, each = length(years)), cell$records, cell$deaths))
  }
  q <- function(col) ifelse(prec, 1 / sqrt(h[[col]]), h[[col]])
  list(contrasts = data.table(model = label, age_band = band, contrast = rownames(ld), log_hazard_ratio = ld$mean,
      sd = ld$sd, hazard_ratio = exp(ld$mean), lower_95 = exp(ld$`0.025quant`),
      upper_95 = exp(ld$`0.975quant`), waic = m$waic$waic, waic_effective_parameters = m$waic$p.eff, minutes = unname(t["elapsed"]) / 60,
      mode_status = m$mode$mode.status, hyperparameter_configurations = if (is.null(m$joint.hyper)) NA_integer_ else nrow(m$joint.hyper)),
    hyper = data.table(model = label, age_band = band, term = sub("Precision for ", "SD of ", rownames(h)), mode = q("mode"),
      lower = ifelse(prec, q("0.975quant"), q("0.025quant")), upper = ifelse(prec, q("0.025quant"), q("0.975quant"))),
    curve = data.table(model = label, age_band = band, pfpr_pct = c(0, grid), log_hazard_ratio = full("mean"), sd = full("sd"),
      lower_95 = full("0.025quant"), upper_95 = full("0.975quant")), year_effects = year_effects)
}
keep <- function(file) if (file.exists(file)) fread(file)[!model %in% paste0(models, tag)] else NULL
files <- file.path(S$out, paste0("band_", k, c("_spacetime_contrasts.csv", "_spacetime_hyperparameters.csv", "_spacetime_pfpr_curves.csv", "_spacetime_year_effects.csv")))
for (label in models) {
  r <- fit(label)
  fwrite(rbind(keep(files[1]), r$contrasts, fill = TRUE)[order(model)], files[1]); fwrite(rbind(keep(files[2]), r$hyper, fill = TRUE)[order(model)], files[2])
  fwrite(rbind(keep(files[3]), r$curve, fill = TRUE)[order(model, pfpr_pct)], files[3])
  if (!is.null(r$year_effects)) fwrite(rbind(keep(files[4]), r$year_effects, fill = TRUE), files[4])
  models <- setdiff(models, label)   # rows of this model are now on file
  message("Fitted ", label)
}
cat("collapsed rows", nrow(a), "of", nrow(d), "records; units", uniqueN(a$unit_id), "years", length(years), "unit-years", uniqueN(a$unit_year_id), "clusters", uniqueN(a$psu_id), "\n")
print(fread(files[1]), digits = 4); print(fread(files[2]), digits = 3)
