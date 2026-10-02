#!/usr/bin/env Rscript
# National inputs for the burden calculation in 2005, 2015 and 2024 (no model is read here):
# IHME all-cause deaths and rates by age, mapped to the seven model age bands; national
# population-weighted MAP PfPR; IHME under-five all-cause and malaria death totals.
# In the analysis project these files were written by the model-independent part of
# R_cbh/burden/01_country_attributable.R and 03_compare_ihme.R (results/cbh/age_band_separate_v1/);
# the code below is that part, unchanged except that the legacy density-weighted PfPR column
# (which needed data/pfpr_by_country_year.csv) is no longer written.
# Usage: Rscript R_cbh/burden/00_national_inputs.R [--year=YYYY]   (default: 2005, 2015 and 2024)
source("R_cbh/load_pipeline.R")
for (pkg in c("countrycode", "terra", "sf", "exactextractr"))
  stopifnot(requireNamespace(pkg, quietly = TRUE))
args <- commandArgs(trailingOnly = TRUE)
stopifnot(all(grepl("^--year=[0-9]{4}$", args)))
years <- if (length(args)) as.integer(sub("^--year=", "", args)) else c(2005L, 2015L, 2024L)
stopifnot(all(years >= 2000L & years <= 2024L))
root <- "results/cbh/national_burden_inputs"
export <- list.files("data", pattern = "2026-09-09 10-58-22[.]csv$", full.names = TRUE)
stopifnot(length(export) == 1L)
ihme_malaria_path <- "data/ihme_malaria_u5_deaths_by_age_country_year.csv"
pop_path <- "data/pop/gpw_v4_population_density_rev11_2020_2.5m.tif"
boundary_path <- "data/africa_admin0.rds"
ages <- cbh_config()$age_bands$age_band
stopifnot(identical(ages, c("<1", "1-5", "6-11", "12-23", "24-35", "36-47", "48-59")))
leaf <- c("0 to 6 days (early neonatal)", "7 to 27 days (late neonatal)",
          "1 to 5 months", "6-11 months", "12 to 23 months", "2 to 4")
all_x <- cbh_read_csv(export)

for (year in years) {
  year_text <- function(x) gsub("{year}", as.character(year), x, fixed = TRUE)
  out <- file.path(root, year_text("country_burden_{year}"))
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  x <- all_x[all_x$Year == year & all_x$Sex == "Both" & all_x$Condition == "All causes" & all_x$Measure == "Deaths", ]
  x$iso3 <- countrycode::countrycode(x$Location, "country.name", "iso3c", warn = FALSE)
  stopifnot(!anyNA(x$iso3), all(is.finite(x$Value)), all(x$Value > 0))
  cbh_unique(x, c("iso3", "Age", "Unit"), year_text("{year} IHME export"))
  countries <- unique(x[c("iso3", "Location")]); countries <- countries[order(countries$iso3), ]
  cbh_atomic_csv(x[c("iso3", "Location", "Year", "Age", "Unit", "Value", "Lower", "Upper")],
                 file.path(out, year_text("ihme_source_{year}.csv")))

  # Population counts per raster cell = density x cell area. Fixed GPW 2020
  # population geography; exact polygon overlap; only pixels with MAP coverage.
  map_path <- if (year == 2024L) "data/pfpr_2to10_africa_2024.tif" else sprintf("data/map_annual/pfpr2_10_%d.tif", year)
  p <- terra::rast(map_path)
  stopifnot(terra::nlyr(p) == 1, terra::is.lonlat(p))
  b <- sf::st_make_valid(readRDS(boundary_path))
  b <- b[b$iso %in% countries$iso3, ]
  density <- terra::resample(terra::crop(terra::rast(pop_path), p), p, method = "bilinear")
  weights <- terra::ifel(density >= 0, density, NA) * terra::cellSize(p, unit = "km")
  covered <- terra::mask(weights, p)
  message(year_text("Extracting national population-weighted {year} PfPR."))
  layers <- c(covered, p * covered, weights)
  names(layers) <- c("covered", "numerator", "all_pop")
  agg <- exactextractr::exact_extract(layers, b, "sum", progress = FALSE)
  den <- agg$sum.covered; num <- agg$sum.numerator; all_pop <- agg$sum.all_pop
  stopifnot(length(den) == nrow(b), length(num) == nrow(b), length(all_pop) == nrow(b))
  pr <- data.frame(iso3 = b$iso, pfpr_pct = 100 * num / den,
    population_weight_on_map = den, population_weight_within_raster = all_pop,
    map_population_coverage_within_raster = den / all_pop)
  cbh_unique(pr, "iso3", "National MAP extraction")
  pr <- merge(countries, pr, by = "iso3", all.x = TRUE, sort = TRUE)
  pr$pfpr_pct[!is.finite(pr$pfpr_pct)] <- NA_real_
  stopifnot(all(pr$pfpr_pct[!is.na(pr$pfpr_pct)] >= 0 & pr$pfpr_pct[!is.na(pr$pfpr_pct)] <= 100))
  pr$status <- ifelse(is.na(pr$pfpr_pct), "missing_MAP_no_estimate", "estimated")
  pr$map_coverage_below_95pct <- pr$map_population_coverage_within_raster < .95
  pr$exposure_year <- year; pr$population_weight_year <- 2020L
  cbh_atomic_csv(pr, file.path(out, year_text("national_pfpr_{year}.csv")))

  # Six disjoint source ages. Early and late neonatal receive the same <1m HR.
  source_rows <- do.call(rbind, lapply(countries$iso3, function(iso) {
    z <- x[x$iso3 == iso, ]
    value <- function(ages, unit, field = "Value") {
      ii <- match(ages, z$Age[z$Unit == unit]); stopifnot(!anyNA(ii))
      z[[field]][which(z$Unit == unit)[ii]]
    }
    deaths <- value(leaf, "Number"); rate <- value(leaf, "Rate (per 100,000)")
    stopifnot(abs(sum(deaths) - value("Under 5", "Number")) < 1e-5 * sum(deaths),
      abs(sum(deaths[1:4]) - value("Under 1", "Number")) < 1e-5 * sum(deaths[1:4]))
    data.frame(iso3 = iso, source_age = leaf, deaths = deaths, rate_per100000 = rate,
      implied_person_years = deaths / (rate / 1e5),
      ihme_deaths_lower = value(leaf, "Number", "Lower"),
      ihme_deaths_upper = value(leaf, "Number", "Upper"),
      ihme_rate_lower = value(leaf, "Rate (per 100,000)", "Lower"),
      ihme_rate_upper = value(leaf, "Rate (per 100,000)", "Upper"))
  }))
  cbh_atomic_csv(source_rows, file.path(out, "ihme_disjoint_age_inputs.csv"))
  bands <- do.call(rbind, lapply(countries$iso3, function(iso) {
    z <- source_rows[source_rows$iso3 == iso, ]; stopifnot(identical(z$source_age, leaf))
    deaths <- c(sum(z$deaths[1:2]), z$deaths[3:5], rep(z$deaths[6] / 3, 3))
    exposure <- c(sum(z$implied_person_years[1:2]), z$implied_person_years[3:5], rep(z$implied_person_years[6] / 3, 3))
    data.frame(iso3 = iso, age_band = ages, ihme_deaths = deaths,
      implied_person_years = exposure, ihme_rate_per100000 = deaths / exposure * 1e5,
      age_mapping = c("0-27 days mapped to model <1 completed month", rep("direct age match", 3),
        rep("IHME 2-4 rate shared; deaths and person-time divided equally", 3)))
  }))
  bands <- merge(bands, pr, by = "iso3", all.x = TRUE)
  bands <- bands[order(bands$iso3, match(bands$age_band, ages)), ]; rownames(bands) <- NULL
  keep <- c("iso3", "age_band", "Location", "pfpr_pct", "ihme_deaths", "implied_person_years", "ihme_rate_per100000",
    "age_mapping", "status", "map_population_coverage_within_raster", "map_coverage_below_95pct", "population_weight_year")
  cbh_atomic_csv(bands[keep], file.path(out, year_text("country_age_inputs_{year}.csv")))

  # Under-five totals: IHME all-cause (sum of the bands) and IHME malaria (direct under-five series).
  totals <- do.call(rbind, lapply(split(bands, bands$iso3), function(z)
    data.frame(iso3 = z$iso3[1], ihme_under5_deaths = sum(z$ihme_deaths))))
  ihme <- cbh_read_csv(ihme_malaria_path)
  ihme <- ihme[ihme$Year == year & ihme$Sex == "Both" & ihme$Age == "Under 5" &
               ihme$Condition == "Malaria" & ihme$Measure == "Deaths" & ihme$Unit == "Number", ]
  ihme$iso3 <- countrycode::countrycode(ihme$Location, "country.name", "iso3c", warn = FALSE)
  cbh_unique(ihme, "iso3", year_text("{year} IHME malaria counts"))
  totals <- merge(totals, data.frame(iso3 = ihme$iso3, ihme_malaria_deaths = ihme$Value), by = "iso3", all = TRUE)
  stopifnot(nrow(totals) == nrow(countries), setequal(totals$iso3, countries$iso3))
  cbh_atomic_csv(totals, file.path(out, year_text("ihme_under5_totals_{year}.csv")))
  inputs <- c(export, ihme_malaria_path, map_path, pop_path, boundary_path, "R_cbh/burden/00_national_inputs.R")
  cbh_atomic_csv(data.frame(file = inputs, md5 = vapply(inputs, cbh_file_hash, "")), file.path(out, "provenance.csv"))
  message(sprintf("%d: %d countries, %d with MAP PfPR", year, nrow(countries), sum(pr$status == "estimated")))
}
