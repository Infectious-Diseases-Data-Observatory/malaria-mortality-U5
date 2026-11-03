# Hazard ratios relative to zero prevalence, exp{f(P) - f(0)}, for the supplementary spline figures, so that they share
# Figure 2's reference point and scale (author request, 3 November 2026). `curve` is one age band of a saved curve table
# (relative to PfPR = 20%, R_cbh/sensitivity/model.R); its point estimates are re-referenced exactly. With the saved
# fit, pointwise 95% intervals come from the PfPR smooth's coefficient covariance, conditional on the smoothing
# parameters, as in Figure 2 (R_cbh/reporting/26_hazard_ratio_by_age.R); without it the intervals are NA.
# segment: "central" over the central 95% of the band's exposure distribution, "extrapolated" from zero to its 2.5th
# percentile (drawn dashed, as in Figure 2), "outside" above the 97.5th percentile (not drawn).
cbh_curve_vs_zero <- function(curve, fit = NULL) {
  stopifnot(length(unique(curve$age_band)) == 1L, sum(curve$pfpr_pct == 0) == 1L)
  est <- curve$log_hazard_ratio - curve$log_hazard_ratio[curve$pfpr_pct == 0]
  se <- rep(NA_real_, nrow(curve))
  if (!is.null(fit)) {
    s <- fit$smooth[[match("s(pfpr_pct)", vapply(fit$smooth, `[[`, "", "label"))]]; ix <- s$first.para:s$last.para
    L <- mgcv::PredictMat(s, data.frame(pfpr_pct = curve$pfpr_pct)) -
      mgcv::PredictMat(s, data.frame(pfpr_pct = rep(0, nrow(curve))))
    stopifnot(max(abs(drop(L %*% coef(fit)[ix]) - est)) < 1e-8)
    se <- sqrt(pmax(rowSums((L %*% fit$Vp[ix, ix]) * L), 0))
  }
  data.frame(age_band = curve$age_band, pfpr_pct = curve$pfpr_pct, log_hr_vs_zero = est, se = se,
    hazard_ratio = exp(est), lower_95 = exp(est - 1.96 * se), upper_95 = exp(est + 1.96 * se),
    segment = ifelse(curve$pfpr_pct < curve$pfpr_p025, "extrapolated",
                     ifelse(curve$pfpr_pct <= curve$pfpr_p975, "central", "outside")),
    pfpr_p025 = curve$pfpr_p025, pfpr_p975 = curve$pfpr_p975)
}

# Figure 2's own curves and intervals for the full primary sample (hazard_ratio_by_age/hazard_ratio_curves.csv), checked
# against the saved primary curve table re-referenced to zero.
cbh_primary_vs_zero <- function(primary_out) {
  hr <- cbh_read_csv(file.path(primary_out, "hazard_ratio_by_age", "hazard_ratio_curves.csv"))
  pc <- cbh_read_csv(file.path(primary_out, "pfpr_curves.csv")); pc <- pc[pc$series == "map_full", ]
  for (a in unique(hr$age_band)) {
    z <- cbh_curve_vs_zero(pc[pc$age_band == a, ]); h <- hr[hr$age_band == a, ]; k <- match(h$pfpr_pct, z$pfpr_pct)
    stopifnot(sum(!is.na(k)) > 10L, max(abs(h$log_hr_vs_zero[!is.na(k)] - z$log_hr_vs_zero[k[!is.na(k)]])) < 1e-8)
  }
  hr
}
