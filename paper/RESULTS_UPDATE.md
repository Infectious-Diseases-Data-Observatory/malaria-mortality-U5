# Updated primary results (DHS and MICS surveys)

Figure 1 is the map of complete birth histories used, by analysis unit (`figures/fig1_analysis_units_map.png`); the former Figure 1, the survey map and timing, is now `Supplementary Figures/sfig_survey_map_and_timing.png`.

Figures 1–5 (Figure 2 is the mortality hazard ratio by age band relative to
zero prevalence; Figure 3 the malaria-attributable fraction by age; Figure 4 national
malaria-attributable under-five mortality per 1,000 child-years, 2000–2024, with UN IGME
all-cause mortality; Figure 5 the PfPR-ACM estimates against the cause-specific
estimates of UN IGME and IHME by country in 2024; the burden comparison with IHME and UN IGME and the probability of
dying before age 5 are supplementary figures) and the
supplementary inclusion flow use the 17-variable
regional-adjustment MAP gamma=2 models in `primary_snow520_merge_dhsmics_gamma2_v11`. The analysis contains
2,335,868 children, 7,639,443 child-band records and
105,114 deaths in 1,452 survey x unit areas,
136 surveys and 37 countries.

It combines 99 DHS and 37 UNICEF MICS surveys, with records placed in the malaria-endemic polygons of Snow et al. (2017): 5,598,304 DHS records and 77,966 deaths in 1,148 survey x unit areas, and 2,041,139 MICS records and 27,148 deaths in 304 survey x unit areas. None of the 5 MIS surveys passes complete-case selection.

The revised adjustment removes sex, multiple births and birth order; replaces
maternal age at each birth with regional mean age at first birth; and adds
regional wasting and stunting prevalence. All 13 survey-level predictors are summaries for each survey x unit area (a Snow et al. polygon or a union of polygons), computed from the DHS and MICS recodes with the DHS definitions, then the same WUENIC and within-survey fallbacks as before. The four national annual
variables are unchanged, except the declared substitution: SSD takes SDN's GDP per capita, health expenditure per capita and political stability for band-entry years before 2011 (2005–2010; 57,509 records).

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

The 2024 totals are 586,723 PfPR-ACM deaths,
428,147 IHME deaths and
440,123 UN IGME deaths, summed over the
42 countries in the national burden comparison (36 of the 37 survey countries; ZAF contributes survey data but is outside the burden set).
These are conditional model-based estimates; source and imputation uncertainty
are not fully propagated.

The supplementary sensitivity figures are refitted on the DHS and MICS surveys:
subgroups (`subgroups_snow520_merge_gamma2_v5`) and no nutrition covariates (`nutrition_adjustment_snow520_merge_gamma2_v5`)
on this sample, and imputed covariates on the larger sample of every placed record
(`primary_snow520_merge_imputed_gamma2_v12`, which retains every record placed in a Snow et al. unit: 8,630,306 records, 122,092 deaths, 161 surveys and 38 countries). Malaria's share of under-five deaths against national
PfPR in 2024 (`Supplementary Figures/sfig_malaria_share_vs_pfpr.png`) compares IHME and
UN IGME (CA-CODE) with the PfPR-ACM model. Their captions are exported to
`Supplementary Figures/`.

Previous versions of overwritten files are backed up under `paper_refresh/previous_overleaf/`. `.latex.txt`
files contain source for manual insertion; they do not change the compiled
manuscript automatically. Figure placement and TeX references remain under the
author's control.
