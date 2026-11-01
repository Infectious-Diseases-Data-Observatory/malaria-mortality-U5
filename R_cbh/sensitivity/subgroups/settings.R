# Subgroup refits of the Snow-unit primary (CBH_PRIMARY_VERSION=snow_merge; v8 on primary v14, v7 = v13, v6 = v12,
# v5 = v11; the v9 refits subgroups_dhsmics_map_gamma2_v4 and the DHS-only v3 were removed with v9 on 1 November 2026).
# Subsets of the fitted 17-variable sample, each refitted separately by age band:
#   sahel           records whose source survey-region centroid is >= 12N, < 36E, outside ETH/ERI/SOM/DJI (as in v9)
#   west_africa, central_africa, east_africa   UN M49 Western, Middle and Eastern Africa countries
#   early, late     surveys with survey year <= / > the median survey year (one vote per survey)
#   records_early, records_late   child-band records with calendar year <= / > the records' median calendar year
cbh_subgroup_settings <- function() {
  # Full suite (user request, 12 October 2026): Sahel, the UN M49 sub-regions of Figure 1, and the survey-period
  # split. Southern Africa is not refitted: 1,061 deaths in 7 surveys and PfPR below 10.3% (95% of records below
  # 7.4%), so the curve at 20% and 40% would be an extrapolation (its size is reported in subregions_not_fitted.csv).
  # Period splits: by survey (survey year up to / after the median survey year; each survey in one half) and, added
  # at the user's request (12 October 2026), by record (child-band calendar year up to / after the median calendar
  # year of the records, about 2013; every survey can contribute to both halves).
  st <- list(
    sample = "dhsmics",
    id = "subgroups_snow520_merge_gamma2_v8",   # v8: primary v14 (MAP 202608); v7 = v13, v6 = v12, v5 = v11
    primary_version = "snow_merge",
    centroids = c("data/derived_dhs/dhs_region_centroids.csv", "data/derived_mics/mics_region_centroids.csv"),
    registry = c("data/derived_dhs/survey_registry.csv", "data/derived_mics/survey_registry_mics.csv"),
    sahel = list(latitude_min = 12, longitude_max = 36, exclude_countries = c("ETH", "ERI", "SOM", "DJI")),
    # UN M49 Eastern Africa (https://unstats.un.org/unsd/methodology/m49/), restricted to
    # countries that can appear in the DHS/MIS/MICS sample.
    east_africa = c("BDI", "COM", "DJI", "ERI", "ETH", "KEN", "MDG", "MOZ", "MWI", "RWA",
                    "SOM", "SSD", "TZA", "UGA", "ZMB", "ZWE"),
    # UN M49 Western, Middle ("Central") and Southern Africa, as grouped in Figure 1 (R_cbh/reporting/03_survey_map.R).
    west_africa = c("BEN", "BFA", "CIV", "CPV", "GHA", "GIN", "GMB", "GNB", "LBR", "MLI", "MRT", "NER", "NGA", "SEN", "SLE", "TGO"),
    central_africa = c("AGO", "CAF", "CMR", "COD", "COG", "GAB", "GNQ", "STP", "TCD"),
    southern_africa = c("BWA", "LSO", "NAM", "SWZ", "ZAF"),
    subgroups = c("sahel", "west_africa", "central_africa", "east_africa", "early", "late", "records_early", "records_late"),
    labels = c(map_full = "Full analysis", sahel = "Sahel (≥12°N)", west_africa = "West Africa",
               central_africa = "Central Africa", east_africa = "East Africa",
               early = "Surveys up to median survey year", late = "Surveys after median survey year",
               records_early = "Records up to median calendar year", records_late = "Records after median calendar year"),
    colours = c(map_full = "#222222", sahel = "#C34D26", west_africa = "#0072B2", central_africa = "#CC79A7",
                east_africa = "#009E73", early = "#7B4FA3", late = "#E69F00", records_early = "#56B4E9", records_late = "#8C8C2A"),
    record_subsets = c("records_early", "records_late"),
    figures = list(sfig_pfpr_splines_by_subgroup = c("sahel"),
                   sfig_pfpr_splines_by_subregion = c("west_africa", "central_africa", "east_africa"),
                   sfig_pfpr_splines_by_period = c("early", "late", "records_early", "records_late")),
    not_fitted = c("southern_africa"))
  st$out <- file.path("results/cbh", st$id)
  st$private <- file.path("data/derived_cbh/models", st$id)
  st
}
