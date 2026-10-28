# malaria-mortality-U5

Code and inputs for **"Reassessing the malaria mortality burden in African children"** (Watson, Darji, …, Guerin, Snow; manuscript in preparation).

The paper treats malaria transmission intensity, measured as *P. falciparum* prevalence in children aged 2–10 (*Pf*PR₂₋₁₀, from the Malaria Atlas Project), as a risk factor for all-cause death in children under 5. Complete birth histories from 136 DHS and UNICEF MICS surveys in 37 sub-Saharan African countries are split into seven age bands from birth to age 5. Since 11 October 2026 the geographic unit is the sub-national polygons of Snow et al. (2017): each record is placed, through its smallest reported administrative unit, in the malaria-endemic polygon holding at least 90% of that unit's population, or else in the union of the polygons each holding at least 5% ([R_cbh/snow/README.md](R_cbh/snow/README.md)). Each band is linked to the population-weighted *Pf*PR₂₋₁₀ of that unit in the band's calendar year. A separate binomial complementary log-log GAM is fitted to each band, with 17 adjustment covariates computed for each survey × unit from the DHS and MICS files. The fitted age-band hazard ratios, contrasting current *Pf*PR with zero, are then applied to IHME all-cause death rates. This gives the share and number of under-five deaths attributable to malaria, directly and indirectly, which are compared with IHME and UN IGME (CA-CODE) cause-specific estimates.

This repository contains only what the manuscript describes. The analysis was developed in a larger project; `docs/PAPER_CODE_FLAGS.md` lists:
- what the code needs that the manuscript does not describe;
- where the manuscript and the code disagree;
- the analyses left out.

## Status

| | |
|---|---|
| Primary analysis | **Snow-unit primary** (since 11 October 2026), `primary_snow520_merge_dhsmics_gamma2_v11`: DHS and MICS surveys placed in the Snow et al. (2017) polygons (merge rule), 17 covariates, MAP PfPR, γ = 2. South Sudan takes Sudan's GDP per capita, health expenditure per capita and political stability for band-entry years before independence (2011) (`R_cbh/primary/national_substitutions.R`). Branch `snow-polygon-primary`. |
| Sample | 136 surveys (99 DHS, 37 MICS) in 37 countries; 1,452 survey × unit areas (215 of them unions of polygons) in 465 polygons; 1,125,610 mothers; 2,335,868 children; 7,639,443 child-band records; 105,114 deaths |
| Sensitivities | Sahel, UN M49 West, Central and East Africa, and period (by survey year and by record calendar year) refits (`subgroups_snow520_merge_gamma2_v5`); without wasting and stunting (`nutrition_adjustment_snow520_merge_gamma2_v5`); imputed covariates (`primary_snow520_merge_imputed_gamma2_v12`) |
| Previous primary | v9 (`primary_map_regional17_dhsmics_gamma2_v9`, survey-regions; 629,136 attributable deaths in 2024) is kept as stage `primary_v9` and compared in `comparison_v9/` (586,723 under the Snow units, ratio 0.93) |
| Verified | The Snow unit construction reproduces the analysis project record for record ([verification/snow_reproduction.md](verification/snow_reproduction.md)); see [Verification](#verification) |

## Repository layout

```
run_pipeline.R      runs every stage in order (resumable; see below)
run_detached.sh     runs the pipeline detached from the terminal
R_inputs/           input producers: survey-region MAP PfPR (v9), UNICEF immunisation panel, region centroids, WHO WMR tables
  fetch/            network scripts that obtained the frozen inputs (not run by the pipeline)
R_cbh/              DHS child-band builder, covariates, HIV model, primary model, burden, reporting, sensitivities
  R/                shared builder functions          config/   survey rules and region overrides
  hiv/              child HIV incidence model (Stan)  covariates/  DHS regional covariates
  snow/             Snow et al. polygons: placement, analysis units (merge rule), unit PfPR and covariates, maps
  primary/          settings (snow_merge, v9), fits, effects, report  burden/  national inputs, annual and Nigerian-state burden
  reporting/        figures, tables, paper export     sensitivity/  subgroups, nutrition, imputation_dhsmics
R_mics/             MICS conversion to the DHS layout, boundaries, PfPR, child bands, covariates
tools/              import, restore, comparison and pre-commit checks
data/               committed inputs and manifests (see data/README.md); raw microdata in data/raw/ (ignored)
paper/              the figures, tables and captions exported for the manuscript by the verified run
verification/       comparison of the re-run with the analysis project's outputs, and of the 13 October run with the 12 October outputs (snow/)
docs/               PAPER_CODE_FLAGS.md
```

## Requirements

- R 4.6.0 with these packages:
  - mgcv 1.9-4, data.table 1.18.4, ggplot2 4.0.3, ragg 1.5.2, patchwork 1.3.2, ggrepel 0.9.8;
  - terra 1.9-34, sf 1.1-1, exactextractr 0.10.1, countrycode 1.8.0;
  - haven 2.5.5, readxl 1.4.5, mice 3.19.0, MASS 7.3-65, dplyr 1.2.1;
  - rstan 2.32.7 with StanHeaders 2.32.10 and a C++ toolchain.
- The fetch scripts also need rdhs, malariaAtlas, geodata, httr and jsonlite.
- Python 3 (standard library only).
- Collation locale `en_GB`, which the runner checks. Sorting, and so factor levels, depend on it.
- About 16 GB of memory, since one fit uses about 3 GB, and about 20 GB of disk for the derived files.
- `run_pipeline.R` stops if a package version differs from the recorded one (`--ignore-versions` overrides).

## Reproducing the analysis

1. Place the DHS, MIS and MICS microdata in `data/raw/` as described in [data/README.md](data/README.md), including the DHS household (PR) and height/weight (HW) recodes that the Snow-unit covariates need. Every other input is committed.
2. Run the whole pipeline, detached; it takes about 6 hours (the runner estimates 354 minutes):
   ```bash
   ./run_detached.sh --all
   ```
   - `Rscript run_pipeline.R --list` shows the stages and which have completed.
   - `--from=STAGE` re-runs a stage and everything after it; `--only=STAGE` re-runs one stage.
   - Logs are in `logs/`, and completion markers (with the commit and script md5s) in `logs/state/`.
3. The pipeline blocks network access and runs one process at a time.

| Stage | What it does | Time |
|---|---|---|
| `restore` | Copies the frozen DHS registry, DHS API pages and StatCompiler table into place | <1 min |
| `inputs` | Survey-region MAP PfPR (annual), UNICEF immunisation panel, DHS region centroids, WHO WMR tables | ~30 min |
| `hiv` | Refits the child HIV incidence model (base and extended), as a check | ~30 min |
| `hiv_panels` | Restores the paper's frozen HIV panels and draws, records the refit's differences, builds the Liberia panels from AIDSinfo counts | <1 min |
| `dhs_bands` | DHS/MIS child-band records (`R_cbh/01_make_analysis_data.R`) | ~6 min |
| `covariates` | DHS published indicators, recode summaries, WUENIC fallbacks, nutrition, first-birth age, complete-case audit | ~20 min |
| `mics` | MICS extraction, inventory, regions and boundaries, PfPR, BR-layout recodes, child bands, covariates | ~30 min |
| `primary_v9` | The v9 survey-region primary (comparison) | ~20 min |
| `snow_units` | Snow polygons, polygon PfPR, survey-region overlay, finer location units, label check, placement, analysis units | ~20 min |
| `snow_covariates` | The 13 regional covariates per survey × unit from the DHS (BR/PR/HW) and MICS files, with a national validation | ~12 min |
| `primary` | Snow-unit preparation, seven fits, effects, national burden, Figures 1–4, Tables 1, 2 and S1, Figs S1, S2 and S6, the supplementary survey map and timing | ~25 min |
| `snow_maps` | Per-country merge-unit maps, boundary-agreement map, comparison with v9 | ~2 min |
| `subgroups` | Sahel, UN M49 West, Central and East Africa, and period refits (Fig S3 and supplementary figures) | ~45 min |
| `nutrition` | Refits without wasting and stunting (Fig S5) | ~20 min |
| `imputation` | Imputed-covariate refits and the multiple-imputation propagation (Fig S4) | ~90 min |
| `validate` | Cross-checks of the reported numbers and provenance hashes | <1 min |
| `export` | Copies figures, tables and captions to `paper/` | <1 min |

`snow_repro` (optional; `--only=snow_repro` with `SNOW_POLYGONS_GPKG` pointing at the analysis project's polygon file) rebuilds the analysis project's population-share split dataset to check the ported unit construction.

`R_inputs/fetch/` contains the scripts that obtained the frozen inputs. They need network access, and some need DHS credentials. The pipeline never runs them.

## Paper figures and tables

Figure text must be larger than ggplot's defaults at printed size (axis and legend titles at least 12 pt; tick labels,
legend text and in-plot labels at least 10 pt); the rule and how to check it are in [CLAUDE.md](CLAUDE.md).

| Paper | File in `paper/` | Script |
|---|---|---|
| Figure 1: complete birth histories by Snow polygon | `figures/fig1_analysis_units_map.png` | `R_cbh/reporting/23_analysis_units_map.R` (lakes: `data/external/natural_earth/ne_10m_lakes.geojson`) |
| Figure 2: attributable fraction by age | `figures/fig2_malaria_attributable_fraction_by_age.png` | `R_cbh/reporting/06_attributable_fraction_by_age.R` |
| Figure 3: comparison with IHME and UN IGME | `figures/fig3_burden_comparison.png` | `R_cbh/reporting/11_burden_comparison_figure.R` |
| Figure 4: probability of dying before age 5 | `figures/fig4_under5_death_probability.png` | `R_cbh/reporting/13_under5_death_probability.R` |
| Figure 5: causal diagram | (drawn by hand; in the Overleaf project) | — |
| Main-text figure: malaria-attributable mortality rates, UN IGME all-cause (PfPR, all-cause and malaria-attributable rates by country, 2000–2024) | `figures/fig_malaria_mortality_rates_unigme.png` | `R_cbh/burden/04_annual_comparison.R` (estimates), `R_cbh/reporting/24_malaria_mortality_rates.R` |
| Supplementary figure: the same with IHME all-cause | `Supplementary Figures/sfig_malaria_mortality_rates_ihme.png` | as above |
| Supplementary table: 2024 country rates by source (PfPR, all-cause, PfPR-ACM and cause-specific malaria) | `tables/country_rates_2024.latex.txt` | `R_cbh/reporting/25_country_rates_table.R` |
| Table 1: country comparison | `tables/country_comparison_2024.latex.txt` | `R_cbh/reporting/09_burden_tables.R` |
| Table 2: source comparison 2000–2024 | `tables/source_comparison.latex.txt` | `R_cbh/reporting/12_source_comparison_table.R` |
| Table S1: age-band results | `tables/age_band_results.latex.txt` | `R_cbh/primary/03_report.R` |
| Fig S1: study flow | `Supplementary Figures/sfig_study_flow.png` | `R_cbh/reporting/01_study_flow_snow.R` |
| Fig S2: PfPR and mortality by age band | `Supplementary Figures/sfig_pfpr_mortality_by_age.png` | `R_cbh/primary/03_report.R` |
| Fig S3: Sahel subgroup | `Supplementary Figures/sfig_pfpr_splines_by_subgroup.png` | `R_cbh/sensitivity/subgroups/02_report.R` |
| Supplementary: UN M49 sub-regions | `Supplementary Figures/sfig_pfpr_splines_by_subregion.png` | `R_cbh/sensitivity/subgroups/02_report.R` |
| Supplementary: periods (survey year, record calendar year) | `Supplementary Figures/sfig_pfpr_splines_by_period.png` | `R_cbh/sensitivity/subgroups/02_report.R` |
| Supplementary: PfPR 40% to 20% by subset | `Supplementary Figures/sfig_pfpr_40_to_20_by_subgroup.png` | `R_cbh/sensitivity/subgroups/02_report.R` |
| Fig S4: imputed covariates | `Supplementary Figures/sfig_pfpr_splines_imputed_covariates.png` | `R_cbh/sensitivity/imputation_dhsmics/06_report.R` |
| Fig S5: without wasting and stunting | `Supplementary Figures/sfig_pfpr_splines_without_nutrition.png` | `R_cbh/sensitivity/nutrition/02_report.R` |
| Fig S6: malaria share against PfPR | `Supplementary Figures/sfig_malaria_share_vs_pfpr.png` | `R_cbh/reporting/20_malaria_share_vs_pfpr.R` |
| Supplementary: surveys and timing (Figure 1 until 12 October 2026) | `Supplementary Figures/sfig_survey_map_and_timing.png` | `R_cbh/reporting/03_survey_map.R` |
| Supplementary: survey-regions against Snow polygons | `Supplementary Figures/sfig_snow_boundary_agreement_map.png` | `R_cbh/snow/22_map_boundary_agreement.R` |
| Supplementary: merged units, one map per country | `Supplementary Figures/snow_merge_units/<ISO3>_merge_units.png` | `R_cbh/snow/21_map_merge_units.R` |
| Supplementary: Snow units against v9 | `Supplementary Figures/sfig_pfpr_curves_v9_vs_snow.png`, `tables/comparison_v9_vs_snow.md` | `R_cbh/reporting/22_compare_v9_snow.R` |
| Results text: 2024 agreement statistics | `results/cbh/…_v11/annual_comparison/country_agreement_2024.csv` | `R_cbh/reporting/21_country_agreement_2024.R` |

## Verification

**Snow-unit primary (11–13 October 2026).** The ported unit construction (`R_cbh/snow/`), run as `split_repro`, reproduces the analysis project's Snow dataset record for record: placement, units, covariates and the 9,690,169-row prepared dataset, with polygon PfPR within 6e-10 ([verification/snow_reproduction.md](verification/snow_reproduction.md)). The recode covariates of every DHS survey are checked against the published national values: 930 of 933 survey-indicator pairs agree within 2 points (median difference 0.03); the three exceptions (Benin 2006 sanitation, Mali 2001 water and sanitation) are surveys outside the complete-case sample. On 13 October 2026 all 17 stages ran at commit 3e2c721, with South Sudan and the new Figure 1 (run `20261013T083723`, 222.6 minutes). Three of them (`inputs`, `hiv` and `dhs_bands`) reused work saved on 12 October by run `20261012T121428`, which built them from scratch. All 11 validation checks pass (`results/cbh/primary_snow520_merge_dhsmics_gamma2_v11/paper_refresh/validation.txt`). Compared with the outputs of 12 October, the run reproduces them apart from the two author decisions, South Sudan and the new Figure 1 ([verification/snow/VERIFICATION_SNOW.md](verification/snow/VERIFICATION_SNOW.md)). The 60 files exported to `paper/` are now the Snow-unit versions. `paper/figures/fig1_survey_map_and_timing.png` is not part of this export. It is the 12 October survey map, without South Sudan; the current version is `paper/Supplementary Figures/sfig_survey_map_and_timing.png`. `main.tex` (L82) still includes `figures/fig1_survey_map_and_timing.png` as Figure 1, so the stale file should not be synced to Overleaf; the author decides whether to remove it. `main.tex` still describes v9.

**v9 (the previous primary).** On 2–4 October 2026 the whole pipeline was re-run from the raw microdata and compared with the analysis project's outputs ([verification/VERIFICATION.md](verification/VERIFICATION.md)):
- every figure, table and caption that the manuscript uses is byte-identical to the Overleaf file (27 of 27);
- the seven primary fits, the burden estimates (629,136 attributable under-five deaths in 2024 against 428,147 from IHME and 440,123 from UN IGME) and the three sensitivities are identical;
- the 120 DHS/MIS child-band files and all 581 extracted MICS files match.

The child HIV incidence panels are the paper's frozen panels (`data/frozen/`). The current Stan code reproduces every reported country-year, but imputed ones differ by Monte Carlo error. The model is refitted as a check, and `--hiv=refit` uses the refit instead.

## Not included

Several analyses in the analysis project are not described in the manuscript and are not here. These are:
- the tensor-product, linear 1–30%, no-region-effect and 1%-floor sensitivities;
- SMC;
- Sahel seasonality;
- the bam-versus-gam check;
- the covariate and random-effect plots;
- the history versions v1–v8.

See `docs/PAPER_CODE_FLAGS.md`, section C.

## Licence

The code is released under CC0 1.0 (`LICENSE`). The committed third-party inputs keep their own terms (see `data/README.md`), notably IHME's terms of use; the Snow et al. polygons are open access with the original publication. DHS and MICS microdata are not redistributed.
