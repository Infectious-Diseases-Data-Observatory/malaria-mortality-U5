#!/usr/bin/env bash
# Refuse a commit that would add microdata or very large files. Run before every commit:
#   tools/check_no_microdata.sh   (checks the staged files)
set -euo pipefail
shopt -s nocasematch   # recode names occur in lower case too (lbpr51fl.rds)
fail=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    data/raw/*|data/derived_cbh/*|data/derived_dhs/*|data/derived_mics/*|data/unicef/original/*|data/dhs/*|data/snow_prevalence_model/*|results/*|logs/*)
      echo "BLOCKED (microdata-derived or output path): $f"; fail=1 ;;
  esac
  case "$f" in
    *records_placed*|*complete_case_dataset*|*covariates_*_long*|*record_units*)
      echo "BLOCKED (record-level file name): $f"; fail=1 ;;
  esac
  case "$f" in   # data files are committed only in these folders
    *.rds|*.gpkg)
      case "$f" in data/africa_admin0.rds|data/dhs_boundaries/*|data/frozen/*|data/external/*) ;;
        *) echo "BLOCKED (.rds/.gpkg outside the committed data folders): $f"; fail=1 ;; esac ;;
  esac
  case "$f" in
    *.sav|*.SAV|*.dta|*.DTA) echo "BLOCKED (survey microdata format): $f"; fail=1 ;;
  esac
  b=$(basename "$f")
  # DHS recode file names, e.g. NGBR8BFL.rds, SLPR61FL.rds, KEKR8CFL.DTA, BFHW43DT.rds (any case)
  if [[ "$b" =~ ^[A-Z]{2}(BR|KR|PR|IR|HR|MR|CR|GE|WI|BH|WM|HH|CH|HW|AR|HV|FW)[0-9A-Z]{2}(FL|SV|DT|SD)\. ]]; then
    echo "BLOCKED (DHS recode file name): $f"; fail=1
  fi
  if [ -f "$f" ]; then
    size=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")
    if [ "$size" -gt 52428800 ]; then echo "BLOCKED (over 50 MB): $f ($size bytes)"; fail=1; fi
  fi
done < <(git diff --cached --name-only --diff-filter=AM)
if [ "$fail" -ne 0 ]; then echo "check_no_microdata: FAILED"; exit 1; fi
echo "check_no_microdata: OK"
