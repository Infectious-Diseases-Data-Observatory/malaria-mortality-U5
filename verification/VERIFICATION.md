# Verification of the full re-run (2–4 October 2026)

The whole pipeline was re-run in this repository: raw DHS/MIS recodes and MICS downloads, plus the committed inputs, through to the exported figures and tables. Each stage's outputs were compared with those of the analysis project in which the paper's results were produced. The comparison tool was `tools/compare_outputs.R`, which opened the analysis project read-only. The per-file results are in this folder (`<checkpoint>.csv`).

**Result: the re-run reproduces the paper.**
- Every figure, table and caption that `main.tex` uses is byte-identical to the file in the Overleaf project (27 of 27).
- The seven primary fits, the national burden estimates and all three sensitivities in the paper are identical.

## Run

Commit `d172f5c` (branch `paper-v9-pipeline`), R 4.6.0, collation locale en_GB. Network access was blocked throughout.

The run was done in two parts:
- **2 October:** `restore` → `mics`.
- **4 October:** `hiv_panels` → `export`, after the decision to use the paper's frozen HIV panels (see below).

`export` was rerun on its own after `paper/` was created.

| Stage | Minutes |
|---|---:|
| inputs (MAP extraction from rasters) | 28.9 |
| hiv (model refit, as a check) | 27.5 |
| dhs_bands | 5.7 (first build; 0.4 when reused) |
| covariates | 16.3 |
| mics | 25.9 |
| primary | 19.1 |
| subgroups | 13.3 |
| nutrition | 17.2 |
| imputation | 64.8 |
| validate, export | <1 |

## Checkpoints

Classes:
- **identical:** byte-for-byte.
- **equivalent:** identical once hashes, file paths, timings and the "cached"/"built" shard status are ignored.
- **DIFFERENT / missing:** explained below.

| Checkpoint | Files | Identical | Equivalent | Other | Explanation of "other" |
|---|---:|---:|---:|---:|---|
| inputs | 6 | 6 | 0 | 0 | Survey-region MAP PfPR (two tables), UNICEF immunisation panel, DHS region centroids (reproduced by a new producer script), WHO WMR tables. |
| hiv | 31 | 19 | 0 | 12 | All panels and draws the models use are identical (frozen panels). The Liberia panels rebuilt from them by `03_add_liberia_aidsinfo.R` are byte-identical. Differences are in the refitted Stan objects and refit summaries, and in new `refit_check/` and `refit_vs_frozen.csv` files (see below). |
| dhs_bands | 124 | 3 | 121 | 0 | All 120 survey child-band files rebuilt from the raw recodes are equivalent. |
| covariates | 218 | 91 | 125 | 2 | `audit_input_manifest.csv` lists fewer covariate scripts (the excluded history scripts). One manifest records "cached" instead of "built". |
| mics | 169 | 119 | 49 | 1 | The build manifest's start and finish times. All 581 SPSS files extracted from the raw MICS downloads are byte-identical. |
| primary | 130 | 107 | 13 | 10 | Intended code changes, all checked: new agreement statistics files; provenance without the v7 and legacy inputs; job list and fit manifest built in code; one link in `RESULTS.md`; national PfPR files without the legacy density-weighted column. |
| sensitivities | 79 | 60 | 17 | 2 | The total fitting time quoted in the subgroup and imputation reports. |
| paper (vs Overleaf) | 28 | 27 | 0 | 1 | `RESULTS_UPDATE.md`, the export's handoff note, no longer lists the analyses excluded from this repository. |

Byte-identical outputs include:

| Group | Outputs |
|---|---|
| Model results | `pfpr_curves.csv`; both hazard-ratio contrast files; the covariate scaling; the prepared-sample summary; the seven fits' PfPR coefficients and covariances (`pfpr_components.rds`, equivalent) |
| Burden | 2024 country totals; 2000–2024 annual totals; Nigerian state totals |
| Main figures and tables | Figures 1–4; Tables 1, 2 and S1 (`.latex.txt`) |
| Supplementary figures | Figs S1–S6 and their captions |
| Sensitivity results | Subgroup and no-nutrition contrasts; pooled multiple-imputation contrasts and curves; mice diagnostics |

## Key numbers reproduced

- **Sample:** 135 surveys (98 DHS, 37 MICS), 37 countries, 1,229 survey-regions, 2,329,388 children, 7,621,617 child-band records, 104,143 deaths. The DHS part has 5,588,463 records and 77,587 deaths.
- **Attributable under-five deaths, 42 countries:**

  | Year | PfPR-ACM model | IHME malaria |
  |---|---:|---:|
  | 2005 | 1,045,865 | 564,067 |
  | 2015 | 736,151 | 416,122 |
  | 2024 | 629,136 | 428,147 |

  UN IGME (CA-CODE) gives 440,123 for 2024.
- **2024 agreement (main.tex L108):** model above IHME in 36 of 42 countries; median ratio 1.61; Spearman ρ = 0.91.
- **Validation:** `R_cbh/reporting/10_validate_reporting.R` passes every check (`results/.../paper_refresh/validation.txt`).

## Child HIV incidence: frozen panels

The paper's models use child HIV incidence panels from the Stan model. The base panel was fitted on 8 September 2026 and the extended panel on 18 September 2026. The analysis project froze the base panel because the current code does not reproduce it.

A fresh refit (stage `hiv`) gives identical values for every reported country-year (2,013). Imputed country-years differ by Monte Carlo error: median |log ratio| 0.06, maximum 0.31 (`results/cbh/hiv_incidence/refit_vs_frozen.csv`).

On 4 October 2026 the user decided to use the frozen panels and draws (`data/frozen/`; stage `hiv_panels`). The refit is kept as a check. `Rscript run_pipeline.R --hiv=refit` uses the refit instead, which changes the downstream results slightly.

## Not re-run

- **Network fetch scripts** (`R_inputs/fetch/`; the inputs they obtained are committed or frozen):
  - DHS catalogue and recode download;
  - StatCompiler, World Bank and UN IGME fetches;
  - malariaAtlas downloads;
  - the Nigeria/DRC admin-1 PfPR script.
- **UNICEF extract.** `R_inputs/trim_unicef_fusion.R` was run once to make the committed extract, and the outputs that use it are identical.
