#!/usr/bin/env python3
"""Export the paper's figures, tables and captions to a manuscript folder (default use: paper/ in this
repository, compared with the Overleaf project); never writes a TeX file."""
import argparse
import csv
import hashlib
import json
import os
import shutil
from datetime import datetime, timezone
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--destination", type=Path, required=True)
parser.add_argument("--copy", action="store_true", help="Copy after validating; default is a local export manifest only")
# The GADM-unit primary (CBH_PRIMARY_VERSION=gadm, set by run_pipeline.R). The Snow-unit primary (v11-v14) was replaced
# by GADM units in v15 (author decision, 3 November 2026; code in git history up to f2db98e).
assert os.environ.get("CBH_PRIMARY_VERSION", "gadm") == "gadm", "export_paper.py exports the GADM-unit primary (gadm)"
default_root = "results/cbh/primary_gadm_merge_dhsmics_gamma2_v15"
parser.add_argument("--root", type=Path, default=Path(default_root))
args = parser.parse_args()
root = args.root
out = root / "paper_refresh"
out.mkdir(parents=True, exist_ok=True)
destination = args.destination.expanduser().resolve()
assert destination.is_dir()
# Sensitivities refitted on the GADM-unit sample.
subgroups = Path("results/cbh/subgroups_gadm_merge_gamma2_v9")
nutrition = Path("results/cbh/nutrition_adjustment_gadm_merge_gamma2_v9")
imputed = Path("results/cbh/primary_gadm_merge_imputed_gamma2_v16")
# Country fixed effects (31 October 2026).
country_fe = Path("results/cbh/country_fixed_effects_gadm_merge_gamma2_v3")

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def read_csv(path):
    with path.open() as f:
        return list(csv.DictReader(f))

figures = read_csv(root / "paper_figures/manifest.csv")
assert [int(x["figure"]) for x in figures] == list(range(1, 6))
assets = []
for row in figures:
    source = Path(row["source"])
    assert source.is_relative_to(root)
    assert hashlib.md5(source.read_bytes()).hexdigest() == row["md5"]
    assets.append((source, Path("figures") / row["filename"]))
assets.extend([
    (root / "paper_figures/CAPTIONS.md", Path("figures/primary_figure_captions.md")),
    # Supplementary figures and tables: those main.tex uses (cut to main.tex, 1 November 2026), plus the survival
    # against PfPR by sub-region and the country fixed effects (both kept by the author).
    (subgroups / "sfig_pfpr_splines_by_subgroup.png", Path("Supplementary Figures/sfig_pfpr_splines_by_subgroup.png")),
    (subgroups / "CAPTION.md", Path("Supplementary Figures/sfig_pfpr_splines_by_subgroup_caption.md")),
    (root / "study_flow/study_flow_diagram.png", Path("Supplementary Figures/sfig_study_flow.png")),
    (nutrition / "sfig_pfpr_splines_without_nutrition.png", Path("Supplementary Figures/sfig_pfpr_splines_without_nutrition.png")),
    (nutrition / "CAPTION.md", Path("Supplementary Figures/sfig_pfpr_splines_without_nutrition_caption.md")),
    (imputed / "sfig_pfpr_splines_imputed_covariates.png", Path("Supplementary Figures/sfig_pfpr_splines_imputed_covariates.png")),
    (imputed / "CAPTION_sfig_imputed_covariates.md", Path("Supplementary Figures/sfig_pfpr_splines_imputed_covariates_caption.md")),
    (root / "study_flow/CAPTION.md", Path("Supplementary Figures/sfig_study_flow_caption.md")),
    (root / "malaria_share/sfig_malaria_share_vs_pfpr.png", Path("Supplementary Figures/sfig_malaria_share_vs_pfpr.png")),
    (root / "malaria_share/CAPTION.md", Path("Supplementary Figures/sfig_malaria_share_vs_pfpr_caption.md")),
])
# The extended subgroup suite (12 October 2026).
assets.extend([
    (subgroups / "sfig_pfpr_splines_by_subregion.png", Path("Supplementary Figures/sfig_pfpr_splines_by_subregion.png")),
    (subgroups / "CAPTION_sfig_pfpr_splines_by_subregion.md", Path("Supplementary Figures/sfig_pfpr_splines_by_subregion_caption.md")),
    # Units of the regional sub-analyses (author request, 1 November 2026).
    (subgroups / "sfig_subregion_units_map.png", Path("Supplementary Figures/sfig_subregion_units_map.png")),
    (subgroups / "CAPTION_sfig_subregion_units_map.md", Path("Supplementary Figures/sfig_subregion_units_map_caption.md")),
    (subgroups / "sfig_pfpr_splines_by_period.png", Path("Supplementary Figures/sfig_pfpr_splines_by_period.png")),
    (subgroups / "CAPTION_sfig_pfpr_splines_by_period.md", Path("Supplementary Figures/sfig_pfpr_splines_by_period_caption.md")),
    # Raw survival against PfPR by UN sub-region with unadjusted spline fits (user request, 15 October 2026).
    (subgroups / "sfig_survival_vs_pfpr_by_subregion.png", Path("Supplementary Figures/sfig_survival_vs_pfpr_by_subregion.png")),
    (subgroups / "CAPTION_sfig_survival_vs_pfpr_by_subregion.md", Path("Supplementary Figures/sfig_survival_vs_pfpr_by_subregion_caption.md")),
    # Countries of the Sahel subset (>= 10N): PfPR and crude mortality by age band (user request, 4 November 2026).
    (subgroups / "table_sahel_countries.latex.txt", Path("tables/table_sahel_countries.latex.txt")),
    (subgroups / "table_sahel_countries.csv", Path("tables/table_sahel_countries.csv")),
    # Country fixed effects in place of the country random intercept (author request, 31 October 2026).
    (country_fe / "sfig_pfpr_splines_country_fixed_effects.png", Path("Supplementary Figures/sfig_pfpr_splines_country_fixed_effects.png")),
    (country_fe / "CAPTION.md", Path("Supplementary Figures/sfig_pfpr_splines_country_fixed_effects_caption.md")),
    (country_fe / "SUMMARY.md", Path("tables/country_fixed_effects_summary.md")),
    # Figure 1 is the map of complete birth histories by analysis unit (author request, 12 October 2026).
    (root / "analysis_units_map/CAPTION.md", Path("figures/fig1_analysis_units_map_caption.md")),
    # National malaria-attributable mortality per 1,000 child-years by all-cause source (user request, 27 October
    # 2026): UN IGME in the main text, IHME in the supplement.
    # The UN IGME version is Figure 4 (paper_figures/manifest.csv); Figure 2 is the hazard ratio by age.
    (root / "mortality_rates/CAPTION_unigme.md", Path("figures/fig4_malaria_mortality_rates_unigme_caption.md")),
    (root / "hazard_ratio_by_age/CAPTION.md", Path("figures/fig2_hazard_ratio_by_age_caption.md")),
    (root / "model_vs_cause_specific/CAPTION.md", Path("figures/fig5_model_vs_cause_specific_2024_caption.md")),
    (root / "mortality_rates/sfig_malaria_mortality_rates_ihme.png", Path("Supplementary Figures/sfig_malaria_mortality_rates_ihme.png")),
    (root / "mortality_rates/CAPTION_ihme.md", Path("Supplementary Figures/sfig_malaria_mortality_rates_ihme_caption.md")),
    # Country rates from IHME against UN IGME all-cause deaths, 2024 (R_cbh/reporting/28_malaria_rates_ihme_vs_unigme.R,
    # formerly hand-run; 1 November 2026), under its Overleaf file name.
    (root / "ihme_vs_unigme/sfig_malaria_rates_ihme_vs_unigme_2024.png", Path("Supplementary Figures/sfig_malaria_rates_ihme_vs_unigme_2024.png")),
    (root / "ihme_vs_unigme/CAPTION.md", Path("Supplementary Figures/sfig_malaria_rates_ihme_vs_unigme_2024_caption.md")),
    (root / "annual_comparison/source_annual_rates_2000_2024.csv", Path("tables/source_annual_rates_2000_2024.csv")),
    # Supplementary table of 2024 country rates by source (user request, 28 October 2026).
    (root / "tables/country_rates_2024.latex.txt", Path("tables/country_rates_2024.latex.txt")),
    (root / "tables/country_rates_2024.csv", Path("tables/country_rates_2024.csv")),
    # Draw-based 95% uncertainty intervals (R_cbh/burden/06_uncertainty_draws.R; 1 November 2026).
    (root / "uncertainty/annual_intervals_2000_2024.csv", Path("tables/uncertainty_annual_intervals_2000_2024.csv")),
    (root / "uncertainty/country_year_intervals_2000_2024.csv", Path("tables/uncertainty_country_year_intervals_2000_2024.csv")),
    (root / "uncertainty/contrasts.csv", Path("tables/uncertainty_contrasts.csv")),
    (root / "uncertainty/SPEC.md", Path("tables/uncertainty_specification.md")),
])
assets.extend([
    # Number sources of the text: age-band deaths and the comparator declines (under-five rows only).
    (root / "tables/age_band_results.csv", Path("tables/age_band_results.csv")),
    (root / "burden_comparison/source_comparison_2000_2024.csv", Path("tables/source_comparison_2000_2024.csv")),
    (root / "annual_comparison/annual_totals_2000_2024.csv", Path("tables/annual_totals_2000_2024.csv")),
])

def check(source, rel):
    assert source.is_file(), f"Missing export source: {source}"
    assert source.suffix.lower() != ".tex"
    assert not rel.is_absolute() and ".." not in rel.parts and rel.suffix.lower() != ".tex"
    assert (destination / rel).resolve().is_relative_to(destination)

# Validate every source before the export manifest is written.
targets = [str(rel) for _, rel in assets]
assert len(set(targets)) == len(targets)
for source, rel in assets:
    check(source, rel)
# A sensitivity figure is current only if its report was rerun after the last change to its inputs or code
# (for example R_cbh/sensitivity/subgroups/02_report.R after an axis change).
for sensitivity in (subgroups, nutrition, country_fe):
    stale = [row["file"] for row in read_csv(sensitivity / "report_provenance.csv")
             if not Path(row["file"]).is_file() or hashlib.md5(Path(row["file"]).read_bytes()).hexdigest() != row["md5"]]
    assert not stale, f"Stale report provenance in {sensitivity}: {', '.join(stale)}; rerun its report script"
figure_dirs = [(root / "malaria_share", "R_cbh/reporting/20_malaria_share_vs_pfpr.R"),
               (root / "mortality_rates", "R_cbh/reporting/24_malaria_mortality_rates.R"),
               (root / "hazard_ratio_by_age", "R_cbh/reporting/26_hazard_ratio_by_age.R"),
               (root / "model_vs_cause_specific", "R_cbh/reporting/27_model_vs_cause_specific.R"),
               (root / "ihme_vs_unigme", "R_cbh/reporting/28_malaria_rates_ihme_vs_unigme.R"),
               (root / "uncertainty", "R_cbh/burden/06_uncertainty_draws.R")]
for figure_dir, script in figure_dirs:
    stale = [row["file"] for row in read_csv(figure_dir / ("input_provenance.csv" if figure_dir.name == "uncertainty" else "provenance.csv"))
             if not Path(row["file"]).is_file() or hashlib.md5(Path(row["file"]).read_bytes()).hexdigest() != row["md5"]]
    assert not stale, f"Stale provenance for {figure_dir}: {', '.join(stale)}; rerun {script}"
rows = [dict(source=str(source.resolve()), destination=str(destination / rel),
             sha256=digest(source), previous_sha256=digest(destination / rel) if (destination / rel).is_file() else "")
        for source, rel in assets]
with (out / "export_manifest.csv").open("w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=list(rows[0]), lineterminator="\n")
    writer.writeheader(); writer.writerows(rows)
if not args.copy:
    print(f"Validated {len(assets)} assets for export; destination unchanged.")
    raise SystemExit(0)

tex_before = {str(p): digest(p) for p in destination.rglob("*.tex")}
backup = out / "previous_overleaf" / datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
for source, rel in assets:
    target = destination / rel
    if target.is_file():
        saved = backup / rel
        saved.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(target, saved)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
    assert digest(target) == digest(source)
tex_after = {str(p): digest(p) for p in destination.rglob("*.tex")}
assert tex_before == tex_after, "TeX changed during export; inspect without overwriting the author's edits"
(out / "export_verification.json").write_text(json.dumps(dict(
    destination=str(destination), exported_assets=len(assets), all_copy_hashes_match=True,
    tex_unchanged_during_export=True, tex_hashes=tex_after, previous_asset_backup=str(backup),
    completed_at=datetime.now(timezone.utc).isoformat()), indent=2) + "\n")
print(f"Exported and verified {len(assets)} assets; {len(tex_after)} TeX files unchanged.")
