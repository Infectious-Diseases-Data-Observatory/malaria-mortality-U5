# Uncertainty in malaria-attributable mortality: specification

500 joint draws (seed 20261101); 95% uncertainty intervals are the 2.5% and 97.5% quantiles; point estimates are the deterministic values of 04_annual_comparison.R.

- PfPR-death spline: each age band's PfPR coefficients drawn from MVN(beta, Vc), which includes smoothing-parameter uncertainty; one draw per band shared by every country and year; bands independent.
- MAP national PfPR2-10 (release 202608): split logit-normal per country-year fitted to MAP's mean and lower and upper bounds, taken as a 95% interval, applied as a spread around the national PfPR used by the burden; one draw per country held over its years; countries independent (sensitivity: one draw shared by all countries).
- All-cause deaths: UN IGME under-five deaths by age group (<1 month, 1-11 months, 1-4 years; bounds taken as 90%) and IHME deaths by age (six ages; 95%), split lognormal around the published values, with a common factor across ages calibrated to the published under-five bounds where they allow (where they are narrower than independent ages would give, the ages are independent; counts in checks.csv); one draw per country held over its years; countries and sources independent. Population and person-years fixed.
- Crisis years are held at the point classification; in each draw their band rates are interpolated from that draw's neighbouring non-crisis years.
- Comparators: CA-CODE and IHME malaria deaths are scaled in each draw by the drawn under-five envelope of their own source; their cause-fraction uncertainty is not included.
- Not included: structural choices (one pooled curve, the PfPR = 0 counterfactual, gamma = 2), correlation between countries' MAP errors other than the sensitivity, and the partial cancellation of continental MAP error between the fit and the burden (so the MAP part is an upper bound).

2024: 627,000 malaria-attributable deaths (95% UI 511,000-732,000) with UN IGME all-cause deaths; 596,000 (467,000-677,000) with IHME.
Monte Carlo SD of the 2024 UN IGME bounds at 500 draws: 8,000 and 9,000 deaths.
