#!/usr/bin/env python3
"""Proposed main.tex for the Snow-unit primary (15 October 2026).

Reads the Overleaf main.tex (read-only), applies the proposed changes below in order, and writes
  <repo>/docs/manuscript/main_proposed.tex   the full proposed manuscript
  <repo>/docs/manuscript/PROPOSED_CHANGES.md the change list, generated from the same table.
Every change must match the current text exactly once, so the script stops if main.tex has moved on.
Numbers come from the verified run of 13 October 2026 (commit 3e2c721); sources in docs/PAPER_TEXT_SNOW.md.
"""
import sys
from pathlib import Path

OV = Path.home() / "Dropbox/Apps/Overleaf/malaria-burden-reassessment/main.tex"
REPO = Path.home() / "Documents/GitHub/malaria-mortality-U5"
PAPER = REPO / "paper"
OUT = REPO / "docs/manuscript"
original = OV.read_text(encoding="utf-8")
text = original


TABLE_FIXES = {
    "country_comparison_2024.latex.txt": [
        ("between the PfPR-ACM model and IHME estimates of malaria-attributable deaths before age five in 2024.",
         "between the malaria-attributable deaths of the PfPR-ACM model and the malaria deaths estimated by IHME, before age five in 2024.")],
    "source_comparison.latex.txt": [
        ("Counts and rates move in opposite directions after 2015 because under-five person-time in these countries grew by 12% between 2015 and 2024.",
         "For IHME and UN IGME, deaths rise but rates fall after 2015, because under-five person-time in these countries grew by 12\\% between 2015 and 2024.")],
    "age_band_results.latex.txt": [("the fixed HIV imputation and filled regional covariates", "the fixed HIV imputation and filled area-level covariates")],
}


def table_source(name, drop_comments):
    lines = (PAPER / "tables" / name).read_text(encoding="utf-8").splitlines()
    out = "\n".join(l for l in lines if not (drop_comments and l.startswith("%")))
    for a, b in TABLE_FIXES.get(name, []):
        assert out.count(a) == 1, (name, a[:60]); out = out.replace(a, b)
    return out


def block(start, end):
    """The exact text from the first line starting with `start` to the end of the following line equal to `end`."""
    i = original.find(start)
    if i < 0:
        return "\x00 not in main.tex: " + start   # never matches, so the change is skipped as already done
    j = original.index(end, i) + len(end)
    return original[i:j]


C = []   # (id, section, kind, old, new, reason); kind: "update" (approach/numbers), "fix" (error found), "optional"


def change(cid, section, kind, old, new, reason):
    C.append(dict(id=cid, section=section, kind=kind, old=old, new=new, reason=reason))


# ---------------------------------------------------------------- Abstract
change("A1", "Abstract", "update", r"(135 surveys, 37 countries)", r"(136 surveys, 37 countries)",
       "South Sudan MICS 2010 now enters (Sudan's national covariates before independence); 99 DHS + 37 MICS in 37 countries.")
change("A2", "Abstract", "update", r"in data from 2,329,388 children under 5 of whom 104,143 died",
       r"in data from 2,335,868 children under 5 of whom 105,114 died", "Snow primary sample (prepared_sample.csv).")
change("A3", "Abstract", "update",
       r"At 20\% prevalence, the model attributes 6\% of neonatal deaths, 32\% of deaths at 6-11 months and 43-54\% of deaths at 1-4 years to malaria.",
       r"At 20\% prevalence, the model attributes 4\% of neonatal deaths, 25\% of deaths at 6-11 months and 43-55\% of deaths at 1-4 years to malaria.",
       "Attributable fractions at PfPR 20% in the Snow primary: 4.4% (<1 month), 24.6% (6-11 months), 43.0-54.5% (12-59 months).")
change("A4", "Abstract", "update", r"we estimate that under-5 malaria mortality fell from 10.8 to 4.6 deaths per 1,000 child-years", r"we estimate that under-5 malaria mortality fell from 10.1 to 4.3 deaths per 1,000 child-years",
       "Pooled rates 10.12 (2000) and 4.33 (2015); the 57% decline is unchanged.")
change("A5", "Abstract", "update", r"and then to 3.5 deaths per 1,000 child-years in 2024", r"and then to 3.3 deaths per 1,000 child-years in 2024",
       "Pooled rate 3.31 in 2024; the further 24% decline is unchanged.")
change("A6", "Abstract", "update", r"were 47\% and 43\% higher than IHME and UN IGME estimate", r"were 37\% and 33\% higher than IHME and UN IGME estimate",
       "2024: 586,723 model deaths against 428,147 (IHME, x1.370) and 440,123 (UN IGME, x1.333).")

# ---------------------------------------------------------------- Results
change("R1", "Results, first paragraph", "update", r"across 41 countries, Figure \ref{fig:map}.",
       r"across 41 countries (Figure \ref{fig:survey_timing}).",
       "Figure 1 is now the map of complete birth histories; the survey map and timing moves to the supplement (new label fig:survey_timing).")
change("R2", "Results, first paragraph", "update",
       r"Each age band was then merged with the population-weighted \textit{Pf}PR$_{2-10}$ estimate from the Malaria Atlas Project (MAP) for the survey region (mostly first-level administrative units) in the calendar year the band started \cite{map2025}, along with a series of national or subnational estimates of identified confounding variables. The five surveys from Lesotho (four DHS, one MICS) were excluded because Lesotho is not a malaria endemic country.",
       r"Each age band was then located in one of the sub-national malaria-endemic areas defined by Snow et al.\ \cite{snow:17} (provinces, regions, states or districts, or unions of them where a survey reports only a coarser region; see Methods) and merged with the population-weighted \textit{Pf}PR$_{2-10}$ estimate from the Malaria Atlas Project (MAP) for that area in the calendar year the band started \cite{map2025}, along with a series of national or subnational estimates of identified confounding variables. The five surveys from Lesotho (four DHS, one MICS) were excluded because Lesotho is not a malaria endemic country, and the five surveys from the Comoros (two) and São Tomé and Príncipe (three) because the Snow et al.\ shapefile has no polygon for these islands.",
       "The unit of analysis is now the Snow et al. polygon (or a union of polygons), not the survey region; two more countries drop out for having no polygon.")
change("R3", "Results, second paragraph", "update",
       r"Restricting the analysis to survey regions and years with all 17 confounding variables measured, a total of 135 surveys (98 DHS, 37 MICS) in 37 countries were included in the primary analysis representing the complete birth histories of 1,125,549 mothers (Figure \ref{fig:flow}); all five MIS surveys, 17 DHS surveys and 9 MICS surveys were excluded because of missing data on identified confounders. The included surveys contributed 7,621,617 child age band records from a total of 2,329,388 children with 104,143 deaths recorded.",
       r"Restricting the analysis to areas and years with all 17 confounding variables measured, a total of 136 surveys (99 DHS, 37 MICS) in 37 countries were included in the primary analysis, representing the complete birth histories of 1,125,610 mothers (Figures \ref{fig:map} and \ref{fig:flow}); all five MIS surveys, 14 DHS surveys and 6 MICS surveys were excluded because of missing data on identified confounders. The included surveys contributed 7,639,443 child age band records from a total of 2,335,868 children with 105,114 deaths recorded, in 1,452 survey-by-area units.",
       "Snow primary sample. 171 = 136 included + 25 excluded for covariates + 10 without a malaria-endemic polygon (Lesotho, the Comoros, São Tomé and Príncipe). The neonatal (37%), first-year (66%) and second-year (13%) shares are unchanged.")
change("R4", "Figure 1 caption", "update",
       r"\caption{Complete birth histories included in the primary analysis by administrative unit based on \cite{snow:17}.}",
       r"\caption{Complete birth histories included in the primary analysis, by sub-national malaria-endemic polygon of Snow et al.\ \cite{snow:17}. Colours show the number of mothers with at least one child age-band record in the analysis: in total 1,125,610 mothers from 136 surveys (99 DHS, 37 MICS; interviews 2003–2025) in 37 countries, contributing 7,639,443 child age-band records and 105,114 deaths. Records were placed in the polygon holding at least 90\% of the population of their reported area, and otherwise in the union of the malaria-endemic polygons each holding at least 5\%. In 215 of the 1,452 survey-by-area units this gives a union of polygons; the 161,042 mothers (14\%) in these unions are divided among their polygons by population share. The 465 polygons with data hold a median of 1,715 mothers (range 76–49,763). Light grey: the 55 malaria-endemic polygons without data, mostly in countries with no included survey (Botswana, Djibouti, Equatorial Guinea, Eritrea, Somalia and Sudan). Warm grey: malaria-free and island polygons, not analysed. Pale: outside the study area or without a polygon (for example the Comoros and Zanzibar). Blue: lakes and reservoirs of at least 300~km$^2$ (Natural Earth). Africa Albers equal-area projection. Survey years and exclusions by country are shown in Figure \ref{fig:survey_timing}.}",
       "Full caption, condensed from the generated caption (paper/figures/fig1_analysis_units_map_caption.md).")
change("R5", "Results, model paragraph", "update", r"adjusted for a set of 17 survey-region and national covariates",
       r"adjusted for a set of 17 area-level and national covariates", "Area-level (survey x Snow unit) covariates replace survey-region ones.")
change("R6", "Results, model paragraph", "fix", r"varied substantially across age groups (Figure \ref{fig:main_result}).",
       r"varied substantially across age groups (Figure \ref{fig:main_result}; Table \ref{tab:primary-age-band-effects}).",
       "Table S1 is never cited in the text.")
change("R7", "Results, attributable fractions", "update",
       r"Under this model, for an average \textit{Pf}PR$_{2-10}$ of 10\%, approximately 30\% of all deaths in children 1 year and older are caused by malaria, compared with less than 5\% in neonates (\ref{fig:main_result2}). For an average \textit{Pf}PR$_{2-10}$ of 40\% (upper end of prevalence estimates in sub-Saharan Africa now), there is a sharper age-dependent increase in malaria deaths with more than half of all deaths between 12 and 59 months attributable to malaria, peaking at $\sim$60\% between 24–35 months.",
       r"Under this model, for an average \textit{Pf}PR$_{2-10}$ of 10\%, approximately 30\% of all deaths in children 1 year and older are caused by malaria (28–37\% across the four yearly bands), compared with less than 5\% in neonates (Figure \ref{fig:main_result2}). For an average \textit{Pf}PR$_{2-10}$ of 40\% (upper end of prevalence estimates in sub-Saharan Africa now), there is a sharper age-dependent increase in malaria deaths, with around half of all deaths between 12 and 59 months attributable to malaria (47–59\%), peaking at 59\% between 24–35 months.",
       "At 10%: 30.8, 37.2, 27.8, 29.0% (12-59 months), 1.9% (neonates). At 40%: 53.1, 59.3, 49.5, 47.3%, so 'more than half' no longer holds at 36-59 months. Also adds the missing 'Figure' before the reference.")
change("R8", "Results, sensitivity paragraph", "update",
       block(r"We conducted a series of sensitivity analyses in subgroups", r"(Figure \ref{fig:without_malnutrition})."),
       r"We conducted a series of sensitivity analyses in subsets of the primary analysis dataset (see Methods): survey regions in the Sahel only (31 surveys in 8 countries), where transmission is highly seasonal; each UN sub-region of Africa except Southern Africa, namely Western Africa (61 surveys in 15 countries), Middle (Central) Africa (18 surveys in 7 countries) and Eastern Africa (50 surveys in 12 countries), Southern Africa (7 surveys in 3 countries) not being refitted because its \textit{Pf}PR$_{2-10}$ never exceeds 10.3\%; surveys conducted up to (74 surveys) or after (62 surveys) the median survey year, 2014; and child age bands entered up to or after the median calendar date of entry (late 2012). In general the subset fits gave similar results (Figures \ref{fig:subgroups}–\ref{fig:subgroups_period}). The exceptions were the Sahel, where mortality rose more steeply between prevalences of 20\% and 40\% for children between 6 and 59 months; Eastern Africa, where the relationship was flat in neonates and differed in shape at older ages; and Central Africa, where 97.5\% of records had a prevalence above 4\%, mortality did not increase between prevalences of 20\% and 40\% after the first month, and the curves were flatter than in the primary analysis at 24–59 months. In the unadjusted data (Figure \ref{fig:survival_by_region}), most of Central Africa's records at low prevalence come from Chad (58\% of its records at 24–59 months with a prevalence below 10\%), where survival at these ages (99.1\%) is lower than at similar prevalence elsewhere (99.6\%). A sensitivity analysis using multiple imputation for the missing covariates, retaining all 161 surveys with a Snow et al.\ area, in 38 countries (8,630,306 child age-band records and 122,092 deaths), gave very similar results to the primary analysis restricted to complete cases (Figure \ref{fig:MI}). Because acute or chronic malnutrition may mediate the relationship between malaria transmission and death as well as confound it, we refitted the models on the same sample without adjusting for wasting and stunting; the estimated prevalence-mortality relationship was very similar (hazard ratios changed by at most 0.04; Figure \ref{fig:without_malnutrition}).",
       "The sensitivity suite now has UN M49 sub-regions (West, Central, East; Southern not refitted) and two period splits (survey year, record year). Counts from the subgroup and imputation results. The Sahel is steeper only between 20% and 40% (40->20% hazard ratios 0.71-0.79 against 0.84-0.94 at 6-59 months; below 20% it is flatter at 12-47 months), and Eastern Africa's departures change direction with the prevalence range, so it is described in general terms. Without nutrition covariates, the largest change is 0.010 (40->20%) and 0.036 (20->0%, 1-5 months), hence 'very similar' rather than 'essentially unchanged'. The Central Africa sentence on Chad cites the new raw-data figure (results/cbh/subgroups_snow520_merge_gamma2_v5/central_africa_low_prevalence.csv: Chad 32,860 of 56,959 records, survival 99.13%; other sub-regions 99.63%).")
change("R9", "Results, burden paragraph", "update",
       r"fell from 10.8 to 4.6 deaths per 1,000 child-years between 2000 and 2015 (a 57\% decline) and to 3.5 in 2024",
       r"fell from 10.1 to 4.3 deaths per 1,000 child-years between 2000 and 2015 (a 57\% decline) and to 3.3 in 2024",
       "Pooled rates 10.12, 4.33 and 3.31; declines 57.2% and 23.7%.")
change("R10", "Results, burden paragraph", "update",
       r"estimates approximately 629,000 under-5 malaria deaths in these countries, 47\% more than IHME (428,000) and 43\% more than UN IGME (440,000).",
       r"estimates approximately 587,000 under-5 malaria deaths in these countries, 37\% more than IHME (428,000) and 33\% more than UN IGME (440,000).",
       "2024: 586,723 deaths.")
change("R11", "Results, country comparison", "update",
       r"exceeded IHME in 36 of the 42 countries (median ratio 1.6)", r"exceeded IHME in 34 of the 42 countries (median ratio 1.5)",
       "country_agreement_2024.csv: 34 of 42, median ratio 1.499; Spearman 0.911 (unchanged at 0.91).")
change("R12", "Results, Nigeria", "update", r"whereas our approach estimates 221 thousand deaths (60\% and 34\% higher, respectively).",
       r"whereas our approach estimates 207 thousand deaths (50\% and 25\% higher, respectively).",
       "Nigeria 206,863 against 138,111 (x1.498) and 165,329 (x1.251).")
change("R13", "Results, Chad", "update", r"In Chad we estimate a 4.1-fold higher total burden than IHME and 1.4-fold higher than UN IGME.",
       r"In Chad we estimate a 3.8-fold higher total burden than IHME and 1.3-fold higher than UN IGME.",
       "Chad 18,646 against 4,884 (x3.82) and 14,345 (x1.30).")
change("R14", "Results, Nigerian states", "update",
       r"greater than IHME's estimates in 36 of the 37 states (Figure \ref{fig:IHME_v_model}B). The differences are concentrated in the northern states: the median state ratio is 1.8 in the three northern zones and 1.3 in the three southern zones.",
       r"greater than IHME's estimates in 35 of the 37 states (Figure \ref{fig:IHME_v_model}B). The differences are concentrated in the northern states: the median state ratio is 1.7 in the three northern zones and 1.2 in the three southern zones. Expressed as the probability of dying before age 5 (Figure \ref{fig:cumulative_risk}), the model attributes a median of 12 deaths per 1,000 live births to malaria across the 42 countries in 2024 (a median 20\% of the all-cause probability), with the highest values in South Sudan (33 per 1,000), Sierra Leone (31) and the Central African Republic (31); this is a median 1.5 times the probability implied by IHME's cause-specific malaria death rates.",
       "States: 35 of 37, medians 1.66 and 1.18. The added sentence cites Figure 4, which the text never cites (under5_death_probability.csv, 2024: median 12.3 per 1,000, share 19.9%, ratio to IHME 1.50).")
change("R15", "Figure 3 caption", "fix", r"between the prevalence-ACM model and IHME and UN IGME", r"between the PfPR-ACM model and IHME and UN IGME",
       "Consistent model name.")
change("R16", "Table 1", "update", block(r"% Replacement table source; saved as plain text.", "\\end{table}"),
       table_source("country_comparison_2024.latex.txt", drop_comments=True),
       "Snow values (paper/tables/country_comparison_2024.latex.txt): the Central African Republic replaces DR Congo in the ten; total 586,723. The caption now says the ranking is by the difference from IHME.")
change("R17", "Table 2", "update", block("\\begin{table}[htbp]\n\\centering\n\\caption{Malaria mortality by source", "\\end{table}"),
       table_source("source_comparison.latex.txt", drop_comments=True),
       "Snow values (paper/tables/source_comparison.latex.txt): model deaths 1,111,970 / 687,031 / 586,723; rates 10.12 / 4.33 / 3.31; adds a footnote on the shared denominator and estimands.")

_t1 = table_source("country_comparison_2024.latex.txt", drop_comments=True)
_t2 = table_source("source_comparison.latex.txt", drop_comments=True)
change("R18", "Tables 1 and 2", "fix", _t1 + "\n\n\n" + _t2, _t2 + "\n\n\n" + _t1,
       "Table 2 (source comparison) is cited before Table 1 (L104 before L107); swapping the two environments numbers them in citation order. References use labels, so nothing else changes.")

# ---------------------------------------------------------------- Corrections to the author's edits (main.tex of 15 October)
change("E1", "Results, first paragraph", "fix",
       r"This gave a total of XXX eligible surveys (119 DHS, 5 MIS, 47 MICS) across XX countries",
       r"This gave a total of 166 eligible surveys (117 DHS, 5 MIS, 44 MICS) across 39 countries",
       "Placeholders filled for mainland sub-Saharan Africa and Madagascar: the registry's 171 surveys in 41 countries less the Comoros (1 DHS, 1 MICS) and São Tomé and Príncipe (1 DHS, 2 MICS); survey_map/survey_timeline_all.csv. Lesotho's five surveys are still in the 166, as the next sentences say.")
change("E2", "Figure 1 label", "fix",
       "    \\label{fig:survey_timing}\n\\end{figure}\n\nWe fitted separate models",
       "    \\label{fig:map}\n\\end{figure}\n\nWe fitted separate models",
       "The map was relabelled fig:survey_timing, so every \\ref{fig:map} (L78) is undefined and the survey-count sentence (L76) points at the map. Restores fig:map; fig:survey_timing is the label of the supplementary survey map and timing (S1).")
change("E3", "Results, attributable fractions", "fix",
       r"compared with less than 5\% in neonates (\ref{fig:main_result2})",
       r"compared with less than 5\% in neonates (Figure \ref{fig:main_result2})", "The word 'Figure' is missing before the reference.")
change("E4", "Results, sensitivity paragraph", "fix",
       r"Southern Africa was excluded because  \textit{Pf}PR$_{2-10}$ never exceeded 10\%)",
       r"Southern Africa was not refitted because its \textit{Pf}PR$_{2-10}$ never exceeds 10.3\%)",
       "Southern Africa's maximum PfPR is 10.33% (subregions_not_fitted.csv), so 'never exceeded 10%' is false; its records are in the primary analysis, it is only not refitted.")
change("E5", "Results, sensitivity paragraph", "update",
       r"The exceptions were the Sahel region, where mortality rose more steeply between prevalences of 20\% and 40\% for children between 6 and 59 months.",
       r"The exceptions were the Sahel region, where mortality rose more steeply between prevalences of 20\% and 40\% for children between 6 and 59 months, and Central Africa, where mortality did not increase between prevalences of 20\% and 40\% after the first month. In the unadjusted data (Figure \ref{fig:survival_by_region}), most of Central Africa's records at low prevalence come from Chad (58\% of its records at 24–59 months with a prevalence below 10\%), where survival at these ages (99.1\%) is lower than at similar prevalence elsewhere (99.6\%).",
       "Explains the flat Central Africa curves and cites the new raw-data figure (central_africa_low_prevalence.csv: Chad 32,860 of 56,959 records, survival 99.13%; other sub-regions 99.63%; Central Africa 40->20% hazard ratios 0.98-1.11 after the first month).")

# ---------------------------------------------------------------- Discussion
change("D1", "Discussion, progress", "fix",
       r"In comparison, our PfPR-ACM model estimates a larger 67\% decrease between 2000 and 2015 (slightly less than the RBM goal of 75\% reduction by 2015) and continued declines since 2015: a 24\% decrease between 2015 and 2024, against 8\% (IHME) and 6\% (UN IGME) (Table \ref{tab:source-comparison}).",
       r"In comparison, our PfPR-ACM model estimates a larger 67\% decrease between 2000 and 2024 (57\% by 2015, against 49\% for IHME and 60\% for UN IGME; the RBM goal was a 75\% reduction by 2015) and continued declines since 2015: a 24\% decrease between 2015 and 2024, against 8\% (IHME) and 6\% (UN IGME) (Table \ref{tab:source-comparison}).",
       "67% is the 2000-2024 decline; 2000-2015 is 57%, which is smaller than UN IGME's 60%, so 'larger' must refer to 2000-2024 (against 53% and 62% in the previous sentence).")
change("D2", "Discussion, indirect effects", "update",
       r"This indirect effect could amount to a third of all deaths caused by malaria if we take the difference between our estimates and IHME/UN IGME at face value.",
       r"This indirect effect could amount to around a quarter of all deaths caused by malaria if we take the difference between our estimates and IHME/UN IGME at face value.",
       "2024: 1 - 428,147/586,723 = 27% (IHME); 1 - 440,123/586,723 = 25% (UN IGME). 'A third' fitted v9 (629,136).")
change("D3", "Discussion, limitations", "update", r"Most of the variation in prevalence is across countries rather than within.",
       r"More than half of the variation in prevalence across child records (57\%) is between countries; the rest is within countries, between sub-national areas and over time.",
       "Computed on the Snow primary (records entering the first age band): 56.7% of the PfPR variance is between countries (v9: 59.0%); 93.5% is between survey x area units.")
change("D4", "Discussion, limitations", "fix", r"there is only a weak association between \textit{PfPR}$_{2-10}$ and neonatal deaths (one third of all deaths)",
       r"there is only a weak association between \textit{PfPR}$_{2-10}$ and neonatal deaths (37\% of all deaths)", "Neonatal share of deaths is 36.7%.")
change("D5", "Discussion, limitations", "optional",
       r"It would then follow that \textit{PfPR}$_{2-10}$ should predict all-cause death, reflecting both direct and indirect effects.",
       r"It would then follow that \textit{PfPR}$_{2-10}$ should predict all-cause death, reflecting both direct and indirect effects. Prevalence is that of the Snow et al.\ polygon containing most of the population of each record's reported location or, where that location spans several polygons (14\% of mothers), the population-weighted mean over them, which blurs local differences in transmission.",
       "Optional limitation on the new unit construction (Figure 1 caption: 161,042 of 1,125,610 mothers in unions).")

# ---------------------------------------------------------------- Methods
change("M1", "Methods, comment block", "optional", block("% missing in main.tex:", "where it lives in the analysis project.") + "\n",
       "% Still open after the Snow-unit update (15 October 2026):\n"
       "% SText 1 describes the archived negative-binomial model and must be rewritten for the binomial cloglog GAM;\n"
       "% Liberia's child HIV incidence from AIDSinfo counts is described only in the commented-out paragraph below;\n"
       "% the two different 2024 MAP rasters (national burden vs Snow areas) and the HIV incidence model details are not described;\n"
       "% Uganda Buganda and Sierra Leone 2013 fixes; licensing of third-party inputs (see docs/PAPER_CODE_FLAGS.md in the code repository).\n",
       "The old notes are partly fixed by these changes; replaced by the items still open (comments only, no change to the PDF).")
change("M2", "Methods, DHS covariates", "update",
       r"For DHS/MIS surveys, child, maternal and household characteristics comprised, from the Births Recodes, maternal age at first live birth, maternal education in completed years, household wealth quintile, urban or rural residence; and, from the published DHS survey-region indicator tables (DHS Program API), coverage of three doses of DTP-containing vaccine (DTP3) and of measles vaccination among children aged 12–23 months, the proportion of births delivered in a health facility, the proportion of non-first births with a preceding birth interval shorter than 24 months, household access to an improved drinking-water source, an improved sanitation facility and electricity, and the prevalence of wasting and stunting among children under five years (WHO Child Growth Standards). Where survey-region DTP3 or measles coverage was not published, the WHO/UNICEF national estimate (WUENIC) for the survey year was used.",
       r"For DHS/MIS surveys, child, maternal and household characteristics were computed from the survey recodes using the DHS indicator definitions: from the Births Recodes, maternal age at first live birth, maternal education in completed years, household wealth quintile, urban or rural residence, coverage of three doses of DTP-containing vaccine (DTP3) and of measles vaccination among living children aged 12–23 months, the proportion of births in the five years before interview delivered in a health facility, and the proportion of non-first births with a preceding birth interval shorter than 24 months; and, from the Household Member Recodes, household access to an improved drinking-water source, an improved sanitation facility and electricity, and the prevalence of wasting and stunting among children under five years (WHO Child Growth Standards; from the Height and Weight Recodes for surveys whose Household Member Recodes predate the standards). Aggregated to the national level, the eight indicators with published DHS national values reproduced them to within 2 percentage points in 930 of 933 survey–indicator pairs, and in all 790 pairs of the included surveys. Where DTP3 or measles coverage could not be computed for an area, the WHO/UNICEF national estimate (WUENIC) for the survey year was used.",
       "All 13 area-level covariates are now computed from the recodes for each survey x Snow area; the published survey-region indicator tables no longer fit the units. National validation: dhs_national_validation.csv.")
change("M3", "Methods, MICS", "update",
       r"analysis regions were unions of DHS boundary polygons for the same country where these exist, and admin-1 polygons otherwise (for example, Guinea-Bissau and the Central African Republic). MICS does not publish survey-region indicator tables, so all 13 regional covariates were computed from the MICS microdata using the DHS definitions;",
       r"the region boundaries were unions of DHS boundary polygons for the same country where these exist, and admin-1 polygons otherwise (for example, Guinea-Bissau and the Central African Republic), and were used to locate MICS records in the Snow et al.\ areas as for DHS. As for DHS, all 13 area-level covariates were computed from the MICS microdata using the DHS definitions;",
       "MICS regions are now only a step to place records in Snow areas.")
change("M4", "Methods, prevalence", "update",
       r"Survey-region values were means of each annual surface over the region's boundary polygons, weighted by the Gridded Population of the World version 4 (GPWv4) 2020 population density \cite{gpwv4}.",
       r"Values for each Snow et al.\ area (below) were means of each annual surface over the area's polygon, weighted by the Gridded Population of the World version 4 (GPWv4) 2020 population density and grid-cell area \cite{gpwv4}; for a union of polygons, the population-weighted mean over its polygons was used." + "\n\n" +
       r"\textit{Geographic units.} Records were located in the 520 malaria-endemic sub-national polygons used by Snow et al.\ to summarise \textit{P.\ falciparum} prevalence in sub-Saharan Africa \cite{snow:17}. Each record was located by the smallest administrative unit reported in its survey: the survey region, or, where a survey region spans several polygons, a finer location variable recorded in the survey file (for example state, province or district), matched to the polygons by boundary geometry, name or a reviewed alias. A record's unit was the polygon holding at least 90\% of the 2020 GPWv4 population of that location; otherwise it was the union of the polygons each holding at least 5\% of that population. Records in locations more than half of whose population lay in polygons classified as malaria free or as islands were excluded, as were records from the Comoros, São Tomé and Príncipe and Zanzibar, which have no endemic polygon. Of the 1,452 survey-by-area units in the primary analysis, 215 are unions of polygons (median 2, maximum 9 polygons), and the units of one survey can overlap; these unions hold 14\% of the mothers (Figure \ref{fig:map}). Rwanda has a single endemic polygon in the shapefile, so each Rwandan survey forms one unit. Figure \ref{fig:boundary_agreement} compares the survey regions with the Snow et al.\ polygons.",
       "Exposure now uses density x cell-area weights over Snow polygons. The new paragraph describes the unit construction (merge rule); the last sentence cites the optional boundary-agreement figure (drop it with that figure).")
change("M5", "Methods, exposure assignment", "update", r"based on the mother's survey region of residence", r"based on the area of the mother's residence", "Snow units.")
change("M6", "Methods, covariates", "update",
       r"Adjustment included 17 covariates: 13 survey-region level summaries and 4 national level measures. Survey-region level covariates were (means or percentages):",
       r"Adjustment included 17 covariates: 13 area-level summaries (computed for each survey and area) and 4 national level measures. Area-level covariates were (means or percentages):", "Snow units.")
change("M7", "Methods, covariates", "update", r"We note that regional summaries describe conditions at the time of the survey",
       r"We note that area-level summaries describe conditions at the time of the survey", "Snow units.")
change("M8", "Methods, survey weights", "update",
       r"DHS recode-derived regional summaries used DHS women's sampling weights, and published DHS regional indicators retained their stated denominators and reference periods. MICS regional summaries were computed from the microdata with the MICS women's, household and children's sampling weights. Regional summaries were calculated before complete-case selection, excluding missing individual responses from each variable's denominator.",
       r"DHS summaries used the DHS women's sampling weights for Births Recode items and the household weights for Household Member and Height and Weight Recode items. MICS summaries were computed from the microdata with the MICS women's, household and children's sampling weights. Area-level summaries were calculated before complete-case selection; for DHS surveys they follow the DHS tabulation rules, with items not asked left out of the denominator and answers recorded as missing or don't know counted as `no'.",
       "No published indicators are used any more; PR/HW items use the household weight (hv005). The old clause 'excluding missing individual responses from each variable's denominator' contradicts the DHS rule in the code (R_cbh/snow/R/label_rules.R: 'missing' and don't know count as 'no'; only items not asked are out of the denominator); MICS items are handled item by item, so the rule is stated for DHS only.")
change("M9", "Methods, fallbacks and South Sudan", "update",
       r"Missing regional DTP3 and measles coverage was replaced by the corresponding national UNICEF estimate for the survey year (\url{https://immunizationdata.who.int/}). Remaining missing regional covariates were replaced by the arithmetic mean of available regional values within the same survey.",
       r"Missing area-level DTP3 and measles coverage was replaced by the corresponding national UNICEF estimate for the survey year (\url{https://immunizationdata.who.int/}). Remaining missing area-level covariates were replaced by the mean of the available values for the survey's other areas, weighted by the number of records in each area. South Sudan became independent from Sudan in July 2011; for band-entry years before 2011, its GDP per capita, health expenditure per capita and political stability were taken from Sudan's series for the same year, which admits the 2010 South Sudan MICS (57,509 child age-band records and 955 deaths, band-entry years 2005–2010). South Sudan's own child HIV incidence series was used throughout.",
       "Record-weighted within-survey mean (merge rule); the South Sudan rule (author decision, 12 October; national_substitutions.csv). Optional extra: 'South Sudan's own GDP estimates for 2008-2010 (23,669 records) were also replaced, so that the three series come from the same country.'")
change("M9b", "Methods, fallbacks", "optional", r"São Tomé and Príncipe had no data and were excluded.",
       r"São Tomé and Príncipe has no child HIV incidence series; its surveys are excluded in any case, as it has no Snow et al.\ polygon.",
       "The exclusion now has a second reason (no polygon).")
change("M10", "Methods, likelihood", "fix",
       r"Because the exposure and all covariates are defined at the survey-region and calendar-year level, the model likelihood is binomial for the number of deaths among children entering each age band in each survey-region and entry month.",
       r"Models were fitted to the child age-band records; because the exposure and all covariates are defined at the area and calendar-year level, this is equivalent to a binomial likelihood for the number of deaths among children entering each age band in each survey-by-area unit and entry month.",
       "Snow units; and the fits use record-level (Bernoulli) data, which the current wording does not say.")
change("M11", "Methods, model", "update",
       r"a penalised cubic regression spline of survey-region \textit{Pf}PR$_{2-10}$ at time of band entry (basis dimension 5)",
       r"a penalised cubic regression spline of area \textit{Pf}PR$_{2-10}$ at time of band entry (basis dimension 5, with knots fixed at those of an earlier survey-region fit, \textit{Pf}PR$_{2-10}$ 0.02–94.8\%)",
       "Frozen reference knots (R_cbh/primary/reference_knots.csv: 0.0165-94.76).")
change("M12", "Methods, model", "update", r"and independent Gaussian random intercepts for survey, country and survey-region.",
       r"and independent Gaussian random intercepts for survey, country and survey-by-area unit. Fewer than 200 records per age band (under 0.02\%) had a prevalence outside the knots, where the spline extrapolates linearly.",
       "Random effect on survey x Snow unit. Records outside the knots: at most 194 per band (upper bound from the imputed sample).")
change("M13", "Methods, burden", "fix", r"Estimates were produced annually for 2004-2024", r"Estimates were produced annually for 2000–2024",
       "The series is 2000-2024 (Table 2, Figure 3C).")
change("M13b", "Methods, burden (Figure 4)", "fix",
       r"with the state sum reconciled against the national estimate.",
       r"with the state sum reconciled against the national estimate. For Figure \ref{fig:cumulative_risk}, the probability of dying before age 5 was calculated as a period life-table (synthetic cohort) probability, ${}_5q_0 = 1 - \exp(-\sum_g H_g)$, with each band's cumulative hazard $H_g$ from the IHME all-cause death rates; the probability caused by malaria is ${}_5q_0$ minus the probability with each band's hazard multiplied by the hazard ratio for \textit{Pf}PR$_{2-10}$ = 0 versus the country's current prevalence, and the IHME equivalent is ${}_5q_0$ minus the probability with IHME's malaria death rates removed.",
       "Figure 4's method is not described anywhere in the text (flag A9); taken from the generated Figure 4 caption.")
change("M14", "Methods, sensitivity overview", "update",
       r"We carried out a suite of sensitivity analyses to look at how changes in the paramerisation of the models, or if subsetting the data (seasonal versus non seasonal, West Africa vs East Africa, earlier vs later surveys) changed the estimated relationship between prevalence and age specific all-cause mortality.",
       r"We carried out a suite of sensitivity analyses to assess whether restricting the data by seasonality of transmission, geographic sub-region or period, removing the nutrition covariates, or imputing missing covariates changed the estimated relationship between prevalence and age-specific all-cause mortality.",
       "Matches the analyses actually run; fixes 'paramerisation'.")
change("M15", "Methods, sensitivity analyses", "update",
       block(r"We refitted the 7 age-band models in four subsets", r"pooling with Rubin's rules."),
       r"We refitted the 7 age-band models in subsets of the primary sample: Sahelian survey regions (boundary centroid at or north of 12°N and west of 36°E, excluding the Horn of Africa; 31 surveys in 8 countries with 18,768 deaths recorded); each UN M49 sub-region of Africa except Southern Africa, namely Western Africa (61 surveys in 15 countries, 54,881 deaths), Middle (Central) Africa (18 surveys in 7 countries, 17,314 deaths) and Eastern Africa (50 surveys in 12 countries, 31,858 deaths), while Southern Africa (7 surveys in Namibia, Eswatini and South Africa, 1,061 deaths) was not refitted because its \textit{Pf}PR$_{2-10}$ never exceeds 10.3\%; surveys conducted up to and including, versus after, the median survey year of 2014 (74 and 62 surveys, respectively); and child age bands entered up to and including, versus after, the median calendar year of entry (2012.8; 3,858,211 and 3,781,232 records). Subset fits used the same specification with knots at quantiles of the subset's own predictor values. In a second sensitivity analysis we imputed every remaining covariate gap rather than excluding records: whole-survey gaps in area-level indicators by chained-equation multiple imputation (predictive mean matching, 10 imputations), the missing 2001 political-stability round by interpolation, and health expenditure for Zimbabwe 2000–2009, Somalia 2000–2012 and all countries in 2024 from a generalised additive model on the observed panel, with draws. As in the primary analysis, South Sudan's GDP per capita, health expenditure per capita and political stability before 2011 were Sudan's values, held fixed. Child HIV incidence came from the extended incidence model (with a latent adolescent series for countries without one), with one posterior draw of each imputed or censored value per imputed dataset. This retained all 8,630,306 records with a Snow et al.\ area (161 surveys in 38 countries with 122,092 deaths); imputation uncertainty was propagated by refitting each of the ten imputed datasets with the smoothing parameters fixed at those of the point fit, and pooling with Rubin's rules.",
       "Snow subgroup suite and imputation sample. The old HIV clause ('Liberia and São Tomé ... latent adolescent series') was wrong: Liberia's rate comes from AIDSinfo counts and is fixed, and São Tomé has no Snow area.")
change("M16", "Data sharing", "update",
       r"All input data are publicly available via the GBD client portal and the DHS website.",
       r"All input data are publicly available: DHS and MIS microdata from the DHS Program and MICS microdata from UNICEF (both after registration), MAP \textit{Pf}PR$_{2-10}$ surfaces, GPWv4 population, the Snow et al.\ sub-national polygons (published with the original article \cite{snow:17}), DHS survey-region boundaries from the DHS Spatial Data Repository, national boundaries from GADM, IHME estimates via the GBD client portal, UN IGME and CA-CODE estimates via the UN IGME portal, WHO/UNICEF immunisation coverage estimates, UNAIDS/UNICEF HIV estimates and World Bank indicators. Lake and reservoir outlines in Figure \ref{fig:map} are from Natural Earth (\url{https://www.naturalearthdata.com/}; public domain) and are used for display only.",
       "Lists every input (and the registration requirement); the repository URL that follows is already correct.")

# ---------------------------------------------------------------- Supplementary
SURVEY_FIG = r"""\begin{figure}[htbp]\centering
\includegraphics[width=\linewidth]{Supplementary Figures/sfig_survey_map_and_timing.png}
\caption{DHS/MIS (circles) and MICS (triangles) surveys with complete birth histories conducted in sub-Saharan Africa since 2000: 124 DHS and MIS surveys and 47 MICS surveys in 41 countries. Filled symbols are the 136 surveys (99 DHS, 37 MICS) in 37 countries included in the primary analysis. Open symbols are the 35 excluded surveys: the five surveys from Lesotho (malaria free); the five from the Comoros (two) and São Tomé and Príncipe (three), which have no Snow et al.\ malaria-endemic polygon; and 25 surveys (14 DHS, all five MIS and 6 MICS) in which a required covariate was unavailable in every survey-by-area unit. Countries are grouped by UN sub-region (Central Africa: UN Middle Africa), and map shading shows the number of included surveys in each country. $n$ is the number of mothers (complete birth histories) contributing at least one child to the primary analysis (1,125,610 in total). Survey year is the year of fieldwork. The 46 MICS surveys without a complete birth history are not shown. DRC: Democratic Republic of the Congo; RC: Republic of the Congo; CAF: Central African Republic.}
\label{fig:survey_timing}
\end{figure}

"""
change("S1", "Supplementary: survey map and timing (old Figure 1) and boundary agreement", "update",
       "\\begin{figure}[htbp]\\centering\n\\includegraphics[width=\\linewidth]{Supplementary Figures/sfig_study_flow.png}",
       SURVEY_FIG + "\\begin{figure}[htbp]\\centering\n\\includegraphics[width=\\linewidth]{Supplementary Figures/sfig_study_flow.png}",
       "The old Figure 1 becomes the first supplementary figure (it is cited first).")
change("S2", "Supplementary: study flow caption", "fix",
       r"\caption{Data sources and analysis flow. External non-DHS data include MAP (population-weighted with a gridded population surface), WHO/UNICEF vaccine coverage, child HIV prevalence (UNAIDS 0-14 case counts divided by the World Bank population estimates) and World Bank economic series for GDP and health expenditure.}",
       r"\caption{Sample inclusion for the primary analysis. Counts below the survey registry are child age-band records, not children. Records were placed in the Snow et al.\ malaria-endemic polygons through their smallest reported administrative unit (see Methods). External data are MAP \textit{Pf}PR$_{2-10}$ (population-weighted over each unit), WHO/UNICEF vaccine coverage estimates, UNAIDS child HIV incidence (new infections per 1,000 uninfected children aged 0–14 years) and World Bank GDP per capita, health expenditure per capita and political stability. For South Sudan, Sudan's values of the last three were used for band-entry years before 2011 (57,509 records).}",
       "The current caption describes child HIV prevalence; the model uses incidence. Adds the Snow placement and the South Sudan rule.")
change("S3", "Supplementary: PfPR by age caption", "fix",
       r"\caption{Malaria prevalence and all-cause age band specific child mortality. The y-axis shows the log hazard ration relative for the age-specific mortality relative to a prevalence of 20\%. Mean values (95\% confidence intervals) are shown by the blue lines (shaded areas).}",
       r"\caption{Malaria prevalence and all-cause age-specific child mortality. Curves show the log hazard ratio of mortality in each age band relative to a prevalence of 20\%, from the seven age-band models of the primary analysis; lines are point estimates and shaded areas 95\% confidence intervals, drawn over the central 95\% of each band's exposure distribution.}",
       "Typo ('ration'), and states the reference and the plotted range.")
change("S4", "Supplementary: subgroup figures", "update",
       block("\\begin{figure}\n    \\centering\n    \\includegraphics[width=0.95\\linewidth]{Supplementary Figures/sfig_pfpr_splines_by_subgroup.png}", "\\label{fig:subgroups}\n\\end{figure}"),
       r"""\begin{figure}
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
\end{figure}""",
       "The Snow suite has three figures: the Sahel (this file now shows the Sahel only), UN sub-regions and periods. Captions condensed from the caption files.")
SURVIVAL_FIG = r"""

\begin{figure}
    \centering
    \includegraphics[width=0.95\linewidth]{Supplementary Figures/sfig_survival_vs_pfpr_by_subregion.png}
    \caption{Survival through each age band against \textit{Pf}PR$_{2-10}$ in the primary analysis sample, by UN sub-region. Each open circle is one survey $\times$ area unit $\times$ band-entry year, with area proportional to the number of children entering the band. Lines are unadjusted spline fits for each sub-region (binomial generalised additive model with a complementary log-log link and a penalised cubic regression spline of \textit{Pf}PR$_{2-10}$, basis dimension 5, no covariates), drawn over the central 95\% of the sub-region's exposure, with 95\% intervals shaded. Southern Africa, whose prevalence spans 0–10\%, is shown as points only. All panels share the same y-axis; points below 93\% (0.6\% of children) are drawn at the lower edge as open triangles. The fits are descriptive: unlike the age-band models, they are not adjusted for confounders, calendar time or survey and area effects.}
    \label{fig:survival_by_region}
\end{figure}"""
change("S4b", "Supplementary: raw survival by sub-region (new)", "update",
       "\\label{fig:subgroups_period}\n\\end{figure}", "\\label{fig:subgroups_period}\n\\end{figure}" + SURVIVAL_FIG,
       "New supplementary figure (user request, 15 October 2026): the raw data behind the sub-region refits, with unadjusted spline fits; caption condensed from CAPTION_sfig_survival_vs_pfpr_by_subregion.md.")
change("S5", "Supplementary: imputation caption", "update", r"\caption{Results from multiply imputed datasets.}",
       r"\caption{Sensitivity analysis: imputed covariates. Log mortality hazard ratios relative to \textit{Pf}PR$_{2-10}$ = 20\% by age band, from the complete-case primary analysis (7,639,443 records, 136 surveys) and from all records with a Snow et al.\ area after imputing every remaining covariate gap (8,630,306 records, 161 surveys in 38 countries; see Methods). Shaded areas are 95\% confidence intervals; curves are drawn over the central 95\% of each sample's exposure. Pooling ten imputed datasets with Rubin's rules changed the 40\%-to-20\% hazard ratios by at most 0.001.}",
       "Condensed from sfig_pfpr_splines_imputed_covariates_caption.md.")
change("S6", "Supplementary: no-nutrition caption", "update",
       r"\caption{Results when removing malnutrition indicators from the list of covariates included for adjustment.}",
       r"\caption{Sensitivity analysis: without the nutrition covariates. Log mortality hazard ratios relative to \textit{Pf}PR$_{2-10}$ = 20\% by age band, from the primary analysis (17 covariates) and from a refit on the same records without area-level wasting and stunting (15 covariates). Shaded areas are 95\% confidence intervals. The largest change in the hazard ratio for a reduction in prevalence from 40\% to 20\% is 0.010, and for 20\% to 0\% 0.036 (both at 1–5 months).}",
       "Condensed from sfig_pfpr_splines_without_nutrition_caption.md.")
change("S7", "Supplementary: malaria share caption", "optional",
       r"for 42 sub-Saharan African countries.}",
       r"for 42 sub-Saharan African countries. The PfPR-ACM model share is attributable (deaths that would not occur at zero prevalence, including deaths caused indirectly by malaria); the IHME and UN IGME (CA-CODE) shares count deaths assigned to malaria as the cause.}",
       "Optional: states the difference in estimands shown in the figure.")
BOUNDARY_FIG = r"""

\begin{figure}[htbp]\centering
\includegraphics[width=\linewidth]{Supplementary Figures/sfig_snow_boundary_agreement_map.png}
\caption{Survey regions of the DHS and MICS files against the Snow et al.\ polygons \cite{snow:17}, for the most recent included survey in each country and the Comoros MICS 2022, which is not analysed. Survey regions are classified by GPW 2020 population: same area (at least 90\% of the region's population lies in one Snow et al.\ polygon, which in turn has at least 90\% of its population in the region); region inside a larger polygon; polygons nested in the region (the region spans several polygons, each lying within it); and boundaries crossing. Regions lying mostly in malaria-free or island polygons, and regions with no Snow et al.\ polygon (the Comoros and Zanzibar), are shown separately; white areas are regions of a mapped survey that are not in the analysis sample. White lines: survey-region boundaries; thin dark lines: Snow et al.\ polygon boundaries; black lines: national borders. Countries without an included survey are light grey.}
\label{fig:boundary_agreement}
\end{figure}"""
change("S9", "Supplementary: boundary agreement (optional)", "optional", r"\label{fig:malaria_share_pfpr}" + "\n" + r"\end{figure}",
       r"\label{fig:malaria_share_pfpr}" + "\n" + r"\end{figure}" + BOUNDARY_FIG,
       "Optional new figure documenting how survey regions map to the Snow et al. polygons; placed last because it is first cited in Methods (drop it together with the last sentence of the geographic-units paragraph, M4).")
change("S8", "Table S1", "fix", block("\\begin{table}[tbp]\n\\centering\n\\caption{Age-specific associations", "\\end{table}"),
       table_source("age_band_results.latex.txt", drop_comments=True),
       "The current Table S1 shows the old DHS-only values (5,465,305 records, 75,726 deaths); replaced by the Snow primary table (7,639,443 records, 105,114 deaths).")

# ---------------------------------------------------------------- apply
def line_of(s, sub):
    return s[: s.index(sub)].count("\n") + 1

norm = lambda t: " ".join(t.split())
applied, skipped = [], []
for c in C:
    n = text.count(c["old"])
    if n == 0:
        c["status"] = "already in main.tex" if c["new"].strip() and norm(c["new"]) in norm(text) else "superseded by the author's edit"
        skipped.append(c); continue
    if n != 1:
        sys.exit(f"{c['id']}: expected one match, found {n}: {c['old'][:80]!r}")
    c["line"] = line_of(original, c["old"]) if original.count(c["old"]) == 1 else None
    text = text.replace(c["old"], c["new"], 1)
    applied.append(c)
assert text.count(r"\cite{snow2017}") == 0
OUT.mkdir(parents=True, exist_ok=True)
(OUT / "main_proposed.tex").write_text(text, encoding="utf-8")

# ---------------------------------------------------------------- change list
def show(s, limit=None):
    s = s.strip()
    return s if limit is None or len(s) <= limit else s[:limit].rsplit(" ", 1)[0] + " …"

kinds = {"update": "updated approach or numbers", "fix": "error in the current text", "optional": "optional"}
md = ["# Proposed changes to main.tex (Snow-unit primary)", "",
      "Generated on 15 October 2026 by a script that applies each change to a copy of the Overleaf `main.tex` (saved 15 October 2026, 18:05). The script checks that every change matches the current text exactly once. `main.tex` itself is not edited.",
      "- **Already applied:** the changes you have already made, or replaced by your own wording, are listed at the end. Corrections to your edits are E1–E5.",
      "- **Full proposed manuscript:** `docs/manuscript/main_proposed.tex`.",
      "- **Numbers:** from the verified run of 13 October 2026 (commit 3e2c721). Sources for each number are in `docs/PAPER_TEXT_SNOW.md`.",
      "- **Line numbers:** those of the current `main.tex`.", "",
      "Kinds of change:",
      "- **update:** follows from the updated approach (Snow et al. units, Figure 1, South Sudan, sensitivity suite).",
      "- **fix:** an error in the current text, found in this review.",
      "- **optional:** a suggestion.", "",
      "## Summary", "", "| ID | Line | Section | Kind | Why |", "|---|---:|---|---|---|"]
for c in applied:
    md.append(f"| {c['id']} | {c['line'] or '–'} | {c['section']} | {c['kind']} | {c['reason']} |")
md += ["", "## Already done in main.tex (not repeated)", "", "| ID | Section | Status |", "|---|---|---|"]
for c in skipped:
    md.append(f"| {c['id']} | {c['section']} | {c['status']} |")
md += ["", "## Not changed here", "",
       "- **SText 1** (`SText1_model_specification.tex`, cited at L287) still describes the archived negative-binomial model. It needs rewriting from `results/cbh/primary_snow520_merge_dhsmics_gamma2_v11/model_formula.txt`. I can draft it as a separate proposed file.",
       "- **Liberia's child HIV incidence.** The commented-out paragraph at L273 describes how it is derived from UNAIDS AIDSinfo counts, and is accurate. Uncommenting it would document flag A1.",
       "- **L65:** still has a `[REF]` placeholder.",
       "- **Table generators in the code repository.** The tables pasted here carry three corrections that their generators still lack, so the `paper/tables/` files differ from the text here until the generators are fixed and the primary stage is rerun:",
       "  - the Table 2 footnote's `12%` is not escaped, so LaTeX drops the rest of the line;",
       "  - the Table 2 footnote's 'counts and rates move in opposite directions' is false for the model column;",
       "  - the Table 1 caption calls IHME's cause-specific deaths 'malaria-attributable', and the Table S1 footnote says 'regional covariates'.",
       "- **Bibliography:** `ref.bib` now has entries for `mics`, `wdi` and `wgi` (added 15 October); the BibTeX below is kept for reference.", "",
       "```bibtex",
       "@misc{mics,",
       "  author       = {{UNICEF}},",
       "  title        = {Multiple Indicator Cluster Surveys ({MICS})},",
       "  howpublished = {\\url{https://mics.unicef.org/surveys}}",
       "}",
       "@misc{wdi,",
       "  author       = {{World Bank}},",
       "  title        = {World Development Indicators},",
       "  howpublished = {\\url{https://databank.worldbank.org/source/world-development-indicators}},",
       "  note         = {GDP per capita (NY.GDP.PCAP.CD) and current health expenditure per capita (SH.XPD.CHEX.PC.CD)}",
       "}",
       "@misc{wgi,",
       "  author       = {{World Bank}},",
       "  title        = {Worldwide Governance Indicators},",
       "  howpublished = {\\url{https://www.worldbank.org/en/publication/worldwide-governance-indicators}},",
       "  note         = {Political Stability and Absence of Violence/Terrorism, estimate (GOV\\_WGI\\_PV\\_EST)}",
       "}",
       "```", "", "## Changes in full", ""]
for c in applied:
    md += [f"### {c['id']} — {c['section']} (L{c['line'] or '–'}, {c['kind']})", "", c["reason"], "",
           "**Current:**", "", "```latex", show(c["old"], 1200) if c["old"].strip() else "(nothing)", "```", "",
           "**Proposed:**", "", "```latex", show(c["new"]) if c["new"].strip() else "(delete)", "```", ""]
(OUT / "PROPOSED_CHANGES.md").write_text("\n".join(md) + "\n", encoding="utf-8")
print(f"{len(applied)} changes applied, {len(skipped)} already done or superseded -> {OUT / 'main_proposed.tex'} and PROPOSED_CHANGES.md")
print("by kind:", {k: sum(c['kind'] == k for c in applied) for k in kinds})
