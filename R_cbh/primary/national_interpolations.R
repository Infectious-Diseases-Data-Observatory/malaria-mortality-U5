# Declared national-covariate fills of the Snow-unit primary (author decisions, 29 October 2026), applied to records
# whose value is missing. Used by R_cbh/primary/00_prepare_snow.R (merge variant). Source after load_pipeline.R.
#   Political stability: the Worldwide Governance Indicators were published every two years until 2002, so there is no
#     value for 1997, 1999 and 2001; of these only 2001 is a band-entry year. In a gap year a country's political
#     stability is the mean of its values for the years before and after, the rule of the imputed-covariate sensitivity
#     (R_cbh/sensitivity/imputation_dhsmics/01_impute_national.R). Without it every record entering a band in 2001 failed
#     complete-case selection (v12).
#   Health expenditure per capita: the WHO Global Health Expenditure Database behind the World Bank series runs about
#     two years behind, so no country in the analysis has a 2024 value; a country's 2024 value is its 2023 value (last
#     observation carried forward). Without it every record entering a band in 2024 failed complete-case selection (v13).
cbh_wgi_gap_years <- function() c(1997L, 1999L, 2001L)
# Political stability of each (country, year) in a gap year, from the governance panel of cbh_config()$annual_panels:
# the mean of the adjacent years' values; NA in other years or where either neighbour has no value.
cbh_political_stability_interpolated <- function(country, year, cfg) {
  spec <- cfg$annual_panels$governance; col <- spec$columns[["political_stability"]]
  panel <- cbh_read_csv(spec$path); cbh_require(panel, c("iso3", "year", col), "governance"); cbh_unique(panel, c("iso3", "year"), "governance")
  value <- function(y) { v <- cbh_num(panel[[col]][match(paste(country, y), paste(panel$iso3, panel$year))]); ifelse(is.finite(v), v, NA_real_) }
  gap <- year %in% cbh_wgi_gap_years()
  stopifnot(!any(gap & is.finite(value(year))))   # a gap year has no published value
  ifelse(gap, (value(year - 1L) + value(year + 1L)) / 2, NA_real_)
}
# Years whose health expenditure is carried forward, named by the year filled, with the year carried.
cbh_health_expenditure_carry_years <- function() c(`2024` = 2023L)
# Log health expenditure per capita of each (country, year) in a carried year, from the health_spending panel of
# cbh_config()$annual_panels: the log of the carried year's value; NA in other years or where that value is not positive.
cbh_health_expenditure_carried <- function(country, year, cfg) {
  spec <- cfg$annual_panels$health_spending; col <- spec$columns[["health_expenditure_pc"]]
  panel <- cbh_read_csv(spec$path); cbh_require(panel, c("iso3", "year", col), "health_spending"); cbh_unique(panel, c("iso3", "year"), "health_spending")
  from <- unname(cbh_health_expenditure_carry_years()[as.character(year)])
  v <- cbh_num(panel[[col]][match(paste(country, from), paste(panel$iso3, panel$year))])
  ifelse(!is.na(from) & is.finite(v) & v > 0, log(v), NA_real_)
}
