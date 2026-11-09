#!/bin/bash
# Seasonality variant "mwi_districts" (R_cbh/sensitivity/seasonality/settings.R; user request, 9 November 2026):
# southern Africa with Malawi's 26 district units in place of its 3 regions, the same children as the main run, compared
# with it. Needs the finer-units data (data/derived_cbh/models/primary_gadm_fine_merge_dhsmics_gamma2_test1/
# complete_case_dataset.rds, built by R_cbh/sensitivity/finer_units/run.sh on branch gadm-finer-mwi-uga) and a current
# main seasonality run (stage seasonality of run_pipeline.R). Writes results/cbh/seasonality_gadm_mwi_districts_v1.
# Run from the repository root:   bash R_cbh/sensitivity/seasonality/run_mwi_districts.sh <log dir>   (about 10 minutes)
set -eu
[ -f run_pipeline.R ] || { echo "Run from the repository root."; exit 1; }
L="${1:?log directory}"; mkdir -p "$L"
f=data/derived_cbh/models/primary_gadm_fine_merge_dhsmics_gamma2_test1/complete_case_dataset.rds
[ -f "$f" ] || { echo "Missing $f: run R_cbh/sensitivity/finer_units/run.sh on branch gadm-finer-mwi-uga first."; exit 1; }
export CBH_PRIMARY_VERSION=gadm CBH_SEASONALITY_VARIANT=mwi_districts
for s in 01_prepare 02_fit 03_report; do echo "$(date +%H:%M:%S) start $s"
  Rscript "R_cbh/sensitivity/seasonality/$s.R" > "$L/mwi_districts_$s.txt" 2>&1 || { echo "FAILED $s"; tail -5 "$L/mwi_districts_$s.txt"; exit 1; }
done
echo "$(date +%H:%M:%S) done: results/cbh/seasonality_gadm_mwi_districts_v1/REPORT.md"
