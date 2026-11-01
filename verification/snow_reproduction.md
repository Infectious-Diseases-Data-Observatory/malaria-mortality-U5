# Snow units: reproduction of the analysis project's split variant (verification step 1)

12 October 2026. The ported unit construction (`R_cbh/snow/01`–`10`, `R_cbh/primary/00_prepare_snow.R`) was run as
`SNOW_VARIANT=split_repro` / `CBH_PRIMARY_VERSION=snow_split_repro`. That is the v9 survey list and v9's `model_ready`
records, with no rule fixes, and the analysis project's `polygons_520.gpkg` read in place for the polygon PfPR. The
outputs were compared with the analysis project's `results/cbh/snow_units/` and `data/derived_cbh/snow_units/`
(read only).

| Step | Output | Result |
|---|---|---|
| 02 polygon PfPR | `pfpr/pfpr_polygon_year.csv` (13,000 rows) | 99 values differ, by at most 5.9e-10 PfPR points (relative < 1e-11). |
| 03 feasibility | `region_snow_overlap.csv`, `region_classification.csv`, `survey_feasibility.csv` | Byte-identical. |
| 04 location variables | `location_variables.csv` | Byte-identical. |
| 05 finer units | `finer_variable_choice.csv`, `finer_unit_crosswalk.csv` | Byte-identical. |
| | `record_placement_by_region.csv`, `survey_feasibility_final_v9.csv`, `_all.csv` (= `_v10`) | Identical apart from one category label, renamed to "outside the shapefile (Comoros, Zanzibar, Sao Tome)". |
| 06 labels | `pr_labels.csv` | Byte-identical. |
| | `br_labels.csv` | Identical content; the analysis project's copy quotes empty strings (`""`). |
| 07 placement | `finer_unit_shares.csv`, `placement_summary.csv` | Byte-identical. |
| | `records_placed.rds` (9,983,417 rows) | `identical()` after sorting. |
| 08 units (merge rule applied to this placement) | 1,422 units, 5,875 records dropped as mostly malaria-free | Equal to the analysis project's corrected `19_merge_rule_all.R`: units, records and deaths. The earlier run of that script duplicated polygons in 119 sets; it was fixed after this comparison found the duplicates. |
| 09/10 covariates | `covariates_dhs_long.csv` (18,044 rows), `covariates_mics_long.csv` (4,208) | Identical (column `unit` = `Admin_ID` under the split rule). |
| | the five audit tables | Identical. |
| 00_prepare_snow | prepared dataset (9,690,169 rows) | Identical keys, weights, deaths and all 17 z-scores. PfPR within 5.9e-10. |
| | Totals | 7,478,478.29 weighted records, 102,973.30 deaths, 2,290,868 children, 1,717 units, 456 polygons, 133 surveys, 36 countries. |

The reproduction is not fitted; the primary uses the merge rule (`snow_merge`).

Since 1 November 2026 (v9 removed), `03_feasibility.R`, `04_location_variables.R` and `05_finer_units.R` no longer write
the `in_v9` and `records_v9` columns or `survey_feasibility_final_v9.csv` (they came from the v9 prepared dataset), so those
files no longer match the analysis project's byte for byte. Classes, placements, units and the prepared dataset are
unaffected.
