# Reassessing the contribution of *P. falciparum* malaria to child mortality in Africa

Code and inputs for the paper of this title (Watson, Darji, Kamau, …, Snow; in preparation).

Malaria deaths are estimated from complex statistical models which assign each death to a single cause, with cause
fractions derived primarily from verbal autopsy data, ignoring indirect mortality effects. This analysis instead pools
survey data from sub-Saharan Africa since 2000 with prevalence estimates from the Malaria Atlas Project (MAP) to
characterise the relationship between prevalence of infection and all-cause mortality in children under 5, and from it
estimates malaria-attributable mortality.

## What the analysis does

1. **Child age bands.** Complete birth histories from DHS, MIS and UNICEF MICS surveys are split into seven age bands
   (<1 month, 1–5 months, 6–11 months, then yearly to 5 years). A band is included if the child entered it alive in
   the 60 months before the interview, in 2000–2024, and the band ended before the interview.
2. **Units and exposure.** Each record is matched, through its lowest reported administrative unit, to one or a union
   of the 520 malaria-endemic sub-national polygons of Snow et al. (2017) (survey-units). Each band takes the MAP
   *Pf*PR₂₋₁₀ (release 202608) of its survey-unit in its calendar year of entry.
3. **Model.** Seven binomial generalised additive models with a complementary log-log link (one per age band; a
   proportional-hazards model for grouped survival times), each with a penalised spline of *Pf*PR₂₋₁₀, a spline of
   calendar time, 17 confounders (13 survey-unit summaries from the survey recodes and 4 national measures) and random
   intercepts for survey, country and survey-unit.
4. **Malaria-attributable mortality.** Each band's attributable fraction, 1 − exp{f(0) − f(P)} at MAP's national
   *Pf*PR₂₋₁₀, is applied to UN IGME all-cause deaths (IHME as a sensitivity analysis) in 42 countries, 2000–2024, and
   compared with the CA-CODE and IHME estimates of malaria deaths. 95% uncertainty intervals come from 500 joint draws
   of the *Pf*PR–mortality curves, MAP's national *Pf*PR₂₋₁₀ and the all-cause deaths.
5. **Sensitivity analyses.** The Sahel and UN M49 sub-regions, survey period, without wasting and stunting, country
   fixed effects, and imputed covariates.

## Running it

- R 4.6.0 with the package versions that `run_pipeline.R` checks, Python 3, and about 16 GB of memory.
- Put the DHS, MIS and MICS microdata in `data/raw/` ([data/README.md](data/README.md)) and download the MAP rasters:
  `Rscript R_inputs/fetch/fetch_map_release_rasters.R 202608 2000 2024`. Every other input is committed.
- Run everything (about 5 to 6 hours; network access is blocked during the run):

  ```bash
  ./run_detached.sh --all
  ```

  `Rscript run_pipeline.R --list` shows the stages and which are complete; `--from=STAGE` and `--only=STAGE` re-run
  part of it. Logs are in `logs/`.
- Results are written to `results/cbh/` (the primary analysis is `primary_snow520_merge_dhsmics_gamma2_v14`), and the
  figures, tables and captions used in the paper are exported to `paper/`.

## Layout

```
run_pipeline.R   runs every stage in order          run_detached.sh   the same, detached from the terminal
R_inputs/        survey-region MAP PfPR, immunisation and other input producers; fetch/ = download scripts
R_mics/          MICS conversion to the DHS layout, regions, PfPR, child bands, covariates
R_cbh/           child bands, covariates, HIV model, Snow units (snow/), primary model (primary/), burden and
                 uncertainty (burden/), figures and tables (reporting/), sensitivity analyses (sensitivity/)
data/            committed inputs and manifests        paper/   figures, tables and captions for the manuscript
```

Figure text sizes follow the rule in [CLAUDE.md](CLAUDE.md).

## Licence

The code is released under CC0 1.0 (`LICENSE`). Committed third-party inputs keep their own terms (see
[data/README.md](data/README.md)), notably IHME's terms of use. DHS and MICS microdata are not redistributed.
