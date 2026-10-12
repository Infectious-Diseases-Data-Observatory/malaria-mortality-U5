# Manuscript text for the Snow-unit primary (12 October 2026)

Replacement text for Overleaf `main.tex`, given as text to paste. No manuscript file is edited. Line numbers refer to `main.tex` as of 12 October 2026. Numbers come from `results/cbh/primary_snow520_merge_dhsmics_gamma2_v11/` and the Snow sensitivity folders. Unchanged numbers are not repeated. All numbers are final for the Snow primary and its sensitivities.

## Abstract (L52)

> Applied to national all-cause mortality estimates from 42 sub-Saharan African countries, we estimate that under-5 malaria mortality fell from 10.0 to 4.3 deaths per 1,000 child-years between 2000 and 2015 (a 57\% decline), and then to 3.2 deaths per 1,000 child-years in 2024 (a further 24\% decline). IHME and UN IGME estimate similarly large declines up until 2015 (49 and 60\% decrease, respectively) but little change since (8 and 6\% decrease). We estimate malaria mortality rates in 2024 were 35\% and 31\% higher than IHME and UN IGME estimate, respectively.

(Previously 10.8, 4.6, 3.5, 47% and 43%. The 57% and 24% declines are unchanged after rounding.)

## Results

**L76: sentence after "...band ended (i.e. was completed) before the interview."**

> Each age band was then located in one of the sub-national malaria-endemic areas defined by Snow et al.\ \cite{snow2017} (provinces, regions, states or districts, or unions of them where a survey reports a coarser region; see Methods) and merged with the population-weighted \textit{Pf}PR$_{2-10}$ estimate from the Malaria Atlas Project (MAP) for that area in the calendar year the band started \cite{map2025}, along with a series of national or subnational estimates of identified confounding variables. The five surveys from Lesotho (four DHS, one MICS) were excluded because Lesotho is not a malaria endemic country, and the five surveys from the Comoros (two) and São Tomé and Príncipe (three) because these islands lie outside the Snow et al.\ endemic areas.

**L77: replace the paragraph.**

> Restricting the analysis to areas and years with all 17 confounding variables measured, a total of 135 surveys (99 DHS, 36 MICS) in 36 countries were included in the primary analysis representing the complete birth histories of 1,118,697 mothers (Figure \ref{fig:flow}); all five MIS surveys, 14 DHS surveys and 7 MICS surveys were excluded because of missing data on identified confounders. The included surveys contributed 7,581,934 child age band records from a total of 2,318,724 children with 104,159 deaths recorded, in 1,442 survey-by-area units. 37\% of these deaths were in neonates (first month of life), 66\% in the first year of life, and 13\% between 1 and 2 years of age.

**L83: Figure 1 caption.** Unchanged, except that open symbols now also include the Comoros and São Tomé and Príncipe surveys. Generated caption: `results/.../survey_map/CAPTION.md`.

**L87: first sentence.** Replace "a set of 17 survey-region and national covariates" with "a set of 17 area-level and national covariates". The neonatal share (37%) is unchanged.

**L90: replace the paragraph.**

> Under this model, for an average \textit{Pf}PR$_{2-10}$ of 10\%, approximately 30\% of all deaths in children 1 year and older are caused by malaria (29–37\% across the four yearly bands), compared with less than 5\% in neonates (Figure \ref{fig:main_result2}). For an average \textit{Pf}PR$_{2-10}$ of 40\% (upper end of prevalence estimates in sub-Saharan Africa now), there is a sharper age-dependent increase in malaria deaths, with around half of all deaths between 12 and 59 months attributable to malaria (47–60\%), peaking at 60\% between 24–35 months.

(Snow, attributable fraction at 10%: <1 month 1.4%, 1–5 months 6.9%, 6–11 months 13.3%, then 30.8, 37.5, 28.9 and 28.8% for the yearly bands. At 40%: 8.8, 19.0, 35.7, 53.6, 60.0, 50.6 and 47.3%. In v9, the 6–11 month attributable fraction at 20% was 31.6%; in Snow it is 23.7%. The other bands differ by at most 2 points.)

**L98: replace the paragraph.**

> We conducted a series of sensitivity analyses in subsets of the primary analysis dataset (see Methods):
> - survey regions in the Sahel only (31 surveys in 8 countries), where transmission is highly seasonal;
> - each UN sub-region with enough data: West Africa (61 surveys in 15 countries), Central Africa (18 surveys in 7 countries) and Eastern Africa (49 surveys in 11 countries). Southern Africa (7 surveys in 3 countries, 1,061 deaths, \textit{Pf}PR$_{2-10}$ at most 10\%) was too small to refit;
> - surveys conducted up to (73 surveys) or after (62 surveys) the median survey year, 2014;
> - child age bands entered up to or after the median calendar date of entry (late 2012).
>
> In general the subset fits gave similar results (Figures \ref{fig:subgroups}–\ref{fig:subgroups_period}). The exceptions were:
> - the Sahel, where the relationship between prevalence and all-cause mortality was steeper for children between 6 and 59 months;
> - Eastern Africa, where it was flat in neonates and flatter at 36–47 months;
> - Central Africa, where fewer than 3\% of records had prevalence below 5\%, mortality did not increase between prevalences of 20\% and 40\% after the first month, and the curves were flatter than in the primary analysis at 24–59 months.
>
> A sensitivity analysis using multiple imputation for the missing covariates, retaining all 161 surveys with a Snow et al.\ area, in 38 countries (8,630,306 child age-band records and 122,092 deaths), gave very similar results to the primary analysis restricted to complete cases (Figure \ref{fig:MI}). Because acute or chronic malnutrition may mediate the relationship between malaria transmission and death as well as confound it, we refitted the models on the same sample without adjusting for wasting and stunting; the estimated prevalence–mortality relationship was essentially unchanged (Figure \ref{fig:without_malnutrition}).

Imputed sensitivity: the 40%→20% hazard ratios are 0.94, 0.92, 0.84, 0.89, 0.89, 0.89 and 0.95, against 0.95, 0.93, 0.84, 0.87, 0.89, 0.89 and 0.94 for complete cases (largest change 0.018). Rubin's-rules pooling changed them by at most 0.001.

The list layout is for review; paste it as running text. The paragraph needs two new figure labels, `fig:subgroups_region` and `fig:subgroups_period`, and their captions (see the Supplementary figures section below).

**L104: replace the paragraph.**

> Pooled across the 42 countries, our estimated under-5 malaria mortality rate fell from 10.0 to 4.3 deaths per 1,000 child-years between 2000 and 2015 (a 57\% decline) and to 3.2 in 2024 (a further 24\% decline), whereas the IHME and UN IGME rates fell by 49\% and 60\% from 2000 to 2015 but by only 8\% and 6\% thereafter (Table~\ref{tab:source-comparison}; Figure~\ref{fig:IHME_v_model}C). In 2024 the \textit{Pf}PR ACM model estimates approximately 576,000 under-5 malaria deaths in these countries, 35\% more than IHME (428,000) and 31\% more than UN IGME (440,000).

**L107–L110: replace.**

> Although the country specific under 5 mortality rates were highly correlated between IHME and our proposed new approach (\textit{Pf}PR ACM, Spearman $\rho$=0.91), the \textit{Pf}PR ACM model estimate exceeded IHME in 33 of the 42 countries (median ratio 1.5), with the largest absolute differences in several populous, high-burden countries (Table \ref{tab:country}).
> In Nigeria, IHME estimates approximately 138 thousand deaths and UN IGME approximately 165 thousand deaths, whereas our approach estimates 204 thousand deaths (48\% and 23\% higher, respectively).
> In Chad we estimate a 3.7-fold higher total burden than IHME and 1.3-fold higher than UN IGME.
> Within Nigeria, applying the \textit{Pf}PR ACM model to state-level age-specific all-cause mortality estimates (IHME) and state-level \textit{Pf}PR$_{2-10}$ estimates gives malaria mortality estimates greater than IHME's estimates in 35 of the 37 states (Figure \ref{fig:IHME_v_model}B). The differences are concentrated in the northern states: the median state ratio is 1.6 in the three northern zones and 1.2 in the three southern zones.

Values: ρ = 0.9105; 33 of 42 countries; median ratio 1.477. Nigeria: 203,752 against 138,111 (×1.475) and 165,329 (×1.232). Chad: 18,300 against 4,884 (×3.75) and 14,345 (×1.28). States: 35 of 37; medians 1.63 and 1.15.

**L120–140, Table 1 (`tab:country`).** Paste `paper/tables/country_comparison_2024.latex.txt`, from `results/.../tables/`. In the ten countries, the Central African Republic comes in and DR Congo drops out; Mali, South Sudan and Cameroon change order. Total: 576,400 / 428,147 / 440,123.

**L150–170, Table 2 (`tab:source-comparison`).** Paste `paper/tables/source_comparison.latex.txt`. Model column:
- deaths: 1,097,510 (2000), 675,647 (2015), 576,400 (2024); change −47.5% (2000–2024) and −14.7% (2015–2024);
- rates: 9.99, 4.26, 3.25; change −67.5% and −23.8%.

The IHME and UN IGME columns are unchanged.

## Discussion (L187)

Replace the sentence beginning "In comparison, our PfPR-ACM model estimates..." with:

> In comparison, our PfPR-ACM model estimates a larger 57\% decrease between 2000 and 2015 (67\% by 2024; the RBM goal was a 75\% reduction by 2015) and continued declines since 2015: a 24\% decrease between 2015 and 2024, against 8\% (IHME) and 6\% (UN IGME) (Table \ref{tab:source-comparison}).

(This also fixes flag B3: the current text gives 67% for 2000–2015.)

## Methods

**L246: replace the DHS covariate sentence.**

> For DHS/MIS surveys, child, maternal and household characteristics were computed from the survey recodes using the DHS indicator definitions:
> - from the Births Recodes: maternal age at first live birth, maternal education in completed years, household wealth quintile, urban or rural residence, coverage of three doses of DTP-containing vaccine (DTP3) and of measles vaccination among living children aged 12–23 months, the proportion of births in the five years before interview delivered in a health facility, and the proportion of non-first births with a preceding birth interval shorter than 24 months;
> - from the Household Member Recodes (or the Height and Weight Recodes for surveys that predate the WHO Child Growth Standards): household access to an improved drinking-water source, an improved sanitation facility and electricity, and the prevalence of wasting and stunting among children under five years (WHO Child Growth Standards).
>
> Aggregated to the national level, these reproduced the published DHS national indicators to within 2 percentage points for 930 of 933 survey–indicator pairs. Where DTP3 or measles coverage could not be computed for an area, the WHO/UNICEF national estimate (WUENIC) for the survey year was used.

**L247: MICS.** Replace "analysis regions were unions of DHS boundary polygons..." with:

> region boundaries were unions of DHS boundary polygons for the same country where these exist, and admin-1 polygons otherwise (for example, Guinea-Bissau and the Central African Republic), and were used to locate MICS records in the Snow et al.\ areas as for DHS.

Also replace "MICS does not publish survey-region indicator tables, so all 13 regional covariates were computed from the MICS microdata using the DHS definitions" with:

> As for DHS, all 13 area-level covariates were computed from the MICS microdata using the DHS definitions.

**L250: replace the last sentence.**

> Values for each Snow et al.\ area (below) were means of each annual surface over the area's polygon, weighted by the Gridded Population of the World version 4 (GPWv4) 2020 population density and grid-cell area \cite{gpwv4}; for a union of polygons, the population-weighted mean over its polygons was used.

**New paragraph after L250 (geographic units).**

> \textit{Geographic units.} Records were located in the 520 malaria-endemic sub-national polygons used by Snow et al.\ to summarise \textit{P.\ falciparum} prevalence in sub-Saharan Africa \cite{snow2017}. Each record was located by the smallest administrative unit reported in its survey: the survey region, or, where a survey region spans several polygons, a finer location variable recorded in the survey file (for example state, province or district), matched to the polygons by boundary geometry, name or a reviewed alias. A record's unit was the polygon holding at least 90\% of the 2020 GPWv4 population of that location; otherwise it was the union of the polygons each holding at least 5\% of that population. Records in locations more than half of whose population lay in polygons classified as malaria free or as islands were excluded, as were records from the Comoros, São Tomé and Príncipe and Zanzibar, which have no endemic polygon. Of the 1,442 survey-by-unit areas in the primary analysis, 215 are unions of polygons (median 2, maximum 9 polygons), and the units of one survey can overlap; they hold 15\% of the records. Rwanda has a single endemic polygon in the shapefile, so each Rwandan survey forms one unit.

**L252: replace "based on the mother's survey region of residence" with** "based on the unit of the mother's residence".

**L267.**
- Replace "13 survey-region level summaries" with "13 area-level summaries (computed for each survey and unit)".
- Replace "Survey-region level covariates were" with "Area-level covariates were".
- The last sentence becomes: "We note that area-level summaries describe conditions at the time of the survey, not values in the past 60 months."

**L269: replace the first sentence.**

> DHS summaries used the DHS women's sampling weights for Births Recode items and the household weights for Household Member Recode items.

**L271: replace the second sentence.**

> Remaining missing area-level covariates were replaced by the mean of the available unit values within the same survey, weighted by the number of records in each unit.

Also, "São Tomé and Príncipe had no data and were excluded" now has a second reason (no endemic polygon). It can stay as is.

**L285.** Replace "defined at the survey-region and calendar-year level" with "defined at the area and calendar-year level", and "in each survey-region and entry month" with "in each area and entry month". Flag B10 on this sentence still stands.

**L287.**
- Replace "a penalised cubic regression spline of survey-region \textit{Pf}PR$_{2-10}$" with "a penalised cubic regression spline of area \textit{Pf}PR$_{2-10}$".
- Replace "random intercepts for survey, country and survey-region" with "random intercepts for survey, country and survey-by-unit area".
- Add after the basis sentence: "Spline knots were held at the values of an earlier fit to survey-region data (\textit{Pf}PR$_{2-10}$ 0.02–94.8\%); at most 139 records per age band (0.01\%) lay outside them, where the spline extrapolates linearly."

**L291.** Replace "Estimates were produced annually for 2004-2024" with "Estimates were produced annually for 2000–2024". This fixes flag B4.

**L296: replace the paragraph.**

> We refitted the 7 age-band models in subsets of the primary sample:
> - Sahelian survey regions (boundary centroid at or north of 12°N and west of 36°E, excluding the Horn of Africa; 31 surveys in 8 countries with 18,768 deaths recorded);
> - each UN M49 sub-region of Africa with enough data:
>   - Western Africa: 61 surveys in 15 countries, 54,881 deaths;
>   - Middle (Central) Africa: 18 surveys in 7 countries, 17,314 deaths;
>   - Eastern Africa: 49 surveys in 11 countries, 30,903 deaths;
>   - Southern Africa (7 surveys in Namibia, Eswatini and South Africa, 1,061 deaths, \textit{Pf}PR$_{2-10}$ at most 10.3\%) was not refitted;
> - surveys before versus after the median survey year of 2014 (73 and 62 surveys, respectively);
> - child age bands entered before versus after the median calendar year of entry (2012.8; 3,800,702 and 3,781,232 records).
>
> Subset fits used the same specification with knots at quantiles of the subset's own predictor values.
>
> In a second sensitivity analysis we imputed every remaining covariate gap rather than excluding records:
> - whole-survey gaps in area-level indicators by chained-equation multiple imputation (predictive mean matching, 10 imputations);
> - the missing 2001 political-stability round by interpolation;
> - national gaps from models fitted to the observed panel, with draws: health expenditure for Zimbabwe 2000–2009, Somalia, South Sudan and all countries in 2024, and GDP per capita and political stability for South Sudan.
>
> No child HIV incidence needed imputing: São Tomé and Príncipe, the only country without a series, has no Snow et al. area.
>
> This retained all 8,630,306 records with a Snow et al.\ area (161 surveys in 38 countries with 122,092 deaths). Imputation uncertainty was propagated by refitting with each of the ten imputed datasets and pooling with Rubin's rules.

Changes from the current text:
- The HIV clause goes. Liberia's incidence comes from AIDSinfo counts (flag B6), and São Tomé has no Snow et al. area.
- The national imputations are now listed in full (flag A16). In the Snow imputed sample, they touch these surveys: Somalia (3 MICS), South Sudan (MICS 2010), Zimbabwe (2 DHS and 2 MICS) and Liberia 2007 (46 records with the 2001 political-stability round).

## Supplementary figures

The Snow subgroup suite gives three figures in place of the current Fig S3. Their captions are in `results/cbh/subgroups_snow520_merge_gamma2_v5/`:
- **Sahel:** `CAPTION.md`, figure `sfig_pfpr_splines_by_subgroup.png`;
- **UN sub-region:** `CAPTION_sfig_pfpr_splines_by_subregion.md`;
- **survey and record period:** `CAPTION_sfig_pfpr_splines_by_period.md`.

Fig S4 (imputation) and Fig S5 (no nutrition) keep their labels.

## Bibliography

`ref.bib` has no entry for Snow et al. (2017). Add:

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

## Data sharing (L288)

The Snow et al. shapefile is open access with the original publication (user, 11 October 2026). Add it to the list of data sources. Flag B8 still applies.
