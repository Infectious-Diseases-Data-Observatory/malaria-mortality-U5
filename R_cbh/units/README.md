# GADM admin-1 units as the unit of analysis

The primary analysis uses the GADM 4.1 admin-1 units (KEMRI-Wellcome merge; national boundaries for Botswana, Ghana, Kenya, Madagascar, Malawi, mainland Tanzania and Uganda) as its geographic unit, in place of the survey-regions of the DHS and MICS files (primary version `gadm`, result id `primary_gadm_merge_dhsmics_gamma2_v15`). The Snow-unit primary (v11–v14) was replaced by the GADM units in v15 (author decision, 3 November 2026; code in git history up to f2db98e). Settings: `R/settings.R` (`units_settings()`, one fixed unit set).

## Rules (user decisions, 6, 11 and 12 October 2026; units of 3 November 2026)

- **Units.** The admin-1 units of the 44 sub-Saharan countries outside North Africa (`00_gadm_layer.R`): 568 units, of which 535 are endemic (the units of analysis), 31 malaria free and 2 island (Bioko, Annobón). A unit is "Island" or "Malaria free" when more than half of its GPW 2020 population lies in the island or malaria-free areas of Snow et al. (2017); it is also "Malaria free" when it has no MAP PfPR estimate (Botswana's Southern and South-East, Eswatini's Manzini). Survey areas with no unit (Comoros, Zanzibar, São Tomé and Príncipe) are excluded.
- **Placement.** A record is located by its smallest reported administrative unit:
  - its survey-region; or
  - in a survey-region spanning several units, a finer location variable such as state, district or province, matched by boundary geometry, unit name or a reviewed alias (`05_finer_units.R`).

  Population shares use GPW v4 2020 population. Seventeen reviewed survey-regions that name a unit but are split only by digitising differences between the survey's boundary file and the layer are placed wholly in that unit (`config/region_overrides.csv`).
- **Merge rule.** The record's unit is the admin-1 unit holding at least 90% of that location's population. Otherwise it is the union of the units each holding at least 5%. Smaller overlaps are boundary noise.
  - No record is split, so there are no weights.
  - Analysis units of one survey can overlap: one region's records can get the union of four admin-1 units, while a neighbouring region keeps one of them.
- **Malaria-free areas.** A record whose location has more than half of its population in malaria-free or island units is dropped. Otherwise those units are left out of its analysis unit.
- **Exposure.** MAP PfPR~2–10~ of the analysis unit in the band-entry year, population-weighted over its admin-1 units (GPW density × cell area).
- **Covariates.** The 13 regional covariates of v9 (the survey-region primary, removed from this repository on 1 November 2026), recomputed for each survey × unit from the DHS BR, PR and HW recodes and the MICS files (`09`, `10`), then the v9 fallbacks (WUENIC, within-survey mean). The 4 national covariates are those of v9, with one declared substitution (12 October 2026): for band-entry years before independence (2011), South Sudan takes Sudan's GDP per capita, health expenditure per capita and political stability (`R_cbh/primary/national_substitutions.R`). Its child HIV incidence is its own. Political stability in 2001, a year without a WGI round, is the mean of the country's 2000 and 2002 values, and health expenditure in 2024, not yet published, is the country's 2023 value (`R_cbh/primary/national_interpolations.R`; 29 October 2026).
- **Surveys.** Every MAP-eligible survey is placed. The sample's 136 surveys are pinned in `R_cbh/primary/survey_set.csv`: `R_cbh/primary/00_prepare.R` stops unless the prepared sample has exactly these surveys.
- **Model.** The seven v9 age-band models, with the random effect on survey × unit (`R_cbh/primary/`).

## Scripts (run in order; stages `units` and `unit_covariates` of `run_pipeline.R`)

| Script | What it does |
|---|---|
| `00_gadm_layer.R` | The unit layer from the KEMRI-Wellcome merge of GADM 4.1 admin 1: the 44 countries, Addis Ababa, Niamey and Bamako cut out of the regions that contain them, ids pinned against `config/unit_ids.csv`, and the type of each unit. Writes `data/external/gadm_admin1/gadm1_units.gpkg` (git-ignored) and `polygons/gadm_layer.csv`. |
| `01_polygons.R` | The 568 units (535 endemic), checked against the counts fixed in `units_settings()`; centroids and population. |
| `02_pfpr_polygons.R` | MAP PfPR for each endemic unit and year, 2000–2024, with the population weight of each value. |
| `03_feasibility.R` | Overlay of every survey-region with eligible records on the units; region classes and the reviewed overrides. |
| `04_location_variables.R` | Location variables finer than the survey-region (names, labels, counts only). |
| `05_finer_units.R` | Places split regions' records through the best finer variable. Reviewed fixes: no previous-residence or health-facility variables (`config/finer_variable_exclusions.csv`); a variable that places nothing is not chosen. |
| `07_placement.R` | Places every eligible record (survey-region matched). Private output: `records_placed.rds`. |
| `08_units.R` | The merge rule (`R/placement.R`, `units_assign`). Private output: `records_units.rds`. |
| `09_covariates_dhs.R`, `10_covariates_mics.R` | The 13 covariates per survey × unit, with a national validation against published DHS values. Every answer label of the DHS items must be classified by `R/label_rules.R` or `config/label_overrides.csv`; `09` stops on any other. |
| then `R_cbh/primary/00_prepare.R` | The prepared dataset of the primary (`CBH_PRIMARY_VERSION=gadm`), with the national substitutions (`national_substitutions.csv`). |

The label inventory (`06`, `06b`) and the unit maps (`21`, `22`) were removed on 1 November 2026, as no paper output uses them.

**Output folders.** Outputs go to `results/cbh/units/` (aggregates) and `data/derived_cbh/units/` (private; git-ignored).

**Inputs.**
- GADM 4.1 admin 1, KEMRI-Wellcome merge of 4 February 2026: `data/Africa GADM 0-2 (040226)/Africa_GADM1_(040226).shp` (not committed: GADM licence and size; see `data/README.md`).
- The Snow et al. (2017) shapefile, `data/external/snow_admin1/Africa_New_Admin.shp` (committed; reference only, see below).
- GPW v4 2020 population density (`data/pop/`) and the MAP PfPR~2–10~ rasters of `cbh_config()$map_raster_dir`.
- Survey-region boundaries: the DHS boundary files of the survey registry and the MICS analysis-region files (`data/derived_mics/boundaries/`).
- DHS PR and HW recodes: `data/raw/dhs/`, listed in `config/dhs_pr_hw_files.csv`.
- Reviewed decisions in `config/`: unit ids (`unit_ids.csv`), survey-region overrides (`region_overrides.csv`), spellings of finer locations (`name_aliases.csv`), excluded finer variables (`finer_variable_exclusions.csv`), answer labels (`label_overrides.csv`) and extra vaccine series (`vaccine_series.csv`).

## The Snow et al. (2017) shapefile

The shapefile is no longer a unit set. It stays a reference input for three uses:

1. **Unit types** (`00_gadm_layer.R`, `units_settings()$snow_shapefile`): a GADM unit is "Island" or "Malaria free" when more than half of its GPW 2020 population lies in Snow island or malaria-free polygons of its own country (also "Malaria free" when it has no MAP PfPR estimate). The script also takes the study area from it: its 44 countries outside North Africa (no island states), without Zanzibar and Pemba, for which it has no polygon.
2. **MICS survey-region boundaries** of Guinea-Bissau, the Central African Republic, Senegal, Somalia and South Sudan, built upstream in `R_mics/` (`R_mics/config/paths.R`; unchanged).
3. **Western Sahara outline** of Figure 1 (`R_cbh/reporting/23_analysis_units_map.R`).

## Checks

- `00_gadm_layer.R` stops if the unit ids differ from `config/unit_ids.csv`, if two units of one country overlap by more than 1 km² or if the overlaps between countries (border digitising) exceed 500 km² in all; `01_polygons.R` stops if the unit counts differ from `units_settings()$counts`.
- `03_feasibility.R` checks each override: the survey-region must be split, and the named endemic unit must be in the survey's country and hold at least 15% of the region's population.
- `09_covariates_dhs.R` compares national recode values with the published DHS values; `10_covariates_mics.R` keeps the regression lock on the v9 MICS national values.
- The placement and covariate code was ported from the analysis project, where it was checked by rebuilding that project's population-share split dataset on the v9 surveys, record for record.
