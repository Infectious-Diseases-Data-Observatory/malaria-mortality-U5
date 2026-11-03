# Child HIV incidence join of the child-band records (R_cbh/units/07_placement.R, the imputed-covariate sensitivity).
# Source after R_cbh/load_pipeline.R. The exploratory joint age-band model (cbh_trial_*), which no kept step ran, was
# removed on 1 November 2026 (git history).
cbh_attach_incidence <- function(d, panel) {
  cbh_require(d, c("country", "entry_year"), "Child-band incidence join")
  cbh_require(panel, c("iso3", "year", "hiv_incidence_per1000", "hiv_incidence_status"), "Child incidence panel")
  cbh_unique(panel, c("iso3", "year"), "Child incidence panel")
  j <- match(paste(d$country, d$entry_year), paste(panel$iso3, panel$year))
  v <- panel$hiv_incidence_per1000[j]
  valid <- is.finite(v) & v > 0
  d$hiv_incidence_per1000 <- ifelse(valid, v, NA_real_)
  d$hiv_incidence_status <- ifelse(is.na(j), "missing_country_year", panel$hiv_incidence_status[j])
  d$hiv_incidence_status[!is.na(j) & !valid] <- "missing_or_invalid_value"
  d$log_hiv_incidence <- log(d$hiv_incidence_per1000)
  d
}
