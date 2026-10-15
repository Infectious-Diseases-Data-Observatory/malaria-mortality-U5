# Manuscript text for the Snow-unit primary (13 October 2026)

> **15 October 2026:** for pasting into `main.tex`, use `docs/manuscript/` instead. It holds the full proposed manuscript (`main_proposed.tex`) and the change list (`PROPOSED_CHANGES.md`), anchored to the 14 October `main.tex` and checked again against the run. This note keeps the sources of the numbers.

Replacement text for Overleaf `main.tex`, given as text to paste. No manuscript file is edited. Line numbers refer to `main.tex` as saved on 8 October 2026; it has not changed since the 12 October version of this note, so the line numbers are the same. Unchanged numbers are not repeated.

All numbers are final for the Snow primary of 13 October 2026 (clean run at commit 3e2c721; validation all PASS) and its sensitivities. Since 12 October the primary includes two author decisions: Figure 1 is a map of complete birth histories per Snow et al. polygon, and South Sudan takes Sudan's GDP per capita, health expenditure per capita and political stability for band-entry years before independence (2011), which admits the 2010 South Sudan MICS (57,509 records, 955 deaths).

Short names for the result folders:
- `P/` = `results/cbh/primary_snow520_merge_dhsmics_gamma2_v11/`
- `SUB/` = `results/cbh/subgroups_snow520_merge_gamma2_v5/`
- `MI/` = `results/cbh/primary_snow520_merge_imputed_gamma2_v12/`
- `NAT/` = `results/cbh/covariate_imputation_snow_v12/`

Each section ends with its sources. Markers:
- **[new 13 Oct]**: a passage that was not in the 12 October version;
- **[numbers 13 Oct]**: a passage from 12 October whose numbers changed;
- no marker: unchanged since 12 October (numbers checked against the new run).

## What changed since 12 October

- Sample: 135 → 136 surveys (MICS 36 → 37), 36 → 37 countries, 1,118,697 → 1,125,610 mothers, 7,581,934 → 7,639,443 records, 2,318,724 → 2,335,868 children, 104,159 → 105,114 deaths, 1,442 → 1,452 survey-by-area units. MICS excluded for covariates: 7 → 6.
- Attributable fraction at 40%: peak 60% → 59% (24–35 months). At 10%: range across the yearly bands 29–37% → 28–37%.
- 2024 burden: 576,400 → 586,723 deaths; 35% and 31% → 37% and 33% above IHME and UN IGME. Rates 10.0, 4.3 and 3.2 → 10.1, 4.3 and 3.3 per 1,000 child-years. The 57% and 24% declines are unchanged.
- Countries above IHME 33 → 34. Nigeria 204 → 207 thousand (48% and 23% → 50% and 25% higher). Chad 3.7-fold → 3.8-fold. Nigerian state medians 1.6 → 1.7 (north), 1.2 unchanged (south).
- Eastern Africa subgroup now includes South Sudan: 49 → 50 surveys, 11 → 12 countries, 30,903 → 31,858 deaths. Surveys up to the median year 73 → 74.
- Imputation sensitivity: South Sudan is no longer imputed (its values before 2011 are Sudan's in both analyses). Largest hazard-ratio change 0.018 → 0.013.
- Rewordings where no result file of the new run gives the 12 October quantity: the Central Africa exposure clause (L98), the share held by unions of polygons (now 14% of mothers) and the count of records outside the spline knots (L287, now an upper bound).
- Corrections after review of this note (13 October), with reasons at each passage:
  - L187: "larger" now refers to the 2000–2024 decline;
  - L98: the reason Southern Africa was not refitted, and every Eastern Africa departure;
  - L296: the period groups ("up to and including"), and the child HIV clause of the imputation sensitivity;
  - the L76 heading, and the boundary sources in the data sharing text.
- New passages: abstract sentence on the sample and attributable fractions, which the 12 October note missed; Figure 1 and its caption; the survey map as a supplementary figure; the South Sudan rule (Methods); the discussion sentence on the indirect share; Table S1; a study flow caption; the data sharing text with Natural Earth; missing bibliography keys.

## Abstract (L51–52)

**L51 [new 13 Oct].** Three replacements in the second paragraph of the abstract:
- "(135 surveys, 37 countries)" becomes "(136 surveys, 37 countries)";
- "data from 2,329,388 children under 5 of whom 104,143 died" becomes "data from 2,335,868 children under 5 of whom 105,114 died";
- the last sentence becomes:

> At 20\% prevalence, the model attributes 4\% of neonatal deaths, 25\% of deaths at 6–11 months and 43–55\% of deaths at 1–4 years to malaria.

(Currently 6%, 32% and 43–54%: the v9 values.)

**L52 [numbers 13 Oct].** Replace the first and third sentences:

> Applied to national all-cause mortality estimates from 42 sub-Saharan African countries, we estimate that under-5 malaria mortality fell from 10.1 to 4.3 deaths per 1,000 child-years between 2000 and 2015 (a 57\% decline), and then to 3.3 deaths per 1,000 child-years in 2024 (a further 24\% decline). IHME and UN IGME estimate similarly large declines up until 2015 (49 and 60\% decrease, respectively) but little change since (8 and 6\% decrease). We estimate malaria mortality rates in 2024 were 37\% and 33\% higher than IHME and UN IGME estimate, respectively.

(Currently 10.8, 4.6, 3.5, 47% and 43%. The 57% and 24% declines are unchanged after rounding.)

Sources: `P/primary_sample.csv` (surveys, countries, children, deaths); `P/attributable_fraction_by_age.csv` (at 20%: 4.4, 24.6, then 46.7, 54.5, 43.0 and 43.9%); `P/annual_comparison/annual_totals_2000_2024.csv` (rates 10.12, 4.33, 3.31; declines 57.2% and 23.7%; IHME 48.9% and 8.1%; UN IGME 60.1% and 5.7%; 2024 ratios 1.370 and 1.333).

## Results

**L76: survey counts [new 13 Oct].** Replace "across 41 countries, Figure \ref{fig:map}." at the end of the second sentence with:

> across 41 countries (Figure \ref{sfig:survey_timing}).

The survey counts (171 surveys: 119 DHS, 5 MIS, 47 MICS; 41 countries) are unchanged. They are now shown in the supplementary survey map, not in Figure 1.

**L76: replace the last two sentences ("Each age band was then merged ..." and "The five surveys from Lesotho ...") with [new 13 Oct: Figure 1 cited]:**

> Each age band was then located in one of the sub-national malaria-endemic areas defined by Snow et al.\ \cite{snow2017} (provinces, regions, states or districts, or unions of them where a survey reports a coarser region; Figure \ref{fig:map} and Methods) and merged with the population-weighted \textit{Pf}PR$_{2-10}$ estimate from the Malaria Atlas Project (MAP) for that area in the calendar year the band started \cite{map2025}, along with a series of national or subnational estimates of identified confounding variables. The five surveys from Lesotho (four DHS, one MICS) were excluded because Lesotho is not a malaria endemic country, and the five surveys from the Comoros (two) and São Tomé and Príncipe (three) because these islands lie outside the Snow et al.\ endemic areas.

**L77: replace the paragraph [numbers 13 Oct].**

> Restricting the analysis to areas and years with all 17 confounding variables measured, a total of 136 surveys (99 DHS, 37 MICS) in 37 countries were included in the primary analysis representing the complete birth histories of 1,125,610 mothers (Figures \ref{fig:map} and \ref{fig:flow}); all five MIS surveys, 14 DHS surveys and 6 MICS surveys were excluded because of missing data on identified confounders (Figure \ref{sfig:survey_timing}). The included surveys contributed 7,639,443 child age band records from a total of 2,335,868 children with 105,114 deaths recorded, in 1,452 survey-by-area units. 37\% of these deaths were in neonates (first month of life), 66\% in the first year of life, and 13\% between 1 and 2 years of age.

The MICS survey added since 12 October is South Sudan 2010 (6,913 mothers), admitted by the South Sudan rule (Methods, L271). Before the rule it was excluded for missing GDP and health expenditure.

Sources: `P/survey_map/survey_timeline_all.csv` (types and exclusion reasons: 99 DHS and 37 MICS included; 14 DHS, 5 MIS and 6 MICS excluded for covariates; 10 surveys in Lesotho, the Comoros and São Tomé and Príncipe); `P/survey_map/mothers_by_survey.csv` (1,125,610 mothers; MC_SSD2010 6,913); `P/prepared_sample.csv` (1,452 units); `P/tables/age_band_results.csv` (deaths: 36.7% neonatal, 65.8% under 1 year, 12.9% at 12–23 months); `P/study_flow/survey_selection.csv` and `P/national_substitutions.csv` (South Sudan); the reference copy's `complete_case_losses.csv` of 12 October (MC_SSD2010 first missing GDP, then health expenditure).

**L80–85: Figure 1 [new 13 Oct].** Replace the whole figure environment. The label `fig:map` is kept.

```latex
\begin{figure}
    \centering
    \includegraphics[width=0.9\linewidth]{figures/fig1_analysis_units_map.png}
    \caption{Complete birth histories included in the primary analysis, by sub-national malaria-endemic polygon of Snow et al.\ \cite{snow2017}. Colours show the number of mothers with at least one child age-band record in the analysis: in total 1,125,610 mothers from 136 surveys (99 DHS, 37 MICS; interviews 2003–2025) in 37 countries, contributing 7,639,443 child age-band records and 105,114 deaths. Records were placed in the polygon holding at least 90\% of the population of their reported area, and otherwise in the union of the malaria-endemic polygons each holding at least 5\%. In 215 of the 1,452 survey-by-area units this gives a union of polygons; the 161,042 mothers (14\%) in these unions are divided among their polygons by population share. The 465 polygons with data hold a median of 1,715 mothers (range 76–49,763). Light grey: the 55 malaria-endemic polygons without data, mostly in countries with no included survey (Botswana, Djibouti, Equatorial Guinea, Eritrea, Somalia and Sudan). Warm grey: malaria-free and island polygons, not analysed. Pale: outside the study area or without a polygon (for example the Comoros and Zanzibar). Blue: lakes and reservoirs of at least 300~km$^2$ (Natural Earth). Africa Albers equal-area projection. Survey years and exclusions by country are shown in Figure \ref{sfig:survey_timing}.}
    \label{fig:map}
\end{figure}
```

Source: `paper/figures/fig1_analysis_units_map_caption.md` (= `P/analysis_units_map/CAPTION.md`). The caption leaves out the colour and line conventions for borders and the scale-bar note; they are in the caption file.

**L87: first sentence.** Replace "a set of 17 survey-region and national covariates" with "a set of 17 area-level and national covariates". The neonatal share (37%) is unchanged.

**L90: replace the paragraph [numbers 13 Oct].**

> Under this model, for an average \textit{Pf}PR$_{2-10}$ of 10\%, approximately 30\% of all deaths in children 1 year and older are caused by malaria (28–37\% across the four yearly bands), compared with less than 5\% in neonates (Figure \ref{fig:main_result2}). For an average \textit{Pf}PR$_{2-10}$ of 40\% (upper end of prevalence estimates in sub-Saharan Africa now), there is a sharper age-dependent increase in malaria deaths, with around half of all deaths between 12 and 59 months attributable to malaria (47–59\%), peaking at 59\% between 24–35 months.

(Attributable fraction at 10%: <1 month 1.9%, 1–5 months 7.4%, 6–11 months 14.0%, then 30.8, 37.2, 27.8 and 29.0% for the yearly bands. At 40%: 10.3, 20.3, 36.3, 53.1, 59.3, 49.5 and 47.3%. In v9, the 6–11 month attributable fraction at 20% was 31.6%; in the Snow primary it is 24.6%. The other bands differ by at most 2.2 points.)

Sources: `P/attributable_fraction_by_age.csv`; `P/comparison_v9/COMPARISON.md`.

**L98: replace the paragraph [numbers 13 Oct].**

> We conducted a series of sensitivity analyses in subsets of the primary analysis dataset (see Methods):
> - survey regions in the Sahel only (31 surveys in 8 countries), where transmission is highly seasonal;
> - each UN sub-region with enough data: West Africa (61 surveys in 15 countries), Central Africa (18 surveys in 7 countries) and Eastern Africa (50 surveys in 12 countries). Southern Africa (7 surveys in 3 countries, 1,061 deaths) was not refitted because its \textit{Pf}PR$_{2-10}$ never exceeds 10.3\%;
> - surveys conducted up to (74 surveys) or after (62 surveys) the median survey year, 2014;
> - child age bands entered up to or after the median calendar date of entry (late 2012).
>
> In general the subset fits gave similar results (Figures \ref{fig:subgroups}–\ref{fig:subgroups_period}). The exceptions were:
> - the Sahel, where the relationship between prevalence and all-cause mortality was steeper for children between 6 and 59 months;
> - Eastern Africa, where it was flat in neonates, flatter at 6–11 and 36–47 months, and steeper at 24–35 and 48–59 months;
> - Central Africa, where 97.5\% of records had a prevalence above 4\%, mortality did not increase between prevalences of 20\% and 40\% after the first month, and the curves were flatter than in the primary analysis at 24–59 months.
>
> A sensitivity analysis using multiple imputation for the missing covariates, retaining all 161 surveys with a Snow et al.\ area, in 38 countries (8,630,306 child age-band records and 122,092 deaths), gave very similar results to the primary analysis restricted to complete cases (Figure \ref{fig:MI}). Because acute or chronic malnutrition may mediate the relationship between malaria transmission and death as well as confound it, we refitted the models on the same sample without adjusting for wasting and stunting; the estimated prevalence–mortality relationship was essentially unchanged (Figure \ref{fig:without_malnutrition}).

Changes from 12 October: Eastern Africa now includes South Sudan (50 surveys, 12 countries); 74 surveys up to the median year. The Central Africa clause now uses the 2.5th percentile of exposure (4.3–4.6% across the age bands), because no result file of the new run gives the 12 October figure ("fewer than 3% below 5%"). The Central Africa sample did not change. The Southern Africa clause now gives the reason in `SUB/REPORT.md`: its prevalence never exceeds 10.3% (95% of records below 7.4%), so a curve at 20% and 40% would be an extrapolation. Size is not the reason: it has 97,137 records.

The Eastern Africa clause now names every band where its curve departs from the primary. The 12 October text named only the neonatal and 36–47 month bands; the same pattern was there on 12 October. The descriptions hold:
- Sahel: 40%→20% hazard ratios 0.71–0.79 at 6–59 months, against 0.84–0.94 in the primary.
- Eastern Africa: 0.97 (0.93–1.02) in neonates. Flatter at 6–11 months (0.90 (0.84–0.96) against 0.84 (0.81–0.88)) and at 36–47 months (0.95 against 0.89). Steeper at 24–35 months (0.80 against 0.89) and 48–59 months (0.83 against 0.94). Close to the primary at 1–5 months (0.90 against 0.92) and 12–23 months (0.88 against 0.88). For 20%→0% at 6–11 months: 0.90 (0.84–0.96) against 0.75 (0.69–0.82).
- Central Africa: 0.98–1.11 after the first month.

If the authors prefer a shorter clause: "Eastern Africa, where it was flat in neonates and differed in shape at older ages". Note that the Eastern Africa curves are the most sensitive to the added South Sudan survey (`verification/snow/VERIFICATION_SNOW.md`, Caveats).

Imputed sensitivity: the 40%→20% hazard ratios are 0.94, 0.92, 0.84, 0.89, 0.89, 0.89 and 0.95, against 0.94, 0.92, 0.84, 0.88, 0.89, 0.89 and 0.94 for complete cases (largest change 0.013). Rubin's-rules pooling changed them by at most 0.001. Without wasting and stunting, the largest change is 0.010 (1–5 months).

The list layout is for review; paste it as running text. The paragraph needs two new figure labels, `fig:subgroups_region` and `fig:subgroups_period` (see the Supplementary figures section below).

Sources: `SUB/sample_summary.csv`, `SUB/subregions_not_fitted.csv`, `SUB/subgroup_definitions.csv`, `SUB/exposure_support.csv`, `SUB/REPORT.md` (hazard-ratio table and the Southern Africa reason), `SUB/pfpr_contrasts.csv` (20%→0%); the reference copy's `SUB/REPORT.md` of 12 October (Eastern Africa pattern); `MI/REPORT.md`; `results/cbh/nutrition_adjustment_snow520_merge_gamma2_v5/CONTRASTS.md`.

**L104: replace the paragraph [numbers 13 Oct].**

> Pooled across the 42 countries, our estimated under-5 malaria mortality rate fell from 10.1 to 4.3 deaths per 1,000 child-years between 2000 and 2015 (a 57\% decline) and to 3.3 in 2024 (a further 24\% decline), whereas the IHME and UN IGME rates fell by 49\% and 60\% from 2000 to 2015 but by only 8\% and 6\% thereafter (Table~\ref{tab:source-comparison}; Figure~\ref{fig:IHME_v_model}C). In 2024 the \textit{Pf}PR ACM model estimates approximately 587,000 under-5 malaria deaths in these countries, 37\% more than IHME (428,000) and 33\% more than UN IGME (440,000).

Source: `P/annual_comparison/annual_totals_2000_2024.csv` (2024: 586,723, 428,147 and 440,123 deaths).

**L107–L110: replace [numbers 13 Oct].**

> Although the country specific under 5 mortality rates were highly correlated between IHME and our proposed new approach (\textit{Pf}PR ACM, Spearman $\rho$=0.91), the \textit{Pf}PR ACM model estimate exceeded IHME in 34 of the 42 countries (median ratio 1.5), with the largest absolute differences in several populous, high-burden countries (Table \ref{tab:country}).
> In Nigeria, IHME estimates approximately 138 thousand deaths and UN IGME approximately 165 thousand deaths, whereas our approach estimates 207 thousand deaths (50\% and 25\% higher, respectively).
> In Chad we estimate a 3.8-fold higher total burden than IHME and 1.3-fold higher than UN IGME.
> Within Nigeria, applying the \textit{Pf}PR ACM model to state-level age-specific all-cause mortality estimates (IHME) and state-level \textit{Pf}PR$_{2-10}$ estimates gives malaria mortality estimates greater than IHME's estimates in 35 of the 37 states (Figure \ref{fig:IHME_v_model}B). The differences are concentrated in the northern states: the median state ratio is 1.7 in the three northern zones and 1.2 in the three southern zones.

Values: ρ = 0.9107; 34 of 42 countries; median ratio 1.499. Nigeria: 206,863 against 138,111 (×1.498) and 165,329 (×1.251). Chad: 18,646 against 4,884 (×3.82) and 14,345 (×1.30). States: 35 of 37; medians 1.66 and 1.18; the state sum is 205,988 against 132,138 IHME malaria deaths (×1.56).

Sources: `P/annual_comparison/country_agreement_2024.csv`; `P/tables/country_comparison_2024.csv`; `P/nigeria_states/README.md` and `state_totals_2024.csv`.

**L120–142, Table 1 (`tab:country`) [numbers 13 Oct].** Paste `paper/tables/country_comparison_2024.latex.txt` (identical to `P/tables/`). Against `main.tex`:
- the Central African Republic comes in (9th: 8,629 / 3,865 / 5,220) and DR Congo drops out;
- the order is Nigeria, Niger, Chad, Mozambique, Mali, South Sudan, Cameroon, Angola, Central African Republic, Côte d'Ivoire;
- total: 586,723 / 428,147 / 440,123 (currently 629,136);
- the caption now says "...between the PfPR-ACM model and IHME estimates..." (the ranking is by the difference from IHME), and a footnote describes the UN IGME series and the totals.

**L145–171, Table 2 (`tab:source-comparison`) [numbers 13 Oct].** Paste `paper/tables/source_comparison.latex.txt` (identical to `P/burden_comparison/`). Model column:
- deaths: 1,111,970 (2000), 687,031 (2015), 586,723 (2024); change −47.2% (2000–2024) and −14.6% (2015–2024);
- rates: 10.12, 4.33, 3.31; change −67.3% and −23.7%.

The IHME and UN IGME columns are unchanged. The pasted table adds a footnote: shared denominator, different estimands, and under-five person-time growth of 12% between 2015 and 2024.

## Discussion

**L187.** Replace the sentence beginning "In comparison, our PfPR-ACM model estimates..." with:

> In comparison, our PfPR-ACM model estimates a larger 67\% decrease between 2000 and 2024 (57\% by 2015, against 49\% for IHME and 60\% for UN IGME; the RBM goal was a 75\% reduction by 2015) and continued declines since 2015: a 24\% decrease between 2015 and 2024, against 8\% (IHME) and 6\% (UN IGME) (Table \ref{tab:source-comparison}).

This fixes flag B3. The current text gives 67% for 2000–2015, but 67% is the 2000–2024 decline. The model's 2000–2015 decline (57%) is smaller than UN IGME's (60%), so "larger" can only refer to 2000–2024: 67%, against the 53% (IHME) and 62% (UN IGME) of the previous sentence. The sentence now agrees with the abstract (L52).

Rates per 100,000 child-years in 2000, 2015 and 2024:
- model: 1,012.47, 433.31 and 330.64 (declines 57.2% to 2015, 67.3% to 2024 and 23.7% from 2015);
- IHME: 513.22, 262.45 and 241.28 (48.9%, 53.0% and 8.1%);
- UN IGME: 659.47, 262.88 and 248.03 (60.1%, 62.4% and 5.7%).

Sources: `P/annual_comparison/annual_totals_2000_2024.csv`; `paper/tables/source_comparison.latex.txt` (−67.3%, −53.0%, −62.4%).

**L192 [new 13 Oct].** Replace "This indirect effect could amount to a third of all deaths caused by malaria if we take the difference between our estimates and IHME/UN IGME at face value." with:

> This indirect effect could amount to around a quarter of all deaths caused by malaria if we take the difference between our estimates and IHME/UN IGME at face value.

"A third" fitted the v9 estimate (629,136 deaths). In the Snow primary the difference is 27% of model deaths against IHME and 25% against UN IGME (2024).

Source: `P/annual_comparison/annual_totals_2000_2024.csv` (1 − 428,147/586,723 = 0.270; 1 − 440,123/586,723 = 0.250).

## Methods

**L246: replace the DHS covariate sentence.**

> For DHS/MIS surveys, child, maternal and household characteristics were computed from the survey recodes using the DHS indicator definitions:
> - from the Births Recodes: maternal age at first live birth, maternal education in completed years, household wealth quintile, urban or rural residence, coverage of three doses of DTP-containing vaccine (DTP3) and of measles vaccination among living children aged 12–23 months, the proportion of births in the five years before interview delivered in a health facility, and the proportion of non-first births with a preceding birth interval shorter than 24 months;
> - from the Household Member Recodes (or the Height and Weight Recodes for surveys that predate the WHO Child Growth Standards): household access to an improved drinking-water source, an improved sanitation facility and electricity, and the prevalence of wasting and stunting among children under five years (WHO Child Growth Standards).
>
> Aggregated to the national level, these reproduced the published DHS national indicators to within 2 percentage points for 930 of 933 survey–indicator pairs. Where DTP3 or measles coverage could not be computed for an area, the WHO/UNICEF national estimate (WUENIC) for the survey year was used.

Source: `results/cbh/snow_units/merge/covariates/dhs_national_validation.csv` (930 of 933 within 2 points).

**L247: MICS.** Replace "analysis regions were unions of DHS boundary polygons..." with:

> region boundaries were unions of DHS boundary polygons for the same country where these exist, and admin-1 polygons otherwise (for example, Guinea-Bissau and the Central African Republic), and were used to locate MICS records in the Snow et al.\ areas as for DHS.

Also replace "MICS does not publish survey-region indicator tables, so all 13 regional covariates were computed from the MICS microdata using the DHS definitions" with:

> As for DHS, all 13 area-level covariates were computed from the MICS microdata using the DHS definitions.

**L250: replace the last sentence.**

> Values for each Snow et al.\ area (below) were means of each annual surface over the area's polygon, weighted by the Gridded Population of the World version 4 (GPWv4) 2020 population density and grid-cell area \cite{gpwv4}; for a union of polygons, the population-weighted mean over its polygons was used.

**New paragraph after L250 (geographic units) [numbers 13 Oct].**

> \textit{Geographic units.} Records were located in the 520 malaria-endemic sub-national polygons used by Snow et al.\ to summarise \textit{P.\ falciparum} prevalence in sub-Saharan Africa \cite{snow2017}. Each record was located by the smallest administrative unit reported in its survey: the survey region, or, where a survey region spans several polygons, a finer location variable recorded in the survey file (for example state, province or district), matched to the polygons by boundary geometry, name or a reviewed alias. A record's unit was the polygon holding at least 90\% of the 2020 GPWv4 population of that location; otherwise it was the union of the polygons each holding at least 5\% of that population. Records in locations more than half of whose population lay in polygons classified as malaria free or as islands were excluded, as were records from the Comoros, São Tomé and Príncipe and Zanzibar, which have no endemic polygon. Of the 1,452 survey-by-unit areas in the primary analysis, 215 are unions of polygons (median 2, maximum 9 polygons), and the units of one survey can overlap; these unions hold 14\% of the mothers (Figure \ref{fig:map}). Rwanda has a single endemic polygon in the shapefile, so each Rwandan survey forms one unit.

Changes from 12 October: 1,442 → 1,452 areas, and "they hold 15% of the records" → "these unions hold 14% of the mothers" (161,042 of 1,125,610). No result file gives the record share for the primary sample; the mother share is the one in the Figure 1 caption.

Sources: `P/prepared_sample.csv` (1,452 units, 215 merged); `results/cbh/snow_units/merge/units/units.csv` with `P/study_flow/survey_selection.csv` (the 215 merged units of the primary surveys: 125 of 2 polygons, maximum 9); `P/analysis_units_map/CAPTION.md` (161,042 mothers, 14.3%); `results/cbh/snow_units/merge/maps/merge_units/merge_units_by_country.csv` (Rwanda: 6 surveys, 6 units).

**L252: replace "based on the mother's survey region of residence" with** "based on the unit of the mother's residence".

**L267.**
- Replace "13 survey-region level summaries" with "13 area-level summaries (computed for each survey and unit)".
- Replace "Survey-region level covariates were" with "Area-level covariates were".
- The last sentence becomes: "We note that area-level summaries describe conditions at the time of the survey, not values in the past 60 months."

**L269: replace the first sentence.**

> DHS summaries used the DHS women's sampling weights for Births Recode items and the household weights for Household Member Recode items.

**L271: replace the second sentence.**

> Remaining missing area-level covariates were replaced by the mean of the available unit values within the same survey, weighted by the number of records in each unit.

**L271: South Sudan [new 13 Oct].** Insert after that sentence (before "Missing child HIV incidence was imputed..."):

> South Sudan became independent from Sudan in July 2011. For band-entry years before 2011, its GDP per capita, health expenditure per capita and political stability were taken from Sudan's series for the same year; this rule admits the 2010 South Sudan MICS (57,509 child age-band records and 955 deaths, band-entry years 2005–2010). South Sudan's own child HIV incidence series was used throughout.

Optional extra sentence, if the authors want the detail: "South Sudan's own GDP estimates for some of these years (23,669 records) were also replaced, so that the three series come from the same country." Without the rule, the survey has no health expenditure or political stability values and is excluded.

Also, "São Tomé and Príncipe had no data and were excluded" now has a second reason (no endemic polygon). It can stay as is.

Sources: `P/national_substitutions.csv` (SSD from SDN, years 2005–2010, 57,509 records, 955 deaths; own GDP values replaced in 23,669 records, none for the other two); `P/study_flow/CAPTION.md`.

**L285.** Replace "defined at the survey-region and calendar-year level" with "defined at the area and calendar-year level", and "in each survey-region and entry month" with "in each area and entry month". Flag B10 on this sentence still stands.

**L287 [numbers 13 Oct].**
- Replace "a penalised cubic regression spline of survey-region \textit{Pf}PR$_{2-10}$" with "a penalised cubic regression spline of area \textit{Pf}PR$_{2-10}$".
- Replace "random intercepts for survey, country and survey-region" with "random intercepts for survey, country and survey-by-unit area".
- Add after the basis sentence: "Spline knots were held at the values of an earlier fit to survey-region data (\textit{Pf}PR$_{2-10}$ 0.02–94.8\%); fewer than 200 records per age band (under 0.02\%) lay outside them, where the spline extrapolates linearly."

The knot count is an upper bound. The primary has no file of records outside the knots. The imputed sample contains every primary record with the same prevalence and has at most 194 records per band outside the knots (56 below and 138 above at <1 month). That is at most 0.016% of the primary records in any band. The 12 October "at most 139" counted only the records above the last knot.

Sources: `R_cbh/primary/reference_knots.csv` (0.0165–94.76); `MI/records_outside_knots.csv`; `P/tables/age_band_results.csv` (records per band).

**L291.** Replace "Estimates were produced annually for 2004-2024" with "Estimates were produced annually for 2000–2024". This fixes flag B4.

**L296: replace the paragraph [numbers 13 Oct; South Sudan new 13 Oct].**

> We refitted the 7 age-band models in subsets of the primary sample:
> - Sahelian survey regions (boundary centroid at or north of 12°N and west of 36°E, excluding the Horn of Africa; 31 surveys in 8 countries with 18,768 deaths recorded);
> - each UN M49 sub-region of Africa with enough data:
>   - Western Africa: 61 surveys in 15 countries, 54,881 deaths;
>   - Middle (Central) Africa: 18 surveys in 7 countries, 17,314 deaths;
>   - Eastern Africa: 50 surveys in 12 countries, 31,858 deaths;
>   - Southern Africa (7 surveys in Namibia, Eswatini and South Africa, 1,061 deaths, \textit{Pf}PR$_{2-10}$ at most 10.3\%) was not refitted;
> - surveys conducted up to and including, versus after, the median survey year of 2014 (74 and 62 surveys, respectively);
> - child age bands entered up to and including, versus after, the median calendar year of entry (2012.8; 3,858,211 and 3,781,232 records).
>
> Subset fits used the same specification with knots at quantiles of the subset's own predictor values.
>
> In a second sensitivity analysis we imputed every remaining covariate gap rather than excluding records:
> - whole-survey gaps in area-level indicators by chained-equation multiple imputation (predictive mean matching, 10 imputations);
> - the missing 2001 political-stability round by interpolation;
> - national gaps from models fitted to the observed panel, with draws: health expenditure for Zimbabwe 2000–2009, Somalia 2000–2012 and all countries in 2024.
>
> South Sudan's GDP per capita, health expenditure per capita and political stability before 2011 were Sudan's, as in the primary analysis, and were held fixed rather than imputed. Child HIV incidence came from the incidence model refitted with a latent adolescent series for countries without one, with one posterior draw of each imputed value per imputed dataset. Among the analysed countries, this changes only Nigeria's imputed child series relative to the primary analysis. No analysed record needed the latent series, which fills only São Tomé and Príncipe (no Snow et al.\ area). Liberia's rate, derived from UNAIDS counts, was held fixed.
>
> This retained all 8,630,306 records with a Snow et al.\ area (161 surveys in 38 countries with 122,092 deaths). Imputation uncertainty was propagated by refitting with each of the ten imputed datasets and pooling with Rubin's rules.

Changes from the current text:
- The HIV clause is rewritten. The current clause ("Liberia and São Tomé from the incidence model with a latent adolescent series") is wrong: Liberia's incidence comes from AIDSinfo counts and is held fixed (flag B6), and São Tomé has no Snow et al. area. But child HIV incidence is still imputed in both analyses:
  - Nigeria has no child series. Its incidence is imputed for all 25 years (2000–2024) in both panels (status `imputed_child_series`). It is the only country of either sample with an imputed series; Liberia's is derived from AIDSinfo counts.
  - The imputed sensitivity reads the extended panel, the primary the base panel. They differ in 1,455 of 3,493 country-years (66 countries), all censored or imputed values. Among the 38 countries of the imputed sample, only Nigeria's 25 country-years differ. Its values are 6–29% higher in the extended panel (2000: 2.18 against 1.69 per 1,000; 2024: 0.35 against 0.31). `MI/REPORT.md` notes that the comparison therefore mixes the covariate imputation with this panel change.
  - In the propagation, each imputed dataset took one posterior draw of every imputed or censored child HIV value (1,074,617 records).
  - São Tomé and Príncipe appears only in the extended panel (25 country-years, `imputed_no_adolescent_series`). No record used it (`MI/imputation_record_counts.csv`: 0).
  - L271 ("Missing child HIV incidence was imputed ...") stays as it is.
- The period bullets say "up to and including, versus after". The current text says "before versus after", but the early groups include the median: surveys with survey year ≤ 2014 (64 before 2014 and 10 in 2014) and records entered at or before 2012.833. The L98 text and the period caption already say "up to".
- The national imputations are now listed in full (flag A16). Since 13 October, South Sudan is no longer imputed: its values before 2011 are Sudan's in both analyses. The panel model still fills South Sudan's GDP for 2016–2024 and its health expenditure for 2011–2016, but no record uses these years (South Sudan's only survey has band entries 2005–2010), so the text leaves them out.
- In the Snow imputed sample, the national imputations reach these surveys. Health expenditure: Somalia (3 MICS) and Zimbabwe (2 DHS and 2 MICS), and the 2024 band entries of five surveys (Ethiopia, Mali, Malawi, Nigeria and Zambia; 7,087 records). Political stability: the 2001 round, in 29 surveys (186,566 records), for example Liberia 2007 (46 records).

Sources: `SUB/sample_summary.csv`, `SUB/subregions_not_fitted.csv`, `SUB/subgroup_definitions.csv` (`survey_year <= 2014`; `records_early <= cutoff < records_late`), `SUB/survey_groups.csv` (early: 64 surveys before 2014 and 10 in 2014); HIV panels `data/derived_cbh/hiv_incidence/child_incidence_country_year_lbr.csv` (primary, `R_cbh/primary/settings.R`) and `child_incidence_country_year_extended_lbr.csv` (imputed sensitivity, `R_cbh/sensitivity/imputation_dhsmics/settings.R`; also `MI/preparation_provenance.csv`); `MI/REPORT.md` (Sample) and `MI/multiple_imputation/REPORT.md` (HIV draws, 1,074,617 records); `NAT/NATIONAL_IMPUTATION.md` and `NAT/national_imputation_summary.csv` (fills); `MI/imputation_record_counts.csv` and `MI/imputation_record_counts_by_survey.csv` (records reached: health expenditure 185,355 in 12 surveys, of which ET8AFL 4,340, ML8AFL 105, MW81FL 1,606, NG8BFL 575 and ZM81FL 461; GDP 0; substituted 57,509 in MC_SSD2010); `MI/prepared_sample.csv`.

## Supplementary figures

**Survey map and timing, formerly Figure 1 [new 13 Oct].** Insert as the first supplementary figure, before the study flow figure (L323), because the text cites it first. This renumbers the supplementary figures (the study flow becomes Fig S2); all references use labels.

```latex
\begin{figure}[htbp]\centering
\includegraphics[width=\linewidth]{Supplementary Figures/sfig_survey_map_and_timing.png}
\caption{DHS/MIS (circles) and MICS (triangles) surveys with complete birth histories conducted in sub-Saharan Africa since 2000: 124 DHS and MIS surveys and 47 MICS surveys in 41 countries. Filled symbols are the 136 surveys (99 DHS, 37 MICS) in 37 countries included in the primary analysis. Open symbols are the 35 excluded surveys: the five surveys from Lesotho (malaria free); the five from the Comoros (two) and São Tomé and Príncipe (three), which have no Snow et al.\ malaria-endemic polygon; and 25 surveys (14 DHS, all five MIS and 6 MICS) in which a required covariate was unavailable in every survey-by-area unit. Countries are grouped by UN sub-region (Central Africa: UN Middle Africa), and map shading shows the number of included surveys in each country. $n$ is the number of mothers (complete birth histories) contributing at least one child to the primary analysis (1,125,610 in total). Survey year is the year of fieldwork. The 46 MICS surveys without a complete birth history are not shown. DRC: Democratic Republic of the Congo; RC: Republic of the Congo; CAF: Central African Republic.}
\label{sfig:survey_timing}
\end{figure}
```

Source: `paper/Supplementary Figures/sfig_survey_map_and_timing_caption.md` (= `P/survey_map/CAPTION.md`). The abbreviations are the labels in the figure.

**Study flow (L323–327) caption [new 13 Oct, optional].** The current caption describes child HIV prevalence (flag B5) and not the Snow placement. A condensed replacement:

> \caption{Sample inclusion for the primary analysis. Counts below the survey registry are child age-band records, not children. Records were placed in the Snow et al.\ malaria-endemic polygons through their smallest reported administrative unit (see Methods). External data are MAP \textit{Pf}PR$_{2-10}$ (population-weighted over each unit), WHO/UNICEF vaccine coverage estimates, UNAIDS child HIV incidence (new infections per 1,000 uninfected children aged 0–14 years) and World Bank GDP per capita, health expenditure per capita and political stability. For South Sudan, Sudan's values of the last three were used for band-entry years before 2011 (57,509 records).}

Source: `paper/Supplementary Figures/sfig_study_flow_caption.md`.

**Subgroups [new 13 Oct: figure environments].** The Snow subgroup suite gives three figures in place of the current Fig S3. Their full captions are exported to `paper/Supplementary Figures/`: `sfig_pfpr_splines_by_subgroup_caption.md`, `sfig_pfpr_splines_by_subregion_caption.md` and `sfig_pfpr_splines_by_period_caption.md`. Condensed versions:

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

Sources: `SUB/CAPTION.md`, `SUB/CAPTION_sfig_pfpr_splines_by_subregion.md`, `SUB/CAPTION_sfig_pfpr_splines_by_period.md`, `SUB/sample_summary.csv`.

The imputation figure (`fig:MI`, currently Fig S4) and the no-nutrition figure (`fig:without_malnutrition`, currently Fig S5) keep their labels; their numbers shift with the new figures. Their full captions are `sfig_pfpr_splines_imputed_covariates_caption.md` and `sfig_pfpr_splines_without_nutrition_caption.md` in the same folder.

## Supplementary tables

**Table S1 (`tab:primary-age-band-effects`, L365–388) [new 13 Oct].** Paste `paper/tables/age_band_results.latex.txt` (identical to `P/tables/`). This fixes flag B1: the current table shows the DHS-only v3 values (5,465,305 records, 75,726 deaths). New values:
- total 7,639,443 records and 105,114 deaths; neonatal deaths 38,595 (36.7%);
- PfPR EDF 2.42, 2.32, 2.61, 3.61, 3.73, 3.37 and 3.32;
- hazard ratio for 40% → 20%: 0.94, 0.92, 0.84, 0.88, 0.89, 0.89 and 0.94;
- hazard ratio for 20% → 0%: 0.96, 0.87, 0.75, 0.53, 0.45, 0.57 and 0.56.

The pasted caption is shorter ("Age-specific associations between malaria prevalence and all-cause mortality.") and a footnote gives the definitions. Flag B12 still applies: the text never cites this table.

## Bibliography

`ref.bib` (saved 7 October 2026) still has no entry for Snow et al. (2017). Add:

```bibtex
@article{snow2017,
  author  = {Snow, Robert W. and Sartorius, Benn and Kyalo, David and Maina, Joseph and Amratia, Punam and Mundia, Clara W. and Bejon, Philip and Noor, Abdisalan M.},
  title   = {The prevalence of \textit{Plasmodium falciparum} in sub-{S}aharan {A}frica since 1900},
  journal = {Nature},
  year    = {2017},
  volume  = {550},
  number  = {7677},
  pages   = {515--518},
  doi     = {10.1038/nature24059}
}
```

Natural Earth needs no entry: the URL in the data sharing statement is enough.

**[new 13 Oct]** Three keys that the live text cites have no entry in `ref.bib`, so they compile as "?": `mics` (L245), `wdi` and `wgi` (L260). This was already true before the Snow primary. The keys `unaids2025` and `aidsinfo` are also missing, but they appear only in the commented-out L273.

## Data sharing (L306)

**[new 13 Oct]** Replace the first sentence ("All input data are publicly available via the GBD client portal and the DHS website.") with:

> All input data are publicly available: DHS and MIS microdata from the DHS Program and MICS microdata from UNICEF (both after registration), MAP \textit{Pf}PR$_{2-10}$ surfaces, GPWv4 population, the Snow et al.\ sub-national polygons (published with the original article \cite{snow2017}), DHS survey-region boundaries from the DHS Spatial Data Repository, national boundaries from GADM, IHME estimates via the GBD client portal, UN IGME and CA-CODE estimates via the UN IGME portal, WHO/UNICEF immunisation coverage estimates, UNAIDS/UNICEF HIV estimates and World Bank indicators. Lake and reservoir outlines in Figure \ref{fig:map} are from Natural Earth (\url{https://www.naturalearthdata.com/}; public domain) and are used for display only.

The 12 October note gave this section as L288; the data sharing statement is at L306. The repository link in the second sentence is already correct. This addresses flag B8 except for licensing (flag B14).

The two boundary sources are new to the list:
- the DHS survey-region boundaries locate DHS records in the Snow et al. polygons (`R_cbh/snow/07_placement.R`) and outline the countries in the supplementary survey map (`R_cbh/reporting/03_survey_map.R`);
- the GADM national boundaries (`data/africa_admin0.rds`) are the country borders of Figure 1 and of the boundary-agreement map.

GADM's terms of use should be checked under flag B14, since `data/africa_admin0.rds` is committed.

Sources: `docs/PAPER_CODE_FLAGS.md` (B8: list of inputs); `data/README.md` (rows "National boundaries", "DHS survey-region boundaries" and Natural Earth 1:10m lakes, public domain, Figure 1 only); `R_cbh/reporting/23_analysis_units_map.R` and `R_cbh/snow/22_map_boundary_agreement.R` (inputs).
