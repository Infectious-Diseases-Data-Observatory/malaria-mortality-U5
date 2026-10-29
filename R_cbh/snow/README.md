# Snow et al. polygons as the unit of analysis

Since 11 October 2026 the primary analysis uses the sub-national polygons of Snow et al. (2017) as its geographic unit, in place of the survey-regions of the DHS and MICS files (primary version `snow_merge`, result id `primary_snow520_merge_dhsmics_gamma2_v13`; v11 and v12 are kept as history). The code was ported from the analysis project's `R_cbh/snow_units/`, where the approach was developed and checked.

## Rules (user decisions, 6, 11 and 12 October 2026)

- **Units.** The 520 malaria-endemic polygons ("Endemic") of the Snow shapefile (`data/external/snow_admin1/`), outside North Africa. The 29 malaria-free and 2 island units, and survey areas with no polygon (Comoros, Zanzibar, São Tomé and Príncipe), are excluded.
- **Placement.** A record is located by its smallest reported administrative unit:
  - its survey-region; or
  - in a survey-region spanning several polygons, a finer location variable such as state, district or province, matched by boundary geometry, polygon name or a reviewed alias (`05_finer_units.R`).

  Population shares use GPW v4 2020 population.
- **Merge rule.** The record's unit is the Snow polygon holding at least 90% of that location's population. Otherwise it is the union of the polygons each holding at least 5%. Smaller overlaps are boundary noise.
  - No record is split, so there are no weights.
  - Units of one survey can overlap: one region's records can get the union of four polygons, while a neighbouring region keeps one of them.
- **Malaria-free areas.** A unit more than half of whose population lies in malaria-free or island units is dropped. Otherwise those polygons are left out of the unit.
- **Exposure.** MAP PfPR~2–10~ of the unit in the band-entry year, population-weighted over its polygons (GPW density × cell area).
- **Covariates.** The 13 regional covariates of v9, recomputed for each survey × unit from the DHS BR, PR and HW recodes and the MICS files (`09`, `10`), then the v9 fallbacks (WUENIC, within-survey mean). The 4 national covariates are those of v9, with one declared substitution (12 October 2026): for band-entry years before independence (2011), South Sudan takes Sudan's GDP per capita, health expenditure per capita and political stability (`R_cbh/primary/national_substitutions.R`; merge variant only, `split_repro` has no substitution). Its child HIV incidence is its own. Political stability in 2001, a year without a WGI round, is the mean of the country's 2000 and 2002 values and health expenditure in 2024, not yet published, is the country's 2023 value (`R_cbh/primary/national_interpolations.R`; v12 and v13, 29 October 2026).
- **Model.** The seven v9 age-band models, with the random effect on survey × unit (`R_cbh/primary/`).

## Scripts (run in order; `SNOW_VARIANT=merge`, the default)

| Script | What it does |
|---|---|
| `01_polygons.R` | The 551 sub-Saharan polygons (520 endemic) from the committed shapefile; centroids and population. |
| `02_pfpr_polygons.R` | MAP PfPR for each polygon and year, 2000–2024, with the population weight of each value. |
| `03_feasibility.R` | Overlay of every survey-region with eligible records on the polygons; region classes. |
| `04_location_variables.R` | Location variables finer than the survey-region (names, labels, counts only). |
| `05_finer_units.R` | Places split regions' records through the best finer variable. Reviewed fixes: no previous-residence variables (`config/finer_variable_exclusions.csv`); a variable that places nothing is not chosen. |
| `06_label_inventory.R`, `06b_check_labels.R` | Answer labels of the DHS covariate items; every label must be classified by `R/label_rules.R` or `config/label_overrides.csv`. |
| `07_placement.R` | Places every eligible record (survey-region matched). Private output: `records_placed.rds`. |
| `08_units.R` | The merge rule (`R/placement.R`, `snow_assign`). Private output: `records_units.rds`. |
| `09_covariates_dhs.R`, `10_covariates_mics.R` | The 13 covariates per survey × unit, with a national validation against published DHS values. |
| then `R_cbh/primary/00_prepare_snow.R` | The prepared dataset of the primary (`CBH_PRIMARY_VERSION=snow_merge`), with the national substitutions (`national_substitutions.csv`). |

**Variant folders.** Outputs go to `results/cbh/snow_units/<variant>/` (aggregates) and `data/derived_cbh/snow/<variant>/` (private; git-ignored).

**Inputs.**
- DHS PR and HW recodes: `data/raw/dhs/`, listed in `config/dhs_pr_hw_files.csv`.
- Placement and label decisions: `config/`.

## Verification

`SNOW_VARIANT=split_repro` (with `CBH_PRIMARY_VERSION=snow_split_repro` for the preparation) rebuilds the analysis project's population-share split dataset on the v9 surveys. It reproduces that dataset record for record (`verification/snow_reproduction.md`). It is a check of the ported code, not a result.
