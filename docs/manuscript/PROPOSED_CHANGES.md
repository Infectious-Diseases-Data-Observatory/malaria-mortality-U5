# Proposed changes to main.tex (Snow-unit primary)

Generated on 15 October 2026 by a script that applies each change to a copy of the Overleaf `main.tex` (saved 15 October 2026, 18:05). The script checks that every change matches the current text exactly once. `main.tex` itself is not edited.
- **Already applied:** the changes you have already made, or replaced by your own wording, are listed at the end. Corrections to your edits are E1–E5.
- **Full proposed manuscript:** `docs/manuscript/main_proposed.tex`.
- **Numbers:** from the verified run of 13 October 2026 (commit 3e2c721). Sources for each number are in `docs/PAPER_TEXT_SNOW.md`.
- **Line numbers:** those of the current `main.tex`.

Kinds of change:
- **update:** follows from the updated approach (Snow et al. units, Figure 1, South Sudan, sensitivity suite).
- **fix:** an error in the current text, found in this review.
- **optional:** a suggestion.

## Summary

| ID | Line | Section | Kind | Why |
|---|---:|---|---|---|
| R14 | 110 | Results, Nigerian states | update | States: 35 of 37, medians 1.66 and 1.18. The added sentence cites Figure 4, which the text never cites (under5_death_probability.csv, 2024: median 12.3 per 1,000, share 19.9%, ratio to IHME 1.50). |
| R16 | 119 | Table 1 | update | Snow values (paper/tables/country_comparison_2024.latex.txt): the Central African Republic replaces DR Congo in the ten; total 586,723. The caption now says the ranking is by the difference from IHME. |
| R17 | 145 | Table 2 | update | Snow values (paper/tables/source_comparison.latex.txt): model deaths 1,111,970 / 687,031 / 586,723; rates 10.12 / 4.33 / 3.31; adds a footnote on the shared denominator and estimands. |
| R18 | – | Tables 1 and 2 | fix | Table 2 (source comparison) is cited before Table 1 (L104 before L107); swapping the two environments numbers them in citation order. References use labels, so nothing else changes. |
| E1 | 76 | Results, first paragraph | fix | Placeholders filled for mainland sub-Saharan Africa and Madagascar: the registry's 171 surveys in 41 countries less the Comoros (1 DHS, 1 MICS) and São Tomé and Príncipe (1 DHS, 2 MICS); survey_map/survey_timeline_all.csv. Lesotho's five surveys are still in the 166, as the next sentences say. |
| E2 | 85 | Figure 1 label | fix | The map was relabelled fig:survey_timing, so every \ref{fig:map} (L78) is undefined and the survey-count sentence (L76) points at the map. Restores fig:map; fig:survey_timing is the label of the supplementary survey map and timing (S1). |
| E3 | 91 | Results, attributable fractions | fix | The word 'Figure' is missing before the reference. |
| E4 | 99 | Results, sensitivity paragraph | fix | Southern Africa's maximum PfPR is 10.33% (subregions_not_fitted.csv), so 'never exceeded 10%' is false; its records are in the primary analysis, it is only not refitted. |
| E5 | 99 | Results, sensitivity paragraph | update | Explains the flat Central Africa curves and cites the new raw-data figure (central_africa_low_prevalence.csv: Chad 32,860 of 56,959 records, survival 99.13%; other sub-regions 99.63%; Central Africa 40->20% hazard ratios 0.98-1.11 after the first month). |
| D5 | 216 | Discussion, limitations | optional | Optional limitation on the new unit construction (Figure 1 caption: 161,042 of 1,125,610 mothers in unions). |
| M1 | 224 | Methods, comment block | optional | The old notes are partly fixed by these changes; replaced by the items still open (comments only, no change to the PDF). |
| M2 | 246 | Methods, DHS covariates | update | All 13 area-level covariates are now computed from the recodes for each survey x Snow area; the published survey-region indicator tables no longer fit the units. National validation: dhs_national_validation.csv. |
| M3 | 247 | Methods, MICS | update | MICS regions are now only a step to place records in Snow areas. |
| M4 | 250 | Methods, prevalence | update | Exposure now uses density x cell-area weights over Snow polygons. The new paragraph describes the unit construction (merge rule); the last sentence cites the optional boundary-agreement figure (drop it with that figure). |
| M5 | 252 | Methods, exposure assignment | update | Snow units. |
| M6 | 267 | Methods, covariates | update | Snow units. |
| M7 | 267 | Methods, covariates | update | Snow units. |
| M8 | 269 | Methods, survey weights | update | No published indicators are used any more; PR/HW items use the household weight (hv005). The old clause 'excluding missing individual responses from each variable's denominator' contradicts the DHS rule in the code (R_cbh/snow/R/label_rules.R: 'missing' and don't know count as 'no'; only items not asked are out of the denominator); MICS items are handled item by item, so the rule is stated for DHS only. |
| M9 | 271 | Methods, fallbacks and South Sudan | update | Record-weighted within-survey mean (merge rule); the South Sudan rule (author decision, 12 October; national_substitutions.csv). Optional extra: 'South Sudan's own GDP estimates for 2008-2010 (23,669 records) were also replaced, so that the three series come from the same country.' |
| M9b | 271 | Methods, fallbacks | optional | The exclusion now has a second reason (no polygon). |
| M10 | 285 | Methods, likelihood | fix | Snow units; and the fits use record-level (Bernoulli) data, which the current wording does not say. |
| M11 | 287 | Methods, model | update | Frozen reference knots (R_cbh/primary/reference_knots.csv: 0.0165-94.76). |
| M12 | 287 | Methods, model | update | Random effect on survey x Snow unit. Records outside the knots: at most 194 per band (upper bound from the imputed sample). |
| M13 | 291 | Methods, burden | fix | The series is 2000-2024 (Table 2, Figure 3C). |
| M13b | 291 | Methods, burden (Figure 4) | fix | Figure 4's method is not described anywhere in the text (flag A9); taken from the generated Figure 4 caption. |
| M14 | 295 | Methods, sensitivity overview | update | Matches the analyses actually run; fixes 'paramerisation'. |
| M15 | 296 | Methods, sensitivity analyses | update | Snow subgroup suite and imputation sample. The old HIV clause ('Liberia and São Tomé ... latent adolescent series') was wrong: Liberia's rate comes from AIDSinfo counts and is fixed, and São Tomé has no Snow area. |
| M16 | 306 | Data sharing | update | Lists every input (and the registration requirement); the repository URL that follows is already correct. |
| S1 | 323 | Supplementary: survey map and timing (old Figure 1) and boundary agreement | update | The old Figure 1 becomes the first supplementary figure (it is cited first). |
| S2 | 325 | Supplementary: study flow caption | fix | The current caption describes child HIV prevalence; the model uses incidence. Adds the Snow placement and the South Sudan rule. |
| S3 | 331 | Supplementary: PfPR by age caption | fix | Typo ('ration'), and states the reference and the plotted range. |
| S4 | 336 | Supplementary: subgroup figures | update | The Snow suite has three figures: the Sahel (this file now shows the Sahel only), UN sub-regions and periods. Captions condensed from the caption files. |
| S4b | – | Supplementary: raw survival by sub-region (new) | update | New supplementary figure (user request, 15 October 2026): the raw data behind the sub-region refits, with unadjusted spline fits; caption condensed from CAPTION_sfig_survival_vs_pfpr_by_subregion.md. |
| S5 | 346 | Supplementary: imputation caption | update | Condensed from sfig_pfpr_splines_imputed_covariates_caption.md. |
| S6 | 353 | Supplementary: no-nutrition caption | update | Condensed from sfig_pfpr_splines_without_nutrition_caption.md. |
| S7 | 360 | Supplementary: malaria share caption | optional | Optional: states the difference in estimands shown in the figure. |
| S9 | 361 | Supplementary: boundary agreement (optional) | optional | Optional new figure documenting how survey regions map to the Snow et al. polygons; placed last because it is first cited in Methods (drop it together with the last sentence of the geographic-units paragraph, M4). |
| S8 | 365 | Table S1 | fix | The current Table S1 shows the old DHS-only values (5,465,305 records, 75,726 deaths); replaced by the Snow primary table (7,639,443 records, 105,114 deaths). |

## Already done in main.tex (not repeated)

| ID | Section | Status |
|---|---|---|
| A1 | Abstract | already in main.tex |
| A2 | Abstract | already in main.tex |
| A3 | Abstract | already in main.tex |
| A4 | Abstract | already in main.tex |
| A5 | Abstract | already in main.tex |
| A6 | Abstract | already in main.tex |
| R1 | Results, first paragraph | superseded by the author's edit |
| R2 | Results, first paragraph | superseded by the author's edit |
| R3 | Results, second paragraph | already in main.tex |
| R4 | Figure 1 caption | superseded by the author's edit |
| R5 | Results, model paragraph | superseded by the author's edit |
| R6 | Results, model paragraph | superseded by the author's edit |
| R7 | Results, attributable fractions | superseded by the author's edit |
| R8 | Results, sensitivity paragraph | superseded by the author's edit |
| R9 | Results, burden paragraph | already in main.tex |
| R10 | Results, burden paragraph | already in main.tex |
| R11 | Results, country comparison | already in main.tex |
| R12 | Results, Nigeria | already in main.tex |
| R13 | Results, Chad | already in main.tex |
| R15 | Figure 3 caption | already in main.tex |
| D1 | Discussion, progress | already in main.tex |
| D2 | Discussion, indirect effects | already in main.tex |
| D3 | Discussion, limitations | already in main.tex |
| D4 | Discussion, limitations | already in main.tex |

## Not changed here

- **SText 1** (`SText1_model_specification.tex`, cited at L287) still describes the archived negative-binomial model. It needs rewriting from `results/cbh/primary_snow520_merge_dhsmics_gamma2_v11/model_formula.txt`. I can draft it as a separate proposed file.
- **Liberia's child HIV incidence.** The commented-out paragraph at L273 describes how it is derived from UNAIDS AIDSinfo counts, and is accurate. Uncommenting it would document flag A1.
- **L65:** still has a `[REF]` placeholder.
- **Table generators in the code repository.** The tables pasted here carry three corrections that their generators still lack, so the `paper/tables/` files differ from the text here until the generators are fixed and the primary stage is rerun:
  - the Table 2 footnote's `12%` is not escaped, so LaTeX drops the rest of the line;
  - the Table 2 footnote's 'counts and rates move in opposite directions' is false for the model column;
  - the Table 1 caption calls IHME's cause-specific deaths 'malaria-attributable', and the Table S1 footnote says 'regional covariates'.
- **Bibliography:** `ref.bib` now has entries for `mics`, `wdi` and `wgi` (added 15 October); the BibTeX below is kept for reference.

```bibtex
@misc{mics,
  author       = {{UNICEF}},
  title        = {Multiple Indicator Cluster Surveys ({MICS})},
  howpublished = {\url{https://mics.unicef.org/surveys}}
}
@misc{wdi,
  author       = {{World Bank}},
  title        = {World Development Indicators},
  howpublished = {\url{https://databank.worldbank.org/source/world-development-indicators}},
  note         = {GDP per capita (NY.GDP.PCAP.CD) and current health expenditure per capita (SH.XPD.CHEX.PC.CD)}
}
@misc{wgi,
  author       = {{World Bank}},
  title        = {Worldwide Governance Indicators},
  howpublished = {\url{https://www.worldbank.org/en/publication/worldwide-governance-indicators}},
  note         = {Political Stability and Absence of Violence/Terrorism, estimate (GOV\_WGI\_PV\_EST)}
}
```

## Changes in full

### R14 — Results, Nigerian states (L110, update)

States: 35 of 37, medians 1.66 and 1.18. The added sentence cites Figure 4, which the text never cites (under5_death_probability.csv, 2024: median 12.3 per 1,000, share 19.9%, ratio to IHME 1.50).

**Current:**

```latex
greater than IHME's estimates in 36 of the 37 states (Figure \ref{fig:IHME_v_model}B). The differences are concentrated in the northern states: the median state ratio is 1.8 in the three northern zones and 1.3 in the three southern zones.
```

**Proposed:**

```latex
greater than IHME's estimates in 35 of the 37 states (Figure \ref{fig:IHME_v_model}B). The differences are concentrated in the northern states: the median state ratio is 1.7 in the three northern zones and 1.2 in the three southern zones. Expressed as the probability of dying before age 5 (Figure \ref{fig:cumulative_risk}), the model attributes a median of 12 deaths per 1,000 live births to malaria across the 42 countries in 2024 (a median 20\% of the all-cause probability), with the highest values in South Sudan (33 per 1,000), Sierra Leone (31) and the Central African Republic (31); this is a median 1.5 times the probability implied by IHME's cause-specific malaria death rates.
```

### R16 — Table 1 (L119, update)

Snow values (paper/tables/country_comparison_2024.latex.txt): the Central African Republic replaces DR Congo in the ten; total 586,723. The caption now says the ranking is by the difference from IHME.

**Current:**

```latex
% Replacement table source; saved as plain text. No manuscript file is edited.
\begin{table}[htbp]
\centering
\caption{Ten countries with the largest absolute differences between the PfPR-ACM model and IHME or UN IGME estimates of malaria-attributable deaths before age five in 2024.}
\label{tab:country}
\begin{tabular}{lrrr}
\toprule
Country & PfPR-ACM model & IHME & UN IGME \\
\midrule
Nigeria & 220,771 & 138,111 & 165,329 \\
Niger & 37,991 & 20,343 & 23,877 \\
Chad & 20,044 & 4,884 & 14,345 \\
Mozambique & 19,595 & 10,285 & 10,315 \\
DR Congo & 70,567 & 61,774 & 105,372 \\
Mali & 20,908 & 12,945 & 6,984 \\
Cameroon & 22,964 & 16,295 & 6,286 \\
South Sudan & 11,384 & 4,779 & 3,980 \\
Angola & 21,118 & 14,652 & 4,734 \\
Cote d'Ivoire & 18,521 & 12,848 & 5,753 \\
\midrule
All 42 countries & 629,136 & 428,147 & 440,123 \\
\bottomrule
\end{tabular}
\end{table}
```

**Proposed:**

```latex
\begin{table}[htbp]
\centering
\caption{Ten countries with the largest absolute differences between the malaria-attributable deaths of the PfPR-ACM model and the malaria deaths estimated by IHME, before age five in 2024.}
\label{tab:country}
\begin{tabular}{lrrr}
\toprule
Country & PfPR-ACM model & IHME & UN IGME \\
\midrule
Nigeria & 206,863 & 138,111 & 165,329 \\
Niger & 36,238 & 20,343 & 23,877 \\
Chad & 18,646 & 4,884 & 14,345 \\
Mozambique & 17,971 & 10,285 & 10,315 \\
Mali & 19,629 & 12,945 & 6,984 \\
South Sudan & 10,635 & 4,779 & 3,980 \\
Cameroon & 21,413 & 16,295 & 6,286 \\
Angola & 19,684 & 14,652 & 4,734 \\
Central African Republic & 8,629 & 3,865 & 5,220 \\
Cote d'Ivoire & 17,098 & 12,848 & 5,753 \\
\midrule
All 42 countries & 586,723 & 428,147 & 440,123 \\
\bottomrule
\end{tabular}
\par\smallskip
\begin{minipage}{\linewidth}\footnotesize
UN IGME denotes the direct under-five CA-CODE 2026 series. Totals include all 42 estimable countries, not only the ten shown. Death counts are rounded after estimation. The model uses the MAP fits with $\gamma=2$ on Snow et al. polygon units.
\end{minipage}
\end{table}
```

### R17 — Table 2 (L145, update)

Snow values (paper/tables/source_comparison.latex.txt): model deaths 1,111,970 / 687,031 / 586,723; rates 10.12 / 4.33 / 3.31; adds a footnote on the shared denominator and estimands.

**Current:**

```latex
\begin{table}[htbp]
\centering
\caption{Malaria mortality by source in 2000, 2015 and 2024, and change to 2024. Negative values are reductions.}
\label{tab:source-comparison}
\small
\setlength{\tabcolsep}{3pt}
\renewcommand{\arraystretch}{1.15}
\begin{tabular*}{\linewidth}{@{\extracolsep{\fill}}lrrr@{}}
\toprule
& \shortstack{PfPR-ACM\\model} & IHME & \shortstack{UN\\IGME} \\
\midrule
\multicolumn{4}{@{}l}{\textit{Malaria deaths}} \\
\quad 2000 & 1,185,329 & 563,657 & 724,276 \\
\quad 2015 & 736,151 & 416,122 & 416,815 \\
\quad 2024 & 629,136 & 428,147 & 440,123 \\
\quad Change 2000--2024 & $-46.9\%$ & $-24.0\%$ & $-39.2\%$ \\
\quad Change 2015--2024 & $-14.5\%$ & $+2.9\%$ & $+5.6\%$ \\
\addlinespace
\multicolumn{4}{@{}l}{\textit{Malaria mortality rate}} \\
\quad 2000 & 10.79 & 5.13 & 6.59 \\
\quad 2015 & 4.64 & 2.62 & 2.63 \\
\quad 2024 & 3.55 & 2.41 & 2.48 \\
\quad Change 2000--2024 & $-67.1\%$ & $-53.0\%$ & $-62.4\%$ \\
\quad Change 2015--2024 & $-23.6\%$ & $-8.1\%$ & $-5.7\%$ \\
\bottomrule
\end{tabular*}
\end{table}
```

**Proposed:**

```latex
\begin{table}[htbp]
\centering
\caption{Malaria mortality by source in 2000, 2015 and 2024, and change to 2024. Negative values are reductions.}
\label{tab:source-comparison}
\small
\setlength{\tabcolsep}{3pt}
\renewcommand{\arraystretch}{1.15}
\begin{tabular*}{\linewidth}{@{\extracolsep{\fill}}lrrr@{}}
\toprule
& \shortstack{PfPR-ACM\\model} & IHME & \shortstack{UN\\IGME} \\
\midrule
\multicolumn{4}{@{}l}{\textit{Malaria deaths}} \\
\quad 2000 & 1,111,970 & 563,657 & 724,276 \\
\quad 2015 & 687,031 & 416,122 & 416,815 \\
\quad 2024 & 586,723 & 428,147 & 440,123 \\
\quad Change 2000--2024 & $-47.2\%$ & $-24.0\%$ & $-39.2\%$ \\
\quad Change 2015--2024 & $-14.6\%$ & $+2.9\%$ & $+5.6\%$ \\
\addlinespace
\multicolumn{4}{@{}l}{\textit{Malaria mortality rate}} \\
\quad 2000 & 10.12 & 5.13 & 6.59 \\
\quad 2015 & 4.33 & 2.62 & 2.63 \\
\quad 2024 & 3.31 & 2.41 & 2.48 \\
\quad Change 2000--2024 & $-67.3\%$ & $-53.0\%$ & $-62.4\%$ \\
\quad Change 2015--2024 & $-23.7\%$ & $-8.1\%$ & $-5.7\%$ \\
\bottomrule
\end{tabular*}
\par\vspace{0.5em}
\begin{minipage}{\linewidth}
\footnotesize
All three columns are deaths before age five in the same 42 countries. Rates use the same annual under-five person-years, implied by the IHME all-cause death count and rate, so within a year the three sources share one denominator.
Model deaths are IHME all-cause deaths in each age band multiplied by the estimated malaria-attributable fraction; IHME and UN IGME are cause-specific malaria death estimates. These are different estimands.
For IHME and UN IGME, deaths rise but rates fall after 2015, because under-five person-time in these countries grew by 12\% between 2015 and 2024.
\end{minipage}
\end{table}
```

### R18 — Tables 1 and 2 (L–, fix)

Table 2 (source comparison) is cited before Table 1 (L104 before L107); swapping the two environments numbers them in citation order. References use labels, so nothing else changes.

**Current:**

```latex
\begin{table}[htbp]
\centering
\caption{Ten countries with the largest absolute differences between the malaria-attributable deaths of the PfPR-ACM model and the malaria deaths estimated by IHME, before age five in 2024.}
\label{tab:country}
\begin{tabular}{lrrr}
\toprule
Country & PfPR-ACM model & IHME & UN IGME \\
\midrule
Nigeria & 206,863 & 138,111 & 165,329 \\
Niger & 36,238 & 20,343 & 23,877 \\
Chad & 18,646 & 4,884 & 14,345 \\
Mozambique & 17,971 & 10,285 & 10,315 \\
Mali & 19,629 & 12,945 & 6,984 \\
South Sudan & 10,635 & 4,779 & 3,980 \\
Cameroon & 21,413 & 16,295 & 6,286 \\
Angola & 19,684 & 14,652 & 4,734 \\
Central African Republic & 8,629 & 3,865 & 5,220 \\
Cote d'Ivoire & 17,098 & 12,848 & 5,753 \\
\midrule
All 42 countries & 586,723 & 428,147 & 440,123 \\
\bottomrule
\end{tabular}
\par\smallskip
\begin{minipage}{\linewidth}\footnotesize
UN IGME denotes the direct under-five CA-CODE 2026 series. Totals include all 42 estimable countries, not only the ten shown. Death counts are rounded after estimation. The model uses the MAP fits with $\gamma=2$ on Snow et al. polygon units.
\end{minipage}
\end{table}


\begin{table}[htbp]
\centering
\caption{Malaria mortality by …
```

**Proposed:**

```latex
\begin{table}[htbp]
\centering
\caption{Malaria mortality by source in 2000, 2015 and 2024, and change to 2024. Negative values are reductions.}
\label{tab:source-comparison}
\small
\setlength{\tabcolsep}{3pt}
\renewcommand{\arraystretch}{1.15}
\begin{tabular*}{\linewidth}{@{\extracolsep{\fill}}lrrr@{}}
\toprule
& \shortstack{PfPR-ACM\\model} & IHME & \shortstack{UN\\IGME} \\
\midrule
\multicolumn{4}{@{}l}{\textit{Malaria deaths}} \\
\quad 2000 & 1,111,970 & 563,657 & 724,276 \\
\quad 2015 & 687,031 & 416,122 & 416,815 \\
\quad 2024 & 586,723 & 428,147 & 440,123 \\
\quad Change 2000--2024 & $-47.2\%$ & $-24.0\%$ & $-39.2\%$ \\
\quad Change 2015--2024 & $-14.6\%$ & $+2.9\%$ & $+5.6\%$ \\
\addlinespace
\multicolumn{4}{@{}l}{\textit{Malaria mortality rate}} \\
\quad 2000 & 10.12 & 5.13 & 6.59 \\
\quad 2015 & 4.33 & 2.62 & 2.63 \\
\quad 2024 & 3.31 & 2.41 & 2.48 \\
\quad Change 2000--2024 & $-67.3\%$ & $-53.0\%$ & $-62.4\%$ \\
\quad Change 2015--2024 & $-23.7\%$ & $-8.1\%$ & $-5.7\%$ \\
\bottomrule
\end{tabular*}
\par\vspace{0.5em}
\begin{minipage}{\linewidth}
\footnotesize
All three columns are deaths before age five in the same 42 countries. Rates use the same annual under-five person-years, implied by the IHME all-cause death count and rate, so within a year the three sources share one denominator.
Model deaths are IHME all-cause deaths in each age band multiplied by the estimated malaria-attributable fraction; IHME and UN IGME are cause-specific malaria death estimates. These are different estimands.
For IHME and UN IGME, deaths rise but rates fall after 2015, because under-five person-time in these countries grew by 12\% between 2015 and 2024.
\end{minipage}
\end{table}


\begin{table}[htbp]
\centering
\caption{Ten countries with the largest absolute differences between the malaria-attributable deaths of the PfPR-ACM model and the malaria deaths estimated by IHME, before age five in 2024.}
\label{tab:country}
\begin{tabular}{lrrr}
\toprule
Country & PfPR-ACM model & IHME & UN IGME \\
\midrule
Nigeria & 206,863 & 138,111 & 165,329 \\
Niger & 36,238 & 20,343 & 23,877 \\
Chad & 18,646 & 4,884 & 14,345 \\
Mozambique & 17,971 & 10,285 & 10,315 \\
Mali & 19,629 & 12,945 & 6,984 \\
South Sudan & 10,635 & 4,779 & 3,980 \\
Cameroon & 21,413 & 16,295 & 6,286 \\
Angola & 19,684 & 14,652 & 4,734 \\
Central African Republic & 8,629 & 3,865 & 5,220 \\
Cote d'Ivoire & 17,098 & 12,848 & 5,753 \\
\midrule
All 42 countries & 586,723 & 428,147 & 440,123 \\
\bottomrule
\end{tabular}
\par\smallskip
\begin{minipage}{\linewidth}\footnotesize
UN IGME denotes the direct under-five CA-CODE 2026 series. Totals include all 42 estimable countries, not only the ten shown. Death counts are rounded after estimation. The model uses the MAP fits with $\gamma=2$ on Snow et al. polygon units.
\end{minipage}
\end{table}
```

### E1 — Results, first paragraph (L76, fix)

Placeholders filled for mainland sub-Saharan Africa and Madagascar: the registry's 171 surveys in 41 countries less the Comoros (1 DHS, 1 MICS) and São Tomé and Príncipe (1 DHS, 2 MICS); survey_map/survey_timeline_all.csv. Lesotho's five surveys are still in the 166, as the next sentences say.

**Current:**

```latex
This gave a total of XXX eligible surveys (119 DHS, 5 MIS, 47 MICS) across XX countries
```

**Proposed:**

```latex
This gave a total of 166 eligible surveys (117 DHS, 5 MIS, 44 MICS) across 39 countries
```

### E2 — Figure 1 label (L85, fix)

The map was relabelled fig:survey_timing, so every \ref{fig:map} (L78) is undefined and the survey-count sentence (L76) points at the map. Restores fig:map; fig:survey_timing is the label of the supplementary survey map and timing (S1).

**Current:**

```latex
\label{fig:survey_timing}
\end{figure}

We fitted separate models
```

**Proposed:**

```latex
\label{fig:map}
\end{figure}

We fitted separate models
```

### E3 — Results, attributable fractions (L91, fix)

The word 'Figure' is missing before the reference.

**Current:**

```latex
compared with less than 5\% in neonates (\ref{fig:main_result2})
```

**Proposed:**

```latex
compared with less than 5\% in neonates (Figure \ref{fig:main_result2})
```

### E4 — Results, sensitivity paragraph (L99, fix)

Southern Africa's maximum PfPR is 10.33% (subregions_not_fitted.csv), so 'never exceeded 10%' is false; its records are in the primary analysis, it is only not refitted.

**Current:**

```latex
Southern Africa was excluded because  \textit{Pf}PR$_{2-10}$ never exceeded 10\%)
```

**Proposed:**

```latex
Southern Africa was not refitted because its \textit{Pf}PR$_{2-10}$ never exceeds 10.3\%)
```

### E5 — Results, sensitivity paragraph (L99, update)

Explains the flat Central Africa curves and cites the new raw-data figure (central_africa_low_prevalence.csv: Chad 32,860 of 56,959 records, survival 99.13%; other sub-regions 99.63%; Central Africa 40->20% hazard ratios 0.98-1.11 after the first month).

**Current:**

```latex
The exceptions were the Sahel region, where mortality rose more steeply between prevalences of 20\% and 40\% for children between 6 and 59 months.
```

**Proposed:**

```latex
The exceptions were the Sahel region, where mortality rose more steeply between prevalences of 20\% and 40\% for children between 6 and 59 months, and Central Africa, where mortality did not increase between prevalences of 20\% and 40\% after the first month. In the unadjusted data (Figure \ref{fig:survival_by_region}), most of Central Africa's records at low prevalence come from Chad (58\% of its records at 24–59 months with a prevalence below 10\%), where survival at these ages (99.1\%) is lower than at similar prevalence elsewhere (99.6\%).
```

### D5 — Discussion, limitations (L216, optional)

Optional limitation on the new unit construction (Figure 1 caption: 161,042 of 1,125,610 mothers in unions).

**Current:**

```latex
It would then follow that \textit{PfPR}$_{2-10}$ should predict all-cause death, reflecting both direct and indirect effects.
```

**Proposed:**

```latex
It would then follow that \textit{PfPR}$_{2-10}$ should predict all-cause death, reflecting both direct and indirect effects. Prevalence is that of the Snow et al.\ polygon containing most of the population of each record's reported location or, where that location spans several polygons (14\% of mothers), the population-weighted mean over them, which blurs local differences in transmission.
```

### M1 — Methods, comment block (L224, optional)

The old notes are partly fixed by these changes; replaced by the items still open (comments only, no change to the PDF).

**Current:**

```latex
% missing in main.tex:
%Liberia's HIV derivation from UNAIDS counts;
%the Uganda Buganda and Sierra Leone 2013 fixes;
%frozen spline knots;
%the Figure 4 and S6 methods;
%two different 2024 MAP rasters;
%the HIV model details;
%the Snow shapefile.

%Places where main.tex disagrees with the code:
%Table S1 still shows the old DHS-only values;
%SText 1 describes the obsolete model;
%L188 says 67% for 2000–2015, but that is 57% (67% is 2000–2024);
%L273 says 2004–2024;
%the S1 caption says HIV prevalence where the model uses incidence;
%the multiple-imputation text doesn't match the v10 method;
%the data-sharing statement points to burden-malaria-prevalence and lists only GBD and DHS as sources.
%Left out: tensor, linear 1–30%, no-region, 1% floor, SMC, seasonality, bam vs gam, and the covariate and random-effect plots. Each is listed with where it lives in the analysis project.
```

**Proposed:**

```latex
% Still open after the Snow-unit update (15 October 2026):
% SText 1 describes the archived negative-binomial model and must be rewritten for the binomial cloglog GAM;
% Liberia's child HIV incidence from AIDSinfo counts is described only in the commented-out paragraph below;
% the two different 2024 MAP rasters (national burden vs Snow areas) and the HIV incidence model details are not described;
% Uganda Buganda and Sierra Leone 2013 fixes; licensing of third-party inputs (see docs/PAPER_CODE_FLAGS.md in the code repository).
```

### M2 — Methods, DHS covariates (L246, update)

All 13 area-level covariates are now computed from the recodes for each survey x Snow area; the published survey-region indicator tables no longer fit the units. National validation: dhs_national_validation.csv.

**Current:**

```latex
For DHS/MIS surveys, child, maternal and household characteristics comprised, from the Births Recodes, maternal age at first live birth, maternal education in completed years, household wealth quintile, urban or rural residence; and, from the published DHS survey-region indicator tables (DHS Program API), coverage of three doses of DTP-containing vaccine (DTP3) and of measles vaccination among children aged 12–23 months, the proportion of births delivered in a health facility, the proportion of non-first births with a preceding birth interval shorter than 24 months, household access to an improved drinking-water source, an improved sanitation facility and electricity, and the prevalence of wasting and stunting among children under five years (WHO Child Growth Standards). Where survey-region DTP3 or measles coverage was not published, the WHO/UNICEF national estimate (WUENIC) for the survey year was used.
```

**Proposed:**

```latex
For DHS/MIS surveys, child, maternal and household characteristics were computed from the survey recodes using the DHS indicator definitions: from the Births Recodes, maternal age at first live birth, maternal education in completed years, household wealth quintile, urban or rural residence, coverage of three doses of DTP-containing vaccine (DTP3) and of measles vaccination among living children aged 12–23 months, the proportion of births in the five years before interview delivered in a health facility, and the proportion of non-first births with a preceding birth interval shorter than 24 months; and, from the Household Member Recodes, household access to an improved drinking-water source, an improved sanitation facility and electricity, and the prevalence of wasting and stunting among children under five years (WHO Child Growth Standards; from the Height and Weight Recodes for surveys whose Household Member Recodes predate the standards). Aggregated to the national level, the eight indicators with published DHS national values reproduced them to within 2 percentage points in 930 of 933 survey–indicator pairs, and in all 790 pairs of the included surveys. Where DTP3 or measles coverage could not be computed for an area, the WHO/UNICEF national estimate (WUENIC) for the survey year was used.
```

### M3 — Methods, MICS (L247, update)

MICS regions are now only a step to place records in Snow areas.

**Current:**

```latex
analysis regions were unions of DHS boundary polygons for the same country where these exist, and admin-1 polygons otherwise (for example, Guinea-Bissau and the Central African Republic). MICS does not publish survey-region indicator tables, so all 13 regional covariates were computed from the MICS microdata using the DHS definitions;
```

**Proposed:**

```latex
the region boundaries were unions of DHS boundary polygons for the same country where these exist, and admin-1 polygons otherwise (for example, Guinea-Bissau and the Central African Republic), and were used to locate MICS records in the Snow et al.\ areas as for DHS. As for DHS, all 13 area-level covariates were computed from the MICS microdata using the DHS definitions;
```

### M4 — Methods, prevalence (L250, update)

Exposure now uses density x cell-area weights over Snow polygons. The new paragraph describes the unit construction (merge rule); the last sentence cites the optional boundary-agreement figure (drop it with that figure).

**Current:**

```latex
Survey-region values were means of each annual surface over the region's boundary polygons, weighted by the Gridded Population of the World version 4 (GPWv4) 2020 population density \cite{gpwv4}.
```

**Proposed:**

```latex
Values for each Snow et al.\ area (below) were means of each annual surface over the area's polygon, weighted by the Gridded Population of the World version 4 (GPWv4) 2020 population density and grid-cell area \cite{gpwv4}; for a union of polygons, the population-weighted mean over its polygons was used.

\textit{Geographic units.} Records were located in the 520 malaria-endemic sub-national polygons used by Snow et al.\ to summarise \textit{P.\ falciparum} prevalence in sub-Saharan Africa \cite{snow:17}. Each record was located by the smallest administrative unit reported in its survey: the survey region, or, where a survey region spans several polygons, a finer location variable recorded in the survey file (for example state, province or district), matched to the polygons by boundary geometry, name or a reviewed alias. A record's unit was the polygon holding at least 90\% of the 2020 GPWv4 population of that location; otherwise it was the union of the polygons each holding at least 5\% of that population. Records in locations more than half of whose population lay in polygons classified as malaria free or as islands were excluded, as were records from the Comoros, São Tomé and Príncipe and Zanzibar, which have no endemic polygon. Of the 1,452 survey-by-area units in the primary analysis, 215 are unions of polygons (median 2, maximum 9 polygons), and the units of one survey can overlap; these unions hold 14\% of the mothers (Figure \ref{fig:map}). Rwanda has a single endemic polygon in the shapefile, so each Rwandan survey forms one unit. Figure \ref{fig:boundary_agreement} compares the survey regions with the Snow et al.\ polygons.
```

### M5 — Methods, exposure assignment (L252, update)

Snow units.

**Current:**

```latex
based on the mother's survey region of residence
```

**Proposed:**

```latex
based on the area of the mother's residence
```

### M6 — Methods, covariates (L267, update)

Snow units.

**Current:**

```latex
Adjustment included 17 covariates: 13 survey-region level summaries and 4 national level measures. Survey-region level covariates were (means or percentages):
```

**Proposed:**

```latex
Adjustment included 17 covariates: 13 area-level summaries (computed for each survey and area) and 4 national level measures. Area-level covariates were (means or percentages):
```

### M7 — Methods, covariates (L267, update)

Snow units.

**Current:**

```latex
We note that regional summaries describe conditions at the time of the survey
```

**Proposed:**

```latex
We note that area-level summaries describe conditions at the time of the survey
```

### M8 — Methods, survey weights (L269, update)

No published indicators are used any more; PR/HW items use the household weight (hv005). The old clause 'excluding missing individual responses from each variable's denominator' contradicts the DHS rule in the code (R_cbh/snow/R/label_rules.R: 'missing' and don't know count as 'no'; only items not asked are out of the denominator); MICS items are handled item by item, so the rule is stated for DHS only.

**Current:**

```latex
DHS recode-derived regional summaries used DHS women's sampling weights, and published DHS regional indicators retained their stated denominators and reference periods. MICS regional summaries were computed from the microdata with the MICS women's, household and children's sampling weights. Regional summaries were calculated before complete-case selection, excluding missing individual responses from each variable's denominator.
```

**Proposed:**

```latex
DHS summaries used the DHS women's sampling weights for Births Recode items and the household weights for Household Member and Height and Weight Recode items. MICS summaries were computed from the microdata with the MICS women's, household and children's sampling weights. Area-level summaries were calculated before complete-case selection; for DHS surveys they follow the DHS tabulation rules, with items not asked left out of the denominator and answers recorded as missing or don't know counted as `no'.
```

### M9 — Methods, fallbacks and South Sudan (L271, update)

Record-weighted within-survey mean (merge rule); the South Sudan rule (author decision, 12 October; national_substitutions.csv). Optional extra: 'South Sudan's own GDP estimates for 2008-2010 (23,669 records) were also replaced, so that the three series come from the same country.'

**Current:**

```latex
Missing regional DTP3 and measles coverage was replaced by the corresponding national UNICEF estimate for the survey year (\url{https://immunizationdata.who.int/}). Remaining missing regional covariates were replaced by the arithmetic mean of available regional values within the same survey.
```

**Proposed:**

```latex
Missing area-level DTP3 and measles coverage was replaced by the corresponding national UNICEF estimate for the survey year (\url{https://immunizationdata.who.int/}). Remaining missing area-level covariates were replaced by the mean of the available values for the survey's other areas, weighted by the number of records in each area. South Sudan became independent from Sudan in July 2011; for band-entry years before 2011, its GDP per capita, health expenditure per capita and political stability were taken from Sudan's series for the same year, which admits the 2010 South Sudan MICS (57,509 child age-band records and 955 deaths, band-entry years 2005–2010). South Sudan's own child HIV incidence series was used throughout.
```

### M9b — Methods, fallbacks (L271, optional)

The exclusion now has a second reason (no polygon).

**Current:**

```latex
São Tomé and Príncipe had no data and were excluded.
```

**Proposed:**

```latex
São Tomé and Príncipe has no child HIV incidence series; its surveys are excluded in any case, as it has no Snow et al.\ polygon.
```

### M10 — Methods, likelihood (L285, fix)

Snow units; and the fits use record-level (Bernoulli) data, which the current wording does not say.

**Current:**

```latex
Because the exposure and all covariates are defined at the survey-region and calendar-year level, the model likelihood is binomial for the number of deaths among children entering each age band in each survey-region and entry month.
```

**Proposed:**

```latex
Models were fitted to the child age-band records; because the exposure and all covariates are defined at the area and calendar-year level, this is equivalent to a binomial likelihood for the number of deaths among children entering each age band in each survey-by-area unit and entry month.
```

### M11 — Methods, model (L287, update)

Frozen reference knots (R_cbh/primary/reference_knots.csv: 0.0165-94.76).

**Current:**

```latex
a penalised cubic regression spline of survey-region \textit{Pf}PR$_{2-10}$ at time of band entry (basis dimension 5)
```

**Proposed:**

```latex
a penalised cubic regression spline of area \textit{Pf}PR$_{2-10}$ at time of band entry (basis dimension 5, with knots fixed at those of an earlier survey-region fit, \textit{Pf}PR$_{2-10}$ 0.02–94.8\%)
```

### M12 — Methods, model (L287, update)

Random effect on survey x Snow unit. Records outside the knots: at most 194 per band (upper bound from the imputed sample).

**Current:**

```latex
and independent Gaussian random intercepts for survey, country and survey-region.
```

**Proposed:**

```latex
and independent Gaussian random intercepts for survey, country and survey-by-area unit. Fewer than 200 records per age band (under 0.02\%) had a prevalence outside the knots, where the spline extrapolates linearly.
```

### M13 — Methods, burden (L291, fix)

The series is 2000-2024 (Table 2, Figure 3C).

**Current:**

```latex
Estimates were produced annually for 2004-2024
```

**Proposed:**

```latex
Estimates were produced annually for 2000–2024
```

### M13b — Methods, burden (Figure 4) (L291, fix)

Figure 4's method is not described anywhere in the text (flag A9); taken from the generated Figure 4 caption.

**Current:**

```latex
with the state sum reconciled against the national estimate.
```

**Proposed:**

```latex
with the state sum reconciled against the national estimate. For Figure \ref{fig:cumulative_risk}, the probability of dying before age 5 was calculated as a period life-table (synthetic cohort) probability, ${}_5q_0 = 1 - \exp(-\sum_g H_g)$, with each band's cumulative hazard $H_g$ from the IHME all-cause death rates; the probability caused by malaria is ${}_5q_0$ minus the probability with each band's hazard multiplied by the hazard ratio for \textit{Pf}PR$_{2-10}$ = 0 versus the country's current prevalence, and the IHME equivalent is ${}_5q_0$ minus the probability with IHME's malaria death rates removed.
```

### M14 — Methods, sensitivity overview (L295, update)

Matches the analyses actually run; fixes 'paramerisation'.

**Current:**

```latex
We carried out a suite of sensitivity analyses to look at how changes in the paramerisation of the models, or if subsetting the data (seasonal versus non seasonal, West Africa vs East Africa, earlier vs later surveys) changed the estimated relationship between prevalence and age specific all-cause mortality.
```

**Proposed:**

```latex
We carried out a suite of sensitivity analyses to assess whether restricting the data by seasonality of transmission, geographic sub-region or period, removing the nutrition covariates, or imputing missing covariates changed the estimated relationship between prevalence and age-specific all-cause mortality.
```

### M15 — Methods, sensitivity analyses (L296, update)

Snow subgroup suite and imputation sample. The old HIV clause ('Liberia and São Tomé ... latent adolescent series') was wrong: Liberia's rate comes from AIDSinfo counts and is fixed, and São Tomé has no Snow area.

**Current:**

```latex
We refitted the 7 age-band models in four subsets of the primary sample: Sahelian survey regions (boundary centroid at or north of 12°N and west of 36°E, excluding the Horn of Africa; 31 surveys in 8 countries with 18,919 deaths recorded), Eastern Africa (UN M49 delimitation of Eastern Africa: 51 surveys in 12 countries with 31,745 deaths), and surveys before versus after the median survey year of 2014 (72 and 63 surveys, respectively). Subset fits used the same specification with knots at quantiles of the subset's own predictor values. In a second sensitivity analysis we imputed every remaining covariate gap rather than excluding records: whole-survey gaps in regional indicators by chained-equation multiple imputation (predictive mean matching, 10 imputations), the missing 2001 political-stability round by interpolation, health expenditure for Zimbabwe 2000–2009 and all countries in 2024 from a generalised additive model on the observed panel, and child HIV incidence for Liberia and São Tomé from the incidence model with a latent adolescent series. This retained all 8,812,458 records (166 surveys in 40 countries with 123,575 deaths); imputation uncertainty was propagated by …
```

**Proposed:**

```latex
We refitted the 7 age-band models in subsets of the primary sample: Sahelian survey regions (boundary centroid at or north of 12°N and west of 36°E, excluding the Horn of Africa; 31 surveys in 8 countries with 18,768 deaths recorded); each UN M49 sub-region of Africa except Southern Africa, namely Western Africa (61 surveys in 15 countries, 54,881 deaths), Middle (Central) Africa (18 surveys in 7 countries, 17,314 deaths) and Eastern Africa (50 surveys in 12 countries, 31,858 deaths), while Southern Africa (7 surveys in Namibia, Eswatini and South Africa, 1,061 deaths) was not refitted because its \textit{Pf}PR$_{2-10}$ never exceeds 10.3\%; surveys conducted up to and including, versus after, the median survey year of 2014 (74 and 62 surveys, respectively); and child age bands entered up to and including, versus after, the median calendar year of entry (2012.8; 3,858,211 and 3,781,232 records). Subset fits used the same specification with knots at quantiles of the subset's own predictor values. In a second sensitivity analysis we imputed every remaining covariate gap rather than excluding records: whole-survey gaps in area-level indicators by chained-equation multiple imputation (predictive mean matching, 10 imputations), the missing 2001 political-stability round by interpolation, and health expenditure for Zimbabwe 2000–2009, Somalia 2000–2012 and all countries in 2024 from a generalised additive model on the observed panel, with draws. As in the primary analysis, South Sudan's GDP per capita, health expenditure per capita and political stability before 2011 were Sudan's values, held fixed. Child HIV incidence came from the extended incidence model (with a latent adolescent series for countries without one), with one posterior draw of each imputed or censored value per imputed dataset. This retained all 8,630,306 records with a Snow et al.\ area (161 surveys in 38 countries with 122,092 deaths); imputation uncertainty was propagated by refitting each of the ten imputed datasets with the smoothing parameters fixed at those of the point fit, and pooling with Rubin's rules.
```

### M16 — Data sharing (L306, update)

Lists every input (and the registration requirement); the repository URL that follows is already correct.

**Current:**

```latex
All input data are publicly available via the GBD client portal and the DHS website.
```

**Proposed:**

```latex
All input data are publicly available: DHS and MIS microdata from the DHS Program and MICS microdata from UNICEF (both after registration), MAP \textit{Pf}PR$_{2-10}$ surfaces, GPWv4 population, the Snow et al.\ sub-national polygons (published with the original article \cite{snow:17}), DHS survey-region boundaries from the DHS Spatial Data Repository, national boundaries from GADM, IHME estimates via the GBD client portal, UN IGME and CA-CODE estimates via the UN IGME portal, WHO/UNICEF immunisation coverage estimates, UNAIDS/UNICEF HIV estimates and World Bank indicators. Lake and reservoir outlines in Figure \ref{fig:map} are from Natural Earth (\url{https://www.naturalearthdata.com/}; public domain) and are used for display only.
```

### S1 — Supplementary: survey map and timing (old Figure 1) and boundary agreement (L323, update)

The old Figure 1 becomes the first supplementary figure (it is cited first).

**Current:**

```latex
\begin{figure}[htbp]\centering
\includegraphics[width=\linewidth]{Supplementary Figures/sfig_study_flow.png}
```

**Proposed:**

```latex
\begin{figure}[htbp]\centering
\includegraphics[width=\linewidth]{Supplementary Figures/sfig_survey_map_and_timing.png}
\caption{DHS/MIS (circles) and MICS (triangles) surveys with complete birth histories conducted in sub-Saharan Africa since 2000: 124 DHS and MIS surveys and 47 MICS surveys in 41 countries. Filled symbols are the 136 surveys (99 DHS, 37 MICS) in 37 countries included in the primary analysis. Open symbols are the 35 excluded surveys: the five surveys from Lesotho (malaria free); the five from the Comoros (two) and São Tomé and Príncipe (three), which have no Snow et al.\ malaria-endemic polygon; and 25 surveys (14 DHS, all five MIS and 6 MICS) in which a required covariate was unavailable in every survey-by-area unit. Countries are grouped by UN sub-region (Central Africa: UN Middle Africa), and map shading shows the number of included surveys in each country. $n$ is the number of mothers (complete birth histories) contributing at least one child to the primary analysis (1,125,610 in total). Survey year is the year of fieldwork. The 46 MICS surveys without a complete birth history are not shown. DRC: Democratic Republic of the Congo; RC: Republic of the Congo; CAF: Central African Republic.}
\label{fig:survey_timing}
\end{figure}

\begin{figure}[htbp]\centering
\includegraphics[width=\linewidth]{Supplementary Figures/sfig_study_flow.png}
```

### S2 — Supplementary: study flow caption (L325, fix)

The current caption describes child HIV prevalence; the model uses incidence. Adds the Snow placement and the South Sudan rule.

**Current:**

```latex
\caption{Data sources and analysis flow. External non-DHS data include MAP (population-weighted with a gridded population surface), WHO/UNICEF vaccine coverage, child HIV prevalence (UNAIDS 0-14 case counts divided by the World Bank population estimates) and World Bank economic series for GDP and health expenditure.}
```

**Proposed:**

```latex
\caption{Sample inclusion for the primary analysis. Counts below the survey registry are child age-band records, not children. Records were placed in the Snow et al.\ malaria-endemic polygons through their smallest reported administrative unit (see Methods). External data are MAP \textit{Pf}PR$_{2-10}$ (population-weighted over each unit), WHO/UNICEF vaccine coverage estimates, UNAIDS child HIV incidence (new infections per 1,000 uninfected children aged 0–14 years) and World Bank GDP per capita, health expenditure per capita and political stability. For South Sudan, Sudan's values of the last three were used for band-entry years before 2011 (57,509 records).}
```

### S3 — Supplementary: PfPR by age caption (L331, fix)

Typo ('ration'), and states the reference and the plotted range.

**Current:**

```latex
\caption{Malaria prevalence and all-cause age band specific child mortality. The y-axis shows the log hazard ration relative for the age-specific mortality relative to a prevalence of 20\%. Mean values (95\% confidence intervals) are shown by the blue lines (shaded areas).}
```

**Proposed:**

```latex
\caption{Malaria prevalence and all-cause age-specific child mortality. Curves show the log hazard ratio of mortality in each age band relative to a prevalence of 20\%, from the seven age-band models of the primary analysis; lines are point estimates and shaded areas 95\% confidence intervals, drawn over the central 95\% of each band's exposure distribution.}
```

### S4 — Supplementary: subgroup figures (L336, update)

The Snow suite has three figures: the Sahel (this file now shows the Sahel only), UN sub-regions and periods. Captions condensed from the caption files.

**Current:**

```latex
\begin{figure}
    \centering
    \includegraphics[width=0.95\linewidth]{Supplementary Figures/sfig_pfpr_splines_by_subgroup.png}
    \caption{Sensitivity analyses: subgroups}
    \label{fig:subgroups}
\end{figure}
```

**Proposed:**

```latex
\begin{figure}
    \centering
    \includegraphics[width=0.95\linewidth]{Supplementary Figures/sfig_pfpr_splines_by_subgroup.png}
    \caption{Sensitivity analysis: Sahel. Log mortality hazard ratios relative to \textit{Pf}PR$_{2-10}$ = 20\% by age band, from the primary analysis (black, with 95\% confidence interval shaded) and refitted to records whose survey-region boundary centroid lies at or north of 12°N and west of 36°E, excluding the Horn of Africa (31 surveys in 8 countries, 18,768 deaths). The refit uses the primary specification with knots at quantiles of the subset's own values. Curves are drawn over the central 95\% of each sample's exposure. The subset is part of the primary sample, so the comparison is descriptive.}
    \label{fig:subgroups}
\end{figure}

\begin{figure}
    \centering
    \includegraphics[width=0.95\linewidth]{Supplementary Figures/sfig_pfpr_splines_by_subregion.png}
    \caption{Sensitivity analysis: UN M49 sub-regions. As Figure \ref{fig:subgroups}, refitted separately in Western Africa (61 surveys in 15 countries, 54,881 deaths), Middle (Central) Africa (18 surveys in 7 countries, 17,314 deaths) and Eastern Africa (50 surveys in 12 countries, 31,858 deaths). Southern Africa (7 surveys in 3 countries, 1,061 deaths) was not refitted because \textit{Pf}PR$_{2-10}$ never exceeds 10.3\%.}
    \label{fig:subgroups_region}
\end{figure}

\begin{figure}
    \centering
    \includegraphics[width=0.95\linewidth]{Supplementary Figures/sfig_pfpr_splines_by_period.png}
    \caption{Sensitivity analysis: period. As Figure \ref{fig:subgroups}, refitted separately in surveys conducted up to (74 surveys) or after (62 surveys) the median survey year, 2014, and in child age bands entered up to (3,858,211 records) or after (3,781,232 records) the median calendar year of entry, 2012.8.}
    \label{fig:subgroups_period}
\end{figure}
```

### S4b — Supplementary: raw survival by sub-region (new) (L–, update)

New supplementary figure (user request, 15 October 2026): the raw data behind the sub-region refits, with unadjusted spline fits; caption condensed from CAPTION_sfig_survival_vs_pfpr_by_subregion.md.

**Current:**

```latex
\label{fig:subgroups_period}
\end{figure}
```

**Proposed:**

```latex
\label{fig:subgroups_period}
\end{figure}

\begin{figure}
    \centering
    \includegraphics[width=0.95\linewidth]{Supplementary Figures/sfig_survival_vs_pfpr_by_subregion.png}
    \caption{Survival through each age band against \textit{Pf}PR$_{2-10}$ in the primary analysis sample, by UN sub-region. Each point is one survey $\times$ area unit $\times$ band-entry year (size: children entering the band). Lines are unadjusted spline fits for each sub-region (binomial generalised additive model with a complementary log-log link and a penalised cubic regression spline of \textit{Pf}PR$_{2-10}$, basis dimension 5, no covariates), drawn over the central 95\% of the sub-region's exposure, with 95\% intervals shaded. Southern Africa, whose prevalence spans 0–10\%, is shown as points only. All panels share the same y-axis; points below 93\% (0.6\% of children) are drawn at the lower edge as open triangles. The fits are descriptive: unlike the age-band models, they are not adjusted for confounders, calendar time or survey and area effects.}
    \label{fig:survival_by_region}
\end{figure}
```

### S5 — Supplementary: imputation caption (L346, update)

Condensed from sfig_pfpr_splines_imputed_covariates_caption.md.

**Current:**

```latex
\caption{Results from multiply imputed datasets.}
```

**Proposed:**

```latex
\caption{Sensitivity analysis: imputed covariates. Log mortality hazard ratios relative to \textit{Pf}PR$_{2-10}$ = 20\% by age band, from the complete-case primary analysis (7,639,443 records, 136 surveys) and from all records with a Snow et al.\ area after imputing every remaining covariate gap (8,630,306 records, 161 surveys in 38 countries; see Methods). Shaded areas are 95\% confidence intervals; curves are drawn over the central 95\% of each sample's exposure. Pooling ten imputed datasets with Rubin's rules changed the 40\%-to-20\% hazard ratios by at most 0.001.}
```

### S6 — Supplementary: no-nutrition caption (L353, update)

Condensed from sfig_pfpr_splines_without_nutrition_caption.md.

**Current:**

```latex
\caption{Results when removing malnutrition indicators from the list of covariates included for adjustment.}
```

**Proposed:**

```latex
\caption{Sensitivity analysis: without the nutrition covariates. Log mortality hazard ratios relative to \textit{Pf}PR$_{2-10}$ = 20\% by age band, from the primary analysis (17 covariates) and from a refit on the same records without area-level wasting and stunting (15 covariates). Shaded areas are 95\% confidence intervals. The largest change in the hazard ratio for a reduction in prevalence from 40\% to 20\% is 0.010, and for 20\% to 0\% 0.036 (both at 1–5 months).}
```

### S7 — Supplementary: malaria share caption (L360, optional)

Optional: states the difference in estimands shown in the figure.

**Current:**

```latex
for 42 sub-Saharan African countries.}
```

**Proposed:**

```latex
for 42 sub-Saharan African countries. The PfPR-ACM model share is attributable (deaths that would not occur at zero prevalence, including deaths caused indirectly by malaria); the IHME and UN IGME (CA-CODE) shares count deaths assigned to malaria as the cause.}
```

### S9 — Supplementary: boundary agreement (optional) (L361, optional)

Optional new figure documenting how survey regions map to the Snow et al. polygons; placed last because it is first cited in Methods (drop it together with the last sentence of the geographic-units paragraph, M4).

**Current:**

```latex
\label{fig:malaria_share_pfpr}
\end{figure}
```

**Proposed:**

```latex
\label{fig:malaria_share_pfpr}
\end{figure}

\begin{figure}[htbp]\centering
\includegraphics[width=\linewidth]{Supplementary Figures/sfig_snow_boundary_agreement_map.png}
\caption{Survey regions of the DHS and MICS files against the Snow et al.\ polygons \cite{snow:17}, for the most recent included survey in each country and the Comoros MICS 2022, which is not analysed. Survey regions are classified by GPW 2020 population: same area (at least 90\% of the region's population lies in one Snow et al.\ polygon, which in turn has at least 90\% of its population in the region); region inside a larger polygon; polygons nested in the region (the region spans several polygons, each lying within it); and boundaries crossing. Regions lying mostly in malaria-free or island polygons, and regions with no Snow et al.\ polygon (the Comoros and Zanzibar), are shown separately; white areas are regions of a mapped survey that are not in the analysis sample. White lines: survey-region boundaries; thin dark lines: Snow et al.\ polygon boundaries; black lines: national borders. Countries without an included survey are light grey.}
\label{fig:boundary_agreement}
\end{figure}
```

### S8 — Table S1 (L365, fix)

The current Table S1 shows the old DHS-only values (5,465,305 records, 75,726 deaths); replaced by the Snow primary table (7,639,443 records, 105,114 deaths).

**Current:**

```latex
\begin{table}[tbp]
\centering
\caption{Age-specific associations between malaria prevalence and all-cause mortality based on primary analysis dataset. Each child can contribute to multiple age band records.}
\label{tab:primary-age-band-effects}
\small
\setlength{\tabcolsep}{3pt}
\renewcommand{\arraystretch}{1.15}
\begin{tabular*}{\linewidth}{@{\extracolsep{\fill}}lrrrcc@{}}
\toprule
\shortstack[l]{Age\\(months)} & \shortstack{Child-band\\records} & \shortstack{Deaths\\(\% of U5 deaths)} & \shortstack{PfPR\\EDF} & \shortstack{HR (95\% interval)\\40\% $\to$ 20\%} & \shortstack{HR (95\% interval)\\20\% $\to$ 0\%} \\
\midrule
$<1$ & 966,553 & 27,788 (36.7\%) & 2.26 & 0.94 (0.91-0.97) & 0.94 (0.89-0.99) \\
1-5 & 868,070 & 11,146 (14.7\%) & 1.77 & 0.92 (0.89-0.96) & 0.91 (0.85-0.97) \\
6-11 & 831,667 & 10,286 (13.6\%) & 2.33 & 0.81 (0.77-0.86) & 0.75 (0.69-0.83) \\
12-23 & 717,905 & 10,215 (13.5\%) & 3.31 & 0.84 (0.78-0.89) & 0.58 (0.51-0.66) \\
24-35 & 713,239 & 8,383 (11.1\%) & 3.38 & 0.82 (0.76-0.89) & 0.53 (0.46-0.61) \\
36-47 & 692,778 & 4,992 (6.6\%) & 3.21 & 0.84 (0.77-0.91) & 0.55 (0.47-0.65) \\
48-59 & 675,093 & 2,916 (3.8\%) & 3.16 & 0.93 (0.84-1.03) & 0.56 (0.47-0.68) …
```

**Proposed:**

```latex
\begin{table}[tbp]
\centering
\caption{Age-specific associations between malaria prevalence and all-cause mortality.}
\label{tab:primary-age-band-effects}
\small
\setlength{\tabcolsep}{3pt}
\renewcommand{\arraystretch}{1.15}
\begin{tabular*}{\linewidth}{@{\extracolsep{\fill}}lrrrcc@{}}
\toprule
\shortstack[l]{Age\\(months)} & \shortstack{Child-band\\records} & \shortstack{Deaths\\(\% of U5 deaths)} & \shortstack{PfPR\\EDF} & \shortstack{HR (95\% interval)\\40\% $\to$ 20\%} & \shortstack{HR (95\% interval)\\20\% $\to$ 0\%} \\
\midrule
$<1$ & 1,346,771 & 38,595 (36.7\%) & 2.42 & 0.94 (0.91--0.97) & 0.96 (0.91--1.01) \\
1--5 & 1,211,050 & 16,076 (15.3\%) & 2.32 & 0.92 (0.88--0.96) & 0.87 (0.81--0.93) \\
6--11 & 1,164,495 & 14,524 (13.8\%) & 2.61 & 0.84 (0.81--0.88) & 0.75 (0.69--0.82) \\
12--23 & 1,007,386 & 13,530 (12.9\%) & 3.61 & 0.88 (0.83--0.94) & 0.53 (0.47--0.61) \\
24--35 & 999,421 & 11,620 (11.1\%) & 3.73 & 0.89 (0.84--0.95) & 0.45 (0.40--0.52) \\
36--47 & 967,271 & 6,826 (6.5\%) & 3.37 & 0.89 (0.82--0.95) & 0.57 (0.49--0.66) \\
48--59 & 943,049 & 3,943 (3.7\%) & 3.32 & 0.94 (0.86--1.03) & 0.56 (0.48--0.66) \\
\midrule
Total & 7,639,443 & 105,114 (100.0\%) & -- & -- & -- \\
\bottomrule
\end{tabular*}
\par\vspace{0.5em}
\begin{minipage}{\linewidth}
\footnotesize
Deaths are observed deaths in the primary analysis sample; percentages use all 105,114 under-five deaths as the denominator.
Displayed percentages use largest-remainder rounding to one decimal place and sum to 100.0\%.
Records are child--age-band observations; a child can contribute multiple records.
EDF: effective degrees of freedom of the PfPR spline. HR: adjusted mortality hazard ratio for reducing PfPR from the first value to the second.
Models were fitted separately by age band using MAP prevalence and $\gamma=2$.
Intervals condition on fitted smoothing parameters, exposure, the fixed HIV imputation and filled area-level covariates; zero PfPR is below observed exposure support in every band.
\end{minipage}
\end{table}
```

