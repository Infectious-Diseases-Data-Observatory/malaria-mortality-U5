# Country fixed-effects sensitivity: proposed text for main.tex

31 October 2026. Numbers are from `results/cbh/country_fixed_effects_snow520_merge_gamma2_v1/` (`SUMMARY.md`,
`burden_comparison_2000_2024.csv`, `hazard_ratios_vs_zero.csv`), refitted on the Snow primary v13 sample. main.tex is
not edited; paste what you want.

## Methods, Sensitivity analyses (main text)

Add at the end of the paragraph (after "...could mediate the relationship between PfPR and death, or confound it."):

```latex
We also refitted the primary models with a fixed effect for each country in place of the country random intercept, so that the effect of \textit{Pf}PR$_{2-10}$ was estimated from variation within countries only.
```

## Supplementary Methods, Sensitivity analyses

Add after the subset paragraph:

```latex
In the country fixed-effects analysis, the country random intercept was replaced by a fixed effect for each of the 37 countries with survey data; the sample, covariates, spline knots, $\gamma$, offset and the survey and survey-unit random intercepts were unchanged.
```

## Results (end of the sensitivity paragraph, after the wasting and stunting sentence)

```latex
With country fixed effects, the hazard ratios at a \textit{Pf}PR$_{2-10}$ of 40\%, as compared with no transmission, were slightly lower, most at 3 and 4 years of age (1.64 and 1.60, compared with 1.95 and 1.84; Figure \ref{fig:country_fe}), and the estimated number of malaria-attributable deaths in 2024 was 9\% lower (569,000; 524,000 using IHME), 29\% more than the UN IGME estimate of malaria deaths and 22\% more than IHME.
```

The full hazard ratios at 40% against no transmission (primary, then fixed effects): <1 month 1.12 and 1.10; 1–5
months 1.27 and 1.27; 6–11 months 1.59 and 1.49; 12–23 months 2.13 and 2.02; 24–35 months 2.45 and 2.29; 36–47 months
1.95 and 1.64; 48–59 months 1.84 and 1.60. The 2015–2024 decline in the rate is unchanged (21% with UN IGME, 24% with
IHME), because the estimate is about 9% lower in every year (8.8% in 2000, 9.0% in 2015 and 2024 with UN IGME).

## Discussion (limitations paragraph)

Option A, add only. After "However, there is good reason to think that the causal effect is identifiable.":

```latex
When the effect of \textit{Pf}PR$_{2-10}$ was estimated within countries only, using country fixed effects, the 2024 estimate fell by 9\% but remained 29\% above the UN IGME estimate of malaria deaths.
```

Option B, as the consistency review suggested: replace "However, there is good reason to think that the causal effect
is identifiable." with "Several observations suggest that residual confounding is limited, although they cannot
exclude it." and add the sentence from option A after it.

## Supplementary figure

Place after the wasting and stunting figure:

```latex
\begin{figure}
    \centering
    \includegraphics[width=\linewidth]{Supplementary Figures/sfig_pfpr_splines_country_fixed_effects.png}
    \caption{Results when replacing the country random intercept with a fixed effect for each country, so that the effect of \textit{Pf}PR$_{2-10}$ is estimated from variation within countries only.}
    \label{fig:country_fe}
\end{figure}
```

A longer caption is in `paper/Supplementary Figures/sfig_pfpr_splines_country_fixed_effects_caption.md`.
