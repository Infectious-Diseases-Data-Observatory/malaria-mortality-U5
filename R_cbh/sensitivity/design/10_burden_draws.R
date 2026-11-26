#!/usr/bin/env Rscript
# Uncertainty intervals for malaria-attributable deaths under a free-form PfPR curve fitted with INLA
# (05_spacetime_inla.R with --integrate --draws; default model M1_rw2_sqrt_ref1_int). The paper's draw machinery is
# used as it is: R_cbh/burden/06_uncertainty_draws.R is evaluated up to, and not including, its scenario runs (inputs,
# the seeded draws of MAP national PfPR and of all-cause deaths, the crisis rule, its zero-noise check); nothing before
# that point writes a file. Only the attributable fraction changes: in draw d and age band g it is 1 - 1/HR from the
# d-th posterior draw of the band's curve (500 draws per band, bands independent), evaluated at the drawn national PfPR
# by linear interpolation between the walk's nodes. Point estimates are the zero-noise run (posterior-mean curve,
# published PfPR and all-cause deaths); 95% intervals are the 2.5% and 97.5% quantiles of the 500 joint draws.
# Checks: the burden loop copied here reproduces the paper's run() draw for draw when given the paper's spline, and the
# paper's published intervals; the zero-noise run reproduces the one-step estimate of 08_burden_one_step.R.
# Arguments: [model] [--mean-curve-test]. With --mean-curve-test the curve draws are replaced by the fit's mean curve
# (read from the band_<k>_spacetime_pfpr_curves.csv files), to test the code before the draws exist; nothing is written.
# Writes <out>/uncertainty_<model>/annual_intervals_2000_2024.csv (by scenario, source and age group, beside the
# paper's), contrasts.csv, checks.csv, comparators_2000_2024.csv (malaria deaths under five in the cause-of-death
# estimates the excess is measured against) and <private>/uncertainty_draws_<model>.rds.
suppressPackageStartupMessages({library(data.table); library(mgcv)})
design_args <- commandArgs(trailingOnly = TRUE); mean_test <- "--mean-curve-test" %in% design_args
design_model <- setdiff(design_args, "--mean-curve-test"); design_model <- if (length(design_model)) design_model[1] else "M1_rw2_sqrt_ref1_int"

## ---- the paper's machinery --------------------------------------------------------------------------------------
paper_script <- "R_cbh/burden/06_uncertainty_draws.R"
exprs <- parse(paper_script, keep.source = FALSE)
first_run <- which(vapply(exprs, function(e) is.call(e) && identical(e[[1]], as.name("<-")) && identical(e[[2]], as.name("scen")), NA))
stopifnot(length(first_run) == 1L)
writers <- c("fwrite", "saveRDS", "cbh_atomic_rds", "cbh_atomic_csv", "writeLines", "write.csv", "ggsave", "file.remove", "unlink")
stopifnot(!any(writers %in% unlist(lapply(exprs[seq_len(first_run - 1L)], all.names))))
for (e in exprs[seq_len(first_run - 1L)]) eval(e, globalenv())
source("R_cbh/sensitivity/design/settings.R"); S <- cbh_design_settings()
dout <- file.path(S$out, paste0("uncertainty_", design_model))

## ---- curve draws ------------------------------------------------------------------------------------------------
# An M3, M3c, M3y or M3cy model (country-specific year trends, with cluster and unit-by-year effects) has the PfPR curve, and so the node grid, of the M1 model of the same name.
base_model <- sub("^M3[cy]*", "M1", sub("_int$", "", design_model)); scale_fun <- cbh_design_walk_scales()[[base_model]]; stopifnot(is.function(scale_fun))
curves <- lapply(seq_along(ages), function(k) {
  if (mean_test) {
    cv <- fread(file.path(S$out, paste0("band_", k, "_spacetime_pfpr_curves.csv")))[model == design_model][order(pfpr_pct)]; stopifnot(nrow(cv) > 0)
    x <- seq(0, 100, by = 0.01); z <- scale_fun(x); nodes <- 0:(ceiling(max(scale_fun(max(cv$pfpr_pct)))) + 1L)
    node_x <- approx(z, x, nodes, ties = "ordered", rule = 2)$y   # the PfPR of each node (the first PfPR that reaches it)
    m <- approx(cv$pfpr_pct, cv$log_hazard_ratio, node_x, rule = 2)$y; m <- m - m[1]
    list(node_mean = m, draws = matrix(m, D, length(m), byrow = TRUE))
  } else {
    z <- readRDS(file.path(S$private, sprintf("curve_draws_band_%d_%s.rds", k, design_model)))
    stopifnot(identical(z$age_band, ages[k]), nrow(z$draws) >= D, identical(as.numeric(z$nodes), as.numeric(seq_along(z$node_mean) - 1)))
    list(node_mean = z$node_mean, draws = z$draws[seq_len(D), , drop = FALSE])
  }
})
af_walk <- function(P, nd, on) {
  AF <- array(NA_real_, c(nd, nC, nY, length(ages))); z <- scale_fun(as.vector(P)); lo <- floor(z); w <- z - lo; d <- rep(seq_len(nd), nC * nY)
  for (g in seq_along(ages)) {
    Fg <- if (on) curves[[g]]$draws[seq_len(nd), , drop = FALSE] else matrix(curves[[g]]$node_mean, nd, length(curves[[g]]$node_mean), byrow = TRUE)
    stopifnot(max(lo) + 1L <= ncol(Fg))
    f <- (1 - w) * Fg[cbind(d, lo + 1L)] + w * Fg[cbind(d, pmin(lo + 2L, ncol(Fg)))] - Fg[d, 1L]
    AF[, , , g] <- -expm1(-f)
  }
  AF
}
af_paper <- function(P, nd, on) {   # the paper's spline, as in its run()
  AF <- array(NA_real_, c(nd, nC, nY, length(ages)))
  for (g in seq_along(ages)) {
    Z <- if (on) Zb[[g]][seq_len(nd), , drop = FALSE] else matrix(0, nd, 4L)
    Bg <- matrix(comp[[g]]$coef, nd, 4L, byrow = TRUE) + Z %*% chol(Vc[[g]]); sm <- comp[[g]]$smooth
    X <- PredictMat(sm, data.frame(pfpr_pct = as.vector(P))); x0 <- drop(PredictMat(sm, data.frame(pfpr_pct = 0)) %*% t(Bg))
    AF[, , , g] <- -expm1(rep(x0, nC * nY) - rowSums(X * Bg[rep(seq_len(nd), nC * nY), , drop = FALSE]))
  }
  AF
}
# The paper's run() with the attributable fraction supplied by af(P, nd, on): PfPR draws, all-cause draws, the crisis
# rule and the sums are the paper's lines.
run_af <- function(af, on = c("curve", "map", "allcause"), nd = D) {
  zc <- if (!"map" %in% on) matrix(0, nd, nC) else Zm[seq_len(nd), , drop = FALSE]
  P <- array(NA_real_, c(nd, nC, nY))
  for (t in seq_len(nY)) {
    sl <- ifelse(zc > 0, matrix(map_sd_up[, t], nd, nC, byrow = TRUE), matrix(map_sd_dn[, t], nd, nC, byrow = TRUE))
    P[, , t] <- 100 * plogis(matrix(lg(P0[, t] / 100), nd, nC, byrow = TRUE) + zc * sl)
  }
  if (!"map" %in% on) for (t in seq_len(nY)) P[, , t] <- matrix(P0[, t], nd, nC, byrow = TRUE)
  AF <- af(P, nd, "curve" %in% on)
  ac_on <- "allcause" %in% on
  Gd <- draw_groups(igme_M, igme, Zig_u, Zig_e, ac_on, nd); Hd <- draw_groups(ihme_M, ihme, Zih_u, Zih_e, ac_on, nd)
  res <- list()
  for (src in c("UN IGME", "IHME")) {
    A <- AC <- AR <- array(0, c(nd, nC, nY)); AG <- lapply(G, function(k) array(0, c(nd, nC, nY)))
    for (j in seq_len(nC)) {
      Db <- if (src == "UN IGME") lapply(seq_along(ages), function(g) Gd[[gi[g]]][, j, ] * split$within_group_share[g]) else {
        h <- lapply(Hd, function(x) x[, j, , drop = FALSE][, 1, ])
        list(h[[1]] + h[[2]], h[[3]], h[[4]], h[[5]], h[[6]] / 3, h[[6]] / 3, h[[6]] / 3)
      }
      Db <- lapply(Db, function(x) if (is.null(dim(x))) matrix(x, nd, nY) else x)
      AR[, j, ] <- Reduce(`+`, Db)
      if (any(crisis[[src]][j, ])) Db <- lapply(seq_along(ages), function(g) crisis_fill(Db[[g]], denom[[src]][[g]][j, ], crisis[[src]][j, ]))
      AC[, j, ] <- Reduce(`+`, Db)
      Ab <- lapply(seq_along(ages), function(g) Db[[g]] * AF[, j, , g])
      A[, j, ] <- Reduce(`+`, Ab)
      for (k in seq_along(G)) AG[[k]][, j, ] <- Reduce(`+`, Ab[gi == k])
    }
    res[[src]] <- list(A = A, AC = AC, AR = AR, AG = AG)
  }
  res$P <- P; res$neg_af_share <- mean(AF < 0); res$min_af <- min(AF)
  res
}

## ---- checks -----------------------------------------------------------------------------------------------------
sources <- c("UN IGME", "IHME")
copy <- run_af(af_paper, nd = 40L); original <- run(nd = 40L)
copy_error <- max(vapply(sources, function(s) max(abs(copy[[s]]$A - original[[s]]$A), abs(copy[[s]]$AC - original[[s]]$AC)), 0))
stopifnot(copy_error < 1e-6); rm(copy, original)
zero_new <- run_af(af_walk, on = character(), nd = 2L)
one_step <- fread(file.path(S$out, "burden_one_step_by_year.csv"))
one_step_error <- if (design_model %in% names(one_step)) max(vapply(sources, function(s)
  max(abs(colSums(zero_new[[s]]$A[1, , ]) / one_step[source == s][order(year)][[design_model]] - 1)), 0)) else NA_real_
stopifnot(is.na(one_step_error) || one_step_error < 5e-3)

## ---- runs and summaries -----------------------------------------------------------------------------------------
group_label <- c(CME_TMM0 = "<1 month", CME_TMM1T11 = "1-11 months", CME_TMY1T4 = "1-4 years")
parts <- function(r, s) { g <- lapply(r[[s]]$AG, function(a) apply(a, c(1, 3), sum))   # draws x years
  c(list(`Under 5` = apply(r[[s]]$A, c(1, 3), sum)), setNames(g, group_label[G]), list(`1-59 months` = g[[2]] + g[[3]])) }
summarise <- function(r, zero, estimate, scenario) rbindlist(lapply(sources, function(s) {
  d <- parts(r, s); p <- parts(zero, s); PY <- colSums(py[[s]]); acd <- apply(r[[s]]$AC, c(1, 3), sum); acp <- colSums(zero[[s]]$AC[1, , ])
  qs <- function(x, pr) apply(x, 2, q, p = pr)
  rbindlist(lapply(names(d), function(a) data.table(estimate = estimate, scenario = scenario, source = s, age_group = a, year = years,
    attributable_deaths = p[[a]][1, ], attributable_deaths_lower = qs(d[[a]], cfg$ui[1]), attributable_deaths_median = qs(d[[a]], .5),
    attributable_deaths_upper = qs(d[[a]], cfg$ui[2]), malaria_rate_per1000 = 1000 * p[[a]][1, ] / PY,
    malaria_rate_per1000_lower = 1000 * qs(d[[a]], cfg$ui[1]) / PY, malaria_rate_per1000_upper = 1000 * qs(d[[a]], cfg$ui[2]) / PY,
    share_of_allcause_under5 = p[[a]][1, ] / acp, share_of_allcause_under5_lower = qs(d[[a]] / acd, cfg$ui[1]),
    share_of_allcause_under5_upper = qs(d[[a]] / acd, cfg$ui[2]))))
}))
envelope_pt <- list(`UN IGME` = igme_u5_pt, IHME = ihme_u5_pt); comparator_pt <- list(`UN IGME` = cacode, IHME = ihme_malaria)
comparator_name <- c(`UN IGME` = "UN IGME (CA-CODE) malaria deaths", IHME = "IHME malaria deaths")
contrasts <- function(r, zero, estimate) rbindlist(lapply(sources, function(s) {
  PY <- colSums(py[[s]]); tt <- function(y) match(y, years); pt <- colSums(zero[[s]]$A[1, , ])
  rate <- function(y) rowSums(r[[s]]$A[, , tt(y)]) / PY[tt(y)]
  change <- function(y0, y1) { d <- 100 * (rate(y1) / rate(y0) - 1)
    data.table(contrast = sprintf("rate change %d-%d (%%)", y0, y1), point = 100 * (pt[tt(y1)] / PY[tt(y1)] / (pt[tt(y0)] / PY[tt(y0)]) - 1), lower = q(d, cfg$ui[1]), upper = q(d, cfg$ui[2])) }
  # older = TRUE: attributable deaths at 1-59 months only, against the same under-five comparator (which has few or no neonatal malaria deaths).
  excess <- function(y, older = FALSE) { k <- tt(y); scale <- r[[s]]$AR[, , k] / matrix(envelope_pt[[s]][, k], nrow(r[[s]]$AR), nC, byrow = TRUE)
    num <- function(x) if (older) rowSums(x[[s]]$AG[[2]][, , k] + x[[s]]$AG[[3]][, , k]) else rowSums(x[[s]]$A[, , k])
    comp_d <- rowSums(scale * matrix(comparator_pt[[s]][, k], nrow(r[[s]]$AR), nC, byrow = TRUE)); d <- 100 * (num(r) / comp_d - 1)
    data.table(contrast = sprintf("excess%s over %s %d (%%)", if (older) " of deaths at 1-59 months" else "", comparator_name[[s]], y),
      point = 100 * (num(zero)[1] / sum(comparator_pt[[s]][, k]) - 1), lower = q(d, cfg$ui[1]), upper = q(d, cfg$ui[2])) }
  stopifnot(identical(unname(group_label[G]), c("<1 month", "1-11 months", "1-4 years")))
  cbind(data.table(estimate = estimate, source = s), rbind(change(2000, 2024), change(2015, 2024), change(2000, 2015), excess(2000), excess(2015), excess(2024),
    excess(2000, TRUE), excess(2015, TRUE), excess(2024, TRUE)))
}))
main_new <- run_af(af_walk)
paper_main <- run(); zero_paper <- run(on = character(), nd = 2L)
annual <- rbind(summarise(main_new, zero_new, design_model, "main"),
  summarise(run_af(af_walk, "curve"), zero_new, design_model, "curve_only"), summarise(run_af(af_walk, "map"), zero_new, design_model, "map_only"),
  summarise(run_af(af_walk, "allcause"), zero_new, design_model, "allcause_only"), summarise(paper_main, zero_paper, "paper", "main"))
contrast <- rbind(contrasts(main_new, zero_new, design_model), contrasts(paper_main, zero_paper, "paper"))
# The paper's rows must be the paper's published intervals.
published <- fread(file.path(settings$out, "uncertainty", "annual_intervals_2000_2024.csv"))[scenario == "main"]
mine <- annual[estimate == "paper" & age_group == "Under 5"][published, on = c("source", "year")]
paper_error <- max(abs(mine$attributable_deaths_lower / mine$i.attributable_deaths_lower - 1), abs(mine$attributable_deaths_upper / mine$i.attributable_deaths_upper - 1),
  abs(mine$attributable_deaths / mine$i.attributable_deaths - 1))
stopifnot(paper_error < 1e-8)
checks <- data.table(item = c("model", "curve draws", "burden loop copied here against the paper's run(), 40 draws (max abs difference, deaths)",
  "paper intervals recomputed here against the published ones (max relative difference)", "zero-noise run against the one-step estimate (max relative difference over years and sources)",
  "share of draw x country x year x band attributable fractions below 0", "minimum attributable fraction in the draws"),
  value = c(design_model, if (mean_test) "TEST: mean curve repeated, not posterior draws" else as.character(D), format(copy_error, digits = 3), format(paper_error, digits = 3),
    format(one_step_error, digits = 3), format(main_new$neg_af_share, digits = 3), format(main_new$min_af, digits = 3)))
print(checks); f0 <- function(x) format(round(x, -3), big.mark = ",")
print(annual[scenario == "main" & year %in% c(2000, 2015, 2024) & age_group %in% c("Under 5", "1-59 months"), .(estimate, source, age_group, year,
  deaths = f0(attributable_deaths), lower = f0(attributable_deaths_lower), median = f0(attributable_deaths_median), upper = f0(attributable_deaths_upper))])
print(contrast[, .(estimate, source, contrast, point = round(point, 1), lower = round(lower, 1), upper = round(upper, 1))])
if (!mean_test) {
  dir.create(dout, recursive = TRUE, showWarnings = FALSE)
  fwrite(annual, file.path(dout, "annual_intervals_2000_2024.csv")); fwrite(contrast, file.path(dout, "contrasts.csv")); fwrite(checks, file.path(dout, "checks.csv"))
  stopifnot(all(vapply(comparator_pt, function(x) ncol(x) == length(years) && !anyNA(x), NA)))
  fwrite(rbindlist(lapply(sources, function(s) data.table(source = s, comparator = comparator_name[[s]], year = years, malaria_deaths_under5 = colSums(comparator_pt[[s]])))),
    file.path(dout, "comparators_2000_2024.csv"))
  saveRDS(list(model = design_model, iso3 = iso, years = years, attributable_deaths = lapply(setNames(sources, sources), function(s) main_new[[s]]$A),
    allcause_deaths = lapply(setNames(sources, sources), function(s) main_new[[s]]$AC), pfpr_pct = main_new$P),
    file.path(S$private, paste0("uncertainty_draws_", design_model, ".rds")))
}
