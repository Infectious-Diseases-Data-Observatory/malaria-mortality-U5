# Verification of the Snow-unit clean run (13 October 2026)

The whole pipeline was run at commit `3e2c721` (branch `snow-polygon-primary`). Each stage's outputs were compared with a saved copy of this repository's outputs from the morning of 12 October 2026 (`malaria-mortality-U5_pre_clean_20261012`, opened read-only). That copy holds the Snow-unit primary before the two author decisions of 12–13 October: Figure 1 as the map of complete birth histories by Snow polygon, and South Sudan's national covariates before independence. The per-file results are in this folder (`<checkpoint>.csv`).

**Result: the run reproduces the 12 October outputs, apart from the two author decisions.**
- Everything upstream of the Snow primary is identical or equivalent: inputs, DHS child bands, covariates, MICS, the v9 survey-region primary and its national burden inputs, and the Snow-unit construction and covariates. The HIV refit check differs by Monte Carlo error. The frozen panels the models use are identical.
- Every difference in the Snow primary, its sensitivities and `paper/` comes from South Sudan MICS 2010 entering the sample (57,509 records, 955 deaths) or from the new Figure 1. Outside South Sudan the prepared data have identical keys and raw values; the z-scores are re-standardised on the larger sample.
- Three items need the author's attention: a stale `paper/figures/fig1_survey_map_and_timing.png`; the East Africa subgroup, whose curves move more than any others; and the boundary-agreement caption, which calls 138 surveys (the primary's plus the Comoros) the primary sample (see Caveats).

## Run

Run `20261013T083723`: commit `3e2c721`, R 4.6.0, macOS Tahoe 26.7.1, locale en_GB. It started at 08:37:23 and finished at 12:20:00 on 13 October 2026 (`logs/detached_20261013T083722.log`). All 17 stage markers are in `logs/state/`. Validation passes all 11 checks (`results/cbh/primary_snow520_merge_dhsmics_gamma2_v11/paper_refresh/validation.txt`).

The runner recorded uncommitted changes. When this check was made, no R or Python file differed from the commit. The uncommitted changes were the exported `paper/` and documentation files.

All 17 stages ran. Three upstream stages reused work saved on 12 October by run `20261012T121428` (commit `0f8d27f`). That run built these stages from scratch and stopped at `covariates` (`12_fetch_nutrition.py`). No code these three stages use changed between `0f8d27f` and `3e2c721`.
- **inputs:** the per-survey MAP extraction cache (`data/map_region_cache/`, written on 12 October from 12:14; 28.5 minutes).
- **hiv:** the Stan fits `fit.rds` and `fit_extended.rds` (sampled on 12 October, finished 12:50 and 13:09; 26.9 minutes). The refit-check panels and draws were rewritten from them.
- **dhs_bands:** the 120 child-band shards (built on 12 October, 13:09–13:14; 5.1 minutes).

| Stage | Minutes (`logs/stage_times.csv`) |
|---|---:|
| restore | <0.1 |
| inputs | 0.2 (cache) |
| hiv (refit check) | 1.2 (cached fits) |
| hiv_panels | <0.1 |
| dhs_bands | 0.4 (cached shards) |
| covariates | 6.3 |
| mics | 7.7 |
| primary_v9 | 18.5 |
| snow_units | 20.8 |
| snow_covariates | 11.2 |
| primary (Snow) | 27.1 |
| snow_maps | 0.6 |
| subgroups | 28.5 |
| nutrition | 20.5 |
| imputation | 79.5 |
| validate, export | <0.1 |
| **Total** | **222.6** |

## Comparison

The tool was a scratch copy of `tools/compare_outputs.R` (`compare_outputs_snow.R`). The copy is not kept in the repository. It had two local changes:
- the results folder is set by `CMP_OUT`;
- the `snow_units` set lists `results/cbh/snow_units/merge` and the three `.rds` files of `data/derived_cbh/snow/merge` (`polygons_551.rds`, `records_placed.rds`, `records_units.rds`), leaving out the two covariate panels, which were compared with `cmp`.

As a diff against `tools/compare_outputs.R`:

```diff
50c50
<   snow_units = c("results/cbh/snow_units/merge", "data/derived_cbh/snow/merge"),
---
>   snow_units = c("results/cbh/snow_units/merge", "data/derived_cbh/snow/merge/polygons_551.rds", "data/derived_cbh/snow/merge/records_placed.rds", "data/derived_cbh/snow/merge/records_units.rds"),
130,131c130,131
< dir.create("verification", showWarnings = FALSE)
< fwrite(out, file.path("verification", paste0(cp, ".csv")))
---
> vout <- Sys.getenv("CMP_OUT", "verification"); dir.create(vout, recursive = TRUE, showWarnings = FALSE)
> fwrite(out, file.path(vout, paste0(cp, ".csv")))
```

To repeat the comparison, apply these changes to a copy and run it from the repository root:

```
CMP_OUT=verification/snow env -u LANG -u LC_ALL Rscript compare_outputs_snow.R \
  --reference=../malaria-mortality-U5_pre_clean_20261012 --checkpoint=<cp>
```

`<cp>` was each of inputs, hiv, dhs_bands, covariates, mics, primary, snow_units, snow_primary and snow_sensitivities. The paper checkpoint also took `--overleaf=../malaria-mortality-U5_pre_clean_20261012/paper`. Some files were compared directly instead:
- the `national_burden_inputs` files, with `cmp`;
- the two Snow covariate panels, with `cmp`;
- the prepared datasets, in R.

The reference copy's `results/cbh/primary_snow520_merge_dhsmics_gamma2_v11/fit_diagnostics.csv` was overwritten by a test on 12 October evening. It was not used.

## Checkpoints

Classes:
- **identical:** byte-for-byte.
- **equivalent:** identical once hashes, file paths and timings are ignored.
- **other:** DIFFERENT or missing, explained below.

| Checkpoint | Files | Identical | Equivalent | Other | Explanation of "other" |
|---|---:|---:|---:|---:|---|
| inputs | 6 | 6 | 0 | 0 | — |
| hiv | 31 | 20 | 0 | 11 | Refit products only (see below). All panels and draws the models use are identical. |
| dhs_bands | 124 | 124 | 0 | 0 | — |
| covariates | 222 | 217 | 3 | 2 | The 218 upstream files are 215 identical and 3 equivalent. The 2 others are the Snow imputation sensitivity's national panel (`imputed_snow_v12/`), written by the imputation stage: South Sudan, and new draws of the 62 non-SSD health-expenditure fills in `national_imputations.rds` (point values identical; see Imputed covariates). |
| mics | 169 | 168 | 0 | 1 | The build manifest's start and finish times. |
| primary (v9) | 130 | 104 | 16 | 10 | `session_info.txt`: macOS 26.6.2 → 26.7.1. Nine `national_burden_inputs` files are "missing" because the tool maps that folder to the analysis project's name. `cmp` finds all 18 files of the folder byte-identical. |
| snow_units | 51 | 48 | 0 | 3 | The boundary-agreement map, table and caption (stage `snow_maps`) read the primary's surveys plus the two Comoros surveys: 10 added rows, all MC_SSD2010. |
| snow_primary | 137 | 18 | 20 | 99 | 94 DIFFERENT and 5 new files: South Sudan and Figure 1 (see below). |
| snow_sensitivities | 84 | 16 | 8 | 60 | South Sudan (see below). |
| paper (vs the reference `paper/`) | 61 | 22 | 0 | 39 | 35 DIFFERENT, each the copy of a result file that differs above. The 4 missing are the new Figure 1 and the moved survey map, each with its caption. |

### Upstream

- **HIV.** The 11 differing files are:
  - the two Stan fit objects;
  - the refit-check panels and draws (data and results copies);
  - `extended_vs_base_panel.csv`, `imputed_no_adolescent_series.csv` and `refit_vs_frozen.csv`.

  The reference holds the refit of 2 October; this run's refit was sampled on 12 October. Both reproduce all 2,013 reported country-years exactly. Imputed child country-years differ from the frozen base panel by Monte Carlo error: median |log ratio| 0.053, maximum 0.40 (the reference refit: 0.063 and 0.31; `results/cbh/hiv_incidence/refit_vs_frozen.csv`).
- **Covariates.** The 3 equivalent files are `reduced_v3/manifest.rds`, the missingness provenance and the reduced-v3 audit input manifest.
- **v9 primary.** The fitted curves, contrasts, burden, figures and tables are byte-identical. The fitted model objects are not: the seven `.rds` files differ by `cmp`, and their md5s in `fit_manifest.csv` differ (the tool classes that file as equivalent because it ignores hashes). The 16 equivalent files are provenance records and `pfpr_components.rds`.
- **Snow-unit construction.** These are all byte-identical:
  - polygons and polygon PfPR;
  - feasibility, labels and placement (`records_placed.rds`);
  - units (`records_units.rds`) and the covariate audits;
  - the 20 per-country merge-unit maps.

  The covariate panels `covariates_dhs_long.csv` and `covariates_mics_long.csv` and the model folder's `regional_covariates_wide_snow.csv` are byte-identical by `cmp`. MC_SSD2010 was already placed in 10 units on 12 October and was lost only at complete cases.
- **Boundary agreement.** `boundary_agreement_regions.csv` gains 10 rows, the 10 MC_SSD2010 regions, all classed "Same area". The other 1,251 rows are identical. The caption's counts change accordingly: 1,251 → 1,261 survey-regions, 137 → 138 surveys, 437 → 447 mapped regions, and South Sudan is mapped.
  - The script adds the Comoros to the primary's surveys by design (`R_cbh/snow/22_map_boundary_agreement.R`: `survey %in% sample_surveys | country %in% c("COM")`). So the map covers 138 surveys in 38 countries, against the primary's 136 in 37 (`prepared_sample.csv`), and maps COM MICS 2022.
  - The exported caption (`paper/Supplementary Figures/sfig_snow_boundary_agreement_map_caption.md`) calls these surveys "the Snow primary sample". This mismatch is for the author.

### Snow primary

**Prepared data.** `complete_case_dataset.rds` has 57,509 more rows. All of them are MC_SSD2010: country SSD, 10 survey × unit areas (each one polygon), 17,144 children, 955 deaths and band-entry years 2005–2010. Without them, the 7,581,934 remaining rows have the same keys and identical values in every raw column. The z-scores differ only because the 17 covariates are re-standardised on the larger sample. Recomputed from the raw values with each side's scaling, they agree exactly.

**Sample ledgers.** The per-survey files (`prepared_selection_by_survey.csv`, `survey_coverage.csv` and the survey-map tables) gain one row, MC_SSD2010. Every other row is identical. `complete_case_losses.csv` loses its two MC_SSD2010 rows (33,840 records first missing GDP, 23,669 first missing health expenditure). In the study flow, records lacking a covariate fall from 1,048,372 to 990,863. The new count `national_substituted` is 57,509 (`study_flow/flow_counts.csv`). `preparation_provenance.csv` adds the three national panels and `national_substitutions.R`.

**National substitutions.** `national_substitutions.csv` is new. It records that SSD takes SDN's GDP per capita, health expenditure per capita and political stability for band-entry years 2005–2010. This covers 57,509 records and 955 deaths, all in the sample. For 23,669 of these records, Sudan's GDP replaces South Sudan's own.

**Fits.** All seven fits converged with full rank (1,652 coefficients, 1,452 survey × unit areas; `fit_diagnostics.csv`). The curves change modestly. At grid points within both versions' central exposure support, the log hazard ratio moves by at most 0.005 (48–59 months) to 0.021 (36–47 months) (`pfpr_curves.csv`). The largest change in PfPR EDF is 2.49 → 2.61 (6–11 months). `grouped_outcome_checks.csv` gains 14 rows: South Sudan and MC_SSD2010 in each band. `session_info.txt` differs in the locale name: en_GB.UTF-8 in the reference Snow runs, en_GB here and in the v9 reference. The v9 text outputs are byte-identical, so the encoding is unaffected.

**Burden.** Every country's PfPR input is identical. Each of the 42 countries' 2024 attributable deaths rises, by 0.9% (Eritrea) to 3.8% (Djibouti), with median 2.1% (`burden/country_totals.csv`). The IHME, UN IGME and WHO values are unchanged wherever they appear; only the model columns differ. The ranking in `tables/country_comparison_2024.csv` (by absolute difference from IHME) shifts: Benin, Guinea and DR Congo now rank above Uganda.

**Wording.** Text changes beyond numbers come from the two decisions.
- **South Sudan (`3e2c721`):**
  - the method sentence of `RESULTS.md`;
  - the South Sudan sentences in the study-flow caption, `COMPARISON.md` and `OVERLEAF_UPDATE.md`;
  - the survey-map caption's MICS clause;
  - the added validation line.
- **Figure 1 (`71615fa`, `8ff1459`):**
  - the Figure 1 entry and manifest row in `paper_figures/`;
  - the survey-map caption heading;
  - the first paragraph of `OVERLEAF_UPDATE.md`;
  - the `analysis_units_map` provenance row.

The 99 other files, by group:

| Group | Files | Content |
|---|---:|---|
| Sample and preparation | 7 | Counts, per-survey selection, complete-case losses, covariate scaling, preparation provenance. |
| Fits | 16 | Curves, contrasts, EDF, smooth summaries, outcome checks, `pfpr_components.rds`, four figures, `fit_diagnostics.csv` (reference overwritten), `session_info.txt`. |
| Burden, tables, comparison | 53 | Burden, annual comparison, burden comparison, Nigerian states, under-five probability, malaria share, tables, and the Snow side of the v9 comparison. The v9 columns there are unchanged. |
| Reports, flow, survey map, export | 18 | `RESULTS.md`, study flow, survey map, `paper_figures/`, `paper_refresh/`. |
| New | 5 | `analysis_units_map/` (map, caption, per-polygon table, provenance) and `national_substitutions.csv`. |

### Sensitivities

**Subgroups** (`subgroups_snow520_merge_gamma2_v5`):
- **Without MC_SSD2010.** Five subgroups do not contain it: Sahel, West Africa, Central Africa, later survey years and later record years. Their samples are unchanged. Their curves agree with the reference to within 1.0e-7 in log hazard ratio, and their contrasts to within 4.8e-8. Their fits differ only through the rescaled covariates. The fREML of each of their five restarted fits shifts by 0.0675, which is the sum of log(SD new / SD old) over the 17 covariates.
- **With MC_SSD2010.** Three subgroups contain it: East Africa, surveys up to the median year and records up to the median year. Each gains exactly 57,509 records, 955 deaths, 17,144 children and 10 survey × unit areas (`sample_summary.csv`). Only these three subgroups change in knots, exposure support and the set of tighter-tolerance restarts (5 fits; 7 → 8 restarts in all).
- All 56 fits converged. The report's total fitting time changes from 1,255 to 1,240 seconds.

**No nutrition covariates** (`nutrition_adjustment_snow520_merge_gamma2_v5`):
- Each band's sample equals the new primary's (1,452 survey × unit areas).
- The largest change in the 40%-to-20% hazard ratio from removing wasting and stunting is 0.007 in the reference and 0.010 here (now at 1–5 months).
- The restarted fits change from two (1–5 and 48–59 months) to one (<1 month). All seven converged.

**Imputed covariates** (`primary_snow520_merge_imputed_gamma2_v12`, `covariate_imputation_snow_v12`):
- **Sample.** Unchanged: 8,630,306 records, 122,092 deaths, 161 surveys, 38 countries (`prepared_sample.csv` identical). MC_SSD2010 was already in this sample, with modelled national values.
- **National panel.** Of 1,000 country-years, 20 differ, all South Sudan. Its 2000–2010 values are now Sudan's observed values (labelled `*_substituted_sdn`) instead of GAM fills. The exception is political stability in 2001, when Sudan has no WGI estimate. That value is the mean of Sudan's 2000 and 2002 values, labelled `wgi_2001_interpolated`, so `interpolated_2001` rises from 39 to 40 (`national_imputation_summary.csv`). No record uses that year. Its GDP fills for 2016–2024 change because its own 2008–2010 GDP no longer enters the GDP model (980 instead of 983 observed country-years). Every other country-year is identical.
- **Model fills.** Political stability falls from 11 to 0, GDP from 17 to 9 and health expenditure from 80 to 69 (`national_imputation_summary.csv`). The health-expenditure model is unchanged: 913 observed country-years, residual SD 0.230, deviance explained 94.2%.
- **Draws.** With no political-stability fill left to draw, the GDP and health-expenditure draws start at a different point of the random sequence. The 62 health-expenditure fills outside South Sudan (39 countries) therefore have new draws from the same model; their point values are identical. The standardised differences of their draw means have SD 1.19 and maximum 2.96, in line with Monte Carlo error.
- **Prepared imputed data.** The same 8,630,306 rows. Only the South Sudan rows' GDP, health expenditure and political stability differ, plus the re-standardisation of those three covariates.
- **Records imputed.** Political stability falls from 244,075 to 186,566 records, GDP from 33,840 to 0 and health expenditure from 242,864 to 185,355. The 57,509 South Sudan records are now substituted, not imputed (`REPORT.md`).
- **Effect.** Within central support, the imputed fit's curves move by at most 0.0013 in log hazard ratio. The largest change in the 40%-to-20% hazard ratio between the complete-case and imputed fits is 0.018 in the reference and 0.013 here. The between-imputation share of variance is at most 1.9% and 1.3%.

### paper/

The export wrote 60 files, each byte-identical to its result file (`paper_refresh/export_manifest.csv`; `export_verification.json`: all copy hashes match). The reference `paper/` was likewise an exact copy of its results (57 of 57). Each difference in `paper/` is therefore the result difference above.

The 22 identical files are:
- the 20 merge-unit maps;
- the Sahel subgroup caption;
- the stale `figures/fig1_survey_map_and_timing.png`.

## Key numbers, 12 October → 13 October

**Sample** (`prepared_sample.csv`, `primary_sample.csv`, `survey_map/mothers_by_survey.csv`):

| | 12 October | 13 October | Difference |
|---|---:|---:|---:|
| Child-band records | 7,581,934 | 7,639,443 | 57,509 |
| Deaths | 104,159 | 105,114 | 955 |
| Children | 2,318,724 | 2,335,868 | 17,144 |
| Mothers | 1,118,697 | 1,125,610 | 6,913 |
| Survey × unit areas | 1,442 | 1,452 | 10 |
| Polygons | 455 | 465 | 10 |
| Surveys | 135 | 136 | 1 |
| Countries | 36 | 37 | 1 |

The DHS part is unchanged: 99 surveys, 5,598,304 records, 77,966 deaths and 1,148 survey × unit areas. The MICS part changes as follows (`validation.txt`, `OVERLEAF_UPDATE.md`):

| MICS part | 12 October | 13 October |
|---|---:|---:|
| Surveys | 36 | 37 |
| Records | 1,983,630 | 2,041,139 |
| Deaths | 26,193 | 27,148 |
| Survey × unit areas | 294 | 304 |

**Effect of PfPR by age band** (`comparison_v9/COMPARISON.md`, `tables/age_band_results.md`):

| Age band | AF at PfPR 20% vs 0, 12 October | 13 October | HR 40% to 20%, 12 October | 13 October |
|---|---|---|---|---|
| <1 month | 3.5% (−1.8 to 8.5) | 4.4% (−0.9 to 9.4) | 0.95 (0.92–0.97) | 0.94 (0.91–0.97) |
| 1–5 months | 12.4% (6.0 to 18.3) | 13.3% (6.9 to 19.3) | 0.93 (0.89–0.96) | 0.92 (0.88–0.96) |
| 6–11 months | 23.7% (16.9 to 29.9) | 24.6% (17.7 to 30.9) | 0.84 (0.80–0.88) | 0.84 (0.81–0.88) |
| 12–23 months | 46.8% (39.6 to 53.2) | 46.7% (39.5 to 53.0) | 0.87 (0.82–0.93) | 0.88 (0.83–0.94) |
| 24–35 months | 54.9% (48.4 to 60.7) | 54.5% (47.9 to 60.3) | 0.89 (0.83–0.95) | 0.89 (0.84–0.95) |
| 36–47 months | 44.4% (35.7 to 52.0) | 43.0% (34.1 to 50.7) | 0.89 (0.82–0.96) | 0.89 (0.82–0.95) |
| 48–59 months | 43.7% (33.6 to 52.3) | 43.9% (33.9 to 52.4) | 0.94 (0.85–1.02) | 0.94 (0.86–1.03) |

**Attributable under-five deaths, 42 countries** (`burden/year_summary.csv`):

| Year | 12 October | 13 October | Change | IHME malaria |
|---|---:|---:|---:|---:|
| 2005 | 966,467 | 980,480 | +1.4% | 564,067 |
| 2015 | 675,647 | 687,031 | +1.7% | 416,122 |
| 2024 | 576,400 | 586,723 | +1.8% | 428,147 |

**2024 deaths by source** (`burden_comparison/source_comparison_2000_2024.csv`):
- PfPR-ACM model: 576,400 → 586,723 (3.25 → 3.31 per 1,000 child-years).
- IHME: 428,147.
- UN IGME (CA-CODE): 440,123.
- WHO WMR 2025, all ages: 579,000 (African Region) and 610,000 (global).

**2000–2024.** The total rises from 19,527,797 to 19,836,512 (+1.6%). Each year rises by 1.3% to 1.9% (`annual_comparison/annual_totals_2000_2024.csv`). The v9 total is 21,215,643, so the Snow/v9 ratio moves from 0.920 to 0.935 (`comparison_v9/COMPARISON.md`). The decline from 2000 to 2024 is 47.5% before and 47.2% now.

**Nigeria, 2024** (`nigeria_states/README.md`, `nigeria_states/national_reconciliation_2024.csv`):
- National estimate: 203,752 → 206,863.
- State sum: 202,897 → 205,988, against 132,138 IHME malaria deaths (ratio 1.54 → 1.56).
- The model exceeds IHME in 35 of 37 states, as before.

**South Sudan, 2024.** Attributable deaths rise from 10,419 to 10,635 (`tables/country_comparison_2024_top10.md`).

**2024 agreement** (`annual_comparison/country_agreement_2024.csv`):

| | 12 October | 13 October |
|---|---:|---:|
| Countries with the model above IHME (of 42) | 33 | 34 |
| Median ratio, model to IHME | 1.48 | 1.50 |
| Spearman ρ of rates, model and IHME | 0.911 | 0.911 |
| Countries with the model above UN IGME | 37 | 38 |
| Median ratio, model to UN IGME | 1.72 | 1.77 |
| Spearman ρ of rates, model and UN IGME | 0.893 | 0.895 |

For the 2024 under-five death probability, the median ratio of the model's malaria-caused probability to IHME's moves from 1.48 (interquartile range 1.08–2.22) to 1.50 (1.09–2.26) (`under5_probability/CAPTION.md`).

## Caveats

- **Stale file in `paper/`.** This export did not write `paper/figures/fig1_survey_map_and_timing.png`. It is not in `export_manifest.csv`, and its file time is 12 October 11:28. It is the 12 October Snow survey map, without South Sudan (36 MICS surveys). Its successor is `Supplementary Figures/sfig_survey_map_and_timing.png`. Git tracks the file (the committed version is the v9 Figure 1). It should not go to Overleaf as the current figure; the author decides whether to remove it.
- **East Africa subgroup.** This subgroup is sensitive to the one added survey. MC_SSD2010 adds 57,509 of its 2,646,166 records and 955 of its 31,858 deaths. Within central support, its curves move by up to 0.13 in log hazard ratio, which is up to 2.6 reference standard errors (1–5 months). Its HR for PfPR 20% to 0 changes from 0.66 to 0.77 at 48–59 months and from 0.92 to 0.84 at 1–5 months (`pfpr_contrasts.csv`). The two period subgroups that contain the survey move by at most 0.06 in log hazard ratio within central support. Any text that quotes the East Africa curve needs the new values.
- **Boundary-agreement caption.** `R_cbh/snow/22_map_boundary_agreement.R` adds the two Comoros surveys to the primary's surveys by design. The caption counts 138 surveys in 38 countries and calls them "the Snow primary sample", which has 136 surveys in 37 countries (see Upstream). The author decides whether the caption should say so.
- **Imputation draws.** The multiple-imputation pooled results are a new Monte Carlo replicate, not only a South Sudan change. The health-expenditure draws for Zimbabwe, Somalia and the 2024 fills changed with the random sequence (see above).
- **HIV refit.** The refit check uses Stan fits sampled on 12 October, not on 13 October. It remains a check only: the models use the frozen panels.
- **Cached upstream stages.** inputs, hiv and dhs_bands were last built from scratch on 12 October (run `20261012T121428`). Their outputs are identical to the reference.
- **Reference fit diagnostics.** The reference copy's `fit_diagnostics.csv` for the Snow primary was overwritten, so it was not compared. This run's file shows all seven fits converged.
- **Not re-run.** The v9 sensitivities (`subgroups_dhsmics_map_gamma2_v4`, `nutrition_adjustment_dhsmics_map_gamma2_v4`, `primary_map_regional17_dhsmics_imputed_gamma2_v10`) are not stages of this pipeline any more. They were not re-run or compared; the v9 record (`verification/VERIFICATION.md`) covers them.
