# malaria-mortality-U5

Code and inputs for **"Reassessing the malaria mortality burden in African children"** (Watson, Darji, …, Guerin, Snow; manuscript in preparation).

The paper treats malaria transmission intensity, measured as *P. falciparum* prevalence in children aged 2–10 (*Pf*PR₂₋₁₀, from the Malaria Atlas Project), as a risk factor for all-cause death in children under 5. Complete birth histories from 135 DHS and UNICEF MICS surveys in 37 sub-Saharan African countries are split into seven age bands from birth to age 5. Each band is linked to the population-weighted *Pf*PR₂₋₁₀ of the survey region in the band's calendar year. A separate binomial complementary log-log GAM is fitted to each band, with 17 adjustment covariates. The fitted age-band hazard ratios, contrasting current *Pf*PR with zero, are then applied to IHME all-cause death rates. This gives the share and number of under-five deaths attributable to malaria, directly and indirectly, which are compared with IHME and UN IGME (CA-CODE) cause-specific estimates.

This repository contains only what the manuscript describes. The analysis was developed in a larger project; `docs/PAPER_CODE_FLAGS.md` lists:
- what the code needs that the manuscript does not describe;
- where the manuscript and the code disagree;
- the analyses left out.

## Status

| | |
|---|---|
| Primary analysis | Version **v9**, `primary_map_regional17_dhsmics_gamma2_v9`: DHS and MICS surveys, 17 covariates, MAP PfPR, γ = 2 |
| Sample | 135 surveys (98 DHS, 37 MICS) in 37 countries; 1,229 survey-regions; 1,125,549 mothers; 2,329,388 children; 7,621,617 child-band records; 104,143 deaths |
| Sensitivities in the paper | Subgroups (`subgroups_dhsmics_map_gamma2_v4`), without wasting and stunting (`nutrition_adjustment_dhsmics_map_gamma2_v4`), imputed covariates (`primary_map_regional17_dhsmics_imputed_gamma2_v10`) |
| Verified | See [Verification](#verification): a full re-run from raw microdata reproduces the paper's figures, tables and numbers |

## Repository layout

```
run_pipeline.R      runs every stage in order (resumable; see below)
run_detached.sh     runs the pipeline detached from the terminal
R_inputs/           input producers: survey-region MAP PfPR, UNICEF immunisation panel, region centroids, WHO WMR tables
  fetch/            network scripts that obtained the frozen inputs (not run by the pipeline)
R_cbh/              DHS child-band builder, covariates, HIV model, primary model, burden, reporting, sensitivities
  R/                shared builder functions          config/   survey rules and region overrides
  hiv/              child HIV incidence model (Stan)  covariates/  DHS regional covariates
  primary/          v9 settings, fits, effects, report  burden/  national inputs, annual and Nigerian-state burden
  reporting/        figures, tables, paper export     sensitivity/  subgroups, nutrition, imputation_dhsmics
R_mics/             MICS conversion to the DHS layout, boundaries, PfPR, child bands, covariates
tools/              import, restore, comparison and pre-commit checks
data/               committed inputs and manifests (see data/README.md); raw microdata in data/raw/ (ignored)
paper/              the figures, tables and captions exported for the manuscript by the verified run
verification/       comparison of the re-run with the analysis project's outputs
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
- About 16 GB of memory, since one fit uses about 3 GB, and about 15 GB of disk for the derived files.
- `run_pipeline.R` stops if a package version differs from the recorded one (`--ignore-versions` overrides).

## Reproducing the analysis

1. Place the DHS, MIS and MICS microdata in `data/raw/` as described in [data/README.md](data/README.md). Every other input is committed.
2. Run the whole pipeline, detached; it takes about 4 hours:
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
| `covariates` | DHS published indicators, recode summaries, WUENIC fallbacks, nutrition, first-birth age, complete-case audit | ~25 min |
| `mics` | MICS extraction, inventory, regions and boundaries, PfPR, BR-layout recodes, child bands, covariates | ~30 min |
| `primary` | v9 preparation, seven fits, effects, national burden, Figures 1–4, Tables 1, 2 and S1, Figs S1, S2 and S6 | ~25 min |
| `subgroups` | Sahel, Eastern Africa and survey-period refits (Fig S3) | ~15 min |
| `nutrition` | Refits without wasting and stunting (Fig S5) | ~20 min |
| `imputation` | Imputed-covariate refits and the multiple-imputation propagation (Fig S4) | ~65 min |
| `validate` | Cross-checks of the reported numbers and provenance hashes | <1 min |
| `export` | Copies figures, tables and captions to `paper/` | <1 min |

`R_inputs/fetch/` contains the scripts that obtained the frozen inputs. They need network access, and some need DHS credentials. The pipeline never runs them.

## Paper figures and tables

| Paper | File in `paper/` | Script |
|---|---|---|
| Figure 1: surveys and timing | `figures/fig1_survey_map_and_timing.png` | `R_cbh/reporting/03_survey_map.R` |
| Figure 2: attributable fraction by age | `figures/fig2_malaria_attributable_fraction_by_age.png` | `R_cbh/reporting/06_attributable_fraction_by_age.R` |
| Figure 3: comparison with IHME and UN IGME | `figures/fig3_burden_comparison.png` | `R_cbh/reporting/11_burden_comparison_figure.R` |
| Figure 4: probability of dying before age 5 | `figures/fig4_under5_death_probability.png` | `R_cbh/reporting/13_under5_death_probability.R` |
| Figure 5: causal diagram | (drawn by hand; in the Overleaf project) | — |
| Table 1: country comparison | `tables/country_comparison_2024.latex.txt` | `R_cbh/reporting/09_burden_tables.R` |
| Table 2: source comparison 2000–2024 | `tables/source_comparison.latex.txt` | `R_cbh/reporting/12_source_comparison_table.R` |
| Table S1: age-band results | `tables/age_band_results.latex.txt` | `R_cbh/primary/03_report.R` |
| Fig S1: study flow | `Supplementary Figures/sfig_study_flow.png` | `R_cbh/reporting/01_study_flow.R` |
| Fig S2: PfPR and mortality by age band | `Supplementary Figures/sfig_pfpr_mortality_by_age.png` | `R_cbh/primary/03_report.R` |
| Fig S3: subgroups | `Supplementary Figures/sfig_pfpr_splines_by_subgroup.png` | `R_cbh/sensitivity/subgroups/02_report.R` |
| Fig S4: imputed covariates | `Supplementary Figures/sfig_pfpr_splines_imputed_covariates.png` | `R_cbh/sensitivity/imputation_dhsmics/06_report.R` |
| Fig S5: without wasting and stunting | `Supplementary Figures/sfig_pfpr_splines_without_nutrition.png` | `R_cbh/sensitivity/nutrition/02_report.R` |
| Fig S6: malaria share against PfPR | `Supplementary Figures/sfig_malaria_share_vs_pfpr.png` | `R_cbh/reporting/20_malaria_share_vs_pfpr.R` |
| Results text: 2024 agreement statistics | `results/cbh/…_v9/annual_comparison/country_agreement_2024.csv` | `R_cbh/reporting/21_country_agreement_2024.R` |

## Verification

On 2–4 October 2026 the whole pipeline was re-run from the raw microdata and compared with the analysis project's outputs ([verification/VERIFICATION.md](verification/VERIFICATION.md)):
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

The code is released under CC0 1.0 (`LICENSE`). The committed third-party inputs keep their own terms (see `data/README.md`), notably IHME's terms of use and those of the Snow admin-1 shapefile. DHS and MICS microdata are not redistributed.
