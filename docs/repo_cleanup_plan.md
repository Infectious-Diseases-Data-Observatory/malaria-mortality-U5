# Repository cleanup plan (for author approval)

1 November 2026. Goal (author request): keep only the code, inputs and outputs needed to produce what `main.tex` uses
(main text and supplement), plus the repository infrastructure. Nothing has been removed. The v9 survey-region
primary is already removed on branch `remove-v9` (2d8e30b) and is not repeated here. Made by a read-only map of all
514 tracked files, a dependency trace from `main.tex` back to code and inputs, and an adversarial check of every
removal (77 entries confirmed safe; 11 corrections folded in below).

## Author decisions so far (1 November 2026)

- Removals and simplifications: **on hold** until the author has reviewed this plan.
- Country fixed-effects sensitivity (decision A): **keep** (stays in the pipeline and export; add to main.tex).
- Optional checks (decisions C, D, E): **as recommended**: remove the snow_repro stage and its split_repro branches,
  v9_surveys.csv and snow_reproduction.md, and the Snow label guard (snow/06, 06b); keep R_cbh/hiv/01_fit_incidence.R but
  make stage hiv optional.
- Legacy child-band inputs (decision F): **remove**, in the same batch as the clean rerun.
- Decisions B, G, H and I: the recommendations below apply unless the author says otherwise.
- `R_cbh/sensitivity/subgroups/03_survival_by_subregion.R` and its figure (survival against PfPR by sub-region): **keep**
  as a supplementary figure (relabelled to match the other figures; copied to Overleaf, 1 November 2026). Remove it and
  its two `paper/` files from the removal list below.
- Manuscript drafts: **removed** (author request; main.tex is edited by hand): the tracked `docs/manuscript/` files and
  `docs/PAPER_TEXT_SNOW.md` on branch `remove-v9`; the untracked drafts moved to the Trash. `eo_comments_replies.md`
  (another session's draft replies to Emelda Okiro's comments) is left until the author decides.

## What main.tex uses

| main.tex | File | Made by |
|---|---|---|
| line 122 | `figures/fig1_analysis_units_map.png` | paper/figures/fig1_analysis_units_map.png (md5 identical to Overleaf) + paper/figures/fig1_analysis_units_map_caption.md <- <primary root>/analysis_units_map/analysis_units_map.png, CAPTION.md, analysis_units_by_polygon.csv <- R_cbh/reporting/23_analysis_units… |
| line 132 | `figures/fig2_hazard_ratio_by_age.png` | paper/figures/fig2_hazard_ratio_by_age.png (identical) + fig2_hazard_ratio_by_age_caption.md <- <root>/hazard_ratio_by_age/fig2_hazard_ratio_by_age.png, CAPTION.md, hazard_ratio_curves.csv <- R_cbh/reporting/26_hazard_ratio_by_age.R (step hr_by_age), using the… |
| line 140 | `figures/fig3_malaria_attributable_fraction_by_age.png` | paper/figures/fig3_malaria_attributable_fraction_by_age.png (identical); caption only in paper/figures/primary_figure_captions.md <- <root>/attributable_fraction_by_age.png and .csv <- R_cbh/reporting/06_attributable_fraction_by_age.R (step age_fractions); cap… |
| line 154 | `figures/fig4_malaria_mortality_rates_unigme.png` | paper/figures/fig4_malaria_mortality_rates_unigme.png (identical) + fig4_..._caption.md <- <root>/mortality_rates/fig_malaria_mortality_rates_unigme.png, CAPTION_unigme.md <- R_cbh/reporting/24_malaria_mortality_rates.R (step rates_figures), reading annual_com… |
| line 166 | `figures/fig5_model_vs_cause_specific_2024.png` | paper/figures/fig5_model_vs_cause_specific_2024.png (identical) + fig5_..._caption.md <- <root>/model_vs_cause_specific/fig5_model_vs_cause_specific_2024.png, CAPTION.md, figure_data.csv <- R_cbh/reporting/27_model_vs_cause_specific.R (step model_vs_cause) |
| line 264 | `Supplementary Figures/Causal_diagram.pdf` | NO repo source and not exported: drawn by hand in Overleaf 'Supplementary Figures/Causal_diagram.pptx' and saved as PDF (docs/PAPER_CODE_FLAGS.md item A20) |
| line 272 | `Supplementary Figures/sfig_study_flow.png` | paper/Supplementary Figures/sfig_study_flow.png (identical) + sfig_study_flow_caption.md <- <root>/study_flow/study_flow_diagram.png, CAPTION.md, flow_counts.csv, survey_selection.csv <- R_cbh/reporting/01_study_flow_snow.R (step flow) |
| line 281 | `Supplementary Figures/sfig_pfpr_splines_by_subgroup.png` | paper/Supplementary Figures/sfig_pfpr_splines_by_subgroup.png (identical) + _caption.md <- results/cbh/subgroups_snow520_merge_gamma2_v8/sfig_pfpr_splines_by_subgroup.png, CAPTION.md <- R_cbh/sensitivity/subgroups/01_fit.R + 02_report.R (stage subgroups; setti… |
| line 287 | `Supplementary Figures/sfig_pfpr_splines_by_period.png` | paper/Supplementary Figures/sfig_pfpr_splines_by_period.png (identical) + _caption.md <- subgroups v8 sfig_pfpr_splines_by_period.png, CAPTION_sfig_pfpr_splines_by_period.md <- R_cbh/sensitivity/subgroups/01_fit.R + 02_report.R |
| line 294 | `Supplementary Figures/sfig_pfpr_splines_by_subregion.png` | paper/Supplementary Figures/sfig_pfpr_splines_by_subregion.png (identical) + _caption.md <- subgroups v8 sfig_pfpr_splines_by_subregion.png, CAPTION_sfig_pfpr_splines_by_subregion.md <- R_cbh/sensitivity/subgroups/01_fit.R + 02_report.R |
| line 301 | `Supplementary Figures/sfig_subregion_units_map.png` | NOT yet in paper/ (export asset added 1 Nov; first copied by the current run's export stage) <- subgroups v8 sfig_subregion_units_map.png, CAPTION_sfig_subregion_units_map.md <- R_cbh/sensitivity/subgroups/04_subregion_units_map.R (needs map layers saved by R_… |
| line 308 | `Supplementary Figures/sfig_pfpr_splines_imputed_covariates.png` | paper/Supplementary Figures/sfig_pfpr_splines_imputed_covariates.png (identical) + _caption.md <- results/cbh/primary_snow520_merge_imputed_gamma2_v15/sfig_pfpr_splines_imputed_covariates.png, CAPTION_sfig_imputed_covariates.md <- R_cbh/sensitivity/imputation_… |
| line 315 | `Supplementary Figures/sfig_pfpr_splines_without_nutrition.png` | paper/Supplementary Figures/sfig_pfpr_splines_without_nutrition.png (identical) + _caption.md <- results/cbh/nutrition_adjustment_snow520_merge_gamma2_v8/sfig_pfpr_splines_without_nutrition.png, CAPTION.md <- R_cbh/sensitivity/nutrition/01_fit.R + 02_report.R … |
| line 322 | `Supplementary Figures/sfig_malaria_share_vs_pfpr.png` | paper/Supplementary Figures/sfig_malaria_share_vs_pfpr.png (identical) + _caption.md <- <root>/malaria_share/sfig_malaria_share_vs_pfpr.png, CAPTION.md <- R_cbh/reporting/20_malaria_share_vs_pfpr.R (step malaria_share) |
| line 328 | `Supplementary Figures/sfig_malaria_mortality_rates_ihme.png` | paper/Supplementary Figures/sfig_malaria_mortality_rates_ihme.png (identical) + _caption.md <- <root>/mortality_rates/sfig_malaria_mortality_rates_ihme.png, CAPTION_ihme.md <- R_cbh/reporting/24_malaria_mortality_rates.R (step rates_figures) |
| line 334 | `Supplementary Figures/sfig_malaria_rates_ihme_vs_unigme_2024.png` | NOT exported and not in paper/. Overleaf file is md5-identical to results/cbh/exploratory/malaria_rates_ihme_vs_igme/malaria_rates_ihme_vs_igme_2024.png (+ CAPTION.md, country_rates_2024.csv) <- R_cbh/exploratory/02_malaria_rates_ihme_vs_igme.R, which run_pipe… |
| lines 345-404 (LaTeX paste | stab:country_rates (Table S1) | paper/tables/country_rates_2024.latex.txt + paper/tables/country_rates_2024.csv <- <root>/tables/country_rates_2024.latex.txt and .csv <- R_cbh/reporting/25_country_rates_table.R (step rates_table), reading annual_comparison/source_country_rates_2000_2024.csv … |

Numbers quoted in the text come from these outputs:

- Lines 58, 117-118, 219 (217 surveys, 171 with CBH, 25 excluded, 136 = 99 DHS + 37 MICS, 37 countries, 1,127,850 CBH, 7,807,872 records, 2,348,875 children, 108,796 deaths; 93 MICS, 47 with CBH in 28 countries, 46 summary only): <root>/study_flow/flow_counts.csv and survey_selection.csv (R_cbh/reporting/01_study_flow_snow.R), <root>/prepared_sample.csv and primary_sample.csv (R_cbh/primary/00_prepa
- Lines 118, 128, 183 (death shares 36%, 66%, 13%, 29%, 34%): paper/tables/age_band_results.csv <- <root>/tables/age_band_results.csv (R_cbh/primary/03_report.R via R_cbh/reporting/age_band_table.R)
- Lines 58, 128 (HR at 40%: 1.12, 1.27, 1.59, 1.84-2.45 with CIs): <root>/hazard_ratio_by_age/hazard_ratio_curves.csv (R_cbh/reporting/26_hazard_ratio_by_age.R; fits R_cbh/primary/01_fit.R). Not exported to paper/
- Lines 58, 137 (AF at 40%: 11%, 21%, 37%, 46-59% with CIs): <root>/attributable_fraction_by_age.csv (R_cbh/reporting/06_attributable_fraction_by_age.R), also pfpr_attributable_fraction_anchors.csv (R_cbh/primary/02_effects.R). Not exported to paper/
- Lines 58, 150, 161, 175 (10.7 to 3.5 and 10.2 to 3.3 per 1,000; 1.16 million to 626,000 and 1.12 million/585,000; 30% to 22%; 109 to 179 million; 67% since 2000; 21-24% since 2015): paper/tables/source_annual_rates_2000_2024.csv <- <root>/annual_comparison/source_annual_rates_2000_2024.csv (R_cbh/burden/04_annual_comparison.R; inputs R_cbh/burden/00_national_inputs.R). The v14 95% UIs will come fr
- Lines 58, 161, 175, 178 (comparators 2.5 and 2.4 per 1,000 and 16%; '40% more'; CA-CODE 63% and IHME 53% decline since 2000; 8% since 2015; 'a third' indirect): paper/tables/annual_totals_2000_2024.csv (who_cacode_deaths, ihme_malaria_deaths) <- <root>/annual_comparison/annual_totals_2000_2024.csv (04_annual_comparison.R), and paper/tables/source_comparison_2000_2024.csv <- <root>/burden_compariso
- Lines 150, 161 and Table S1 (UN IGME/IHME ratio 0.47-1.52, median 0.84; largest differences BDI, NGA, COD, SSD, BFA; GNQ, CMR, NGA vs UN IGME; CAF, TCD, NER vs IHME; LBR; BDI, GNQ, RWA): paper/tables/country_rates_2024.csv <- R_cbh/reporting/25_country_rates_table.R
- Line 161 ('large majority' = 37 and 34 of 42 countries): paper/figures/fig5_model_vs_cause_specific_2024_caption.md <- <root>/model_vs_cause_specific/CAPTION.md (R_cbh/reporting/27_model_vs_cause_specific.R)
- Lines 146, 253, 288, 302 (subgroup sizes: Sahel 31 surveys, 8 countries, 19,652 deaths, 1,556,866 bands; West 61/15/56,426/3,743,776; Central 18/7/17,628/1,230,434; East 50/12/33,671/2,735,874; 74/62 surveys; 3,935,148/3,872,724 records; 2014; late 2012; Southern never above 11%): results/cbh/subgroups_snow520_merge_gamma2_v8/sample_summary.csv, subgroup_definitions.csv, subregions_not_fitted.csv 
- Line 146 (qualitative Sahel and Central Africa claims): subgroups v8 pfpr_contrasts.csv and pfpr_curves.csv (R_cbh/sensitivity/subgroups/02_report.R)
- Lines 146, 255 (MI: 8,630,306 records, 122,092 deaths, 161 surveys, 38 countries; Rubin's rules at most 0.001): results/cbh/primary_snow520_merge_imputed_gamma2_v15/comparison_sample.csv, imputation_record_counts.csv, multiple_imputation/pooled_contrasts.csv (R_cbh/sensitivity/imputation_dhsmics/03_prepare.R, 05_propagate.R, 06_report.R). In paper/ as text in Supplementary Figures/sfig_pfpr_spline
- Line 146 ('hazard ratios changed by at most 0.04', no nutrition): nutrition_adjustment_snow520_merge_gamma2_v8/comparison_contrasts.csv and comparison_pfpr_curves.csv (R_cbh/sensitivity/nutrition/02_report.R). No output gives 0.04: the exported caption gives 0.010 (40% vs 20%)
- Line 239 (822,434 records and 13,296 deaths excluded; 793,641; 28,793; 38/25/22/11/4%): <root>/complete_case_losses.csv (R_cbh/primary/00_prepare_snow.R) and study_flow/flow_counts.csv. Not exported
- Line 247 (age split 52/48% and 38/32/19/11%): <root>/annual_comparison/igme_age_split.csv (R_cbh/burden/04_annual_comparison.R). Not exported
- Lines 249, 329 (14 UN IGME crisis country-years in 4 countries; IHME Somalia 2011, South Sudan 2024): <root>/annual_comparison/crisis_years.csv (04_annual_comparison.R); also in paper/Supplementary Figures/sfig_malaria_mortality_rates_ihme_caption.md
- Lines 104, 150, 247 (42 countries): <root>/annual_comparison/included_countries.csv (04_annual_comparison.R; set pinned by burden_excluded in R_cbh/00_config.R)
- Line 243 (knots spanning 0-95%, six time knots, gamma = 2, mgcv 1.9-4): R_cbh/primary/reference_knots.csv, R_cbh/primary/settings.R and specification.R, <root>/fit_manifest.csv
- Line 223 (90% and 5% placement thresholds; 366 MICS labels, 291 exact and 75 reviewed): R_cbh/snow/07_placement.R and R_cbh/snow/config; R_mics/05_region_map.R and R_mics/config/region_overrides.csv (output data/derived_mics/region_map_auto.csv is gitignored)
- Line 237 (HIV for Liberia and Nigeria; South Sudan before 2011; 2001 interpolation; 2024 health expenditure): R_cbh/hiv/01_fit_incidence.R, R_cbh/hiv/03_add_liberia_aidsinfo.R, data/HIV_Epidemiology_Children_Adolescents_2025.xlsx; <root>/national_substitutions.csv and national_interpolations.csv (R_cbh/primary/national_substitutions.R)
- Line 180 (the two sources disagree on malaria's share): Supplementary figure sfig_malaria_share_vs_pfpr (R_cbh/reporting/20_malaria_share_vs_pfpr.R)
- External numbers with no repo source: line 71 (430,000) and line 175 (434,000) WHO WMR under-5 deaths in sub-Saharan Africa; line 175 '600,000 per year' (cited wmr, gbd). R_inputs/who_wmr2025_tables.R only supplies the all-ages WHO rows of source_comparison, which main.tex does not quote

Findings while mapping:
- `Supplementary Figures/sfig_malaria_rates_ihme_vs_unigme_2024.png` (main.tex line 334) and the Results ratio range
  (0.47–1.52, median 0.84) come from a hand-run script, `R_cbh/exploratory/02_malaria_rates_ihme_vs_igme.R`, which
  the pipeline does not run, so they go stale after every rerun. Proposed: move it into the pipeline (simplify list).
- The Table S1 pasted into main.tex (lines 345–404) is older than `paper/tables/country_rates_2024.latex.txt`; the
  v14 version (with 95% intervals) will replace it.
- The Discussion's 'hazard ratios changed by at most 0.04' (no nutrition) is not produced by any output (the caption
  gives 0.010).

## Proposed removals

Grouped by area; *knock-on* lists the edits elsewhere so nothing breaks. Git history keeps everything.

- **`R_cbh/burden/05_nigeria_state_burden.R`** (high): Nigerian state burden. No state figure, table or number is in main.tex.  
  *Knock-on:* run_regional.R: drop step nigeria_burden. 10_validate_reporting.R: drop the nigeria_states checks (state_totals/national_reconciliation, about lines 85-87). export_paper.py: drop the nigeria_states/state_totals_2024.csv -> tables/nigeria_state_totals_2024.csv entry. 04_paper_figures.R: drop the nigeria_states text (goes with the burden_comparison section). Remove with 08, data/map_pfpr_admin1_202608.csv and data/external/nigeria_states/*.
- **`R_cbh/reporting/07_annual_mortality_comparison.R`** (high): Old annual comparison figure (figure5_data.csv). Not in main.tex; Figure 4 shows the trend. Its only reader is 11.  
  *Knock-on:* run_regional.R: drop step annual_plot. Optional: drop the audit files that only 07 reads from 04_annual_comparison.R. data/external/figure5/source.json stays (04 hashes it).
- **`R_cbh/reporting/08_nigeria_state_comparison.R`** (high): Nigerian state figure (old Figure 6). Not in main.tex.  
  *Knock-on:* run_regional.R: drop step nigeria_plot.
- **`R_cbh/reporting/09_burden_tables.R`** (high): Old 2024 country death table (old Table 1). Table S1 comes from 25.  
  *Knock-on:* run_regional.R: drop step burden_tables. 10_validate_reporting.R: drop the tables/country_comparison_2024.csv checks and remove country_comparison_2024.latex.txt from the latex row-terminator loop (about line 119). export_paper.py: drop country_comparison_2024.csv, _top10.md and .latex.txt from the tables loop.
- **`R_cbh/reporting/11_burden_comparison_figure.R`** (high): sfig_burden_comparison (counts and rates). In the Overleaf folder but not in main.tex.  
  *Knock-on:* run_regional.R: drop step burden_figure. 04_paper_figures.R: drop the sections reading burden_comparison/CAPTION.md and CAPTION_counts.md, or it fails. export_paper.py: drop the 2 burden_comparison entries. 12_source_comparison_table.R also writes to burden_comparison/ and is unaffected.
- **`R_cbh/reporting/13_under5_death_probability.R`** (high): sfig_under5_death_probability. Exported but not in main.tex.  
  *Knock-on:* run_regional.R: drop step u5_probability. 04_paper_figures.R: drop the section reading under5_probability/CAPTION.md. export_paper.py: drop its 2 entries. Leaves data/igme_u5mr_by_country.csv, R_inputs/fetch/fetch_igme_u5mr.R and 00_national_inputs.R's ihme_disjoint_age_inputs.csv without a kept reader.
- **`R_cbh/reporting/21_country_agreement_2024.R`** (high): Country agreement statistics. No reader. The 'large majority' counts come from 27's Figure 5 caption.  
  *Knock-on:* run_regional.R: drop step agreement.
- **`R_cbh/reporting/log_axes.R`** (high): Log-axis helper used only by non-paper plots (03_report.R plots, 08, 11).  
  *Knock-on:* 03_report.R: drop source('R_cbh/reporting/log_axes.R') and its report_provenance entry, as part of trimming 03.
- **`R_cbh/exploratory/01_survival_vs_pfpr.R`** (high): Hand-run exploratory plot. No reader, not in main.tex.  
  *Knock-on:* None.
- **`R_cbh/sensitivity/subgroups/03_survival_by_subregion.R`** (medium): sfig_survival_vs_pfpr_by_subregion is in the Overleaf folder but not included in main.tex, and no number is quoted from it. The author requested it on 15 October, so confirm.  
  *Knock-on:* run_pipeline.R: drop it from stage subgroups. export_paper.py: drop its 2 entries. Nothing else reads its outputs.
- **`R_cbh/snow/21_map_merge_units.R`** (high): Per-country merge-unit maps. None is in main.tex; only export_paper.py reads them.  
  *Knock-on:* run_pipeline.R: drop it from stage snow_maps. export_paper.py: drop the merge_units glob and the CAPTION_merge_units.md append, which asserts the file exists.
- **`R_cbh/snow/22_map_boundary_agreement.R`** (high): sfig_snow_boundary_agreement_map is in the Overleaf folder but not included in main.tex.  
  *Knock-on:* export_paper.py: drop its 2 entries and the snow_maps path. run_pipeline.R: delete stage snow_maps, which is empty once 21 goes and 22_compare_v9_snow.R is removed in remove-v9, and its minutes entry. 01_polygons.R's polygons.csv then has no reader (harmless).
- **`R_cbh/covariates/02_extract_regional.R; R_cbh/covariates/03_audit_missingness.R; R_cbh/covariates/04_report.R; R_cbh/covariates/11_extract_first_birth_age.R; R_cbh/covariates/12_fetch_nutrition.py; R_`** (high): The v9 survey-region covariate overlay and its audit. The Snow primary recomputes covariates per unit (snow/09, 10) and reads none of these outputs. grep confirms that, outside this folder, only v9 code (00_prepare_regional.R, 01_study_flow.R, the imputation else-branch) reads planned17_audit, first_birth_age.csv or nutrition_published.csv. remove-v9 does not cover these.  
  *Knock-on:* run_pipeline.R: the covariates stage becomes R('R_cbh/covariates/01_fetch_published.R') and R('R_cbh/covariates/07_prepare_unicef.R'). Comments in snow/09 and snow/R/label_rules.R cite 11 and 17 for definitions; reword them. Frees data/frozen/.../planned17_audit/nutrition_*.json and the subnational DHS API pages.
- **`R_cbh/covariates/05_validate.R`** (high): Tests of the v9 overlay helpers and outputs.  
  *Knock-on:* Optional: move its cbh_unicef_fill test (about lines 101-111) into 07_prepare_unicef.R first, because the Snow primary uses that function.
- **`R_cbh/covariates/14_exclusion_attribution.R`** (high): v9 complete-case attribution, read only by the v9 study flow (01_study_flow.R, removed in remove-v9). remove-v9 rewires it to keep it running, but nothing kept reads its output. The paper's loss shares come from 00_prepare_snow.R complete_case_losses.csv.  
  *Knock-on:* run_pipeline.R: drop both covariates-stage calls (default and --liberia).
- **`R_cbh/covariates/run.R`** (high): Wrapper for 02, 17, 07, 03, 04 and 05, of which only 07 is needed.  
  *Knock-on:* run_pipeline.R: call 07_prepare_unicef.R directly in stage covariates.
- **`R_cbh/covariates/regional.R`** (high): v9 survey-region covariate helpers. No function in it runs in the Snow chain; specification.R uses it only in the nutrition==FALSE branch, which no version takes.  
  *Knock-on:* specification.R: drop source() line 2 and the nutrition==FALSE branch. primary/01_fit.R: drop it from the code list (line 43) and the non-regional branch. imputation_dhsmics/03_prepare.R: drop it from the code list (line 29-32). These code-hash changes force refits of all primary and sensitivity fits.
- **`R_mics/09_regional_covariates.R`** (high): v9 MICS survey-region overlay. snow/10 hard-codes the lock values and reads nothing from it. remove-v9 keeps it.  
  *Knock-on:* run_pipeline.R: drop it from stage mics. Remove R_mics/10 with it (remove-v9 points 10 at this script's output). Drop its rows from verification/*.csv and tools/compare_outputs.R if those are kept.
- **`R_mics/10_exclusion_attribution_mics.R`** (high): v9 MICS exclusion attribution, read only by the removed v9 study flow.  
  *Knock-on:* run_pipeline.R: drop it from stage mics.
- **`R_inputs/who_wmr2025_tables.R`** (medium): All-age WHO WMR 2025 series, read only by 12_source_comparison_table.R for rows main.tex does not quote. The WHO 430,000 and 434,000 are cited from the WMR.  
  *Knock-on:* Depends on decision B. 12_source_comparison_table.R: drop the WMR rows and the results/who_wmr2025_*.csv inputs and provenance. run_pipeline.R: drop it from stage inputs. tools/compare_outputs.R: drop it from the list, if that file is kept.
- **`R_inputs/fetch/fetch_igme_u5mr.R`** (high): Fetches data/igme_u5mr_by_country.csv, read only by 13.  
  *Knock-on:* Remove with 13 and the data file.
- **`R_inputs/fetch/pfpr_admin1_ng_cd_2024.R`** (high): Writes the superseded 202508 admin-1 PfPR file that nothing reads.  
  *Knock-on:* Remove with data/pfpr_admin1_ng_cd_2024.csv.
- **`tools/check_trimmed_config.R`** (high): One-off check against the private analysis project. Not needed to regenerate anything.  
  *Knock-on:* Reword the comment in R_inputs/00_config.R. tools/ is the folder of the restore stage, so this marks restore stale and the next --all reruns everything (do it in the same batch as the other edits).
- **`tools/freeze_pr_hw_table.R`** (high): One-off that wrote the committed R_cbh/snow/config/dhs_pr_hw_files.csv from the private analysis project.  
  *Knock-on:* Reword the comment in R_cbh/snow/R/dhs_files.R. Same restore-stage staleness as above.
- **`tools/import_from_analysis_project.R`** (medium): Historical one-off import from the private analysis project. It cannot run without that project, and the manifests it wrote are committed and edited since.  
  *Knock-on:* data/README.md: replace the provenance sentence (the INPUTS_MANIFEST source column keeps the record). Same restore-stage staleness.
- **`docs/PAPER_CODE_FLAGS.md`** (high): Code vs main.tex review of 1 and 8 October (v9/v11), now superseded.  
  *Knock-on:* The README rewrite drops its link. labels.R and other comments cite docs/ANALYSIS_PLAN.md, which is not tracked; reword those comments.
- **`docs/PAPER_TEXT_SNOW.md`** (high): 13 October replacement text, superseded by its own header note.  
  *Knock-on:* None.
- **`docs/manuscript/PROPOSED_CHANGES.html; docs/manuscript/PROPOSED_CHANGES.md; docs/manuscript/build_proposed.py; docs/manuscript/main_proposed.tex`** (high): 15-16 October proposal set against an old main.tex. build_proposed.py's anchors no longer match, and it reads tables that are being removed.  
  *Knock-on:* None (keep the docs/manuscript/ folder: CLAUDE.md sends proposals there, and the untracked NEJM drafts live in it).
- **`docs/manuscript/map_202608_impact.md`** (high): Pre-switch estimate, superseded by the 202608 switch and the v14 rerun.  
  *Knock-on:* None.
- **`docs/manuscript/methods_covariate_adjustment_proposed.tex; docs/manuscript/methods_data_sources_proposed.tex`** (high): Superseded by methods_v13_proposed.tex, as its header says.  
  *Knock-on:* None.
- **`verification/VERIFICATION.md; verification/covariates.csv; verification/dhs_bands.csv; verification/hiv.csv; verification/inputs.csv; verification/mics.csv; verification/paper.csv; verification/primar`** (high): Records of the 2-4 October v9 re-run (MAP 202508), stale for the Snow primary and 202608.  
  *Knock-on:* The README rewrite drops its links. Git history keeps the records.
- **`verification/snow/VERIFICATION_SNOW.md; verification/snow/covariates.csv; verification/snow/dhs_bands.csv; verification/snow/hiv.csv; verification/snow/inputs.csv; verification/snow/mics.csv; verifica`** (high): 13 October v11 clean-run records, superseded. They were made with a compare script that is not tracked.  
  *Knock-on:* README link.
- **`data/map_annual/pfpr2_10_{2000..2024}.tif (25 files)`** (high): MAP release 202508 rasters. Every exposure now comes from data/map_annual_202608 (validation asserts it). 115 MB, 38% of tracked data.  
  *Knock-on:* data/INPUTS_MANIFEST.csv: drop the 25 rows, or the preflight stops with 'input files are missing'. data/README.md: drop the rows. The blobs stay in git history unless it is rewritten.
- **`data/pfpr_2to10_africa_2024.tif`** (high): Former 202508 2024 raster. Only legacy fetch code references it.  
  *Knock-on:* INPUTS_MANIFEST row. R_inputs/fetch/00_utils.R PFPR_TIF and the MAP block of 01_fetch_data.R (simplify). data/README row.
- **`data/pfpr_admin1_ng_cd_2024.csv`** (high): Superseded 202508 admin-1 PfPR. Nothing reads it.  
  *Knock-on:* INPUTS_MANIFEST row; data/README row.
- **`data/igme_u5mr_by_country.csv`** (high): Read only by 13 (figure not in main.tex).  
  *Knock-on:* INPUTS_MANIFEST row; data/README row.
- **`data/map_pfpr_admin1_202608.csv`** (high): MAP admin-1 PfPR, used only by the Nigerian state burden (05).  
  *Knock-on:* INPUTS_MANIFEST row. R_inputs/fetch/fetch_map_national_pfpr.R: drop the admin-1 half. R_cbh/00_config.R map_admin1: the path is not existence-checked, so leave it until the next full rebuild (editing 00_config.R changes the child-band signature).
- **`data/external/nigeria_states/Data Explorer - export_trigger_table - All causes - Deaths - Rate (per 100,000), Number in Abia, Adamawa,...  2026-09-16 13-53-49.csv; data/external/nigeria_states/GBD NG `** (high): IHME Nigerian-state inputs of 05 and 08. Removing them also removes IHME-licensed state data from the repo.  
  *Knock-on:* 3 INPUTS_MANIFEST rows; data/README rows.
- **`data/dhs_boundaries/CI2005AIS.rds; data/dhs_boundaries/MZ2015AIS.rds; data/dhs_boundaries/TZ2007AIS.rds; data/dhs_boundaries/TZ2012AIS.rds`** (high): AIS boundaries not in the survey registry and referenced by no script (grep confirmed).  
  *Knock-on:* 4 INPUTS_MANIFEST rows. data/README count 128 -> 124.
- **`data/frozen/data/derived_cbh/regional_adjustment/subnational_*_page*.json (23 files)`** (high): Cached published sub-national DHS values used only by the v9 overlay. snow/09 keeps level == 'national'.  
  *Knock-on:* R_cbh/covariates/01_fetch_published.R: loop over 'national' only, or it needs these with network blocked. 23 INPUTS_MANIFEST rows (frozen_restore).
- **`data/frozen/data/derived_cbh/regional_adjustment/planned17_audit/nutrition_{1..7,metadata}_page1.json (8 files)`** (high): Cached published regional wasting/stunting, read only by 12_fetch_nutrition.py (v9 overlay).  
  *Knock-on:* 8 INPUTS_MANIFEST rows. Remove with 12_fetch_nutrition.py.
- **`data/frozen/data/derived_dhs/map_pfpr_by_survey_region.csv; data/frozen/data/derived_dhs/map_pfpr_window_years.csv`** (high): 202508 frozen_fallback tables, reachable only through --map=frozen, which run_pipeline.R now refuses.  
  *Knock-on:* 2 INPUTS_MANIFEST rows. tools/restore_frozen.R: drop the --map branch. run_pipeline.R: drop the --map option and map_frozen.
- **`data/frozen/data/derived_cbh/hiv_incidence/child_incidence_country_year_lbr.csv; data/frozen/data/derived_cbh/hiv_incidence/child_incidence_country_year_extended_lbr.csv`** (high): Reference copies (frozen_fallback) that no script reads; 03_add_liberia_aidsinfo.R rebuilds both.  
  *Knock-on:* 2 INPUTS_MANIFEST rows; data/README paragraph.
- **`paper/RESULTS_UPDATE.md`** (medium): Export handoff note. Not used by main.tex, and it links tables that are being removed.  
  *Knock-on:* export_paper.py: stop copying the handoff to paper/ (keep results/.../paper_refresh/OVERLEAF_UPDATE.md), or drop the handoff code (about 150 lines) and its reads of survey_timeline_all.csv, national_substitutions.csv and covariate_scaling.csv.
- **`paper/Supplementary Figures/sfig_burden_comparison.png; paper/Supplementary Figures/sfig_burden_comparison_caption.md`** (high): Not in main.tex.  
  *Knock-on:* Goes with 11 (export entries).
- **`paper/Supplementary Figures/sfig_under5_death_probability.png; paper/Supplementary Figures/sfig_under5_death_probability_caption.md`** (high): Not in main.tex.  
  *Knock-on:* Goes with 13 (export entries).
- **`paper/Supplementary Figures/sfig_pfpr_40_to_20_by_subgroup.png`** (high): Not in main.tex. The subgroup claims come from pfpr_contrasts.csv.  
  *Knock-on:* export_paper.py: drop the entry. Optionally drop the plot in subgroups/02_report.R.
- **`paper/Supplementary Figures/sfig_snow_boundary_agreement_map.png; paper/Supplementary Figures/sfig_snow_boundary_agreement_map_caption.md`** (high): Not in main.tex.  
  *Knock-on:* Goes with snow/22.
- **`paper/Supplementary Figures/sfig_survey_map_and_timing.png; paper/Supplementary Figures/sfig_survey_map_and_timing_caption.md`** (high): Not in main.tex.  
  *Knock-on:* export_paper.py: drop 2 entries. 04_paper_figures.R: drop the survey_map section. 03_survey_map.R stays as a table producer (simplify), because Figure 1 needs its CSVs.
- **`paper/Supplementary Figures/sfig_survival_vs_pfpr_by_subregion.png; paper/Supplementary Figures/sfig_survival_vs_pfpr_by_subregion_caption.md`** (medium): Not in main.tex.  
  *Knock-on:* Goes with subgroups/03_survival_by_subregion.R.
- **`paper/Supplementary Figures/snow_merge_units/*_merge_units.png (20 files) and paper/Supplementary Figures/snow_merge_units/CAPTION.md`** (high): Not in main.tex.  
  *Knock-on:* Goes with snow/21.
- **`paper/tables/age_band_results.latex.txt; paper/tables/age_band_results.md`** (high): main.tex has no age-band table. The CSV carries the numbers.  
  *Knock-on:* export_paper.py: drop both names from the tables loop. Optionally age_band_table.R writes the CSV only, and 10_validate drops the age_band latex row check.
- **`paper/tables/country_comparison_2024.csv; paper/tables/country_comparison_2024.latex.txt; paper/tables/country_comparison_2024_top10.md`** (high): Old Table 1, not in main.tex.  
  *Knock-on:* Goes with 09.
- **`paper/tables/nigeria_state_totals_2024.csv`** (high): Not in main.tex.  
  *Knock-on:* Goes with 05.
- **`paper/tables/source_comparison.latex.txt`** (high): Old Table 2 LaTeX, not in main.tex.  
  *Knock-on:* export_paper.py: drop the entry. 12_source_comparison_table.R: stop writing it (decision B).

## Proposed simplifications (files kept, parts removed)

- **`run_pipeline.R`**: After remove-v9: drop the --map option and map_frozen (the restore and inputs stages lose their branches); covariates stage = 01_fetch_published.R + 07_prepare_unicef.R; mics stage without 09 and 10; inputs stage without who_wmr2025_tables.R (and without 02b under decision F); delete stage snow_maps; subgroups stage without 03_survival_by_subregion.R; country_fe, hiv and snow_repro per decisions A, D and C; if 06/06b go (decision E), change snow_unit_steps(SNOW)[1:9]/[10:11] to [1:7]/[8:9]; update the header comment and the minutes vector.
- **`R_cbh/primary/run_regional.R`**: Drop steps annual_plot (07), nigeria_burden (05), nigeria_plot (08), burden_figure (11), burden_tables (09), agreement (21) and u5_probability (13). Add a step for the IHME vs UN IGME figure (moved exploratory/02) after rates_table. Keep source_table (12) per decision B. The final message names RESULTS.md, so update it if 03 is trimmed.
- **`R_cbh/reporting/export_paper.py`**: Cut the asset list to main.tex. Drop burden_comparison, under5_probability, pfpr_40_to_20_by_subgroup, survival_by_subregion, boundary_agreement, merge_units (glob and caption), survey_map png/caption, country_comparison x3, age_band md/latex, source_comparison.latex.txt and nigeria_state_totals; drop country_fe per decision A (assets and the report-provenance loop). Add Supplementary Figures/sfig_malaria_rates_ihme_vs_unigme_2024.png (+ caption), which is in main.tex but not exported today. Stop copying RESULTS_UPDATE.md into paper/. sfig_subregion_units_map is already in the list.
- **`R_cbh/reporting/04_paper_figures.R`**: Keep the Figure 1-5 manifest and the five captions (paper/figures/primary_figure_captions.md is the only caption source for Figure 3). Drop the sections that read burden_comparison/CAPTION*.md, under5_probability/CAPTION.md and survey_map/CAPTION.md, and the stale notes about former figures.
- **`paper/figures/primary_figure_captions.md`**: Regenerated by the trimmed 04_paper_figures.R, with only the Figure 1-5 captions.
- **`R_cbh/reporting/10_validate_reporting.R`**: Drop the checks on removed outputs: nigeria_states, tables/country_comparison_2024 (sums and latex loop entry), age_band latex check (if dropped), and burden/year_summary vs annual totals if 02 is cut to 2024. Rewrite the stale PASS text. It scans every *provenance.csv under the result folder, so stale files from removed scripts in an old result folder fail it: use a fresh folder or delete them.
- **`R_cbh/primary/03_report.R`**: Only tables/age_band_results.csv reaches the paper. Reduce it to the cbh_primary_age_table() call (drop pfpr_splines.png, pfpr_40_to_20.png, country_deaths_all_years.png, country_vs_ihme.png, deaths_by_age.png, drc_survival.png, the residual plot, the log10 CSVs, RESULTS.md and the log_axes source), or move that call into 06_attributable_fraction_by_age.R and drop the report step.
- **`R_cbh/reporting/age_band_table.R`**: Write age_band_results.csv only (drop the .md and .latex.txt).
- **`R_cbh/primary/02_effects.R`**: Drop the DRC life table (read only by 03's drc_survival.png) and pfpr_attributable_fraction_anchors.csv (no reader). Keep the burden country_totals/country_age_estimates (read by 04 and 20), the contrasts and the EDF.
- **`R_cbh/burden/00_national_inputs.R`**: Drop ihme_disjoint_age_inputs.csv, whose only readers are the DRC life table and 13.
- **`R_cbh/primary/04_diagnostics.R`**: Keep survey_coverage.csv (read by 01_study_flow_snow.R). Drop fitted_outcome_checks.csv and grouped_outcome_checks.csv, which only feed 03's residual plot, unless the author wants them as a model check.
- **`R_cbh/reporting/03_survey_map.R`**: Keep survey_map/survey_coverage.csv and mothers_by_survey.csv, which Figure 1 (23) and 10_validate read (and survey_timeline_all.csv if the export handoff stays). Drop survey_map_and_timing.png, its CAPTION.md and country_summary.csv (no reader).
- **`R_cbh/reporting/20_malaria_share_vs_pfpr.R`**: Drop malaria_share_table_2024.{csv,md,latex.txt}, which nothing reads.
- **`R_cbh/reporting/12_source_comparison_table.R`**: Per decision B: keep only the under-five PfPR-ACM, IHME and UN IGME rows of source_comparison_2000_2024.csv (the source of the 53% and 8% comparators); drop the WMR rows and inputs, SOURCE_COMPARISON.md and source_comparison.latex.txt. Consider computing the UN IGME decline over WPP child-years, so that the quoted 63% appears in an output (it is 62.4% today).
- **`R_cbh/burden/04_annual_comparison.R`**: Optional: drop the audit files read only by 07 (denominator, country_year_input, map_input, agreement_with_existing_primary).
- **`R_cbh/exploratory/02_malaria_rates_ihme_vs_igme.R`**: Supplies Supplementary Figure sfig_malaria_rates_ihme_vs_unigme_2024 (main.tex) and the Results ratio range 0.47-1.52 (median 0.84), but it is hand-run and goes stale after reruns. Move it to R_cbh/reporting/ (for example 28_malaria_rates_ihme_vs_unigme.R), read the root from cbh_primary_settings(), write to <root>/, add it as a run_regional step and export it under the Overleaf file name.
- **`R_cbh/sensitivity/subgroups/02_report.R`**: Drop pfpr_40_to_20_by_subgroup.png (not in main.tex).
- **`R_cbh/sensitivity/nutrition/02_report.R`**: main.tex says 'hazard ratios changed by at most 0.04', but no output gives 0.04 (the caption gives 0.010). Add the chosen summary to CONTRASTS.md/CAPTION.md or change the text. No removals.
- **`R_cbh/sensitivity/imputation_dhsmics/02_impute_regional.R; R_cbh/sensitivity/imputation_dhsmics/03_prepare.R`**: remove-v9 rebases the settings, but 02 still has the v9 else-branch (dhs_overlay, mics_overlay, annual_maps; these settings are gone) and 03 lists covariates/regional.R in its code provenance. Drop both, and the comments citing nonexistent files (covariates/15_, 16_, imputation/01_propagate.R).
- **`R_cbh/covariates/01_fetch_published.R`**: Fetch the 'national' level only (and drop the breastfeeding IDs used only by v9 checks), so the 23 subnational frozen pages can go. snow/09 reads only level == 'national'.
- **`R_cbh/primary/specification.R; R_cbh/primary/01_fit.R; R_cbh/sensitivity/model.R; R_cbh/analysis/model.R`**: Remove dead code: specification.R drops source(regional.R) and the nutrition==FALSE branch; 01_fit.R drops the settings$regional==FALSE formula branch (cbh_sensitivity_formula(cbh_trial_spec())) and regional.R from its code list; sensitivity/model.R drops cbh_sensitivity_formula; analysis/model.R drops cbh_trial_data/prepare/fit/contrasts and keeps cbh_trial_spec, cbh_attach_incidence and cbh_trial_formula. All four are in the run_pipeline helpers and in the fit code provenance, so every stage goes stale and all fits rerun.
- **`tools/restore_frozen.R`**: Drop the --map branch (frozen_fallback MAP tables).
- **`R_inputs/fetch/00_utils.R; R_inputs/fetch/01_fetch_data.R`**: Keep only what still feeds committed inputs (GPW raster, africa_admin0.rds, wb_gdp_pc.csv) and drop the MAP 202508 raster, IGME, live-birth, DTP3, DHS-universe and data/dhs blocks and the unused model helpers. Alternatively, fold the remaining helpers into 01_fetch_data.R.
- **`R_inputs/fetch/fetch_map_national_pfpr.R`**: Drop the admin-1 half once the Nigerian state chain goes.
- **`R_cbh/00_config.R`**: Once Nigeria and the legacy panels go, map_admin1 (and, under decision F, annual_panels$hiv/immunisation) are unused. Any edit here changes the child-band build signature and rebuilds all DHS and MICS shards, so edit only with the decision F batch. Leaving map_admin1 dangling is harmless (not existence-checked).
- **`data/INPUTS_MANIFEST.csv`**: Drop the rows of every removed input: 25 map_annual, pfpr_2to10_africa_2024.tif, pfpr_admin1_ng_cd_2024.csv, igme_u5mr_by_country.csv, map_pfpr_admin1_202608.csv, 3 nigeria_states, 4 AIS boundaries, 23 subnational pages, 8 nutrition pages, 4 frozen_fallback rows; plus decisions F and G. If the frozen base HIV draws go, use_frozen_hiv.R's count changes from 4 to 3. Consider adding the two data/unicef subsets so the preflight md5-checks them.
- **`data/README.md`**: Rewrite after the removals: drop the 202508 and Nigeria rows, the IGME U5MR row and the frozen-fallback paragraph; change the boundary count to 124; fix the pointer to R_inputs/fetch/download_pr_hw.R (which does not exist) to tools/import_pr_hw.R; drop the import_from_analysis_project.R provenance sentence; note the unicef subsets.
- **`README.md`**: Rewrite short (separate step, per the user): what the repo does, drawn from main.tex, plus how to run it and where the outputs go. Drop the v9/v11 verification, old Tables 1/2 and the 26-row asset table, and the links to removed docs and verification.
- **`R_cbh/snow/README.md`**: Update the result id (v14), drop the split_repro text if decision C removes it, and the 21/22 maps (and 06/06b under decision E).

## Corrections from the adversarial check (applied when the plan is carried out)

- **`R_cbh/covariates/01_fetch_published.R (SIMPLIFY entry)`**: The plan says to fetch the 'national' level only and also to drop the breastfeeding indicator IDs. Dropping the IDs breaks the offline run. *Correction:* Change only the level loop (for(level in 'national')) and leave the 10-ID query unchanged. If the IDs must go, filter the rows first (d <- d[d$IndicatorId %in% ids, ]) before line 51. Even then, the provenance URLs would no longer match the query that made the cached pages.
- **`R_cbh/R/external_data.R (decision F: removing annual_panels$hiv from R_cbh/00_config.R)`**: Decision F's edit list leaves out external_data.R. Removing the hiv panel from cbh_config() as recommended makes the DHS and MICS child-band builds crash. *Correction:* In the same batch, drop the c('hiv_prev_pct','log_hiv_prev') pair from external_data.R line 57, or guard it on the column existing. The analysis/model.R line 73 'hiv_prev_pct' entry goes with cbh_trial_data, as already planned.
- **`R_cbh/reporting/export_paper.py (decision A: removing country fixed effects)`**: The knock-on edits for removing country_fe are incomplete. Deleting the country_fe path variable as recommended makes the export fail with a NameError. *Correction:* If decision A removes the stage, also edit the handoff text at lines 263-265, or drop the handoff block. The rewritten README (remove-v9 commit d94ffef, line 28) also lists 'country fixed effects' as a sensitivity analysis, so update it too.
- **`R_cbh/reporting/10_validate_reporting.R / recommended sequence (notes)`**: The recommended sequence (commit the v14 export, apply the cleanup, do one clean full run) reuses the same result folder. Provenance files left there by removed scripts make the validate stage fail. *Correction:* Before the clean run, add an explicit step: delete those subfolders and files from the v14 result folder (nigeria_states/, under5_probability/, burden_comparison/figure_provenance.csv and the 11 outputs, tables/burden_table_provenance.csv, annual_comparison/figure_provenance.csv and country_agreement_provenance.csv, report_provenance.csv if 03 is dropped). Alternatively, move the folder aside or bump the version id. Do the same when adapting the 10_validate edits.
- **`run_pipeline.R deps() / notes on stage markers`**: The notes say paper, docs and verification deletions alone touch no stage marker. That is true only if export_paper.py is left alone. But the paper/ deletions only stick if export_paper.py stops exporting those files, and that edit makes the primary stage and every later stage stale. *Correction:* Say so in the sequence: after edits that touch only reporting or export, use Rscript run_pipeline.R --only=validate and --only=export, not --all. Or batch these edits with the full rerun.
- **`README.md (SIMPLIFY) / notes on remove-v9`**: The plan's description of remove-v9 is out of date, and the README entry does not account for the README that branch already rewrote. *Correction:* Build on d94ffef. After the cleanup, update README lines 28, 50 and 51 to match the decisions, instead of rewriting from scratch.
- **`R_cbh/sensitivity/imputation_dhsmics/02_impute_regional.R (SIMPLIFY)`**: The entry says 02 still has the v9 else-branch (dhs_overlay, mics_overlay, annual_maps). On remove-v9 that is no longer true. *Correction:* Limit this entry to 03_prepare.R's code list and the comments in 01 and 02.
- **`R_cbh/reporting/10_validate_reporting.R (line references)`**: The line numbers in the plan come from main, but the plan is to be applied on top of remove-v9. *Correction:* Cite the remove-v9 line numbers, or locate the edits by content.
- **`R_cbh/analysis/model.R; R_cbh/sensitivity/model.R (SIMPLIFY)`**: After the proposed dead-code removal, cbh_trial_spec and cbh_trial_formula, which the plan keeps, also have no callers in kept code. *Correction:* Keeping them does no harm. Either drop them too (decision G already touches cbh_trial_spec's incidence_draws path), or record that they are kept on purpose.
- **`R_cbh/exploratory/02_malaria_rates_ihme_vs_igme.R (SIMPLIFY: move to reporting)`**: The move is underspecified in ways that could cause confusion or stale exports. *Correction:* Write to its own subfolder (for example <root>/ihme_vs_unigme/) with a distinct CSV name. Write provenance.csv and add the folder to export_paper.py's figure_dirs. Ask the author whether the in-panel statistics note should move to the caption.
- **`R_mics/09_regional_covariates.R (REMOVE)`**: The knock-on list rewords the comments citing covariates 11 and 17 but leaves out the comments that cite R_mics/09. *Correction:* Reword these comments in the same batch (snow/10 is in the snow_covariates stage, so this adds no extra staleness to the planned full rerun).

## Decisions for the author

A. **Country fixed-effects sensitivity (requested 31 October): it is not in main.tex or the Overleaf folder. Add it to the paper, or remove it?**  
   Files: `R_cbh/sensitivity/country_fe/01_fit.R; R_cbh/sensitivity/country_fe/02_report.R; paper/Supplementary Figures/sfig_pfpr_splines_country_fixed_effects.png; paper/Supplementary Figures/sfig_pfpr_splines_country_fixed_effects_caption.md; paper/tables/country_fixed_effects_summary.md; docs/manuscript/cou`  
   Recommendation: Remove, unless it is going into the Supplement now. That means removing stage country_fe (about 20 min) and its minutes entry, and in export_paper.py the country_fe path, 3 assets and the report-provenance loop entry. If it goes in, refresh the proposed text with the v2 numbers (it quotes v1).
B. **Discussion comparator declines (63% UN IGME, 53% IHME since 2000; 8% since 2015): keep the old source-comparison table as their source, or compute them elsewhere?**  
   Files: `R_cbh/reporting/12_source_comparison_table.R; paper/tables/source_comparison_2000_2024.csv; paper/tables/annual_totals_2000_2024.csv; R_inputs/who_wmr2025_tables.R`  
   Recommendation: Keep 12 trimmed to the under-five rows, keep both CSV exports as the number sources, and drop the WMR rows, the LaTeX and the md, so who_wmr2025_tables.R can go. Also fix the 63%: today it is CA-CODE deaths over WPP child-years computed by hand, while the CSV gives 62.4% (IHME person-years). uncertainty/contrasts.csv covers only PfPR-ACM changes, so it cannot replace this.
C. **Keep the optional Snow split reproduction check (stage snow_repro)? It needs the private analysis project's GPKG and is not part of --all.**  
   Files: `R_cbh/snow/config/v9_surveys.csv; verification/snow_reproduction.md; split_repro branches in R_cbh/snow/R/settings.R, R_cbh/primary/settings.R (snow_split_repro), R_cbh/snow/02_pfpr_polygons.R (gpkg/density), R_cbh/snow/R/placement.R and 08_units.R (split rule), R_cbh/snow/07_placement.R (universe v`  
   Recommendation: Remove the stage, the split_repro branches, v9_surveys.csv and snow_reproduction.md together; git history keeps the evidence. It is the last v9-tied piece left after remove-v9. Removing a R_cbh/snow/config csv changes the helpers md5, so every stage goes stale; do it in the same batch as the other code edits.
D. **Keep the HIV model refit (stage hiv) in --all? It is only a check; use_frozen_hiv.R restores the panels the paper uses.**  
   Files: `R_cbh/hiv/01_fit_incidence.R; run_pipeline.R stage hiv`  
   Recommendation: Keep 01_fit_incidence.R, because it is the model the Supplementary Methods describe and it made the frozen panels. Make stage hiv optional, like snow_repro, which saves about 30 min, and drop the unused --cv and --validate-latent options. use_frozen_hiv.R already copes when no refit exists.
E. **Drop the snow label inventory guard (06 and 06b)? It is not needed for any paper output.**  
   Files: `R_cbh/snow/06_label_inventory.R; R_cbh/snow/06b_check_labels.R`  
   Recommendation: Remove both, because 09_covariates_dhs.R already stops on an unclassified label. Change the snow_unit_steps index slices in run_pipeline.R ([1:9] -> [1:7], [10:11] -> [8:9]).
F. **Remove the legacy child-band inputs and dead loader? They feed no model, but removing them changes the child-band build signature and forces a full dhs_bands/mics rebuild.**  
   Files: `R_inputs/02b_extract_unicef_immunisation.R; data/frozen/data/derived_dhs/hiv_prevalence_country_year.csv; R_cbh/R/load.R; R_cbh/00_config.R (annual_panels$hiv, annual_panels$immunisation, map_admin1)`  
   Recommendation: Do it only together with the other code edits that already force a full rerun. Then drop the two annual_panels entries and map_admin1 from 00_config.R, 02b from the inputs stage, the frozen panel's INPUTS_MANIFEST row, and load.R from load_pipeline.R and the hard-coded helper list in 23_analysis_units_map.R. Check that the prepared dataset is unchanged (only hiv_prev_pct, hib3/pcv3/rotavirus columns go).
G. **Remove the frozen base-panel HIV draws (2.2 MB), which no kept step reads?**  
   Files: `data/frozen/data/derived_cbh/hiv_incidence/child_incidence_draws.rds`  
   Recommendation: Keep it, so the frozen HIV set stays whole (the gain is small). If it is removed: change use_frozen_hiv.R's stopifnot(nrow(m) == 4L) to 3, drop its manifest row and remove the unused spec$imputation_draw path in analysis/model.R.
H. **Keep tools/compare_outputs.R after the verification records are removed?**  
   Files: `tools/compare_outputs.R`  
   Recommendation: Keep it until the slimmed pipeline has been rerun and paper/ checked against the current v14 export, then remove it. Its checkpoint lists still name removed outputs (WMR, v9; remove-v9 edits some of them).
I. **Are these manuscript drafts still in use?**  
   Files: `docs/manuscript/methods_v13_proposed.tex; docs/manuscript/uncertainty_first_pass.md`  
   Recommendation: Remove methods_v13_proposed.tex if the untracked NEJM Methods drafts supersede it. Keep uncertainty_first_pass.md until the Discussion caveats are final; otherwise fold its caveats into the uncertainty SPEC and reword the comment in R_cbh/burden/06_uncertainty_draws.R.

## Pipeline after the cleanup

run_pipeline.R stages, applied on top of remove-v9: restore (tools/restore_frozen.R, no --map) -> inputs (R_inputs/02_extract_map_pfpr.R, 41_extract_map_window_years.R, dhs_region_centroids.R; plus 02b only if decision F keeps it) -> [hiv: R_cbh/hiv/01_fit_incidence.R default and --extended; optional under decision D] -> hiv_panels (tools/use_frozen_hiv.R, R_cbh/hiv/03_add_liberia_aidsinfo.R) -> dhs_bands (R_cbh/01_make_analysis_data.R) -> covariates (R_cbh/covariates/01_fetch_published.R national only, R_cbh/covariates/07_prepare_unicef.R) -> mics (R_mics/00a, 00, 01, 04, 05, 06, 07, 08, 11) -> snow_units (R_cbh/snow/01-05, 07, 08; plus 06/06b if decision E keeps them) -> snow_covariates (snow/09, 10) -> primary (run_regional.R) -> subgroups (subgroups/01_fit.R, 02_report.R, 04_subregion_units_map.R) -> nutrition (nutrition/01_fit.R, 02_report.R) -> [country_fe only if decision A keeps it] -> imputation (imputation_dhsmics/01-06) -> validate (10_validate_reporting.R) -> export (export_paper.py). Optional: snow_repro only if decision C keeps it. Removed: primary_v9 (remove-v9) and snow_maps.
run_regional.R steps: prepare (00_prepare_snow.R) -> fit (01_fit.R) -> national_inputs (burden/00_national_inputs.R) -> effects (02_effects.R) -> diagnostics (04_diagnostics.R, survey_coverage) -> report (03_report.R reduced to the age-band table, or folded into age_fractions) -> flow (01_study_flow_snow.R) -> survey_map (03_survey_map.R, tables only) -> units_map (23, Figure 1) -> hr_by_age (26, Figure 2) -> age_fractions (06, Figure 3) -> annual_burden (burden/04_annual_comparison.R) -> uncertainty (burden/06_uncertainty_draws.R) -> rates_figures (24, Figure 4 and IHME supplement) -> rates_table (25, Table S1) -> model_vs_cause (27, Figure 5) -> ihme_vs_unigme (moved exploratory/02, new step: sfig_malaria_rates_ihme_vs_unigme_2024) -> source_table (12, trimmed, per decision B) -> malaria_share (20) -> paper_manifest (04_paper_figures.R). Removed steps: annual_plot (07), nigeria_burden (05), nigeria_plot (08), burden_figure (11), burden_tables (09), agreement (21), u5_probability (13). The order still holds the existing dependencies: diagnostics before flow (survey_coverage.csv), flow before survey_map (survey_selection.csv), survey_map before units_map (mothers_by_survey, survey_coverage), rates_table before model_vs_cause.

## Sequence

1. Tonight's run (commit 0a9a198) finishes and exports the v14 results; they are the paper's numbers.
2. After approval: apply this plan on top of `remove-v9`, merge into `map-202608`, move the v9 fits and results and the
   provenance files of removed scripts in the v14 results folder to the Trash (the validate stage would otherwise fail
   on them).
3. One full rerun (`--all`, the slimmer pipeline should take about 4–5 hours) so that every output and provenance record
   matches the cleaned code; the numbers should not change. Then validate, export and compare with tonight's export.

Overleaf files not used by main.tex (outside the repository, listed only): figures/: none (all 5 PNGs are included; only .DS_Store is extra); Supplementary Figures/Causal_diagram.pptx (hand-drawn source of the included Causal_diagram.pdf; keep as source); Supplementary Figures/sfig_birth_history_schematic.png (no repo source, no git history); Supplementary Figures/sfig_pfpr_age_schematic.png (no repo source); Supplementary Figures/sfig_pfpr_mortality_schematic.png (no repo source); Supplementary Figures/sfig_raw_mortality_vs_pfpr.png (no repo source); Supplementary Figures/sfig_snow_polygon_records_map.png (no repo source); Supplementary Figures/sfig_burden_comparison.png (= paper/; R_cbh/reporting/11_burden_comparison_figure.R); Supplementary Figures/sfig_under5_death_probability.png (= paper/; R_cbh/reporting/13_under5_death_probability.R); Supplementary Figures/sfig_pfpr_40_to_20_by_subgroup.png (= paper/; R_cbh/sensitivity/subgroups/02_report.R); Supplementary Figures/sfig_pfpr_curves_v9_vs_snow.png (= paper/; R_cbh/reporting/22_compare_v9_snow.R; depends on v9); Supplementary Figures/sfig_snow_boundary_agreement_map.png (= paper/; R_cbh/snow/22_map_boundary_agreement.R); Supplementary Figures/sfig_survey_map_and_timing.png (= paper/; R_cbh/reporting/03_survey_map.R); Supplementary Figures/sfig_survival_vs_pfpr_by_subregion.png (= paper/; R_cbh/sensitivity/subgroups/03_survival_by_subregion.R); Supplementary Figures/.DS_Store and figures/.DS_Store; tables/ (outside the requested scope, listed for completeness; main.tex \inputs nothing): age_band
