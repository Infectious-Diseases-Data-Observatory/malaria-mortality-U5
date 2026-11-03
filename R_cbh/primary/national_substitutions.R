# Declared national-covariate substitutions of the primary (author decision, 12 October 2026). South Sudan
# became independent in July 2011 and its World Bank and WGI series start in 2008 (GDP), 2011 (political stability) and
# 2017 (health expenditure): for band-entry years before 2011 it takes Sudan's (SDN) GDP per capita, health expenditure
# per capita and political stability for the same year, from the same files (cbh_config()$annual_panels) with the
# validity rules and transformations of cbh_attach_external(). This replaces South Sudan's own 2008-2010 GDP too, so
# the pre-independence series is Sudan's throughout. Child HIV incidence is not substituted (South Sudan has its own
# UNAIDS series). Used by R_cbh/primary/00_prepare.R and R_cbh/sensitivity/imputation_dhsmics (01_impute_national.R,
# 03_prepare.R). Source after load_pipeline.R.
cbh_national_substitutions <- function() data.frame(country = "SSD", source_country = "SDN", before_year = 2011L,
  note = "independent from July 2011", stringsAsFactors = FALSE)
# The substituted covariates: model variable, raw column (as named by cbh_attach_external()), annual panel, log scale.
cbh_substituted_covariates <- function() data.frame(variable = c("log_gdp_pc", "log_health_expenditure_pc", "political_stability"),
  raw = c("gdp_pc", "health_expenditure_pc", "political_stability"), panel = c("gdp", "health_spending", "governance"),
  log = c(TRUE, TRUE, FALSE), stringsAsFactors = FALSE)
# Whether a rule covers each (country, year).
cbh_national_substituted <- function(country, year, rules = cbh_national_substitutions()) {
  k <- match(as.character(country), rules$country); !is.na(k) & year < rules$before_year[k]
}
# The covered rows, with the source country's raw and model-scale values for the same year (NA where its panel has no
# valid value; callers decide whether a gap is allowed).
cbh_national_substitute <- function(country, year, cfg, rules = cbh_national_substitutions()) {
  row <- which(cbh_national_substituted(country, year, rules))
  out <- data.frame(row = row, country = as.character(country[row]), year = year[row], stringsAsFactors = FALSE)
  out$source_country <- rules$source_country[match(out$country, rules$country)]
  vars <- cbh_substituted_covariates()
  for (i in seq_len(nrow(vars))) {
    spec <- cfg$annual_panels[[vars$panel[i]]]; col <- spec$columns[[vars$raw[i]]]
    panel <- cbh_read_csv(spec$path); cbh_require(panel, c("iso3", "year", col), vars$panel[i]); cbh_unique(panel, c("iso3", "year"), vars$panel[i])
    v <- cbh_num(panel[[col]][match(paste(out$source_country, out$year), paste(panel$iso3, panel$year))])
    v[!(is.finite(v) & (!vars$log[i] | v > 0))] <- NA_real_   # finite, and positive where the model uses the log
    out[[vars$raw[i]]] <- v
    out[[vars$variable[i]]] <- if (vars$log[i]) log(v) else v
  }
  out
}
