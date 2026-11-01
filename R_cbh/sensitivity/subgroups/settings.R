# Subgroup refits of the current primary PfPR models (plan section 3.4.1).
# Four subsets of the fitted 17-variable sample, each refitted separately by age band:
#   sahel        survey regions with boundary centroid >= 12N, < 36E, outside ETH/ERI/SOM/DJI
#   east_africa  UN M49 Eastern Africa countries
#   early        surveys with survey year <= median survey year (one vote per survey)
#   late         surveys with survey year >  median survey year
# sample = "dhsmics" (default) refits the DHS and MICS primary (v9; v3 was v7, v2 was v5); sample = "dhs"
# reproduces the earlier DHS-only refits of v3 (subgroups_map_gamma2_v1).
cbh_subgroup_settings <- function(sample = c("dhsmics", "dhs")) {
  sample <- match.arg(sample)
  st <- list(
    sample = sample,
    id = "subgroups_map_gamma2_v1",
    primary_version = "regional",
    centroids = "data/derived_dhs/dhs_region_centroids.csv",
    registry = "data/derived_dhs/survey_registry.csv",
    sahel = list(latitude_min = 12, longitude_max = 36, exclude_countries = c("ETH", "ERI", "SOM", "DJI")),
    # UN M49 Eastern Africa (https://unstats.un.org/unsd/methodology/m49/), restricted to
    # countries that can appear in the DHS/MIS/MICS sample.
    east_africa = c("BDI", "COM", "DJI", "ERI", "ETH", "KEN", "MDG", "MOZ", "MWI", "RWA",
                    "SOM", "SSD", "TZA", "UGA", "ZMB", "ZWE"),
    # UN M49 Western, Middle ("Central") and Southern Africa, as grouped in Figure 1 (R_cbh/reporting/03_survey_map.R).
    west_africa = c("BEN", "BFA", "CIV", "CPV", "GHA", "GIN", "GMB", "GNB", "LBR", "MLI", "MRT", "NER", "NGA", "SEN", "SLE", "TGO"),
    central_africa = c("AGO", "CAF", "CMR", "COD", "COG", "GAB", "GNQ", "STP", "TCD"),
    southern_africa = c("BWA", "LSO", "NAM", "SWZ", "ZAF"),
    subgroups = c("sahel", "east_africa", "early", "late"),
    labels = c(map_full = "Full analysis", sahel = "Sahel (≥12°N)",
               east_africa = "Eastern Africa", early = "Surveys up to median year",
               late = "Surveys after median year"),
    colours = c(map_full = "#222222", sahel = "#C34D26", east_africa = "#009E73",
                early = "#7B4FA3", late = "#E69F00"))
  if (sample == "dhsmics") {
    st$id <- "subgroups_dhsmics_map_gamma2_v4"   # v9 primary; v3 = v7 and v2 = v5, kept as history
    st$primary_version <- "regional_mics"
    # The Snow-unit primary (CBH_PRIMARY_VERSION=snow_merge): the same subgroups; Sahel membership by the record's
    # source survey-region centroid, as in v9 (user plan default, 11 October 2026).
    if (identical(Sys.getenv("CBH_PRIMARY_VERSION"), "snow_merge")) {
      st$id <- "subgroups_snow520_merge_gamma2_v8"; st$primary_version <- "snow_merge"   # v8: primary v14 (MAP 202608); v7 = v13, v6 = v12, v5 = v11
      # Full suite (user request, 12 October 2026): Sahel, the UN M49 sub-regions of Figure 1, and the survey-period
      # split. Southern Africa is not refitted: 1,061 deaths in 7 surveys and PfPR below 10.3% (95% of records below
      # 7.4%), so the curve at 20% and 40% would be an extrapolation (its size is reported in subregions_not_fitted.csv).
      # Period splits: by survey (survey year up to / after the median survey year; each survey in one half) and, added
      # at the user's request (12 October 2026), by record (child-band calendar year up to / after the median calendar
      # year of the records, about 2013; every survey can contribute to both halves).
      st$subgroups <- c("sahel", "west_africa", "central_africa", "east_africa", "early", "late", "records_early", "records_late")
      st$record_subsets <- c("records_early", "records_late")
      st$labels <- c(map_full = "Full analysis", sahel = "Sahel (≥12°N)", west_africa = "West Africa",
                     central_africa = "Central Africa", east_africa = "East Africa",
                     early = "Surveys up to median survey year", late = "Surveys after median survey year",
                     records_early = "Records up to median calendar year", records_late = "Records after median calendar year")
      st$colours <- c(map_full = "#222222", sahel = "#C34D26", west_africa = "#0072B2", central_africa = "#CC79A7",
                      east_africa = "#009E73", early = "#7B4FA3", late = "#E69F00", records_early = "#56B4E9", records_late = "#8C8C2A")
      st$figures <- list(sfig_pfpr_splines_by_subgroup = c("sahel"),
                         sfig_pfpr_splines_by_subregion = c("west_africa", "central_africa", "east_africa"),
                         sfig_pfpr_splines_by_period = c("early", "late", "records_early", "records_late"))
      st$not_fitted <- c("southern_africa")
    }
    st$centroids <- c(st$centroids, "data/derived_mics/mics_region_centroids.csv")
    st$registry <- c(st$registry, "data/derived_mics/survey_registry_mics.csv")
  }
  if (is.null(st$figures)) st$figures <- list(sfig_pfpr_splines_by_subgroup = st$subgroups)
  if (is.null(st$record_subsets)) st$record_subsets <- character()
  st$out <- file.path("results/cbh", st$id)
  st$private <- file.path("data/derived_cbh/models", st$id)
  st
}
cbh_subgroup_sample <- function(args) if ("--dhs-only" %in% args) "dhs" else "dhsmics"
