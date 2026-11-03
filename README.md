# Reassessing the contribution of *P. falciparum* malaria to child mortality in Africa

Code and inputs for the paper of this title (Watson, Darji, Kamau, …, Snow; in preparation).

Malaria deaths are estimated from complex statistical models which assign each death to a single cause, with cause
fractions derived primarily from verbal autopsy data, ignoring indirect mortality effects. This analysis instead pools
survey data from sub-Saharan Africa since 2000 with prevalence estimates from the Malaria Atlas Project (MAP) to
characterise the relationship between prevalence of infection and all-cause mortality in children under 5, and from it
estimates malaria-attributable mortality.

## What the analysis does

1. **Child age bands.** Complete birth histories from DHS, MIS and UNICEF MICS surveys are split into seven age bands
   (<1 month, 1–5 months, 6–11 months, then yearly to 5 years). A band is included if the child entered it alive in
   the 60 months before the interview, in 2000–2024, and the band ended before the interview.
2. **Units and exposure.** Each record is matched, through its lowest reported administrative unit, to one or a union
   of the 535 malaria-endemic GADM 4.1 admin-1 units (survey-units; KEMRI-Wellcome merge, with national boundaries
   for Botswana, Ghana, Kenya, Madagascar, Malawi, mainland Tanzania and Uganda). Units mostly in the malaria-free and
   island areas of Snow et al. (2017), or without a MAP estimate, are excluded. Each band takes the MAP *Pf*PR₂₋₁₀
   (release 202608) of its survey-unit in its calendar year of entry.
3. **Model.** Seven binomial generalised additive models with a complementary log-log link (one per age band; a
   proportional-hazards model for grouped survival times), each with a penalised spline of *Pf*PR₂₋₁₀, a spline of
   calendar time, 17 confounders (13 survey-unit summaries from the survey recodes and 4 national measures) and random
   intercepts for survey, country and survey-unit.
4. **Malaria-attributable mortality.** Each band's attributable fraction, 1 − exp{f(0) − f(P)} at MAP's national
   *Pf*PR₂₋₁₀, is applied to UN IGME all-cause deaths (IHME as a sensitivity analysis) in 42 countries, 2000–2024, and
   compared with the CA-CODE and IHME estimates of malaria deaths. 95% uncertainty intervals come from 500 joint draws
   of the *Pf*PR–mortality curves, MAP's national *Pf*PR₂₋₁₀ and the all-cause deaths.
5. **Sensitivity analyses.** The Sahel and UN M49 sub-regions, survey period, without wasting and stunting, country
   fixed effects, and imputed covariates.

## Table S1: national estimates for 2024

Malaria prevalence (*Pf*PR₂₋₁₀, MAP's national estimates) and under-five mortality in 2024 by country: all-cause deaths,
*Pf*PR-ACM malaria-attributable deaths and cause-specific malaria deaths per 1,000 child-years, with the share of all
under-five deaths (%) in square brackets and, for *Pf*PR-ACM, the 95% uncertainty interval in parentheses. Rows run
from the highest to the lowest prevalence; the last row is the 42-country population-weighted average. These values
are those of the GADM-unit primary v15 (MAP release 202608, run of 3 November 2026), copied from
`paper/tables/country_rates_2024.latex.txt`; refresh this copy after every rerun.

| Country | *Pf*PR₂₋₁₀ (%) | All-cause, UN IGME | All-cause, IHME | *Pf*PR-ACM, UN IGME-based | *Pf*PR-ACM, IHME-based | Malaria deaths, UN IGME (CA-CODE) | Malaria deaths, IHME |
|---|--:|--:|--:|--:|--:|--:|--:|
| Benin | 35.4 | 16.0 | 14.3 | 4.86 (3.1–7.0) [30] | 4.62 (3.4–5.6) [32] | 3.12 [19] | 3.10 [22] |
| C. African Rep. | 32.1 | 20.8 | 24.3 | 5.80 (2.8–8.5) [28] | 6.89 (3.2–9.4) [28] | 5.28 [26] | 3.12 [13] |
| Burundi | 31.8 | 9.9 | 18.4 | 2.73 (1.4–5.0) [28] | 5.44 (3.7–7.0) [30] | 1.65 [17] | 6.06 [33] |
| Sierra Leone | 29.2 | 19.8 | 24.5 | 5.97 (3.1–8.3) [30] | 7.10 (3.8–9.1) [29] | 5.85 [30] | 5.47 [22] |
| Burkina Faso | 28.8 | 16.1 | 11.9 | 4.89 (2.8–7.9) [30] | 3.24 (2.3–4.0) [27] | 2.57 [16] | 2.35 [20] |
| DR Congo | 28.8 | 19.5 | 14.3 | 5.83 (4.3–8.2) [30] | 4.27 (3.0–5.9) [30] | 5.32 [25] | 4.26 [30] |
| Malawi | 27.7 | 10.3 | 11.7 | 2.19 (1.4–3.2) [21] | 3.06 (2.1–3.8) [26] | 0.98 [9] | 1.89 [16] |
| Côte d'Ivoire | 25.4 | 13.8 | 14.8 | 3.31 (2.2–4.5) [24] | 3.62 (2.6–4.3) [24] | 1.24 [9] | 2.50 [17] |
| Mozambique | 25.3 | 12.8 | 13.3 | 2.92 (2.0–4.0) [23] | 3.30 (2.6–4.0) [25] | 1.78 [14] | 1.82 [14] |
| South Sudan | 25.2 | 20.7 | 23.1 | 4.68 (0.93–15.4) [23] | 6.29 (4.5–7.4) [27] | 2.58 [12] | 3.44 [12] |
| Guinea | 24.9 | 20.0 | 17.6 | 5.42 (3.5–7.7) [27] | 4.85 (3.4–5.9) [28] | 3.09 [15] | 2.97 [17] |
| Zambia | 24.5 | 10.3 | 10.8 | 2.33 (1.7–3.1) [23] | 2.85 (2.3–3.3) [27] | 0.81 [8] | 1.46 [14] |
| Uganda | 24.1 | 10.2 | 12.3 | 2.26 (1.4–3.0) [22] | 3.17 (2.0–4.2) [26] | 1.53 [15] | 3.43 [28] |
| Nigeria | 24.1 | 25.3 | 19.0 | 7.03 (4.0–9.4) [28] | 5.34 (2.9–6.9) [28] | 4.89 [19] | 3.58 [19] |
| Angola | 23.9 | 10.6 | 13.1 | 2.68 (1.5–4.5) [25] | 3.60 (2.5–4.7) [27] | 0.75 [7] | 2.45 [19] |
| Togo | 23.5 | 13.9 | 12.9 | 3.60 (2.0–5.5) [26] | 3.41 (2.2–4.2) [27] | 1.82 [13] | 1.65 [13] |
| Cameroon | 23.2 | 13.8 | 15.0 | 3.60 (2.2–5.4) [26] | 4.12 (3.0–5.2) [27] | 1.41 [10] | 3.21 [21] |
| Eq. Guinea | 21.8 | 14.6 | 11.2 | 3.34 (1.2–7.1) [23] | 2.60 (1.6–3.5) [23] | 0.36 [3] | 3.56 [32] |
| Rep. of Congo | 21.3 | 8.2 | 10.4 | 1.84 (0.77–4.2) [22] | 2.53 (1.8–3.1) [24] | 0.59 [7] | 1.89 [18] |
| Niger | 19.6 | 24.8 | 24.7 | 6.43 (3.9–9.3) [26] | 7.05 (4.7–9.4) [29] | 4.99 [20] | 3.66 [15] |
| Gabon | 17.8 | 6.7 | 7.5 | 1.11 (0.59–1.9) [17] | 1.46 (0.95–1.9) [19] | 0.09 [1] | 1.13 [15] |
| Mali | 17.2 | 16.1 | 18.5 | 3.44 (2.5–4.6) [21] | 4.10 (2.9–5.2) [22] | 1.64 [10] | 2.72 [15] |
| Ghana | 16.8 | 7.5 | 9.2 | 1.24 (0.82–1.8) [17] | 1.68 (1.2–2.2) [18] | 0.32 [4] | 1.57 [17] |
| Liberia | 14.6 | 18.6 | 19.0 | 3.26 (2.0–4.7) [18] | 3.43 (2.2–4.7) [18] | 4.50 [24] | 3.42 [18] |
| Chad | 14.0 | 21.4 | 22.5 | 4.52 (2.3–7.5) [21] | 4.44 (2.4–6.0) [20] | 3.89 [18] | 1.19 [5] |
| Tanzania | 9.5 | 7.8 | 9.1 | 0.80 (0.49–1.1) [10] | 1.02 (0.68–1.4) [11] | 0.66 [8] | 1.01 [11] |
| Madagascar | 9.0 | 13.3 | 12.1 | 1.74 (1.0–2.7) [13] | 1.60 (1.00–2.3) [13] | 2.00 [15] | 1.04 [9] |
| Guinea-Bissau | 6.6 | 14.4 | 15.3 | 1.48 (0.22–4.1) [10] | 1.41 (0.23–3.2) [9] | 1.13 [8] | 0.73 [5] |
| Kenya | 5.3 | 8.2 | 7.0 | 0.41 (0.08–1.1) [5] | 0.47 (0.09–1.1) [7] | 0.31 [4] | 0.47 [7] |
| Ethiopia | 4.0 | 9.3 | 11.5 | 0.43 (0.18–0.89) [5] | 0.53 (0.24–0.97) [5] | 0.36 [4] | 0.54 [5] |
| Comoros | 3.5 | 8.2 | 9.3 | 0.25 (0.13–0.43) [3] | 0.40 (0.24–0.65) [4] | 0.12 [1] | 0.03 [0] |
| The Gambia | 3.3 | 8.9 | 11.2 | 0.37 (0.22–0.56) [4] | 0.50 (0.37–0.68) [4] | 0.43 [5] | 0.34 [3] |
| Somalia | 2.9 | 22.4 | 18.0 | 1.13 (0.37–3.0) [5] | 0.93 (0.45–1.7) [5] | 0.25 [1] | 0.28 [2] |
| Rwanda | 2.2 | 7.9 | 10.9 | 0.24 (0.09–0.47) [3] | 0.41 (0.16–0.69) [4] | 0.38 [5] | 1.22 [11] |
| Senegal | 2.2 | 7.7 | 8.6 | 0.20 (0.13–0.29) [3] | 0.24 (0.17–0.32) [3] | 0.26 [3] | 0.28 [3] |
| Mauritania | 1.9 | 7.8 | 8.2 | 0.17 (0.10–0.28) [2] | 0.19 (0.13–0.26) [2] | 0.21 [3] | 0.29 [4] |
| Djibouti | 1.5 | 10.2 | 9.4 | 0.14 (0.06–0.30) [1] | 0.16 (0.11–0.21) [2] | 0.19 [2] | 0.11 [1] |
| Eritrea | 1.3 | 7.2 | 11.5 | 0.14 (0.07–0.30) [2] | 0.30 (0.19–0.43) [3] | 0.32 [4] | 0.04 [0] |
| Zimbabwe | 0.7 | 13.6 | 11.0 | 0.08 (0.04–0.13) [1] | 0.12 (0.08–0.16) [1] | 0.23 [2] | 0.13 [1] |
| Namibia | 0.3 | 7.5 | 7.4 | 0.02 (0.01–0.03) [0] | 0.03 (0.02–0.04) [0] | 0.11 [1] | 0.03 [0] |
| Eswatini | 0.0 | 9.4 | 10.1 | 0.00 (0.00–0.00) [0] | 0.00 (0.00–0.00) [0] | 0.01 [0] | 0.00 [0] |
| Botswana | 0.0 | 6.8 | 4.8 | 0.00 (0.00–0.00) [0] | 0.00 (0.00–0.00) [0] | 0.00 [0] | 0.00 [0] |
| **All 42 countries** | **18.6** | **15.6** | **14.8** | **3.51 (2.9–4.1) [23]** | **3.36 (2.6–3.8) [23]** | **2.46 [16]** | **2.41 [16]** |

## Running it

- R 4.6.0 with the package versions that `run_pipeline.R` checks, Python 3, and about 16 GB of memory.
- Put the DHS, MIS and MICS microdata in `data/raw/` and the GADM 4.1 admin layers (KEMRI-Wellcome merge) in
  `data/Africa GADM 0-2 (040226)/` ([data/README.md](data/README.md)), and download the MAP rasters:
  `Rscript R_inputs/fetch/fetch_map_release_rasters.R 202608 2000 2024`. Every other input is committed.
- Run everything (about 5 hours; network access is blocked during the run):

  ```bash
  ./run_detached.sh --all
  ```

  `Rscript run_pipeline.R --list` shows the stages and which are complete; `--from=STAGE` and `--only=STAGE` re-run
  part of it. Logs are in `logs/`.
- Results are written to `results/cbh/` (the primary analysis is `primary_gadm_merge_dhsmics_gamma2_v15`), and the
  figures, tables and captions used in the paper are exported to `paper/`.

## Layout

```
run_pipeline.R   runs every stage in order          run_detached.sh   the same, detached from the terminal
R_inputs/        survey-region MAP PfPR, region centroids and the UNICEF extracts; fetch/ = download scripts
R_mics/          MICS conversion to the DHS layout, regions, PfPR, child bands
R_cbh/           child bands, covariates, HIV model, GADM units (units/), primary model (primary/), burden and
                 uncertainty (burden/), figures and tables (reporting/), sensitivity analyses (sensitivity/)
tools/           restore of the frozen inputs and HIV panels, DHS PR/HW recode import, output comparison, the
                 microdata commit guard
data/            committed inputs and manifests        paper/   figures, tables and captions for the manuscript
```

Figure text sizes follow the rule in [CLAUDE.md](CLAUDE.md).

## Licence

The code is released under CC0 1.0 (`LICENSE`). Committed third-party inputs keep their own terms (see
[data/README.md](data/README.md)), notably IHME's terms of use. DHS and MICS microdata are not redistributed.
