<!-- Design note, 31 October 2026. Not yet implemented in the pipeline; no repo code was changed. -->
<!-- How it was produced: two scouts traced the burden code and the available uncertainty inputs; one agent drafted the
     first pass and prototyped it; four critics (draw dependence, MAP exposure, all-cause mortality, survival model and
     interpretation) raised 35 issues with probes; a verifier confirmed 16 and partly confirmed 19 (none refuted),
     correcting magnitudes where overstated. The prototype reproduces the v13 point estimates exactly with all noise off.
     Probe scripts are in the session scratchpad, which is temporary: move what is needed into the repo before relying on it. -->

# Uncertainty intervals for the PfPR-ACM burden (Snow primary v13): first pass, and how it could mislead

Unless stated, figures are for 2024, use UN IGME all-cause deaths, and cover the 42 countries. The point estimate is 625,627 deaths, or 3.50 per 1,000 child-years. Probe numbers are reviewer estimates from scratch scripts; none are in the repo. The probe tags in brackets are listed with their full paths at the end. No repo file was edited.

## 1. What uncertainty information we have

| Input | In the repo | Form | Gap |
|---|---|---|---|
| MAP PfPR2-10 (release 202508) | Mean surface only, 2000–2024 (`R_inputs/fetch/01_fetch_data.R:23`, `R_inputs/02_extract_map_pfpr.R:60-61`) | 2.5′ rasters | The repo keeps band 1 (the estimate) only. MAP's platform API gives **national PfPR2-10 with LCI and UCI** for all 42 of our countries and every year 2000–2024 (`/map-platform-app-backend/api/v1/trends/malaria/Pf_PR-rate/admin0/{mean,lci,uci}?version=202508` on data.malariaatlas.org, read 1 November 2026; admin-1 is also served) [map_api]. The interval level is not stated. These are marginal intervals, with no correlation between countries or years. MAP's national means match ours closely: r = 0.996 and median absolute difference 0.7 pp over all country-years. The larger gaps are mostly in 2000–2001, where MAP uses its own population surface and we use GPW 2020. Eswatini is the exception, at 18.3% (ours) against 0.6% (MAP) in 2000. The raster coverage also has per-pixel LCI and UCI bands. Neither service has realisations. A newer release, 202608 (2000–2025), is also served. |
| UN IGME all-cause deaths | Median plus LOWER/UPPER for each country, year and age group (TMM0, TMM1T11, TMY1T4, TMY0T4). `04` reads OBS_VALUE only (`04_annual_comparison.R:69`). | Marginal bounds, no draws | The coverage level is not stated (assumed 90%). The bounds do not add across ages. ARR, infant and 1–59-month bounds are only in the full UNICEF dump; the trimmed extract leaves them out (`R_inputs/trim_unicef_fusion.R:22`). |
| Survival model (PfPR spline) | `Vp`, `Vc` and `Ve` in each `map_full_age_g.rds`. `pfpr_components.rds` holds only the Vp block (`R_cbh/primary/01_fit.R:125-127`). | 4×4 per band | No covariance between bands, because the seven bands are fitted separately. It can be estimated from the saved fits in seconds [m1]. |
| WPP child-years | Point values only | — | No bounds anywhere, so death totals are conditional on WPP. |
| IHME all-cause | Value/Lower/Upper. Bounds are dropped at `04:75` (dcast on Value) and kept but unused in `00_national_inputs.R:81-84`. | Marginal bounds | Level assumed 95%. The 2024 bounds behave differently from earlier years (correlation across ages 0.67 in 2024, about 0 before). |
| CA-CODE malaria deaths and fraction | Death bounds at `04:55-57`, labelled 90%. Fraction with bounds in `data/external/cacode/unicef_cacode_u5_malaria_fraction_2000_2024.csv`. | Marginal bounds | The level is described inconsistently (`04:57` against `20_malaria_share_vs_pfpr.R:84`). The death bounds include UN IGME envelope error. |
| IHME malaria | Lower/Upper are in the CSV, but only Value is kept (`04:50`) | Marginal bounds | — |
| HIV imputation (Nigeria) | 200 draws (`data/derived_cbh/hiv_incidence/child_incidence_draws.rds`); the primary uses the median | Draws | Effect on the total is ±0.27% [m4]. It can be ignored. |

## 2. First-pass algorithm

"500 draws from each model" has to mean D **joint** draws. Draw d uses spline draw d (the same for every country and year), MAP draw d and UN IGME draw d. It is not 500³ combinations, and the quantiles of each source must never be combined afterwards.

The prototype is `uq_first_pass.R` [uq]. With every source of noise switched off it reproduces v13 exactly (largest difference 6e-10, and the same 14 crisis country-years). Steps marked **[cheap fix]** are additions that keep the approach simple.

1. **Stage.** Add a new script, `R_cbh/burden/06_uncertainty_draws.R`, to run after `04` with `CBH_PRIMARY_VERSION=snow_merge` (`04` defaults to v9, `04:11`). It reads `04`'s outputs, the IGME CSV and the saved fits.
   - Do not edit `01_fit.R`. Its hash enters the fit signature, so any edit forces all seven bands to refit (`01_fit.R:41-44,69,73`).
   - Use one RNG stream per component (`L'Ecuyer-CMRG`).
   - Use D = 4,000 rather than 500 **[cheap fix]**. At 500 draws the Monte Carlo SD of each 2024 bound is about 1% of the point (6,100–6,900 deaths); at 4,000 it is 0.36%. The run takes about 70 s [m2].
2. **Spline.** For each band, take `Vc[ix,ix]` from the saved fit. Check the file's md5 against `fit_manifest.csv`, and check that its coefficients and Vp match `pfpr_components.rds`.
   - Draw from Vc rather than Vp **[cheap fix]**, which adds smoothing-parameter uncertainty. The SE ratio Vc/Vp is 1.01–1.54 [p5b].
   - Each band's draw is shared by every country and year.
3. **MAP.** P⁽ᵈ⁾꜀ₜ is the population-weighted national mean of realisation r(d), using the weights at `04:129-135`. A sparse country × cell matrix does this in 0.1 s per realisation-year. The spline is not refitted.
   - Until realisations exist, replace the logit placeholder with draws from a logit-normal fitted to MAP's national mean, LCI and UCI for each country-year. Centre the draws on our own national value (Section 4, item 4) **[cheap fix]**. The draws carry the continental component that partly cancels in the AF (pitfall (a)3), so treat the MAP contribution as an upper bound.
4. **AF.** Compute the AF as at `04:157-160`, with the drawn inputs. Keep negative AF draws (1.5% of cells, all at low PfPR), and apply the ≥0 check to the point estimate only.
5. **UN IGME.** Use a split lognormal fitted to L, M and U, with z = 1.645 because the bounds are taken to be 90% **[cheap fix: coverage conversion]**.
   - Correlate the age groups with ρ꜀ₜ, calibrated to the under-5 bounds by the delta method.
   - Draw countries independently.
   - Hold each country's error constant over years. This is a first-pass assumption; see 3(c)2.
6. **Age split and crisis rule.** Split the age groups into bands as at `04:202-211`.
   - **Fix the crisis flags** at `04`'s point classification (`crisis_year`) **[cheap fix]**. In each draw, replace the flagged years with that draw's own log-linear interpolation (`04:255-259`).
   - Re-running `find_crises` in every draw would tie the classification to the assumed time structure. With rough AR(1) errors, 22–28% of draws would flag a spurious 2024 crisis and break the check at `25_country_rates_table.R:73` [a2, dep_p2].
7. **Aggregates and contrasts inside each draw** **[cheap fix]**. Compute the country rates, the 42-country rate (ΣA/Σpop, `04:291-301`), the 2024/2000 ratio, model/CA-CODE and UN IGME − IHME within each draw. For the IHME rows, apply AF⁽ᵈ⁾ to IHME deaths, for both the crisis-free series and the series without the crisis rule (the latter feeds Table 2).
8. **Report.** The headline is `04`'s deterministic point. The 95% UI is the 2.5% and 97.5% quantiles of the draws. Store the draw median and mean as diagnostics, and round to 3 significant figures **[cheap fix]**.
9. **Checks.**
   - A run with no noise reproduces `04`.
   - The draws reproduce L and U.
   - The covariance of the β draws is close to Vc.
   - The crisis flags are the same in every draw.
   - Monte Carlo error is estimated from independent batches of draws.

```r
D <- 4000; zq <- qnorm(0.95)                                    # 90% IGME bounds (assumed)
Vc[[g]] <- readRDS(fit_path[g])$fit$Vc[ix, ix]                  # md5 checked vs fit_manifest.csv
B[[g]]  <- MASS::mvrnorm(D, comp[[g]]$coef, Vc[[g]])            # D x 4, shared over c, t
P[d,c,t] <- if (have_map) 100 * (W[[t]] %*% real[[r(d), t]])[c] / rowSums(W[[t]])[c] else P0[c,t]
AF[d,c,t,g] <- -expm1(drop((X_g(0) - X_g(P[d,c,t])) %*% B[[g]][d, ]))   # 04:157-160
rho[c,t] <- clip01(delta_rho(M, L, U, zq))
z <- sqrt(rho[c,t]) * u[d,c] + sqrt(1 - rho[c,t]) * e[d,c,k]    # constant over t (first pass)
G[d,c,k,t] <- M[k,c,t] * exp(z * ifelse(z > 0, log(U/M), log(M/L)) / zq)
Db[, g] <- G[d,c,k_of[g], ] * share[g]                          # 04:202-211
Db[cr0[c, ], g] <- interp_loglinear(Db[, g] / pop[c, ], cr0[c, ]) * pop[c, cr0[c, ]]  # flags fixed
A[d,c,] <- rowSums(Db * AF[d,c,,]); rate42[d,t] <- 1000 * sum(A[d,,t]) / sum(pop[,t])
ui <- quantile(x_d, c(.025, .975)); point <- value_from_04
```


**Where the width comes from in the prototype** (2024, 42 countries, UN IGME-based deaths, 500 draws; relative to the
point estimate of 626,000; `uq_first_pass_42country.csv`):

| Source drawn | 95% UI (deaths) | Relative |
|---|---|---|
| Survival-model spline only (Vc, bands independent) | 540,000–704,000 | −13.7% / +12.5% |
| UN IGME all-cause only (split lognormal, 90% bounds) | 574,000–705,000 | −8.2% / +12.7% |
| MAP placeholder only (logit SD 0.25, countries independent; **invented**) | 578,000–654,000 | −7.7% / +4.5% |
| All three, paired draws | 527,000–751,000 | −15.7% / +20.0% |

With Vp in place of Vc the spline-only interval is −10.4% / +9.9%, close to the earlier review's 560,000–688,000.

**Prototype result** [uq], with 500 draws, Vc, bands independent, UN IGME and the MAP placeholder at τ = 0.25:
- 2024: 3.50 per 1,000 (2.95–4.20), or 626,000 deaths (527,000–751,000).
- 2000: 10.66 per 1,000 (9.55–11.70).
- Paired 2024/2000 ratio: 0.328 (0.298–0.371). Dividing one year's bounds by the other's would give 0.252–0.440, which is wrong.

## 3. How it could be wrong or misleading

Items are ranked by severity within each group. All magnitudes are reviewer estimates.

### (a) Interval width is wrong (mostly too narrow)

1. **Age bands drawn independently (medium-high).**
   - **Problem.** The seven separate fits store no covariance between bands, so the first pass sets it to zero. The likelihood factorises over bands, so the correlation comes from cluster-level deviations that the bands share, not from the same children appearing in several bands. Cluster-summed score influences give a mean correlation of 0.20 between bands for log HR(20% vs 0), clustering at survey:unit level, and higher for adjacent bands [m1, dep_p3].
   - **Size.** The spline-only 2024 interval goes from −13%/+12% to about −17%/+15.5%. The full interval goes from about −16.5%/+20% to −20%/+23%. The 2000 rate interval is about 40% wider (9.58–11.63 becomes 9.14–12.04) [dep_p7, v2]. Trend ratios barely move.
   - **Size of the alternative.** A single draw shared by all bands (−32%/+28%) is an upper bound that the data reject.
   - **Fix.** Section 4, item 1.
2. **Variation between countries in the PfPR effect, mostly Chad (medium).**
   - **Problem.** For 12–23 months, the country-clustered SE of log HR(40% vs 0) is 0.132, against 0.075 from Vc [m1]. But Chad contributes about 50% of the one-step jackknife sum of squares. Without Chad the jackknife SD is 6.8%, against 6.3% from Vc [m5]. Dropping Chad alone moves the 2024 total by about −7.1% (one-step approximation, not a refit).
   - **Size.** With country clusters the main interval is −24.7%/+25.8%. That rests mostly on Chad; a Chad-robust interval is about −20%/+23%.
   - **Fix.** Use survey:unit clusters in the main run. Run country clusters and leave-Chad-out as sensitivities.
3. **MAP not propagated, and the obvious way to add it over-counts (medium).**
   - **What MAP's national intervals show.** The intervals imply a logit SD (if they are 95%) of 0.34 in 2024: that is the median over our 42 countries, with a range of 0.08–1.66. Mid-period it is 0.12–0.15 (2010–2015), and 0.25 in 2000 [map_api]. So a constant τ = 0.25 is too narrow for 2024 and too wide for 2010–2015. Uncertainty is largest in the latest years, so it widens the 2015–2024 comparison as well as the 2024 total.
   - **What the first pass does.** There are no realisations, in the repo or on MAP's server. The placeholder (τ = 0.25, countries independent) adds about 0.7 points to each side of the 42-country interval [exp_p4]. For countries below 10% PfPR it supplies 42% of the squared log-width of the country interval, which is invented [exp_p3].
   - **Why plugging in realisations over-counts.** The spline was fitted on the same surface. A continental shift that moves both the fit exposure and the national exposure largely cancels in the AF (reasoned).
   - **Size.** The MAP-only "common error" interval (−17.8%/+14.4%) should not be added [dep_p5]. Local spatial correlation that is not shared with the fit raises the MAP SD by ×1.1–1.4 [exp_p3].
   - **Fix.** Propagate each country's deviation from the continental component, and do not refit on each realisation (see (b)1).
4. **IHME all-cause not drawn (medium).**
   - **Problem.** The IHME bounds are dropped at `04:75`, so the IHME rows carry only spline and MAP error. The difference in width between the two sources is therefore an artefact.
   - **Size.** Drawing IHME widens the 2024 IHME-based rate from 2.79–3.69 to 2.71–3.82 (+23% width). The 2024/2015 ratio interval becomes six times wider [a3].
   - **Fix.** Draw IHME the same way as UN IGME (95% level assumed), with 2024 calibrated separately.
5. **Country intervals assume one pooled curve (medium).**
   - **Problem.** Every country uses the same curve draw, so country intervals leave out real differences between countries in the PfPR effect.
   - **Size.** Subregion curves move the 2000 estimates for COD (−32%), CAF (−27%) and CMR (−23%) outside their first-pass intervals [m3]. These shifts are descriptive, since the subset curves have their own sampling error. Six countries have no fitting data; they hold 0.8% of 2024 deaths.
   - **Fix.** Label the country intervals as conditional on a common curve, and add a subregion-sensitivity column to Table S1.
6. **Minor items (low).**
   - A single age-group correlation makes the 1–59-month envelope too narrow: −16.0%/+18.4% becomes −16.4%/+18.9% with a calibrated 3×3 correlation [a1, a3].
   - UN IGME and the survival model share DHS/MICS birth histories. This cannot be measured; a correlation of r = 0.1 gives −19.5%/+22.8% [a4].
   - Smoothing parameters are very uncertain (SD of log λ 0.9–1.7, with γ = 2), and Vc is only a first-order correction [m1].
   - Negligible: fixed age-split shares (±0.1–0.3%), within-unit clustering, unweighted records, conditional against marginal AF, and the single HIV imputation [a4, m1, m4].

### (b) Problems that shift the centre

1. **Measurement error in the fit's MAP exposure (medium).**
   - **Why the current fit is close.** The fit uses MAP posterior means. That is Berkson error to first order, which leaves the curve nearly unbiased: the total moves only −0.3% to −1.4% at τ 0.1–0.25 [exp_p2b].
   - **Why refitting is wrong.** The obvious way to propagate this error, refitting on each MAP realisation, imputes exposure without conditioning on mortality. That attenuates the curve: −11.7% at τ 0.25 and −33% at τ 0.5 [exp_p2b].
   - **Classical error.** A share of classical error would also bias the total down (−10.5% at τ 0.25), but this is speculative.
   - **Fix.** Keep the fit on the posterior mean and state the Berkson assumption. Optionally, run SIMEX on one band (about 150 s per refit).
2. **Structural choices that lie outside the UI (medium).**
   - Reference at 1.85% PfPR instead of 0: −8.9%.
   - Curve fitted to records after 2012.7: +10.5%.
   - Subregion curves: −1.3% (−6.6% in 2000).
   - IHME all-cause instead of UN IGME: −6.5%.
   - AF averaged over polygons: −1.4% to −2.1%.
   - IHME age split: −2.0%.

   These figures come from [m2] and earlier reviews. All of them fall inside the UI, but none is sampling uncertainty. A 5% reference gives about 475,000 (−24%), which is a different estimand.

   PfPR from 0 to 19% is a single cubic segment (`R_cbh/primary/reference_knots.csv`), so part of the precision at f(0) comes from the basis rather than the data (reasoned) [m3].
3. **Jensen and centring effects (low).**
   - The AF is concave in PfPR (elasticity 0.44). The draw mean is −0.5% to −1.1% from the point at τ 0.25 [exp_p1].
   - The draw median is +0.5% from the point, from the split-lognormal UN IGME draws.
   - Keep the point as the headline, and report draw mean minus point.

### (c) Problems in how intervals would be compared or described

1. **The CA-CODE comparison and the "42% higher" claim (high).**
   - **Problem.** CA-CODE deaths are the CA-CODE fraction times the UN IGME envelope (median ratio 1.0003 over 1,001 country-years). Their bounds include the envelope error and are 2.3 times wider than the fraction-only bounds [v1]. Holding CA-CODE fixed counts the envelope error on one side only. Showing model bars beside CA-CODE's published bars counts it twice.
   - **Size, 42 countries.** The model/CA-CODE ratio is 1.42. Its interval is 1.19–1.69 with CA-CODE fixed, 1.15–1.77 with independent bars, and 1.20–1.63 with the envelope paired [a3].
   - **Size, countries.** Of the 37 countries whose point ratio exceeds 1, the interval lies wholly above 1 in 19 with CA-CODE fixed, 14 with independent bars and 22 with the envelope paired [a4].
   - **What this means for the claim.** With the envelope paired and the unit-level joint covariance, P(ratio > 1) ≈ 1. The excess holds up against sampling error, but less well against structural choices: a 1.85% reference gives 1.30, and a 5% reference about 1.08 [m2].
   - **The estimands differ.** CA-CODE counts deaths with malaria as the underlying cause, while PfPR-ACM includes indirect deaths. The ratio's interval therefore measures how much larger our estimate is, not whether the two disagree.
   - **Aggregates.** Never sum country bounds to get an aggregate. For CA-CODE in West and Central Africa, summed bounds give ±27.6% against the published ±14% [p4].
2. **Trends (medium).**
   - **UN IGME errors over time.** Holding UN IGME errors constant over years conflicts with the published 2015–2024 ARR bounds, which imply a median correlation of 0.48 between those years [dep_p1]. Calibrating to them widens the 2000→2024 ratio by 15–30% (0.298–0.371 becomes 0.293–0.377) and the 2015→2024 ratio by 37–55% [dep_p2, dep_p7]. Single-year levels do not change.
   - **MAP over time.** A MAP placeholder held constant over years cancels in trend ratios by construction.
   - **Curve over time.** The curve is assumed not to change over time. Period-specific curves give a ratio of 0.361, which is inside the main UI [m2].
   - **What survives.** The fall from 10.7 to 3.5 per 1,000 survives every variant. Any 2015–2024 claim is the most exposed.
3. **UN IGME against IHME country ratios (medium).** With only UN IGME drawn, 9 countries have a ratio interval that excludes 1; with IHME also drawn, 5 do [a4]. The Results' range of 0.47–1.52 needs both sources drawn.
4. **Labelling (medium).**
   - **The UI is conditional.** It assumes the model: causal interpretation, the PfPR = 0 counterfactual, one curve pooled across countries and constant over time, the basis, and γ = 2. Death totals are also conditional on WPP population, and the UI leaves out MAP until realisations exist. Call it "95% UI for sampling uncertainty in …", not "the uncertainty".
   - **Other figures disagree.** Figure S7 (`20_malaria_share_vs_pfpr.R:41-46`) and the under-5 probability figure (`13_under5_death_probability.R:40`) use Vp, bands drawn independently and the spline only. They would show different intervals for the same 2024 share.
   - **95% tails are extrapolated.** The 2.5% and 97.5% points lie beyond the published 90% bounds. UN IGME alone gives SSD −80%/+244% in 2024 [a2].

## 4. Recommended second pass

1. **Joint spline covariance.**
   - V_J = blockdiag(Vc_g) + R − blockdiag(Ve_g), where R comes from the survey:unit cluster-summed scores of the saved fits. Project V_J to positive semi-definite and make one 28-dimensional draw.
   - It needs only the saved fits and takes about 10 s [m1].
   - Sensitivities: country clusters and leave-Chad-out.
2. **Pair the comparators.**
   - CA-CODE⁽ᵈ⁾ = CA-CODE × (F⁽ᵈ⁾/F) × (E⁽ᵈ⁾/E), where E is the drawn UN IGME 1–59-month deaths and F⁽ᵈ⁾ is drawn from the fraction bounds (normal truncated at 0).
   - Draw IHME all-cause (keep Lower/Upper at `04:75`) and IHME malaria (`04:50`).
   - Compute takes seconds.
3. **UN IGME time and age structure.**
   - Add CME_ARR_U5MR, CME_TMY0 and CME_TMM1T59 to `R_inputs/trim_unicef_fusion.R:22`.
   - Over years, use a smooth Gaussian-copula kernel calibrated to each country's ARR correlation, clipped to 0.05–0.95. Across ages, use a 3×3 correlation calibrated to the three published composites.
   - Check that the draws reproduce the ARR bounds and the UNICEF_SSA aggregate bounds. Keep the crisis flags fixed.
   - Compute takes seconds.
4. **MAP realisations.**
   - Request at least 100, ideally 500, realisations from the 202508 run that are joint across 2000–2024. National extraction takes about 4 minutes for 100 realisations.
   - Ask MAP for the correlation between countries and between years too. The national intervals cannot give it, and it sets the width of the sub-Saharan total and of the trend.
   - Until the realisations arrive, use MAP's national intervals [map_api]:
     - Fit a logit-normal to each country-year's mean, LCI and UCI, or a split logit-normal where they are asymmetric. Confirm the interval level with MAP first.
     - Apply the spread around our own national value.
     - For the sub-Saharan total, run two cases that bound the truth: countries independent, and countries perfectly correlated. Bound the correlation between years the same way for the 2015–2024 comparison.
     - The per-pixel LCI and UCI bands are not needed for this.
   - Check Eswatini's national PfPR: ours is 18.3% in 2000 against MAP's 0.6%, far more than population weights explain.
   - Propagate country deviations from the continental component, with the fit kept on the posterior mean.
   - Centre the draws so they preserve the mean, and check that the mean of the realisations reproduces `national_pfpr_2000_2024.csv` to within 0.05 pp.
   - Bootstrap the Monte Carlo error over realisations as well. At R = 100, the SD of the 2.5% quantile is about 14% of the half-width [EXP-06].
5. **Structural sensitivity table, kept outside the UI.**
   - Reference at 1.85% and at 5%.
   - Period curves and subregion curves.
   - IHME all-cause.
   - Leave-Chad-out.
   - AF averaged over polygons.
   - Crisis threshold at 1.20 and 1.30.
   - A basis with knots near 2% and 5% (refitting all seven bands, about 20 minutes).
   - γ = 1 on one band (about 150 s).
6. **Consistent figures.** Have Figure S7 and `13_under5_death_probability.R` read their intervals from `06`'s draw file.

## 5. Open questions for the author

1. MAP's API has national (and per-pixel) LCI and UCI but no realisations. Should we propagate the national intervals, with the correlation between countries bounded, and also request realisations (and UN IGME posterior trajectories)? Or should we publish with MAP stated as not propagated?
2. Can you confirm the coverage levels: UN IGME 90%, IHME 95%, CA-CODE 90%? And should we report 95% intervals, which extrapolate the tails, or 90% intervals?
3. Which cluster level should the spline use, survey:unit or country? Should Chad be handled as a sensitivity, or allowed to widen the main interval?
4. Are you content to state two independence assumptions?
   - Countries are independent. The published regional bounds support this.
   - UN IGME is independent of the survival model. This is argued, not tested; should we report the r = 0.1 sensitivity?
5. Should the headline be the deterministic point (recommended) or the draw median?
6. How should Figure 5 show the comparison: a ratio interval, paired bars with a caveat, or the share scale, where the envelope cancels?
7. Which trend claims will the paper make: 2000→2024 only, or also 2015→2024?
8. Should we give intervals for deaths, or for rates only, with deaths labelled as conditional on WPP?

## Probe index

Outputs (`.out` and `.csv`) share each script's stem in the same folder.

- [uq] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/uq_first_pass.R
- [map_api] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/map_api/ (fetch_trends.R; map_admin0_pfpr_202508.csv and map_admin0_pfpr_202608.csv, which hold iso3, year, mean, lci and uci; layer and band metadata)
- [p1c] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/p1c_pixels_per_country.R
- [p4] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/p4_cacode.R
- [p5b] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/p5b_vp_vc.R
- [m1] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/m1_cluster_sandwich.R
- [m2] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/m2_spline_interval_probes.R (outputs m2_structural.csv, m2_vs_cacode.csv, m2_mc_error.csv)
- [m3] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/m3_country_heterogeneity.R
- [m4] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/m4_hiv_one_step.R
- [m5] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/m5_country_jackknife.R
- [dep_p1] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/dep_p1_igme_time_corr.R
- [dep_p2] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/dep_p2_igme_dependence.R
- [dep_p3] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/dep_p3_band_correlation.R
- [dep_p5] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/dep_p5_map_dependence.R
- [dep_p7] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/dep_p7_main_combined.R
- [exp_p1] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/exp/exp_p1_national_map_errors.R
- [exp_p2b] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/exp/exp_p2b_error_structure_sim.R
- [exp_p3] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/exp/exp_p3_spatial_averaging.R
- [exp_p4] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/exp/exp_p4_combined_map_share.R
- [a1] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/all/a1_igme_structure.R
- [a2] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/all/a2_igme_only_and_crisis.R
- [a3] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/all/a3_combined.R
- [a4] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/all/a4_country_claims.R
- [v1] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/verify/v1_cacode_envelope.R
- [v2] /private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/uncertainty/verify/v2_band_cov_delta.R