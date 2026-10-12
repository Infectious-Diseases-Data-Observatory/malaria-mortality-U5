# Data

All inputs to the analysis live here. Every committed file is listed in `INPUTS_MANIFEST.csv`, with its size, md5 and origin, and `run_pipeline.R` checks every md5 before it runs. Raw survey microdata are **not** committed (see below).

## Survey microdata (not in git)

DHS, MIS and MICS microdata cannot be redistributed. Register with the programmes and place the files as follows. `raw_manifest.csv` lists every file name with its size and md5, but no contents.

| What | Where | How to obtain |
|---|---|---|
| 124 DHS/MIS Births Recodes (BR), as `.rds` files named by the DHS file name, e.g. `NGBR8BFL.rds` | `data/raw/dhs/` | [DHS Program](https://dhsprogram.com/data/) (registration and project approval). The files were read with `rdhs` (`R_inputs/fetch/01_access_dhs_data.R --download` saves them in this form). |
| DHS/MIS Household Member Recodes (PR, flat), e.g. `NGPR8BFL.rds`, for every DHS survey, and WHO height/weight recodes (HW, Stata), e.g. `BFHW43DT.rds`, for the older surveys whose BR files lack WHO z-scores; the list is `R_cbh/snow/config/dhs_pr_hw_files.csv` | `data/raw/dhs/` | As above (`R_inputs/fetch/download_pr_hw.R`). Used for the Snow-unit covariates; SLPR61FL also recomputes the Sierra Leone 2013 regional values of v9. |
| 93 UNICEF MICS survey downloads (zip archives in `<ISO>_<year>_MICS<n>_v01_M/` folders) | `data/raw/MICS_Datasets/` | [UNICEF MICS](https://mics.unicef.org/surveys) (registration). `R_mics/00a_extract.R` extracts the SPSS files to `data/raw/MICS_extracted/`. |
| Full UNICEF data dump `fusion_GLOBAL_DATAFLOW_UNICEF_1.0_all.csv` (563 MB) | `data/unicef/original/` | [UNICEF data warehouse](https://data.unicef.org/), global dataflow. Optional: only needed to remake the committed extract (`R_inputs/trim_unicef_fusion.R`). |

Every file derived from microdata (child-band files, prepared datasets, model fits, survey-region covariate tables) is written to `data/derived_cbh/`, `data/derived_dhs/` or `data/derived_mics/`. These folders, `data/raw/` and `results/` are ignored by git. `tools/check_no_microdata.sh` blocks a commit that would add such files.

## Committed inputs

| Input | Files | Source and terms |
|---|---|---|
| MAP *P. falciparum* parasite rate, ages 2–10, annual 2000–2024 (release `Malaria__202508_Global_Pf_Parasite_Rate`) | `map_annual/pfpr2_10_YYYY.tif` (survey-region exposure), `pfpr_2to10_africa_2024.tif` (national burden, 2024) | [Malaria Atlas Project](https://malariaatlas.org/), via `malariaAtlas` (`R_inputs/fetch/01_fetch_data.R`). CC BY 4.0. The two 2024 rasters differ (different downloads). |
| GPW v4 population density 2020, 2.5 arc-minutes | `pop/gpw_v4_population_density_rev11_2020_2.5m.tif` | CIESIN/SEDAC. CC BY 4.0. |
| National boundaries | `africa_admin0.rds` | `geodata`/GADM via `R_inputs/fetch/01_fetch_data.R`. |
| DHS survey-region boundaries | `dhs_boundaries/<SurveyId>.rds` (128) | [DHS Spatial Data Repository](https://spatialdata.dhsprogram.com/), via `rdhs::download_boundaries`. |
| Snow et al. (2017) sub-national polygons: the 520 malaria-endemic units of analysis (plus 29 malaria-free and 2 island units); also Guinea-Bissau and CAR MICS regions and some MICS region labels | `external/snow_admin1/Africa_New_Admin.*` | Snow malaria prevalence project (KEMRI-Wellcome), released open access with the original publication (Snow et al. 2017, *Nature* 550:515–518; per the authors of this repository, 11 October 2026). |
| Lakes and reservoirs (Natural Earth 1:10m, v5) | `external/natural_earth/ne_10m_lakes.geojson` | [Natural Earth](https://www.naturalearthdata.com/), from the `nvkelso/natural-earth-vector` repository (downloaded 12 October 2026). Public domain. Drawn on the Figure 1 map only. |
| UNICEF/WHO immunisation estimates (WUENIC) | `unicef/fusion_GLOBAL_DATAFLOW_UNICEF_1.0_immunisation_subset.csv`, `unicef/CHECKSUMS.csv` | Header plus every `IM_` line of the UNICEF data dump, unchanged (`R_inputs/trim_unicef_fusion.R`). |
| Child HIV epidemiology (UNAIDS 2025 estimates, via UNICEF) | `HIV_Epidemiology_Children_Adolescents_2025.xlsx` | [UNICEF data](https://data.unicef.org/topic/hivaids/). |
| New HIV infections, children 0–14, Liberia | `unaids_aidsinfo/liberia_new_hiv_infections_children_0_14.csv` | [UNAIDS AIDSinfo](https://aidsinfo.unaids.org/). |
| GDP per capita (current US$, NY.GDP.PCAP.CD); current health expenditure per capita (current US$, SH.XPD.CHEX.PC.CD); political stability (WGI, GOV_WGI_PV_EST) | `wb_gdp_pc.csv`, `wb_hexp_pc.csv`, `wb_polstab.csv` | World Bank WDI / Worldwide Governance Indicators, CC BY 4.0. Fetch scripts: `R_inputs/fetch/01_fetch_data.R` and `R_inputs/fetch/fetch_world_bank.R`. |
| IHME GBD all-cause under-five deaths and rates by age group, 45 sub-Saharan countries, 2000–2025 (exported 9 September 2026) | `Data Explorer - … 2026-09-09 10-58-22.csv` | [IHME GBD Results](https://vizhub.healthdata.org/gbd-results/). **IHME terms of use apply** (non-commercial; attribution). |
| IHME GBD under-five malaria deaths by age (exported 3 September 2026) | `ihme_malaria_u5_deaths_by_age_country_year.csv` | As above. |
| IHME GBD Nigerian states: all-cause and malaria (exported 16 September 2026) | `external/nigeria_states/` (with `source.json`) | As above. |
| UN IGME under-five mortality rate (World Bank mirror, SH.DYN.MORT) | `igme_u5mr_by_country.csv` | [UN IGME](https://childmortality.org/). Fetch script: `R_inputs/fetch/fetch_igme_u5mr.R`. |
| CA-CODE 2026 under-five malaria deaths and malaria share of under-five deaths | `external/figure5/unicef_cacode_u5_malaria_2000_2024.csv`, `external/cacode/unicef_cacode_u5_malaria_fraction_2000_2024.csv` (each with `source.json`) | UNICEF SDMX service behind [childmortality.org](https://childmortality.org/causes-of-death/data), WHO/UNICEF CA-CODE release of 18 March 2026. |
| MAP PfPR for Nigerian states and DR Congo provinces, 2024 | `pfpr_admin1_ng_cd_2024.csv` | Computed from the 2024 MAP raster and malariaAtlas admin-1 shapes (`R_inputs/fetch/pfpr_admin1_ng_cd_2024.R`). |

## Frozen copies of fetched inputs (`frozen/`)

The re-run uses the same vintages of internet sources as the paper. `run_pipeline.R` (stage `restore`) copies these files from `frozen/<path>` to `<path>`:

- **DHS survey registry** (`frozen/data/derived_dhs/survey_registry.csv`). This is the DHS catalogue query of `R_inputs/fetch/01_access_dhs_data.R`, with repository-relative paths. Re-querying the live catalogue could add surveys.
- **DHS API pages.** The published regional indicator pages (`*_page*.json`), the nutrition pages and the StatCompiler indicator table.
- **National HIV prevalence panel.** A legacy candidate column in the child-band files; the model does not use it.

The fetch scripts reuse these caches and download only missing pages. The pipeline blocks network access, so a missing cache fails instead of downloading.

`frozen/` also holds reference copies of the survey-region MAP tables and the child HIV incidence panels from the analysis project. They are used only to diagnose a difference (`run_pipeline.R --map=frozen` uses the MAP tables).

## Provenance

`INPUTS_MANIFEST.csv` and `raw_manifest.csv` were written by `tools/import_from_analysis_project.R`, which copied the inputs from the analysis project where the paper's analysis was developed.
