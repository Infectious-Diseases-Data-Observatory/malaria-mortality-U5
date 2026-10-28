#!/usr/bin/env Rscript
# Record paper figure sources/captions locally. Does not access or edit Overleaf.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
source("R_cbh/reporting/labels.R")
root <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION","regional_mics"))$out
out <- file.path(root,"paper_figures")
dir.create(out,recursive=TRUE,showWarnings=FALSE)
# Figure 3 combines the former Figures 4 (2024 panel), 6 and 5 as panels A, B and C.
# Decided 22 September 2026: the log-hazard-by-age curve figure moves to the
# supplement, so the attributable-fraction figure becomes Figure 2 and the
# burden comparison becomes Figure 3.
# Figure 4 (added 24 September 2026): probability of dying before age 5 by country, all causes
# and caused by malaria, with national PfPR in a left panel (R_cbh/reporting/13_under5_death_probability.R).
# Snow-unit primary (12 October 2026, author request): Figure 1 is the map of complete birth histories by analysis
# unit (R_cbh/reporting/23_analysis_units_map.R); the survey map and timing moves to the supplement.
# Reorganised 28 October 2026 (author request): Figure 2 is the hazard ratio by age relative to zero prevalence
# (R_cbh/reporting/26_hazard_ratio_by_age.R), Figure 3 the attributable fraction by age, Figure 4 the malaria-
# attributable mortality rates with UN IGME all-cause mortality; the burden comparison and the probability of dying
# before age 5 move to the supplement, and the log-HR curves relative to 20% leave the paper.
snow <- identical(cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION","regional_mics"))$unit,"snow")
fig1 <- if(snow) c(file="fig1_analysis_units_map.png",source="analysis_units_map/analysis_units_map.png") else
  c(file="fig1_survey_map_and_timing.png",source="survey_map/survey_map_and_timing.png")
figures <- data.frame(figure=1:5,
  filename=c(fig1[["file"]],"fig2_hazard_ratio_by_age.png",
    "fig3_malaria_attributable_fraction_by_age.png","fig4_malaria_mortality_rates_unigme.png",
    "fig5_model_vs_cause_specific_2024.png"),
  source=file.path(root,c(fig1[["source"]],
    "hazard_ratio_by_age/fig2_hazard_ratio_by_age.png","attributable_fraction_by_age.png",
    "mortality_rates/fig_malaria_mortality_rates_unigme.png","model_vs_cause_specific/fig5_model_vs_cause_specific_2024.png")))
stopifnot(all(file.exists(figures$source)))
figures$md5 <- vapply(figures$source,cbh_file_hash,"")
cbh_atomic_csv(figures,file.path(out,"manifest.csv"))
writeLines(c("# Main-paper figures and draft captions","",
  "Figures contain no title, subtitle or embedded caption. Axis labels, age/year facet labels and legends remain. File numbering here does not alter the order of figures in TeX.","",
  if(snow) c("## Figure 1 — complete birth histories used, by analysis unit","",
    "File: `fig1_analysis_units_map.png` (source `analysis_units_map/analysis_units_map.png`; values in `analysis_units_map/analysis_units_by_polygon.csv`).","",
    readLines(file.path(root,"analysis_units_map/CAPTION.md"))[-c(1,2)],"") else
  c("## Figure 1 — survey map and timing","",
    "File: `fig1_survey_map_and_timing.png` (source `survey_map/survey_map_and_timing.png`).","",
    readLines(file.path(root,"survey_map/CAPTION.md"))[-c(1,2)],""),
  "## Figure 2 — hazard ratio of death by age band, relative to zero prevalence","",
  "File: `fig2_hazard_ratio_by_age.png` (source `hazard_ratio_by_age/fig2_hazard_ratio_by_age.png`; values in `hazard_ratio_by_age/hazard_ratio_curves.csv`).","",
  readLines(file.path(root,"hazard_ratio_by_age/CAPTION.md"))[-c(1,2)],"",
  "## Figure 3 — malaria-attributable fraction by age","",
  "File: `fig3_malaria_attributable_fraction_by_age.png` (source `attributable_fraction_by_age.png`).","",
  paste0(cbh_paper_model_label(), ": estimated share of all-cause deaths attributable to malaria within each completed-month age band, at MAP PfPR[2–10] levels of 10%, 20%, 30% and 40% (lower panel), with the distribution of observed deaths by age band (upper panel). Age is drawn to scale; vertical lines mark the band boundaries at 1, 6, 12, 24, 36 and 48 months. Upper panel: each band's share of all under-five deaths observed in the primary sample, as bars of equal width at the band midpoints (bar width does not show band width). Lower panel: points show 100 × {1 − exp[f_g(0) − f_g(P)]}, using the seven separate primary MAP gamma=2 models, placed near the band midpoint; dashed lines connect discrete age-band estimates and do not imply a continuous-age fit. The denominator is all-cause deaths within each band, not all under-five deaths pooled across bands. The hazard-based attributable fraction follows the primary burden convention of holding annual person-time fixed; no country-specific IHME inputs are used here. Zero prevalence lies below observed exposure support, so the counterfactual requires extrapolation. Vertical bars show conditional pointwise 95% intervals, dodged by prevalence level; the interval limits and support flags are retained in attributable_fraction_by_age.csv."),"",
  "## Figure 4 — national malaria-attributable under-five mortality with UN IGME all-cause mortality, 2000–2024","",
  "File: `fig4_malaria_mortality_rates_unigme.png` (source `mortality_rates/fig_malaria_mortality_rates_unigme.png`; the IHME version is the supplementary figure `sfig_malaria_mortality_rates_ihme.png`).","",
  readLines(file.path(root,"mortality_rates/CAPTION_unigme.md"))[-c(1,2)],"",
  "## Figure 5 — PfPR-ACM against cause-specific malaria mortality by country, 2024 (UN IGME, A; IHME, B)","",
  "File: `fig5_model_vs_cause_specific_2024.png` (source `model_vs_cause_specific/fig5_model_vs_cause_specific_2024.png`; values in `model_vs_cause_specific/figure_data.csv`).","",
  readLines(file.path(root,"model_vs_cause_specific/CAPTION.md"))[-c(1,2)],"",
  "## Supplementary figure — comparison with IHME and UN IGME as deaths per 1,000 child-years: countries (A), Nigerian states (B) and annual trend (C) (formerly Figure 3)","",
  "File: `sfig_burden_comparison.png` (exported to the manuscript's `Supplementary Figures/` folder; source `burden_comparison/fig4_burden_comparison.png`). Panel sources: `annual_comparison/country_estimates_2000_2024.csv` (2024 rates), `nigeria_states/state_totals_2024.csv`, `annual_comparison/figure5_data.csv`. The death-count version is the supplementary figure `burden_comparison/sfig_burden_comparison_counts.png` with its own caption (`CAPTION_counts.md`). The separate three-year country scatter (`burden/country_vs_ihme.png`), state figure (`nigeria_states/`) and annual figure (`annual_comparison/`) remain saved results but are no longer paper figures.","",
  readLines(file.path(root,"burden_comparison/CAPTION.md"))[-c(1,2)],"",
  "## Supplementary figure — national PfPR and probability of dying before age 5, all causes and caused by malaria (formerly Figure 4)","",
  "File: `sfig_under5_death_probability.png` (exported to the manuscript's `Supplementary Figures/` folder; source `under5_probability/under5_death_probability_2024.png`; values in `under5_probability/under5_death_probability.csv`).","",
  readLines(file.path(root,"under5_probability/CAPTION.md"))[-c(1,2)],"",
  if(snow) c("## Supplementary figure — survey map and timing (formerly Figure 1)","",
    "File: `sfig_survey_map_and_timing.png` (exported to the manuscript's `Supplementary Figures/` folder; source `survey_map/survey_map_and_timing.png`).","",
    readLines(file.path(root,"survey_map/CAPTION.md"))[-c(1,2)],"") else character(),
  "## Supplementary figure — count version of the burden comparison","",
  "File: `sfig_burden_comparison_counts.png` (exported to the manuscript's `Supplementary Figures/` folder).","",
  readLines(file.path(root,"burden_comparison/CAPTION_counts.md"))[-c(1,2)],"",
  "[Source paths and hashes](manifest.csv). Copy the five main images into the manuscript's `figures/` folder and the supplementary images into `Supplementary Figures/`. The burden comparison is exported as `Supplementary Figures/sfig_burden_comparison.png` (the source file keeps its historical name). Since 28 October 2026 the former main files fig2_malaria_attributable_fraction_by_age.png, fig3_burden_comparison.png and fig4_under5_death_probability.png and the supplementary sfig_pfpr_mortality_by_age.png are no longer exported; TeX references to them need updating by the author. No TeX edits are needed to prepare or copy the images; TeX references/captions are managed separately."),file.path(out,"CAPTIONS.md"))
