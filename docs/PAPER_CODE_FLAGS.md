# Paper and code: items to check

This repository holds only what the manuscript (`main.tex` in the Overleaf project, as of 1 October 2026) describes. This note lists:

- **A.** what the code needs that `main.tex` does not describe (kept, and flagged here);
- **B.** where `main.tex` and the code disagree;
- **C.** analyses left out because `main.tex` does not describe them.

Line numbers refer to `main.tex` as of 1 October 2026.

## A. Needed by the analysis but not described in main.tex

| # | Item | Where in this repository |
|---|---|---|
| A1 | Liberia's child HIV incidence is derived from UNAIDS AIDSinfo counts divided by the child population. The only methods text about it is commented out (L255). | `R_cbh/hiv/03_add_liberia_aidsinfo.R`, `data/unaids_aidsinfo/` |
| A2 | Uganda 2016's north and south Buganda regions are admitted as Central 1 and Central 2 (14,495 records, 156 deaths). | `R_cbh/config/region_overrides.csv` |
| A3 | Sierra Leone 2013 regional values are recomputed from its recodes, including the household-member (PR) file, because the published DHS API rows are mis-assigned. | `R_cbh/covariates/17_recode_replacements.R` |
| A4 | The regional covariate derivation corrections of 28 September 2026. MICS: vaccination under the DHS tabulation rules, completed-grade education, facility delivery, water and sanitation coding, Mozambique 2008. DHS: Uganda 2016 wealth decoding. | `R_mics/09_regional_covariates.R`, `R_mics/education_level_map.csv`, `R_cbh/covariates/regional.R` |
| A5 | Region matching between recodes, boundaries and published indicators: survey rules, region overrides, published-region aliases, versions, gap reviews and exclusions. | `R_cbh/config/`, `R_cbh/covariates/published_*.csv`, `R_mics/config/region_overrides.csv` |
| A6 | Spline knots are fixed to the original MAP fits (a committed snapshot), not recomputed. | `R_cbh/primary/reference_knots.csv` |
| A7 | Fits that fail the convergence or Hessian checks are refitted with strict tolerances, e.g. some subgroup bands. | `R_cbh/primary/01_fit.R` and the sensitivity fit scripts |
| A8 | Nigerian state PfPR uses malariaAtlas admin-1 shapes with GPW density weights. This differs slightly from the national method, which uses density × cell area. | `data/pfpr_admin1_ng_cd_2024.csv`, `R_inputs/fetch/pfpr_admin1_ng_cd_2024.R` |
| A9 | Figure 4 method: synthetic-cohort probability of dying before age 5 from IHME age-band rates; intervals from independent draws of the age-band log hazard ratios; IHME's own malaria-caused probability. | `R_cbh/reporting/13_under5_death_probability.R` |
| A10 | Supplementary Figure S6 uses the CA-CODE 2026 published malaria *fraction* of under-five deaths. Its denominator is CA-CODE's own cause total (DR Congo 2024: 428,472 deaths against 385,039 in UN IGME). Countries flagged for WHO malaria estimates are drawn hollow. | `R_cbh/reporting/20_malaria_share_vs_pfpr.R`, `data/external/cacode/` |
| A11 | The 2024 agreement statistics in the results text: Spearman ρ = 0.91, model above IHME in 36 of 42 countries, median ratio 1.6 (L108). In the analysis project these were produced only by the 1%-floor sensitivity, which is not in the paper. They are now computed by a primary-pipeline script (identical values). | `R_cbh/reporting/21_country_agreement_2024.R` |
| A12 | The WHO World Malaria Report 2025 death series in Table 2 is transcribed by hand from the report's tables. | `R_inputs/who_wmr2025_tables.R` |
| A13 | Two different 2024 MAP rasters are used: `data/pfpr_2to10_africa_2024.tif` for the national burden and `data/map_annual/pfpr2_10_2024.tif` for the survey-region exposure. Their md5s differ. | `data/` |
| A14 | The IHME GBD round and export dates are not stated: all-cause by age exported 9 September 2026, malaria by age 3 September 2026, Nigerian states 16 September 2026. | `data/INPUTS_MANIFEST.csv` |
| A15 | Details of the HIV incidence model: Stan; adolescent and child series; latent adolescent path for countries without one; posterior-median panel in the primary; draws for the imputation sensitivity. The paper uses the panels fitted on 8 September (base) and 18 September 2026 (extended). A refit with the current code reproduces every reported country-year, but imputed country-years differ by Monte Carlo error (median 6%, maximum 31%), so the pipeline uses the frozen panels (user decision, 4 October 2026). | `R_cbh/hiv/`, `data/frozen/`, `tools/use_frozen_hiv.R` |
| A16 | The full list of national imputations in the imputed-covariate sensitivity (v10) includes Somalia health expenditure and South Sudan GDP, health expenditure and political stability. | `R_cbh/sensitivity/imputation_dhsmics/01_impute_national.R` |
| A17 | The Guinea-Bissau and CAR MICS regions use the Snow prevalence project's Africa admin-1 shapefile. | `data/external/snow_admin1/`, `R_mics/04_boundaries_gnb_caf.R` |
| A18 | Child-band files still carry four legacy candidate columns that the model does not use: national HIV prevalence, Hib3, PCV and rotavirus coverage. They are kept so that the rebuilt files match the paper's. They could be removed in a later version without changing any result. | `R_cbh/00_config.R` (`annual_panels`), `data/frozen/data/derived_dhs/hiv_prevalence_country_year.csv` |
| A19 | The DHS survey-region centroids that define the Sahel subgroup were a stored table with no producing script. A producer now exists and reproduces it (coordinates within 1e-13°). | `R_inputs/dhs_region_centroids.R` |
| A20 | The causal diagram (Figure 5) is drawn by hand (`Causal_diagram.pptx` → PDF). No code produces it. | Overleaf `figures/` |

## B. Disagreements between main.tex and the code (for the authors to fix in the text)

| # | main.tex | Code / results |
|---|---|---|
| B1 | Table S1 (L347–370) shows the DHS-only v3 values (5,465,305 records, 75,726 deaths). | The v9 table is `paper/tables/age_band_results.latex.txt` (7,621,617 records, 104,143 deaths), matching L77. |
| B2 | L269 says the model equations are in SText 1, but `SText1_model_specification.tex` describes the archived negative-binomial "Method 2" (600 survey-regions, 1% floor). It also needs `figures/sfig1_spec_comparison.png`, which does not exist. | The current formula is `results/cbh/primary_map_regional17_dhsmics_gamma2_v9/model_formula.txt`. |
| B3 | L188: "a larger 67% decrease between 2000 and 2015". | The 2000–2015 decline is 57%; 67% is 2000–2024 (Table 2). |
| B4 | L273: estimates "annually for 2004–2024". | The series covers 2000–2024. |
| B5 | Fig S1 caption (L307): "child HIV prevalence (UNAIDS 0–14 case counts divided by World Bank population)". | The model uses modelled child HIV *incidence* per 1,000 uninfected (`R_cbh/hiv/`). |
| B6 | L278 (multiple imputation): Liberia and São Tomé both use the latent HIV series; the list of national imputations is incomplete. | In v10, Liberia uses AIDSinfo counts (held fixed) and only São Tomé is latent; see A16. |
| B7 | L253 mentions São Tomé and Príncipe's HIV exclusion but not Liberia's derivation. | See A1. |
| B8 | Data sharing (L288) points to `Infectious-Diseases-Data-Observatory/burden-malaria-prevalence` and lists only GBD and DHS as data sources. | This repository is `malaria-mortality-U5`. The inputs also include MICS, MAP, GPW, UNAIDS/UNICEF, World Bank/WGI, UN IGME, CA-CODE and the Snow shapefile; DHS and MICS microdata require registration. |
| B9 | The Figure 3 caption mentions only IHME. | Panel C also shows UN IGME. |
| B10 | L267 describes a binomial likelihood "for the number of deaths among children entering each age band in each survey-region and entry month". | The fits use child-band records (Bernoulli with a band-width offset), with the same likelihood as the grouped binomial. |
| B11 | Fig S2 caption typo: "log hazard ration". | — |
| B12 | Figure 4 (`fig:cumulative_risk`) and Table S1 (`tab:primary-age-band-effects`) are never cited in the text. | — |
| B13 | L277 lists sensitivity analyses ("seasonal vs non-seasonal, West Africa vs East Africa, earlier vs later") that do not match the subgroups reported. | The subgroups are Sahel, Eastern Africa, and surveys up to vs after the median year (2014). |
| B14 | Licensing: the repository LICENSE is CC0. | CC0 can cover the code but not the third-party inputs (IHME, MAP, GPW, UNICEF/UNAIDS, World Bank, UN IGME, CA-CODE, Snow shapefile). See `data/README.md`. |

## C. Analyses in the analysis project that are not in this repository

None of these is described in `main.tex`. All remain in the analysis project (`R_cbh/sensitivity/<name>/` unless stated) with their results.

- PfPR × calendar-year tensor-product model, and its Figure 3 analogue (`tensor_pfpr_year`)
- PfPR forced linear on records with PfPR 1–30% (`linear_pfpr_1_30`)
- Without the survey-region random intercept (`no_region_re`)
- 1% prevalence floor as the counterfactual (`reference_floor`; its floor-0 agreement statistics are A11)
- SMC before/after (`smc`; uses GiveWell DataWell cluster data that must not leave the analysis project)
- Sahel mortality by calendar month (`R_cbh/seasonality/`)
- `bam` versus `gam` method check (`bam_vs_gam`; not rerun on v9)
- Covariate forest plot, covariate pairs plot, random-effects forest, calendar-year trend plot (`R_cbh/reporting/14`–`17`)
- Death-count version of Figure 3 (still produced in `burden_comparison/`, not exported)
- The malaria-share table for 42 countries (Overleaf `tables/` holds no copy)
- IHME vs UN IGME comparisons conditional on survival to 6 or 12 months (`R_cbh/reporting/18`, `19`)
- History versions v1–v8 of the primary, DHS-only analyses, and all `R_dhs/` model scripts
