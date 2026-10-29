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
# The primary version (CBH_PRIMARY_VERSION, set by run_pipeline.R): snow_merge = the Snow-unit primary (since
# 11 October 2026), regional_mics = the v9 survey-region primary.
snow = os.environ.get("CBH_PRIMARY_VERSION", "regional_mics") == "snow_merge"
default_root = "results/cbh/primary_snow520_merge_dhsmics_gamma2_v12" if snow else "results/cbh/primary_map_regional17_dhsmics_gamma2_v9"
parser.add_argument("--root", type=Path, default=Path(default_root))
args = parser.parse_args()
root = args.root
out = root / "paper_refresh"
out.mkdir(parents=True, exist_ok=True)
destination = args.destination.expanduser().resolve()
assert destination.is_dir()
# Sensitivities refitted on the DHS and MICS sample; the DHS-only versions are kept as history.
subgroups = Path("results/cbh/subgroups_snow520_merge_gamma2_v6" if snow else "results/cbh/subgroups_dhsmics_map_gamma2_v4")
nutrition = Path("results/cbh/nutrition_adjustment_snow520_merge_gamma2_v6" if snow else "results/cbh/nutrition_adjustment_dhsmics_map_gamma2_v4")
imputed = Path("results/cbh/primary_snow520_merge_imputed_gamma2_v12" if snow else "results/cbh/primary_map_regional17_dhsmics_imputed_gamma2_v10")

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
    # Reorganised 28 October 2026 (author request): the burden comparison and the probability of dying before age 5
    # are supplementary figures; the log-HR curves relative to 20% (pfpr_splines.png) are no longer in the paper.
    (root / "burden_comparison/fig4_burden_comparison.png", Path("Supplementary Figures/sfig_burden_comparison.png")),
    (root / "burden_comparison/CAPTION.md", Path("Supplementary Figures/sfig_burden_comparison_caption.md")),
    (root / "under5_probability/under5_death_probability_2024.png", Path("Supplementary Figures/sfig_under5_death_probability.png")),
    (root / "under5_probability/CAPTION.md", Path("Supplementary Figures/sfig_under5_death_probability_caption.md")),
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
if snow:
    # Snow-unit primary: the extended subgroup suite (12 October 2026), the maps of survey-regions against the Snow
    # polygons (one per country where units had to be merged) and the comparison with the v9 survey-region primary.
    snow_maps = Path("results/cbh/snow_units/merge/maps")
    assets.extend([
        (subgroups / "sfig_pfpr_splines_by_subregion.png", Path("Supplementary Figures/sfig_pfpr_splines_by_subregion.png")),
        (subgroups / "CAPTION_sfig_pfpr_splines_by_subregion.md", Path("Supplementary Figures/sfig_pfpr_splines_by_subregion_caption.md")),
        (subgroups / "sfig_pfpr_splines_by_period.png", Path("Supplementary Figures/sfig_pfpr_splines_by_period.png")),
        (subgroups / "CAPTION_sfig_pfpr_splines_by_period.md", Path("Supplementary Figures/sfig_pfpr_splines_by_period_caption.md")),
        (subgroups / "pfpr_40_to_20_by_subgroup.png", Path("Supplementary Figures/sfig_pfpr_40_to_20_by_subgroup.png")),
        # Raw survival against PfPR by UN sub-region with unadjusted spline fits (user request, 15 October 2026).
        (subgroups / "sfig_survival_vs_pfpr_by_subregion.png", Path("Supplementary Figures/sfig_survival_vs_pfpr_by_subregion.png")),
        (subgroups / "CAPTION_sfig_survival_vs_pfpr_by_subregion.md", Path("Supplementary Figures/sfig_survival_vs_pfpr_by_subregion_caption.md")),
        (snow_maps / "boundary_agreement_map.png", Path("Supplementary Figures/sfig_snow_boundary_agreement_map.png")),
        (snow_maps / "CAPTION_boundary_agreement_map.md", Path("Supplementary Figures/sfig_snow_boundary_agreement_map_caption.md")),
        (root / "comparison_v9/pfpr_hr_curves_v9_vs_snow.png", Path("Supplementary Figures/sfig_pfpr_curves_v9_vs_snow.png")),
        (root / "comparison_v9/COMPARISON.md", Path("tables/comparison_v9_vs_snow.md")),
        # Figure 1 is the map of complete birth histories by analysis unit; the survey map and timing (Figure 1 of
        # v9) moves to the supplement (author request, 12 October 2026).
        (root / "analysis_units_map/CAPTION.md", Path("figures/fig1_analysis_units_map_caption.md")),
        (root / "survey_map/survey_map_and_timing.png", Path("Supplementary Figures/sfig_survey_map_and_timing.png")),
        (root / "survey_map/CAPTION.md", Path("Supplementary Figures/sfig_survey_map_and_timing_caption.md")),
        # National malaria-attributable mortality per 1,000 child-years by all-cause source (user request, 27 October
        # 2026): UN IGME in the main text, IHME in the supplement.
        # The UN IGME version is Figure 4 (paper_figures/manifest.csv); Figure 2 is the hazard ratio by age.
        (root / "mortality_rates/CAPTION_unigme.md", Path("figures/fig4_malaria_mortality_rates_unigme_caption.md")),
        (root / "hazard_ratio_by_age/CAPTION.md", Path("figures/fig2_hazard_ratio_by_age_caption.md")),
        (root / "model_vs_cause_specific/CAPTION.md", Path("figures/fig5_model_vs_cause_specific_2024_caption.md")),
        (root / "mortality_rates/sfig_malaria_mortality_rates_ihme.png", Path("Supplementary Figures/sfig_malaria_mortality_rates_ihme.png")),
        (root / "mortality_rates/CAPTION_ihme.md", Path("Supplementary Figures/sfig_malaria_mortality_rates_ihme_caption.md")),
        (root / "annual_comparison/source_annual_rates_2000_2024.csv", Path("tables/source_annual_rates_2000_2024.csv")),
        # Supplementary table of 2024 country rates by source (user request, 28 October 2026).
        (root / "tables/country_rates_2024.latex.txt", Path("tables/country_rates_2024.latex.txt")),
        (root / "tables/country_rates_2024.csv", Path("tables/country_rates_2024.csv")),
    ])
    for png in sorted((snow_maps / "merge_units").glob("*_merge_units.png")):
        assets.append((png, Path("Supplementary Figures/snow_merge_units") / png.name))
    assets.append((snow_maps / "CAPTION_merge_units.md", Path("Supplementary Figures/snow_merge_units/CAPTION.md")))
for name in ("age_band_results.csv", "age_band_results.md", "age_band_results.latex.txt",
             "country_comparison_2024.csv", "country_comparison_2024_top10.md", "country_comparison_2024.latex.txt"):
    assets.append((root / "tables" / name, Path("tables") / name))
assets.extend([
    (root / "burden_comparison/source_comparison.latex.txt", Path("tables/source_comparison.latex.txt")),
    (root / "burden_comparison/source_comparison_2000_2024.csv", Path("tables/source_comparison_2000_2024.csv")),
    (root / "annual_comparison/annual_totals_2000_2024.csv", Path("tables/annual_totals_2000_2024.csv")),
    (root / "nigeria_states/state_totals_2024.csv", Path("tables/nigeria_state_totals_2024.csv")),
])
handoff = out / "OVERLEAF_UPDATE.md"
handoff_rel = Path("RESULTS_UPDATE.md")

def check(source, rel):
    assert source.is_file(), f"Missing export source: {source}"
    assert source.suffix.lower() != ".tex"
    assert not rel.is_absolute() and ".." not in rel.parts and rel.suffix.lower() != ".tex"
    assert (destination / rel).resolve().is_relative_to(destination)

# Validate every source before the handoff is written, so a failed export leaves no new handoff.
targets = [str(rel) for _, rel in assets] + [str(handoff_rel)]
assert len(set(targets)) == len(targets)
for source, rel in assets:
    check(source, rel)
# A sensitivity figure is current only if its report was rerun after the last change to its inputs or code
# (for example R_cbh/sensitivity/subgroups/02_report.R after an axis change).
for sensitivity in (subgroups, nutrition):
    stale = [row["file"] for row in read_csv(sensitivity / "report_provenance.csv")
             if not Path(row["file"]).is_file() or hashlib.md5(Path(row["file"]).read_bytes()).hexdigest() != row["md5"]]
    assert not stale, f"Stale report provenance in {sensitivity}: {', '.join(stale)}; rerun its report script"
figure_dirs = [(root / "malaria_share", "R_cbh/reporting/20_malaria_share_vs_pfpr.R")]
if snow:
    figure_dirs.append((root / "mortality_rates", "R_cbh/reporting/24_malaria_mortality_rates.R"))
    figure_dirs.append((root / "hazard_ratio_by_age", "R_cbh/reporting/26_hazard_ratio_by_age.R"))
    figure_dirs.append((root / "model_vs_cause_specific", "R_cbh/reporting/27_model_vs_cause_specific.R"))
for figure_dir, script in figure_dirs:
    stale = [row["file"] for row in read_csv(figure_dir / "provenance.csv")
             if not Path(row["file"]).is_file() or hashlib.md5(Path(row["file"]).read_bytes()).hexdigest() != row["md5"]]
    assert not stale, f"Stale provenance for {figure_dir}: {', '.join(stale)}; rerun {script}"

sample =read_csv(root / "prepared_sample.csv")[0]
annual = next(row for row in read_csv(root / "annual_comparison/annual_totals_2000_2024.csv") if row["year"] == "2024")
n_covariates = len(read_csv(root / "covariate_scaling.csv"))
coverage = read_csv(root / "survey_map/survey_coverage.csv")
selection = {row["survey"]: row for row in read_csv(root / "prepared_selection_by_survey.csv")}
timeline = read_csv(root / "survey_map/survey_timeline_all.csv")
burden_countries = {row["iso3"] for row in read_csv(root / "annual_comparison/included_countries.csv")}
assert {row["type"] for row in coverage} <= {"DHS", "MICS"} and len(coverage) == int(sample["surveys"])

def part(kind):
    rows = [row for row in coverage if row["type"] == kind]
    return dict(surveys=len(rows), countries={row["country"] for row in rows},
                regions=sum(int(row["regions"]) for row in rows),
                records=sum(round(float(selection[row["survey"]]["records"])) for row in rows),
                deaths=sum(round(float(selection[row["survey"]]["deaths"])) for row in rows))

dhs, mics = part("DHS"), part("MICS")
assert dhs["records"] + mics["records"] == round(float(sample["records"]))
assert dhs["deaths"] + mics["deaths"] == round(float(sample["deaths"]))
assert dhs["regions"] + mics["regions"] == int(sample["regions"])
survey_countries = dhs["countries"] | mics["countries"]
assert len(survey_countries) == int(sample["countries"]) and int(annual["countries"]) == len(burden_countries)
fmt = lambda x: f"{float(x):,.0f}"
codes = lambda x: ", ".join(sorted(x))
mis_total = sum(row["type"] == "MIS" for row in timeline)
outside = survey_countries - burden_countries
if snow:
    composition = (
        f"It combines {dhs['surveys']} DHS and {mics['surveys']} UNICEF MICS surveys, with records placed in the "
        f"malaria-endemic polygons of Snow et al. (2017): {fmt(dhs['records'])} DHS records and {fmt(dhs['deaths'])} deaths in "
        f"{fmt(dhs['regions'])} survey x unit areas, and {fmt(mics['records'])} MICS records and {fmt(mics['deaths'])} deaths in "
        f"{fmt(mics['regions'])} survey x unit areas."
        + (f" None of the {mis_total} MIS surveys passes complete-case selection." if mis_total and not any(
            row["type"] == "MIS" and row["status"].startswith("Included") for row in timeline) else ""))
    predictors = ("All 13 survey-level predictors are summaries for each survey x unit area (a Snow et al. polygon or a "
                  "union of polygons), computed from the DHS and MICS recodes with the DHS definitions, then the same "
                  "WUENIC and within-survey fallbacks as before.")
elif mics["surveys"]:
    # The DHS part is declared by the primary's settings and checked by the preparation.
    assert (root / "dhs_part.csv").is_file(), "dhs_part.csv missing; rerun R_cbh/primary/00_prepare_regional.R"
    reference = read_csv(root / "dhs_part.csv")[0]
    dhs_label = reference["note"]
    assert all(int(reference[k]) == dhs[k] for k in ("records", "deaths", "regions", "surveys")) and \
        int(reference["countries"]) == len(dhs["countries"]), "DHS part does not match its declared sample"
    added = mics["countries"] - dhs["countries"]
    composition = (
        f"It combines {dhs['surveys']} DHS and {mics['surveys']} UNICEF MICS surveys. "
        f"The DHS part is {dhs_label} "
        f"({fmt(dhs['records'])} records, {fmt(dhs['deaths'])} deaths, {fmt(dhs['regions'])} survey-regions, "
        f"{dhs['surveys']} surveys, {len(dhs['countries'])} countries); the MICS surveys add "
        f"{fmt(mics['records'])} records, {fmt(mics['deaths'])} deaths, {fmt(mics['regions'])} survey-regions"
        + (f" and {len(added)} {'country' if len(added) == 1 else 'countries'} ({codes(added)})." if added else ".")
        + (f" None of the {mis_total} MIS surveys passes complete-case selection." if mis_total else ""))
    predictors = ("All 13 survey-level predictors are survey-region summaries: for DHS surveys, published "
                  "regional indicators or weighted recode summaries; for MICS surveys, values computed from "
                  "the microdata with the DHS definitions and the same WUENIC and within-survey fallbacks.")
else:
    composition = f"The analysis contains {dhs['surveys']} DHS surveys."
    predictors = "All 13 survey-level predictors are survey-region summaries."
national = "The four national annual\nvariables are unchanged."
if snow:
    # Declared national substitutions of the Snow preparation (one row per country and covariate).
    subs = sorted({(r["country"], r["source_country"], r["before_year"], r["years"], r["records_in_sample"])
                   for r in read_csv(root / "national_substitutions.csv")})
    if subs:
        national = ("The four national annual\nvariables are unchanged, except the declared substitution"
                    + ("s" if len(subs) > 1 else "") + ": " + "; ".join(
                        f"{c} takes {src}'s GDP per capita, health expenditure per capita and political stability for "
                        f"band-entry years before {y} ({yrs.replace('-', '–')}; {fmt(n)} records)" for c, src, y, yrs, n in subs) + ".")
overlap = (f"{len(survey_countries & burden_countries)} of the {len(survey_countries)} survey countries"
           + (f"; {codes(outside)} contributes survey data but is outside the burden set" if len(outside) == 1 else
              f"; {codes(outside)} contribute survey data but are outside the burden set" if outside else ""))
v6 = imputed / "prepared_sample.csv"
v6_text = ""
if v6.is_file():
    s6 = read_csv(v6)[0]
    flow = {row["item"]: int(row["count"]) for row in read_csv(root / "study_flow/flow_counts.csv")}
    retained = int(s6["records"]) == (flow["placed"] if snow else flow["eligible"] - flow["missing_map"])
    kept = "record placed in a Snow et al. unit" if snow else "MAP-eligible record"
    v6_text = (f"{', which retains every ' + kept if retained else ''}: {fmt(s6['records'])} records, {fmt(s6['deaths'])} deaths, "
               f"{s6['surveys']} surveys and {s6['countries']} countries")
title = "Updated primary results (DHS and MICS surveys)" if mics["surveys"] else "Updated primary results"
fig1_text = ("Figure 1 is the map of complete birth histories used, by analysis unit (`figures/fig1_analysis_units_map.png`); "
             "the former Figure 1, the survey map and timing, is now `Supplementary Figures/sfig_survey_map_and_timing.png`.\n\n") if snow else ""
handoff.write_text(f"""# {title}

{fig1_text}Figures 1–5 (Figure 2 is the mortality hazard ratio by age band relative to
zero prevalence; Figure 3 the malaria-attributable fraction by age; Figure 4 national
malaria-attributable under-five mortality per 1,000 child-years, 2000–2024, with UN IGME
all-cause mortality; Figure 5 the PfPR-ACM estimates against the cause-specific
estimates of UN IGME and IHME by country in 2024; the burden comparison with IHME and UN IGME and the probability of
dying before age 5 are supplementary figures) and the
supplementary inclusion flow use the {n_covariates}-variable
regional-adjustment MAP gamma=2 models in `{root.name}`. The analysis contains
{fmt(sample['children'])} children, {fmt(sample['records'])} child-band records and
{fmt(sample['deaths'])} deaths in {fmt(sample['regions'])} {'survey x unit areas' if snow else 'survey-regions'},
{fmt(sample['surveys'])} surveys and {fmt(sample['countries'])} countries.

{composition}

The revised adjustment removes sex, multiple births and birth order; replaces
maternal age at each birth with regional mean age at first birth; and adds
regional wasting and stunting prevalence. {predictors} {national}

No TeX file has been edited. Update manuscript text and captions manually using:

- [Age-band table source](tables/age_band_results.latex.txt), with death
  percentages summing to 100.0% and both prevalence contrasts.
- [Country table source](tables/country_comparison_2024.latex.txt).
- [Source comparison table source](tables/source_comparison.latex.txt) and its
  [values](tables/source_comparison_2000_2024.csv).
- [Main figure captions](figures/primary_figure_captions.md), with the
  [Figure 2](figures/fig2_hazard_ratio_by_age_caption.md) and
  [Figure 4](figures/fig4_malaria_mortality_rates_unigme_caption.md) captions, and the
  [burden comparison caption](<Supplementary Figures/sfig_burden_comparison_caption.md>).
- [Inclusion-flow caption](<Supplementary Figures/sfig_study_flow_caption.md>).
- [Annual totals](tables/annual_totals_2000_2024.csv) and
  [Nigerian state totals](tables/nigeria_state_totals_2024.csv).

The 2024 totals are {fmt(annual['model_deaths'])} PfPR-ACM deaths,
{fmt(annual['ihme_malaria_deaths'])} IHME deaths and
{fmt(annual['who_cacode_deaths'])} UN IGME deaths, summed over the
{annual['countries']} countries in the national burden comparison ({overlap}).
These are conditional model-based estimates; source and imputation uncertainty
are not fully propagated.

The supplementary sensitivity figures are refitted on the DHS and MICS surveys:
subgroups (`{subgroups.name}`) and no nutrition covariates (`{nutrition.name}`)
on this sample, and imputed covariates on the larger {'sample of every placed record' if snow else 'MAP-eligible sample'}
(`{imputed.name}`{v6_text}). Malaria's share of under-five deaths against national
PfPR in 2024 (`Supplementary Figures/sfig_malaria_share_vs_pfpr.png`) compares IHME and
UN IGME (CA-CODE) with the PfPR-ACM model. Their captions are exported to
`Supplementary Figures/`.

Previous versions of overwritten files are backed up under `paper_refresh/previous_overleaf/`. `.latex.txt`
files contain source for manual insertion; they do not change the compiled
manuscript automatically. Figure placement and TeX references remain under the
author's control.
""")
assets.append((handoff, handoff_rel))
check(handoff, handoff_rel)
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
