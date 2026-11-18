# Reassessing the contribution of *Plasmodium falciparum* malaria to child mortality in Africa

Code and inputs for the paper of this title (Watson, Darji, Kamau, Gill, Okiro, Guérin, Snow; in preparation). The text
below follows the paper.

## Summary

**Background.** Malaria deaths are estimated from complex statistical models which assign one death to a single cause
whilst ignoring the indirect effects of malaria infection on child survival. We pooled survey data from sub-Saharan
Africa with prevalence of infection estimates to characterise the combined direct and indirect impact of malaria on
all-cause mortality during the first five years of life.

**Methods.** We fitted multivariable age-specific proportional hazards models to survival outcomes in children under
5, with prevalence of infection in children 2–10 years of age (*Pf*PR₂₋₁₀) as the exposure, adjusted for confounders.
Malaria-attributable fractions were applied to national all-cause mortality estimates from 42 sub-Saharan African
countries from 2000 to 2024.

**Results.** Among 2,347,261 children (108,747 deaths), the hazard ratio for death at 40% *Pf*PR₂₋₁₀, relative to 0%,
was 1.08 (95% confidence interval [CI], 1.02 to 1.14) in neonates, 1.27 (95% CI, 1.17 to 1.39) at 1–5 months, 1.66
(95% CI, 1.50 to 1.84) at 6–11 months, and 1.88 to 2.44 at 1–4 years. Assuming no residual confounding, this implied
malaria-attributable fractions between 7% (neonates) and 47% to 59% (1–4 years). In 2024, the model estimated 627,000
(95% uncertainty interval [UI], 511,000 to 732,000) malaria-attributable deaths (23% of under-5 deaths), compared with
440,000 malaria deaths in current estimates (42% more; 95% UI, 15 to 59).

**Conclusions.** The impact of malaria infection on childhood mortality is considerably higher than current estimates.

## Methods

### Data sources

Complete birth histories were obtained from the Births Recodes of the Demographic and Health Surveys and Malaria
Indicator Surveys (DHS/MIS) and from UNICEF Multiple Indicator Cluster Surveys (MICS). Ages were grouped in 7 discrete
bands: <1 month, 1–5 months, 6–11 months, 1–2 years, 2–3 years, 3–4 years and 4–5 years. An age band was eligible for
inclusion in the analysis if the child entered it alive in the 60 months before the interview and in a calendar year
between 2000 and 2024, and the whole band ended before the interview, irrespective of the survival outcome.
(`R_cbh/01_make_analysis_data.R`, `R_mics/`)

The analysis was done at the sub-national level. The geographic units were the first-level administrative units
(admin-1; for example states, provinces or regions) of malaria-endemic sub-Saharan Africa from the Database of Global
Administrative Areas (GADM) version 4.1 with minor amendments. Each survey record was matched to one admin-1 unit, or
to a union of units where the survey's location spanned several, using the lowest-level administrative unit reported
in the survey; we denote these as survey-units. Of the 568 units, 31 were malaria free and 2 were islands, leaving 535
endemic units. (`R_cbh/units/`, [R_cbh/units/README.md](R_cbh/units/README.md))

*Plasmodium falciparum* prevalence estimates were taken from the Malaria Atlas Project (MAP) annual modelled surfaces
of the parasite rate standardised to ages 2 to 10 years (*Pf*PR₂₋₁₀) for 2000 until 2024 (release 202608). Each age
band was assigned a *Pf*PR₂₋₁₀ estimate based on its corresponding survey-unit and the calendar year of entry into the
band. (`R_inputs/`, `R_cbh/units/02_pfpr_polygons.R`)

To estimate malaria-attributable mortality, national all-cause deaths at <1 month, 1–11 months and 1–4 years were
obtained from UN IGME, with the UN World Population Prospects (WPP) population under 5 to determine the child-years at
risk. Estimates of under-five malaria deaths were obtained from the Child and Adolescent Causes of Death Estimation
(CA-CODE) 2026 series disseminated through the UN IGME portal. A sensitivity analysis used IHME Global Burden of
Disease all-cause deaths and person-years by age.

### Covariate adjustment

Covariate selection was guided by a simplified causal diagram, used to select variables that are common causes of
transmission intensity and mortality and that lie off the causal pathway. We did not adjust for long-lasting
insecticide treated net coverage or indoor residual spraying because these determine prevalence only, and
corresponding reductions in mortality are mediated by the reductions in transmission.

Covariate adjustment included 13 survey-unit level summaries (means or percentages computed separately for each
survey) and 4 national level measures. From the DHS Births Recodes, we computed mean maternal age at first live birth,
mean maternal education, mean household wealth quintile, percentage of urban residence, coverage of the third dose of
the diphtheria, tetanus toxoid, and pertussis vaccine (DTP3), coverage of the first dose of the measles vaccine,
delivery in a health facility, and proportion with short birth intervals. From the household and height and weight
recodes we computed the proportion with an improved drinking-water source, improved sanitation facility, electricity,
and the prevalence of wasting and stunting. Estimates of national child HIV incidence were taken from the UNAIDS 2025
estimates. Estimates of the annual gross domestic product per capita, current health expenditure per capita and
political stability and absence of violence were taken from the World Bank. HIV incidence, GDP and health expenditure
were log transformed. (`R_cbh/units/09_covariates_dhs.R`, `R_cbh/units/10_covariates_mics.R`, `R_cbh/covariates/`,
`R_cbh/hiv/`)

In the primary analysis, missing DTP3 and measles coverage was replaced by the WHO/UNICEF national estimate (WUENIC),
and any other missing survey-unit summary by the mean of the survey's other units. Records with a covariate still
missing were excluded: 822,434 of 8,624,561 eligible records (9.5%) and 13,296 of 122,043 deaths (10.9%). Nearly all
came from 25 surveys in which a covariate was unavailable for every area, most often anthropometry (38% of excluded
records), place of delivery (25%) and national health expenditure (22%). These records were included in the
multiple-imputation sensitivity analysis. (`R_cbh/primary/00_prepare.R`)

### Statistical model

The unit of observation was the child age band record and the outcome was death versus survival during the age band.
We fitted seven separate models, one per age band, because both the effect of *Pf*PR₂₋₁₀ and the effects of the
confounding variables could differ by age band. Each model was a binomial generalised additive model with a
complementary log-log link and an offset equal to the log band width in years, so that the linear predictor is the log
annualised mortality hazard, giving a proportional-hazards model for grouped survival times.

The linear predictor comprised a penalised cubic regression spline of *Pf*PR₂₋₁₀ by survey-unit at band entry (basis
dimension 5), a penalised cubic regression spline of calendar time at band entry (basis dimension 6), the 17
standardised covariates entered linearly, and independent Gaussian random intercepts for survey, country and
survey-unit. Hazard ratios between two prevalence levels X and Y were calculated as exp{f(Y) − f(X)} from the fitted
spline f of each age band. Confidence intervals used the Bayesian coefficient covariance matrix conditional on the
estimated smoothing parameters. (`R_cbh/primary/`)

### Malaria-attributable mortality

The relationship between *Pf*PR₂₋₁₀ and mortality was estimated sub-nationally, but all-cause mortality estimates are
available only by country, so malaria-attributable mortality was estimated nationally based on the fitted model. For
each country and year, the malaria-attributable fraction of all-cause mortality for each age band was calculated as
1 − exp{f(0) − f(x)}, where x is the MAP national estimate of *Pf*PR₂₋₁₀ for the corresponding country and year. The
malaria-attributable mortality rate was then calculated by multiplying this fraction with the all-cause mortality rate
for the age group. We refer to this approach as the *Pf*PR-all-cause mortality (*Pf*PR-ACM) model.

In the primary analysis we used UN IGME all-cause death estimates, which are reported in age bands of <1 month, 1–11
months, and 1–4 years. Deaths between 1–11 months and 1–4 years were split across the age bands of the model in
proportion to the deaths observed in the survey sample. Estimates were produced annually for 2000 until 2024, in the
42 sub-Saharan African countries with national MAP estimates. Because the malaria-attributable fraction of deaths will
not generalise to periods of crisis (conflict, famine), crisis years took crisis-free values (14 of the 1,050
country-years, in the Central African Republic, Malawi, Somalia and South Sudan). We estimated 95% uncertainty
intervals (UI) from 500 random draws from the three separate models (the prevalence-mortality model, MAP prevalence
estimates, and UN IGME all-cause mortality estimates). (`R_cbh/burden/`)

### Sensitivity analyses

We refitted the seven age-band models to subsets of the primary sample: the UN M49 sub-regions of Western, Central and
Eastern Africa; surveys conducted up to or after the median survey year, 2014; and age bands entered up to or after
the median calendar date of entry (late 2012). Multiple imputation using chained equations was used to fit the models
to the full dataset. We refitted the primary models excluding the wasting and stunting covariates, because measures of
malnutrition could mediate the relationship between *Pf*PR₂₋₁₀ and death, or confound it. (`R_cbh/sensitivity/`)

## Results

Of 217 DHS, MIS and MICS surveys conducted in sub-Saharan Africa since 2000, 171 recorded complete birth histories.
The primary analysis included 136 surveys (99 DHS and 37 MICS) from 37 countries. These data contained 1,127,215
complete birth histories contributing 7,802,127 child age band records from 2,347,261 children of whom 108,747 died.

Under the *Pf*PR-ACM model, the population-weighted average malaria-attributable mortality rate across the 42 malaria
endemic countries fell from 10.4 (95% UI, 9.3–11.2) deaths per 1,000 child-years in 2000 to 3.5 (95% UI, 2.9–4.1) in
2024. In 2024, the model estimated 627,000 (95% UI, 511,000 to 732,000) malaria-attributable deaths in children under
5. This was 42% (95% UI, 15 to 59) greater than the CA-CODE estimate of 440,000 deaths, and the *Pf*PR-ACM estimates
were higher in 31 of the 42 countries.

### Figures and tables of the paper

Every figure and table is written to `results/cbh/` and exported, with a caption note, to `paper/`.

| In the paper | File in `paper/` | Made by |
|---|---|---|
| Figure 1: complete birth histories by administrative unit | `figures/fig1_analysis_units_map.png` | `R_cbh/reporting/23_analysis_units_map.R` |
| Figure 2: hazard ratio by age | `figures/fig2_hazard_ratio_by_age.png` | `R_cbh/reporting/26_hazard_ratio_by_age.R` |
| Figure 3: malaria-attributable fraction by age | `figures/fig3_malaria_attributable_fraction_by_age.png` | `R_cbh/reporting/06_attributable_fraction_by_age.R` |
| Figure 4: prevalence, all-cause and malaria-attributable mortality, 2000–2024 | `figures/fig4_malaria_mortality_rates_unigme.png` | `R_cbh/reporting/24_malaria_mortality_rates.R` |
| Figure 5: *Pf*PR-ACM against CA-CODE by country, 2024 | `figures/fig5_model_vs_cause_specific_2024.png` | `R_cbh/reporting/27_model_vs_cause_specific.R` |
| Supplementary: units of the regional sub-analyses | `Supplementary Figures/sfig_subregion_units_map.png` | `R_cbh/sensitivity/subgroups/04_subregion_units_map.R` |
| Supplementary: data sources and analysis flow | `Supplementary Figures/sfig_study_flow.png` | `R_cbh/reporting/01_study_flow.R` |
| Supplementary: refits by UN sub-region and by period | `Supplementary Figures/sfig_pfpr_splines_by_subregion.png`, `sfig_pfpr_splines_by_period.png` | `R_cbh/sensitivity/subgroups/02_report.R` |
| Supplementary: multiply imputed covariates | `Supplementary Figures/sfig_pfpr_splines_imputed_covariates.png` | `R_cbh/sensitivity/imputation_dhsmics/06_report.R` |
| Supplementary: without wasting and stunting | `Supplementary Figures/sfig_pfpr_splines_without_nutrition.png` | `R_cbh/sensitivity/nutrition/02_report.R` |
| Supplementary: Figure 4 with IHME all-cause mortality | `Supplementary Figures/sfig_malaria_mortality_rates_ihme.png` | `R_cbh/reporting/24_malaria_mortality_rates.R` |
| Supplementary: *Pf*PR-ACM with IHME against UN IGME all-cause mortality | `Supplementary Figures/sfig_malaria_rates_ihme_vs_unigme_2024.png` | `R_cbh/reporting/28_malaria_rates_ihme_vs_unigme.R` |
| Supplementary: malaria share of under-five deaths against prevalence | `Supplementary Figures/sfig_malaria_share_vs_pfpr.png` | `R_cbh/reporting/20_malaria_share_vs_pfpr.R` |
| Supplementary: survival against prevalence by sub-region | `Supplementary Figures/sfig_survival_vs_pfpr_by_subregion.png` | `R_cbh/sensitivity/subgroups/03_survival_by_subregion.R` |
| Supplementary: Figure 5 on log scales, and with IHME | `Supplementary Figures/sfig_model_vs_cause_specific_log_2024.png`, `sfig_model_vs_cause_specific_ihme_2024.png` | `R_cbh/reporting/27_model_vs_cause_specific.R` |
| Supplementary table: national estimates for 2024 | `tables/country_rates_2024.latex.txt` | `R_cbh/reporting/25_country_rates_table.R` |
| Supplementary table: records excluded for a missing covariate | `tables/excluded_records_by_survey.latex.txt` | `R_cbh/reporting/29_excluded_records_table.R` |

The causal diagram of the supplement was drawn by hand and is not generated here.

### National estimates for 2024

National malaria prevalence (*Pf*PR₂₋₁₀, MAP national estimates) and under-five mortality in 2024, by country:
all-cause deaths (UN IGME), *Pf*PR-ACM malaria-attributable deaths with 95% uncertainty intervals, and CA-CODE malaria
deaths, per 1,000 child-years, each with its share of all under-five deaths. Rows run from the highest to the lowest
prevalence; the last row is the 42-country population-weighted average. Copied from
`paper/tables/country_rates_2024.latex.txt`; refresh this copy after every rerun.

| Country | *Pf*PR₂₋₁₀ (%) | All-cause deaths per 1,000 (UN IGME) | *Pf*PR-ACM: deaths per 1,000 (95% UI) | *Pf*PR-ACM: % of deaths | CA-CODE: deaths per 1,000 | CA-CODE: % of deaths |
|---|--:|--:|--:|--:|--:|--:|
| Benin | 35.4 | 16.0 | 4.9 (3.1–7.0) | 30 | 3.1 | 19 |
| C. African Rep. | 32.1 | 20.8 | 5.8 (2.8–8.5) | 28 | 5.3 | 26 |
| Burundi | 31.8 | 9.9 | 2.7 (1.4–5.0) | 28 | 1.7 | 17 |
| Sierra Leone | 29.2 | 19.8 | 6.0 (3.1–8.3) | 30 | 5.8 | 30 |
| Burkina Faso | 28.8 | 16.1 | 4.9 (2.8–7.9) | 30 | 2.6 | 16 |
| DR Congo | 28.8 | 19.5 | 5.8 (4.3–8.2) | 30 | 5.3 | 25 |
| Malawi | 27.7 | 10.3 | 2.2 (1.4–3.2) | 21 | 1.0 | 9 |
| Côte d'Ivoire | 25.4 | 13.8 | 3.3 (2.2–4.5) | 24 | 1.2 | 9 |
| Mozambique | 25.3 | 12.8 | 2.9 (2.0–4.0) | 23 | 1.8 | 14 |
| South Sudan | 25.2 | 20.7 | 4.7 (0.9–15.4) | 23 | 2.6 | 12 |
| Guinea | 24.9 | 20.0 | 5.4 (3.5–7.7) | 27 | 3.1 | 15 |
| Zambia | 24.5 | 10.3 | 2.3 (1.7–3.1) | 23 | 0.8 | 8 |
| Uganda | 24.1 | 10.2 | 2.3 (1.4–3.0) | 22 | 1.5 | 15 |
| Nigeria | 24.1 | 25.3 | 7.0 (4.0–9.4) | 28 | 4.9 | 19 |
| Angola | 23.9 | 10.6 | 2.7 (1.5–4.5) | 25 | 0.7 | 7 |
| Togo | 23.5 | 13.9 | 3.6 (2.0–5.5) | 26 | 1.8 | 13 |
| Cameroon | 23.2 | 13.8 | 3.6 (2.2–5.4) | 26 | 1.4 | 10 |
| Eq. Guinea | 21.8 | 14.6 | 3.3 (1.2–7.1) | 23 | 0.4 | 3 |
| Rep. of Congo | 21.3 | 8.2 | 1.8 (0.8–4.2) | 22 | 0.6 | 7 |
| Niger | 19.6 | 24.8 | 6.4 (3.9–9.3) | 26 | 5.0 | 20 |
| Gabon | 17.8 | 6.7 | 1.1 (0.6–1.9) | 17 | 0.1 | 1 |
| Mali | 17.2 | 16.1 | 3.4 (2.5–4.6) | 21 | 1.6 | 10 |
| Ghana | 16.8 | 7.5 | 1.2 (0.8–1.8) | 17 | 0.3 | 4 |
| Liberia | 14.6 | 18.6 | 3.3 (2.0–4.7) | 18 | 4.5 | 24 |
| Chad | 14.0 | 21.4 | 4.5 (2.3–7.5) | 21 | 3.9 | 18 |
| Tanzania | 9.5 | 7.8 | 0.8 (0.5–1.1) | 10 | 0.7 | 8 |
| Madagascar | 9.0 | 13.3 | 1.7 (1.0–2.7) | 13 | 2.0 | 15 |
| Guinea-Bissau | 6.6 | 14.4 | 1.5 (0.2–4.1) | 10 | 1.1 | 8 |
| Kenya | 5.3 | 8.2 | 0.4 (0.1–1.1) | 5 | 0.3 | 4 |
| Ethiopia | 4.0 | 9.3 | 0.4 (0.2–0.9) | 5 | 0.4 | 4 |
| Comoros | 3.5 | 8.2 | 0.3 (0.1–0.4) | 3 | 0.1 | 1 |
| The Gambia | 3.3 | 8.9 | 0.4 (0.2–0.6) | 4 | 0.4 | 5 |
| Somalia | 2.9 | 22.4 | 1.1 (0.4–3.0) | 5 | 0.2 | 1 |
| Rwanda | 2.2 | 7.9 | 0.2 (0.1–0.5) | 3 | 0.4 | 5 |
| Senegal | 2.2 | 7.7 | 0.2 (0.1–0.3) | 3 | 0.3 | 3 |
| Mauritania | 1.9 | 7.8 | 0.2 (0.1–0.3) | 2 | 0.2 | 3 |
| Djibouti | 1.5 | 10.2 | 0.1 (0.1–0.3) | 1 | 0.2 | 2 |
| Eritrea | 1.3 | 7.2 | 0.1 (0.1–0.3) | 2 | 0.3 | 4 |
| Zimbabwe | 0.7 | 13.6 | 0.1 (0.0–0.1) | 1 | 0.2 | 2 |
| Namibia | 0.3 | 7.5 | 0.0 (0.0–0.0) | 0 | 0.1 | 1 |
| Eswatini | 0.0 | 9.4 | 0.0 (0.0–0.0) | 0 | 0.0 | 0 |
| Botswana | 0.0 | 6.8 | 0.0 (0.0–0.0) | 0 | 0.0 | 0 |
| **All 42 countries** | **18.6** | **15.6** | **3.5 (2.9–4.1)** | **23** | **2.5** | **16** |

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

The stages, in order: `restore` and `inputs` (frozen inputs, MAP prevalence), `hiv_panels` (child HIV incidence; `hiv`
refits the model and is optional), `dhs_bands` and `mics` (child age bands), `covariates`, `units` and
`unit_covariates` (geographic units, prevalence and covariates), `primary` (the seven models, malaria-attributable
mortality, and the paper's figures and tables), `subgroups`, `nutrition` and `imputation` (sensitivity analyses),
`validate` and `export`.

## Layout

```
run_pipeline.R   runs every stage in order          run_detached.sh   the same, detached from the terminal
R_inputs/        survey-region MAP PfPR and the UNICEF extracts; fetch/ = download scripts
R_mics/          MICS conversion to the DHS layout, regions, PfPR, child bands
R_cbh/           child bands, covariates, HIV model, GADM units (units/), primary model (primary/), burden and
                 uncertainty (burden/), figures and tables (reporting/), sensitivity analyses (sensitivity/)
tools/           restore of the frozen inputs and HIV panels, DHS PR/HW recode import, the microdata commit guard
data/            committed inputs and manifests        paper/   figures, tables and captions for the manuscript
```

Figure text sizes follow the rule in [CLAUDE.md](CLAUDE.md).

## Data access and sharing

This study complied with the Guidelines for Accurate and Transparent Health Estimates Reporting (GATHER). All input
data are publicly available: DHS/MIS and MICS microdata from the DHS Program and UNICEF; UN IGME, UN WPP, CA-CODE,
WHO/UNICEF immunisation and UNAIDS child HIV estimates from UNICEF; IHME estimates from the GBD Results tool;
*Pf*PR₂₋₁₀ from the Malaria Atlas Project; World Bank indicators; GPWv4 from NASA SEDAC; and GADM 4.1 boundaries.

## Licence

The code is released under CC0 1.0 (`LICENSE`). Committed third-party inputs keep their own terms (see
[data/README.md](data/README.md)), notably IHME's terms of use. DHS and MICS microdata are not redistributed.
