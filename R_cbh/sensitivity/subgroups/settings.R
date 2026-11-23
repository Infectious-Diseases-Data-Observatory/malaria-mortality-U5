# Subgroup refits of the GADM-unit primary (CBH_PRIMARY_VERSION=gadm; v10 on primary v19, v9 on v15; the Snow-unit v5-v8 on
# primary v11-v14 were replaced with it, author decision 3 November 2026; code in git history up to f2db98e).
# Subsets of the fitted 17-variable sample, each refitted separately by age band:
#   west_africa, central_africa, east_africa   UN M49 Western, Middle and Eastern Africa countries
#   early, late     surveys with survey year <= / > the median survey year (one vote per survey)
#   records_early, records_late   child-band records with calendar year <= / > the records' median calendar year
cbh_subgroup_settings <- function() {
  # Full suite (user request, 12 October 2026): the UN M49 sub-regions of Figure 1 and the survey-period split. The
  # Sahel subset was removed on 18 November 2026 (author request: not in the paper; git tag pre-cleanup-20261118). Southern Africa is not refitted: about 1,000 deaths in 7 surveys and PfPR below about 10%, so the curve at
  # 20% and 40% would be an extrapolation (its size is reported in subregions_not_fitted.csv).
  # Period splits: by survey (survey year up to / after the median survey year; each survey in one half) and, added
  # at the user's request (12 October 2026), by record (child-band calendar year up to / after the median calendar
  # year of the records, about 2013; every survey can contribute to both halves).
  st <- list(
    sample = "dhsmics",
    id = "subgroups_gadm_merge_gamma2_v10",   # v10: primary v19 (whole-population unit PfPR); v9: primary v15 (GADM units)
    primary_version = "gadm",
    # UN M49 Eastern Africa (https://unstats.un.org/unsd/methodology/m49/), restricted to
    # countries that can appear in the DHS/MIS/MICS sample.
    east_africa = c("BDI", "COM", "DJI", "ERI", "ETH", "KEN", "MDG", "MOZ", "MWI", "RWA",
                    "SOM", "SSD", "TZA", "UGA", "ZMB", "ZWE"),
    # UN M49 Western, Middle ("Central") and Southern Africa, as grouped in Figure 1 (R_cbh/reporting/03_survey_map.R).
    west_africa = c("BEN", "BFA", "CIV", "CPV", "GHA", "GIN", "GMB", "GNB", "LBR", "MLI", "MRT", "NER", "NGA", "SEN", "SLE", "TGO"),
    central_africa = c("AGO", "CAF", "CMR", "COD", "COG", "GAB", "GNQ", "STP", "TCD"),
    southern_africa = c("BWA", "LSO", "NAM", "SWZ", "ZAF"),
    subgroups = c("west_africa", "central_africa", "east_africa", "early", "late", "records_early", "records_late"),
    labels = c(map_full = "Full analysis", west_africa = "West Africa",
               central_africa = "Central Africa", east_africa = "East Africa",
               early = "Surveys up to median survey year", late = "Surveys after median survey year",
               records_early = "Records up to median calendar year", records_late = "Records after median calendar year"),
    colours = c(map_full = "#222222", west_africa = "#0072B2", central_africa = "#CC79A7",
                east_africa = "#009E73", early = "#7B4FA3", late = "#E69F00", records_early = "#56B4E9", records_late = "#8C8C2A"),
    record_subsets = c("records_early", "records_late"),
    figures = list(sfig_pfpr_splines_by_subregion = c("west_africa", "central_africa", "east_africa"),
                   sfig_pfpr_splines_by_period = c("early", "late", "records_early", "records_late")),
    not_fitted = c("southern_africa"))
  st$out <- file.path("results/cbh", st$id)
  st$private <- file.path("data/derived_cbh/models", st$id)
  st
}
