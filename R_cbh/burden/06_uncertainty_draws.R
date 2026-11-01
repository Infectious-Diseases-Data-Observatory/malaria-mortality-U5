#!/usr/bin/env Rscript
# Uncertainty in malaria-attributable mortality (author request, 1 November 2026): 500 joint draws of the three inputs,
# pushed through the arithmetic of R_cbh/burden/04_annual_comparison.R draw by draw. 95% uncertainty intervals are the 2.5% and 97.5% quantiles of the draws; the point
# estimate stays 04's deterministic value. Totals, rates and contrasts are computed inside each draw, never from bounds.
#   PfPR-death spline: each band's PfPR coefficients ~ MVN(beta, Vc) (Vc includes smoothing-parameter uncertainty),
#     read from the saved fits; one draw per band shared by every country and year; bands independent.
#   MAP national PfPR: MAP gives each country-year's mean and interval bounds but no realisations or correlations. Each
#     country-year is a split logit-normal fitted to MAP's mean, LCI and UCI (taken as 95%), applied as a logit-scale
#     spread around the national PfPR the burden uses; one standard normal per country, held over all its years, and
#     countries independent (author decision). A sensitivity shares one normal across all countries.
#   All-cause deaths: UN IGME's three age groups (bounds taken as 90%) and IHME's six leaf ages (95%), each a split
#     lognormal around the published value; within a country-year the groups share a common factor whose weight
#     reproduces the published under-five bounds; one draw per country, held over all its years; countries and the two
#     sources independent. Population and person-years are fixed.
# Crisis years stay at 04's classification; in each draw their band rates are the log-linear interpolation of that
# draw's rates in the neighbouring non-crisis years, as in 04. Comparators: in each draw CA-CODE (UN IGME) and IHME
# malaria deaths are scaled by the drawn under-five envelope of their own source; their cause-fraction uncertainty is
# not included. Outputs: <out>/uncertainty/ (intervals, contrasts, checks, SPEC.md) and <private>/uncertainty_draws.rds.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
suppressPackageStartupMessages({ library(data.table); library(mgcv) })
settings <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION", "snow_merge"))
cfg <- list(draws = 500L, seed = 20261101L, igme_level = 0.90, ihme_level = 0.95, map_level = 0.95, ui = c(.025, .975))
ac <- file.path(settings$out, "annual_comparison")
out <- file.path(settings$out, "uncertainty"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
years <- 2000:2024; nY <- length(years)
ages <- cbh_config()$age_bands$age_band
ihme_path <- list.files("data", pattern = "2026-09-09 10-58-22[.]csv$", full.names = TRUE); stopifnot(length(ihme_path) == 1L)
igme_path <- "data/unicef/fusion_GLOBAL_DATAFLOW_UNICEF_1.0_igme_wpp_subset.csv"
paths <- c(age = file.path(ac, "source_age_estimates_2000_2024.csv"), nat = file.path(ac, "national_pfpr_2000_2024.csv"),
  split = file.path(ac, "igme_age_split.csv"), rates = file.path(ac, "source_country_rates_2000_2024.csv"),
  annual = file.path(ac, "source_annual_rates_2000_2024.csv"), estimates = file.path(ac, "country_estimates_2000_2024.csv"),
  components = file.path(settings$private, "pfpr_components.rds"), manifest = file.path(settings$out, "fit_manifest.csv"),
  map = cbh_config()$map_national, igme = igme_path, ihme = ihme_path)
stopifnot(all(file.exists(paths)))

## ---- point inputs (04's outputs) -----------------------------------------------------------------------------------
age_pt <- fread(paths[["age"]]); nat <- fread(paths[["nat"]]); split <- fread(paths[["split"]])
rates_pt <- fread(paths[["rates"]]); annual_pt <- fread(paths[["annual"]]); est <- fread(paths[["estimates"]])
stopifnot(identical(split$age_band, ages), "rate_denominator" %in% names(age_pt))
iso <- sort(unique(nat$iso3)); nC <- length(iso); stopifnot(nC == 42L)
cy <- function(dt, col) {
  z <- dcast(as.data.table(dt), iso3 ~ year, value.var = col); m <- as.matrix(z[match(iso, z$iso3), -1, with = FALSE])
  stopifnot(identical(colnames(m), as.character(years)), !anyNA(m)); m
}
P0 <- cy(nat, "pfpr_pct")
band <- function(src, a, col) cy(age_pt[source == src & age_band == a], col)
crisis <- list(`UN IGME` = cy(age_pt[source == "UN IGME" & age_band == ages[1]], "crisis_year") == "TRUE",
               IHME = cy(age_pt[source == "IHME" & age_band == ages[1]], "crisis_year") == "TRUE")
denom <- list(`UN IGME` = lapply(ages, function(a) band("UN IGME", a, "rate_denominator")),
              IHME = lapply(ages, function(a) band("IHME", a, "rate_denominator")))
py <- list(`UN IGME` = cy(rates_pt[source == "UN IGME"], "under5_person_years"), IHME = cy(rates_pt[source == "IHME"], "under5_person_years"))
cacode <- cy(est, "who_cacode_deaths"); ihme_malaria <- cy(est, "ihme_malaria_deaths")
countries <- unique(rates_pt[, .(iso3, country)])[match(iso, iso3)]

## ---- MAP: split logit-normal spread from MAP's national interval -------------------------------------------------
map <- as.data.table(cbh_map_national(iso, years))
z_map <- qnorm(1 - (1 - cfg$map_level) / 2)
lg <- function(p) qlogis(pmin(pmax(p, 1e-9), 1 - 1e-9))
map[, `:=`(sd_dn = (lg(pfpr_pct / 100) - lg(pfpr_lci_pct / 100)) / z_map, sd_up = (lg(pfpr_uci_pct / 100) - lg(pfpr_pct / 100)) / z_map)]
map[pfpr_lci_pct <= 0, sd_dn := sd_up]   # MAP's lower bound is exactly 0 in a few low-prevalence country-years
map_sd_dn <- cy(map, "sd_dn"); map_sd_up <- cy(map, "sd_up")
stopifnot(all(is.finite(map_sd_dn)), all(is.finite(map_sd_up)), all(map_sd_dn >= 0), all(map_sd_up >= 0))

## ---- all-cause bounds: split lognormal per group and the common-factor weight rho ----------------------------------
# rho (country x year): the share of each group's log variance carried by a factor common to the groups, chosen by the
# delta method so that the implied under-five log width equals the published one (clipped to 0-1).
group_spread <- function(M, L, U, M5, L5, U5, level) {
  z <- qnorm(1 - (1 - level) / 2); k <- length(M)
  up <- lapply(seq_len(k), function(i) log(U[[i]] / M[[i]]) / z)
  dn <- lapply(seq_len(k), function(i) ifelse(L[[i]] > 0, log(M[[i]] / L[[i]]) / z, log(U[[i]] / M[[i]]) / z))
  s <- lapply(seq_len(k), function(i) (up[[i]] + dn[[i]]) / 2); w <- lapply(seq_len(k), function(i) M[[i]] / M5)
  s5 <- log(U5 / L5) / (2 * z)
  diag_part <- Reduce(`+`, lapply(seq_len(k), function(i) (w[[i]] * s[[i]])^2))
  ws <- Reduce(`+`, lapply(seq_len(k), function(i) w[[i]] * s[[i]]))
  rho <- pmin(pmax((s5^2 - diag_part) / (ws^2 - diag_part), 0), 1)
  rho[!is.finite(rho)] <- 0
  list(up = up, dn = dn, rho = rho)
}
ig <- fread(igme_path)[REF_AREA %in% iso & TIME_PERIOD %in% years]
igm <- function(ind, col) cy(ig[INDICATOR == ind, .(iso3 = REF_AREA, year = TIME_PERIOD, v = get(col))], "v")
G <- c("CME_TMM0", "CME_TMM1T11", "CME_TMY1T4"); gi <- match(split$igme_indicator, G); stopifnot(!anyNA(gi))
igme_M <- lapply(G, igm, col = "OBS_VALUE")
igme <- group_spread(igme_M, lapply(G, igm, col = "LOWER_BOUND"), lapply(G, igm, col = "UPPER_BOUND"),
  igm("CME_TMY0T4", "OBS_VALUE"), igm("CME_TMY0T4", "LOWER_BOUND"), igm("CME_TMY0T4", "UPPER_BOUND"), cfg$igme_level)
leaf <- c("0 to 6 days (early neonatal)", "7 to 27 days (late neonatal)", "1 to 5 months", "6-11 months", "12 to 23 months", "2 to 4")
ih <- fread(ihme_path)[Year %in% years & Sex == "Both" & Condition == "All causes" & Measure == "Deaths" & Unit == "Number"]
ih[, iso3 := countrycode::countrycode(Location, "country.name", "iso3c", warn = FALSE)]
ih <- ih[iso3 %in% iso]
ihm <- function(a, col) cy(ih[Age == a, .(iso3, year = Year, v = get(col))], "v")
ihme_M <- lapply(leaf, ihm, col = "Value")
ihme <- group_spread(ihme_M, lapply(leaf, ihm, col = "Lower"), lapply(leaf, ihm, col = "Upper"),
  ihm("Under 5", "Value"), ihm("Under 5", "Lower"), ihm("Under 5", "Upper"), cfg$ihme_level)
igme_u5_pt <- Reduce(`+`, igme_M); ihme_u5_pt <- Reduce(`+`, ihme_M)

## ---- spline: Vc from the saved fits (paths and md5s from the fit manifest) ----------------------------------------
comp <- readRDS(paths[["components"]]); manifest <- fread(paths[["manifest"]])
Vc <- lapply(seq_along(ages), function(g) {
  piece <- comp[[paste0("map_full_age_", g)]]; m <- manifest[fit_id == piece$fit_id]
  stopifnot(nrow(m) == 1L, identical(cbh_file_hash(m$model_file), m$md5), identical(piece$model_md5, m$md5))
  f <- readRDS(m$model_file)$fit; ix <- f$smooth[[1]]$first.para:f$smooth[[1]]$last.para
  stopifnot(max(abs(coef(f)[ix] - piece$coef)) == 0, max(abs(f$Vp[ix, ix] - piece$covariance)) == 0)
  v <- f$Vc[ix, ix]; rm(f); invisible(gc()); v
})

## ---- seeded, component-specific streams (switching one component off leaves the others' draws unchanged) ----------
D <- cfg$draws
RNGkind("L'Ecuyer-CMRG"); set.seed(cfg$seed); s <- .Random.seed; streams <- list()
for (nm in c(paste0("spline_", seq_along(ages)), "map", "igme", "ihme")) { streams[[nm]] <- s; s <- parallel::nextRNGStream(s) }
normals <- function(nm, n) { assign(".Random.seed", streams[[nm]], envir = globalenv()); rnorm(n) }
Zb <- lapply(seq_along(ages), function(g) matrix(normals(paste0("spline_", g), D * 4L), D, 4L))
Zm <- matrix(normals("map", D * nC), D, nC)
zi <- normals("igme", D * nC * 4L); Zig_u <- matrix(zi[seq_len(D * nC)], D, nC); Zig_e <- array(zi[-seq_len(D * nC)], c(D, nC, 3L))
zh <- normals("ihme", D * nC * 7L); Zih_u <- matrix(zh[seq_len(D * nC)], D, nC); Zih_e <- array(zh[-seq_len(D * nC)], c(D, nC, 6L))

# Interpolation weights of 04's crisis rule: a flagged year takes the log-linear interpolation between the nearest
# earlier and later non-crisis years (the nearest non-crisis year at either end).
crisis_weights <- function(flag) lapply(which(flag), function(t) {
  ok <- which(!flag); lo <- ok[ok < t]; hi <- ok[ok > t]
  if (length(lo) && length(hi)) { lo <- max(lo); hi <- min(hi); list(t = t, i = c(lo, hi), w = c((hi - t) / (hi - lo), (t - lo) / (hi - lo))) }
  else list(t = t, i = if (length(lo)) max(lo) else min(hi), w = 1)
})
crisis_fill <- function(Db, den, flag) {   # Db: D x T band deaths of one country; den: band denominators (T)
  for (cw in crisis_weights(flag)) Db[, cw$t] <- exp(log(Db[, cw$i, drop = FALSE] %*% diag(1 / den[cw$i], length(cw$i))) %*% cw$w) * den[cw$t]
  Db
}
draw_groups <- function(M, sp, Zu, Ze, on, nd) lapply(seq_along(M), function(k) {
  outk <- array(NA_real_, c(nd, nC, nY))
  for (t in seq_len(nY)) {
    z <- if (on) sweep(Zu[seq_len(nd), , drop = FALSE], 2, sqrt(sp$rho[, t]), `*`) +
      sweep(Ze[seq_len(nd), , k, drop = FALSE][, , 1], 2, sqrt(1 - sp$rho[, t]), `*`) else matrix(0, nd, nC)
    sl <- ifelse(z > 0, matrix(sp$up[[k]][, t], nd, nC, byrow = TRUE), matrix(sp$dn[[k]][, t], nd, nC, byrow = TRUE))
    outk[, , t] <- matrix(M[[k]][, t], nd, nC, byrow = TRUE) * exp(z * sl)
  }
  outk
})

## ---- one scenario ------------------------------------------------------------------------------------------------
run <- function(on = c("spline", "map", "allcause"), map_shared = FALSE, nd = D) {
  B <- lapply(seq_along(ages), function(g) {
    Z <- if ("spline" %in% on) Zb[[g]][seq_len(nd), , drop = FALSE] else matrix(0, nd, 4L)
    matrix(comp[[g]]$coef, nd, 4L, byrow = TRUE) + Z %*% chol(Vc[[g]])
  })
  zc <- if (!"map" %in% on) matrix(0, nd, nC) else if (map_shared) matrix(Zm[seq_len(nd), 1], nd, nC) else Zm[seq_len(nd), , drop = FALSE]
  P <- array(NA_real_, c(nd, nC, nY))
  for (t in seq_len(nY)) {
    sl <- ifelse(zc > 0, matrix(map_sd_up[, t], nd, nC, byrow = TRUE), matrix(map_sd_dn[, t], nd, nC, byrow = TRUE))
    P[, , t] <- 100 * plogis(matrix(lg(P0[, t] / 100), nd, nC, byrow = TRUE) + zc * sl)
  }
  if (!"map" %in% on) for (t in seq_len(nY)) P[, , t] <- matrix(P0[, t], nd, nC, byrow = TRUE)
  AF <- array(NA_real_, c(nd, nC, nY, length(ages)))
  for (g in seq_along(ages)) {
    sm <- comp[[g]]$smooth
    X <- PredictMat(sm, data.frame(pfpr_pct = as.vector(P)))   # rows: draw fastest, then country, then year
    x0 <- drop(PredictMat(sm, data.frame(pfpr_pct = 0)) %*% t(B[[g]]))
    f <- rowSums(X * B[[g]][rep(seq_len(nd), nC * nY), , drop = FALSE])
    AF[, , , g] <- -expm1(rep(x0, nC * nY) - f)
  }
  ac_on <- "allcause" %in% on
  Gd <- draw_groups(igme_M, igme, Zig_u, Zig_e, ac_on, nd); Hd <- draw_groups(ihme_M, ihme, Zih_u, Zih_e, ac_on, nd)
  res <- list()
  for (src in c("UN IGME", "IHME")) {
    A <- AC <- AR <- array(0, c(nd, nC, nY))
    for (c in seq_len(nC)) {
      Db <- if (src == "UN IGME") lapply(seq_along(ages), function(g) Gd[[gi[g]]][, c, ] * split$within_group_share[g]) else {
        h <- lapply(Hd, function(x) x[, c, , drop = FALSE][, 1, ])
        list(h[[1]] + h[[2]], h[[3]], h[[4]], h[[5]], h[[6]] / 3, h[[6]] / 3, h[[6]] / 3)
      }
      Db <- lapply(Db, function(x) if (is.null(dim(x))) matrix(x, nd, nY) else x)
      AR[, c, ] <- Reduce(`+`, Db)
      if (any(crisis[[src]][c, ])) Db <- lapply(seq_along(ages), function(g) crisis_fill(Db[[g]], denom[[src]][[g]][c, ], crisis[[src]][c, ]))
      AC[, c, ] <- Reduce(`+`, Db)
      A[, c, ] <- Reduce(`+`, lapply(seq_along(ages), function(g) Db[[g]] * AF[, c, , g]))
    }
    res[[src]] <- list(A = A, AC = AC, AR = AR)
  }
  res$P <- P; res$neg_af_share <- mean(AF < 0); res$min_af <- min(AF)
  res
}
q <- function(x, p) quantile(x, p, names = FALSE, type = 7)

## ---- check: every component off reproduces 04 exactly ------------------------------------------------------------
zero <- run(on = character(), nd = 2L)
check <- rbindlist(lapply(c("UN IGME", "IHME"), function(src) {
  pa <- cy(age_pt[source == src, .(a = sum(attributable_deaths)), by = .(iso3, year)], "a")
  pc <- cy(age_pt[source == src, .(a = sum(allcause_deaths)), by = .(iso3, year)], "a")
  pr <- cy(age_pt[source == src, .(a = sum(allcause_deaths_reported)), by = .(iso3, year)], "a")
  data.table(source = src, max_abs_attributable = max(abs(zero[[src]]$A[1, , ] - pa)), max_abs_allcause = max(abs(zero[[src]]$AC[1, , ] - pc)),
    max_abs_reported = max(abs(zero[[src]]$AR[1, , ] - pr)))
}))
stopifnot(all(check$max_abs_attributable < 1e-6), all(check$max_abs_allcause < 1e-6), all(check$max_abs_reported < 1e-6),
  max(abs(zero$P[1, , ] - P0)) < 1e-9)

## ---- runs ---------------------------------------------------------------------------------------------------------
scen <- list(main = run(), map_countries_correlated = run(map_shared = TRUE), spline_only = run("spline"),
  map_only = run("map"), allcause_only = run("allcause"))

## ---- summaries ----------------------------------------------------------------------------------------------------
pt_A <- lapply(c(`UN IGME` = "UN IGME", IHME = "IHME"), function(src) cy(age_pt[source == src, .(a = sum(attributable_deaths)), by = .(iso3, year)], "a"))
pt_AC <- lapply(c(`UN IGME` = "UN IGME", IHME = "IHME"), function(src) cy(age_pt[source == src, .(a = sum(allcause_deaths)), by = .(iso3, year)], "a"))
envelope_pt <- list(`UN IGME` = igme_u5_pt, IHME = ihme_u5_pt); comparator_pt <- list(`UN IGME` = cacode, IHME = ihme_malaria)
comparator_name <- c(`UN IGME` = "UN IGME (CA-CODE) malaria deaths", IHME = "IHME malaria deaths")
annual <- rbindlist(lapply(names(scen), function(sn) rbindlist(lapply(c("UN IGME", "IHME"), function(src) {
  r <- scen[[sn]][[src]]; PY <- colSums(py[[src]])
  rbindlist(lapply(seq_len(nY), function(t) {
    a <- rowSums(r$A[, , t]); acd <- rowSums(r$AC[, , t])
    data.table(scenario = sn, source = src, year = years[t], attributable_deaths = sum(pt_A[[src]][, t]),
      attributable_deaths_lower = q(a, cfg$ui[1]), attributable_deaths_median = q(a, .5), attributable_deaths_upper = q(a, cfg$ui[2]),
      malaria_rate_per1000 = 1000 * sum(pt_A[[src]][, t]) / PY[t], malaria_rate_per1000_lower = 1000 * q(a, cfg$ui[1]) / PY[t],
      malaria_rate_per1000_upper = 1000 * q(a, cfg$ui[2]) / PY[t],
      malaria_fraction = sum(pt_A[[src]][, t]) / sum(pt_AC[[src]][, t]), malaria_fraction_lower = q(a / acd, cfg$ui[1]),
      malaria_fraction_upper = q(a / acd, cfg$ui[2]), allcause_deaths_lower = q(acd, cfg$ui[1]), allcause_deaths_upper = q(acd, cfg$ui[2]))
  }))
}))))
main <- scen$main
country <- rbindlist(lapply(c("UN IGME", "IHME"), function(src) {
  r <- main[[src]]
  rbindlist(lapply(seq_len(nC), function(c) rbindlist(lapply(seq_len(nY), function(t) {
    a <- r$A[, c, t]; acd <- r$AC[, c, t]; p <- main$P[, c, t]; den <- py[[src]][c, t]
    data.table(source = src, iso3 = iso[c], country = countries$country[c], year = years[t],
      pfpr_pct = P0[c, t], pfpr_pct_lower = q(p, cfg$ui[1]), pfpr_pct_upper = q(p, cfg$ui[2]),
      attributable_deaths = pt_A[[src]][c, t], attributable_deaths_lower = q(a, cfg$ui[1]), attributable_deaths_upper = q(a, cfg$ui[2]),
      malaria_rate_per1000 = 1000 * pt_A[[src]][c, t] / den, malaria_rate_per1000_lower = 1000 * q(a, cfg$ui[1]) / den,
      malaria_rate_per1000_upper = 1000 * q(a, cfg$ui[2]) / den, malaria_fraction = pt_A[[src]][c, t] / pt_AC[[src]][c, t],
      malaria_fraction_lower = q(a / acd, cfg$ui[1]), malaria_fraction_upper = q(a / acd, cfg$ui[2]),
      allcause_deaths = pt_AC[[src]][c, t], allcause_deaths_lower = q(acd, cfg$ui[1]), allcause_deaths_upper = q(acd, cfg$ui[2]))
  }))))
}))
# Contrasts inside each draw: change in the 42-country rate, and the excess over the source's cause-specific estimate
# (the comparator scaled by the drawn envelope of its own source).
contrast <- rbindlist(lapply(names(scen), function(sn) rbindlist(lapply(c("UN IGME", "IHME"), function(src) {
  r <- scen[[sn]][[src]]; PY <- colSums(py[[src]]); t <- function(y) match(y, years)
  rate <- function(x, y) rowSums(x[, , t(y)]) / PY[t(y)]; prate <- function(y) sum(pt_A[[src]][, t(y)]) / PY[t(y)]
  change <- function(y0, y1) { d <- 100 * (rate(r$A, y1) / rate(r$A, y0) - 1)
    data.table(contrast = sprintf("rate change %d-%d (%%)", y0, y1), point = 100 * (prate(y1) / prate(y0) - 1), lower = q(d, cfg$ui[1]), upper = q(d, cfg$ui[2])) }
  excess <- function(y) { k <- t(y); scale <- r$AR[, , k] / matrix(envelope_pt[[src]][, k], nrow(r$AR), nC, byrow = TRUE)
    comp_d <- rowSums(scale * matrix(comparator_pt[[src]][, k], nrow(r$AR), nC, byrow = TRUE))
    d <- 100 * (rowSums(r$A[, , k]) / comp_d - 1)
    data.table(contrast = sprintf("excess over %s %d (%%)", comparator_name[[src]], y), point = 100 * (sum(pt_A[[src]][, k]) / sum(comparator_pt[[src]][, k]) - 1),
      lower = q(d, cfg$ui[1]), upper = q(d, cfg$ui[2])) }
  cbind(data.table(scenario = sn, source = src), rbind(change(2000, 2024), change(2015, 2024), change(2000, 2015), excess(2000), excess(2015), excess(2024)))
}))))
# Monte Carlo error of the 2024 bounds at D draws (bootstrap over draws).
set.seed(cfg$seed + 1L)
mc <- rbindlist(lapply(c("UN IGME", "IHME"), function(src) {
  a <- rowSums(main[[src]]$A[, , nY]); bs <- replicate(2000L, { x <- sample(a, replace = TRUE); c(q(x, cfg$ui[1]), q(x, cfg$ui[2])) })
  data.table(source = src, year = 2024L, draws = D, mc_sd_lower = sd(bs[1, ]), mc_sd_upper = sd(bs[2, ]),
    mc_sd_lower_relative = sd(bs[1, ]) / sum(pt_A[[src]][, nY]), mc_sd_upper_relative = sd(bs[2, ]) / sum(pt_A[[src]][, nY]))
}))
# Do the draws reproduce the inputs' published bounds? (2.5/97.5% of MAP and 5/95% or 2.5/97.5% of the all-cause groups)
gd <- draw_groups(igme_M, igme, Zig_u, Zig_e, TRUE, D); hd <- draw_groups(ihme_M, ihme, Zih_u, Zih_e, TRUE, D)
bound_err <- function(x, M, L, U, level) { lo <- apply(x, c(2, 3), q, p = (1 - level) / 2); hi <- apply(x, c(2, 3), q, p = 1 - (1 - level) / 2)
  ok <- L > 0; e <- c(abs(lo[ok] / L[ok] - 1), abs(hi / U - 1)); wr <- (log(hi[ok]) - log(lo[ok])) / (log(U[ok]) - log(L[ok]))
  wr <- wr[is.finite(wr)]
  c(median_rel_error_lower = median(abs(lo[ok] / L[ok] - 1)), median_rel_error_upper = median(abs(hi / U - 1)),
    p95_rel_error = unname(quantile(e, .95)), max_rel_error = max(e), median_width_ratio = median(wr),
    min_width_ratio = min(wr), max_width_ratio = max(wr)) }
bounds <- rbind(
  data.table(input = "UN IGME under 5 (sum of drawn groups)", t(bound_err(Reduce(`+`, gd), NULL, igm("CME_TMY0T4", "LOWER_BOUND"), igm("CME_TMY0T4", "UPPER_BOUND"), cfg$igme_level))),
  data.table(input = "IHME under 5 (sum of drawn leaf ages)", t(bound_err(Reduce(`+`, hd), NULL, ihm("Under 5", "Lower"), ihm("Under 5", "Upper"), cfg$ihme_level))),
  data.table(input = "MAP national PfPR", t(bound_err(main$P, NULL, cy(map, "pfpr_lci_pct") * (P0 / cy(map, "pfpr_pct")), cy(map, "pfpr_uci_pct") * (P0 / cy(map, "pfpr_pct")), cfg$map_level))))
# A broken calibration (wrong interval level, a group mismatch after an input update) must not pass silently; the
# tolerance allows for Monte Carlo error at 500 draws and for the cells where rho is floored at 0 (checks.csv).
stopifnot(all(bounds$median_rel_error_lower < .03), all(bounds$median_rel_error_upper < .03),
  all(bounds$median_width_ratio > .9 & bounds$median_width_ratio < 1.1), all(bounds$max_width_ratio < 1.5))
checks <- rbind(
  data.table(item = "zero-noise run reproduces 04 (max abs difference, deaths)", value = format(max(check$max_abs_attributable), digits = 3)),
  data.table(item = "draws", value = as.character(D)), data.table(item = "seed", value = as.character(cfg$seed)),
  data.table(item = "crisis country-years held fixed (UN IGME, IHME)", value = paste(sum(crisis$`UN IGME`), sum(crisis$IHME), sep = ", ")),
  data.table(item = "share of draw x country x year x band attributable fractions below 0 (main)", value = format(main$neg_af_share, digits = 3)),
  data.table(item = "minimum attributable fraction in the draws (main)", value = format(main$min_af, digits = 3)),
  data.table(item = "MAP country-years with lower bound 0 (lower spread set to upper)", value = as.character(sum(map$pfpr_lci_pct <= 0))),
  data.table(item = "country-years with the common factor floored at 0 (UN IGME, IHME): published under-five bounds narrower than independent ages", value = paste(sum(igme$rho == 0), sum(ihme$rho == 0), sep = ", ")))
fwrite(country, file.path(out, "country_year_intervals_2000_2024.csv"))
fwrite(annual, file.path(out, "annual_intervals_2000_2024.csv"))
fwrite(contrast, file.path(out, "contrasts.csv"))
fwrite(mc, file.path(out, "monte_carlo_error_2024.csv"))
fwrite(bounds, file.path(out, "input_bound_reproduction.csv"))
fwrite(checks, file.path(out, "checks.csv"))
cbh_atomic_rds(list(settings = cfg, iso3 = iso, years = years,
  attributable_deaths = lapply(c(`UN IGME` = "UN IGME", IHME = "IHME"), function(src) main[[src]]$A),
  allcause_deaths = lapply(c(`UN IGME` = "UN IGME", IHME = "IHME"), function(src) main[[src]]$AC), pfpr_pct = main$P),
  file.path(settings$private, "uncertainty_draws.rds"))

## ---- specification and provenance --------------------------------------------------------------------------------
a24 <- annual[scenario == "main" & year == 2024]; f0 <- function(x) format(round(x, -3), big.mark = ",")
spec <- c("# Uncertainty in malaria-attributable mortality: specification", "",
  sprintf("%d joint draws (seed %d); 95%% uncertainty intervals are the 2.5%% and 97.5%% quantiles; point estimates are the deterministic values of 04_annual_comparison.R.", D, cfg$seed), "",
  "- PfPR-death spline: each age band's PfPR coefficients drawn from MVN(beta, Vc), which includes smoothing-parameter uncertainty; one draw per band shared by every country and year; bands independent.",
  sprintf("- MAP national PfPR2-10 (release %s): split logit-normal per country-year fitted to MAP's mean and lower and upper bounds, taken as a %d%% interval, applied as a spread around the national PfPR used by the burden; one draw per country held over its years; countries independent (sensitivity: one draw shared by all countries).", cbh_config()$map_release, round(100 * cfg$map_level)),
  sprintf("- All-cause deaths: UN IGME under-five deaths by age group (<1 month, 1-11 months, 1-4 years; bounds taken as %d%%) and IHME deaths by age (six ages; %d%%), split lognormal around the published values, with a common factor across ages calibrated to the published under-five bounds where they allow (where they are narrower than independent ages would give, the ages are independent; counts in checks.csv); one draw per country held over its years; countries and sources independent. Population and person-years fixed.", round(100 * cfg$igme_level), round(100 * cfg$ihme_level)),
  "- Crisis years are held at the point classification; in each draw their band rates are interpolated from that draw's neighbouring non-crisis years.",
  "- Comparators: CA-CODE and IHME malaria deaths are scaled in each draw by the drawn under-five envelope of their own source; their cause-fraction uncertainty is not included.",
  "- Not included: structural choices (one pooled curve, the PfPR = 0 counterfactual, gamma = 2), correlation between countries' MAP errors other than the sensitivity, and the partial cancellation of continental MAP error between the fit and the burden (so the MAP part is an upper bound).", "",
  sprintf("2024: %s malaria-attributable deaths (95%% UI %s-%s) with UN IGME all-cause deaths; %s (%s-%s) with IHME.",
    f0(a24[source == "UN IGME"]$attributable_deaths), f0(a24[source == "UN IGME"]$attributable_deaths_lower), f0(a24[source == "UN IGME"]$attributable_deaths_upper),
    f0(a24[source == "IHME"]$attributable_deaths), f0(a24[source == "IHME"]$attributable_deaths_lower), f0(a24[source == "IHME"]$attributable_deaths_upper)),
  sprintf("Monte Carlo SD of the 2024 UN IGME bounds at %d draws: %s and %s deaths.", D, f0(mc[source == "UN IGME"]$mc_sd_lower), f0(mc[source == "UN IGME"]$mc_sd_upper)))
writeLines(spec, file.path(out, "SPEC.md"))
prov <- c(unname(paths), manifest$model_file, "R_cbh/burden/06_uncertainty_draws.R")
cbh_atomic_csv(data.frame(file = prov, md5 = vapply(prov, cbh_file_hash, "")), file.path(out, "input_provenance.csv"))
print(checks); print(annual[scenario == "main" & year %in% c(2000, 2015, 2024)]); print(contrast[scenario == "main"])
