# Effect of MAP release 202608 on the headline: one-step estimate

1 November 2026. The paper uses MAP's PfPR2-10 release 202508 (2000–2024). MAP has since published 202608
(2000–2025). This note estimates how the Snow primary v13 burden would change under 202608 without refitting, and
says what a full switch would add. main.tex is not edited.

## Bottom line

- **2024 with UN IGME:** malaria-attributable deaths rise by 2.0%, from 626,000 to 638,000. The excess over the UN IGME
  (CA-CODE) estimate of malaria deaths goes from 42% to 45%.
- **2024 with IHME:** deaths rise by 2.9%, from 585,000 to 602,000. The excess over IHME goes from 37% to 41%.
- **2015:** unchanged (690,000 with UN IGME). In 2000 the estimate is 1.5% lower.
- **2015–2024 fall in the rate:** smaller, at 19.1% instead of 20.8% (UN IGME) and 21.8% instead of 24.0% (IHME).
- **Countries:** the 2024 change is a net figure. 202608 raises PfPR in many mid-burden countries, such as Zambia,
  Burkina Faso, Malawi, Niger and Angola, and lowers it in the Democratic Republic of the Congo. Nigeria is unchanged.
- **Approximate refit:** an independent review refitted the seven models with each record's exposure moved by MAP's
  national shift. The 2024 increase grows by about half a point, to 642,000 (+2.6%) with UN IGME and 605,000 (+3.4%)
  with IHME. Within-country revisions are not captured, so a full switch is likely +2.5–3% (UN IGME) and +3–4% (IHME),
  give or take 1.5 points.
- **Recommendation at the time:** keep 202508 and report 202608 as a sensitivity analysis. The change is small against
  the spline-only interval in `uncertainty_first_pass.md` (2024: 540,000–704,000). **Superseded (1 November 2026):**
  the author chose to switch the paper to 202608, with MAP's national PfPR in the burden step, on branch `map-202608`.

## Method

1. **MAP national PfPR.** MAP's platform API gives national PfPR2-10 (mean, LCI, UCI) by country-year for both
   releases (`https://data.malariaatlas.org/map-platform-app-backend/api/v1/trends/malaria/Pf_PR-rate/admin0/mean?version=202508`,
   and the same with `version=202608`).
2. **Shift.** For each country-year, the paper's national PfPR was shifted on the logit scale by MAP's own
   202608 − 202508 difference. Shifting by the difference keeps the paper's population weights (GPW 2020), which
   differ from MAP's.
3. **Burden.** The attributable fraction was recomputed from the primary PfPR spline components for each age band and
   applied to the primary's crisis-adjusted all-cause deaths, from both UN IGME and IHME. Nothing else changed.

**Checks.**
- The primary reproduces the published attributable fractions (within 1e-10) and annual totals (within 1e-4).
- An additive shift gives the same changes to within 0.1 percentage points.
- Using MAP's national values directly for both releases gives the same release effect: +2.0% (UN IGME) and +3.0%
  (IHME) in 2024.
  - On their own, MAP's national values give a 2024 total of 613,000 (202508), 2% below the paper's 626,000.
  - That gap reflects population weighting alone, and it is about the same size as the release effect.

## Totals (malaria-attributable deaths, 42 countries)

| All-cause source | Year | 202508 (published) | 202608, one step | Change | Excess over cause-specific, 202508 → 202608 |
|---|---|---:|---:|---:|---|
| UN IGME | 2000 | 1,159,000 | 1,141,000 | −1.5% | +60% → +58% (CA-CODE) |
| UN IGME | 2015 | 690,000 | 690,000 | −0.1% | +66% → +65% (CA-CODE) |
| UN IGME | 2024 | 626,000 | 638,000 | +2.0% | +42% → +45% (CA-CODE) |
| IHME | 2000 | 1,117,000 | 1,100,000 | −1.5% | +98% → +95% (IHME) |
| IHME | 2015 | 688,000 | 688,000 | +0.1% | +65% → +65% (IHME) |
| IHME | 2024 | 585,000 | 602,000 | +2.9% | +37% → +41% (IHME) |

## Countries that drive the 2024 change (UN IGME all-cause deaths)

PfPR is national PfPR2-10 (%). "Paper" is the paper's population weighting; the 202608 column applies MAP's shift to
it.

| Country | MAP 202508 | MAP 202608 | Paper 202508 | Paper 202608 | Deaths 202508 | Deaths 202608 | Change |
|---|---:|---:|---:|---:|---:|---:|---:|
| DR Congo | 33.3 | 28.8 | 36.1 | 31.4 | 122,500 | 117,900 | −4,500 |
| Niger | 16.7 | 19.6 | 17.3 | 20.3 | 28,400 | 31,000 | +2,600 |
| Zambia | 13.7 | 24.5 | 14.3 | 25.4 | 5,500 | 7,600 | +2,200 |
| Burkina Faso | 20.4 | 28.8 | 20.9 | 29.4 | 14,500 | 16,600 | +2,100 |
| Ethiopia | 3.1 | 4.0 | 4.0 | 5.0 | 8,300 | 10,300 | +2,000 |
| Angola | 19.4 | 23.9 | 20.3 | 25.1 | 15,700 | 17,400 | +1,600 |
| Côte d'Ivoire | 20.8 | 25.4 | 21.6 | 26.3 | 14,300 | 15,700 | +1,400 |
| Malawi | 19.2 | 27.7 | 19.2 | 27.6 | 5,700 | 7,000 | +1,300 |
| Uganda | 21.3 | 24.1 | 21.9 | 24.7 | 17,400 | 18,500 | +1,100 |
| Guinea | 20.5 | 24.9 | 21.4 | 26.0 | 11,200 | 12,200 | +1,000 |
| Kenya | 3.8 | 5.3 | 4.6 | 6.4 | 2,500 | 3,300 | +900 |
| Senegal | 6.5 | 2.2 | 6.8 | 2.3 | 1,400 | 500 | −900 |
| Burundi | 21.5 | 31.8 | 23.4 | 34.4 | 5,400 | 6,200 | +800 |
| Nigeria | 24.1 | 24.1 | 24.7 | 24.6 | 239,400 | 239,200 | −200 |

Deaths go up in 21 countries and down in 21. The net change is +12,600: +19,300 from rises and −6,700 from falls.

## What the one-step estimate leaves out

- **The fit.** A full switch also changes the survey-region exposures on which the seven PfPR curves are fitted. MAP's
  national shift gives an approximate size:
  - Across the 7.8 million records, mean absolute change 1.1 percentage points; correlation of old and new exposure
    0.992.
  - Records from 2020–2024 change most (mean absolute change 2.2 points), but they are 10% of records and 8% of deaths.
  - Burundi's records rise most (mean +8.8 points).
  - An approximate refit with these shifted exposures was run, using the same specification; a control refit
    reproduced the published coefficients to within 5e-6. On its own it adds +0.56% (UN IGME) and +0.54% (IHME) to
    2024, and +0.4% to 2015. The AFs rise slightly below 24 months and fall slightly at 24–59 months.
  - The true within-country pattern of the revision could move this either way, roughly −1% to +1.5% of the 2024
    total.
- **2025.** 202608 adds 2025. Using it would also need 2025 all-cause deaths, and the pipeline's all-cause inputs stop
  at 2024.
- **Survey-region detail.** The national shift stands in for the change within each survey region. The actual change
  could differ inside a country, for example between northern and southern Nigeria.

## What a full switch would take

1. **Download.** Download the 202608 rasters for 2000–2024 (or 2025) at the Africa extent from data.malariaatlas.org.
   - `getRaster` fetches all four bands, about 12 MB per band-year uncompressed.
   - Band 1 is about 4.5 MB per year once stored, about 110 MB in all, like the current `data/map_annual/`.
   - That domain is probably outside GiveWell's network allowlist, so it needs approval first.
2. **Re-extract.** Point `MAP_DATASET_ID` (`R_inputs/00_config.R:48`) at 202608 and re-extract the exposures.
   - The Snow primary's unit exposures come from `R_cbh/snow/02_pfpr_polygons.R` over the annual rasters.
   - The 2024 national value is read from a separate file, `data/pfpr_2to10_africa_2024.tif`
     (`04_annual_comparison.R:25`, `00_national_inputs.R:43`). It must be replaced too.
   - The reference knots in `R_cbh/primary/reference_knots.csv` follow the 202508 exposure range (lower knot 0.0165,
     upper 94.76), so they need recomputing.
3. **Refit.** Refit the seven primary models (about 20 minutes).
4. **Rerun.** Rerun the burden, the sensitivity analyses, validation and the export, and update every number in the
   paper.

## Proposed text (supplementary sensitivity analyses)

```latex
Using MAP's subsequent release of \textit{Pf}PR$_{2-10}$ estimates (version 202608) in place of the version used here (202508), without refitting the models, changed the estimated number of malaria-attributable deaths in 2024 by 2\% (638,000; 602,000 using IHME).
```

## Files

These are in the session scratchpad, which is temporary. Move what is needed into the repo before relying on them.

- `/private/tmp/claude-501/-Users-jameswatson-Documents-GitHub-malaria-mortality-U5/57dde47b-92b2-46b6-a340-8eddaacbee64/scratchpad/map_api/one_step_202608.R`: the one-step burden. Run it from the repo root with `CBH_PRIMARY_VERSION=snow_merge`. Its outputs are `one_step_totals.csv`, `one_step_country_2024.csv` and `one_step_national_pfpr.csv`.
- `.../map_api/fit_exposure_shift.R`: the approximate change in the fit's exposures.
- `.../map_api/fetch_trends.R`: fetches MAP's national PfPR. Its outputs are `map_admin0_pfpr_202508.csv` and `map_admin0_pfpr_202608.csv` (iso3, year, mean, lci, uci).
