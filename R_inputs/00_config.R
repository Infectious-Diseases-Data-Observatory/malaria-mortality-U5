# =============================================================================
# R_inputs/00_config.R
# Shared configuration for the input producers in R_inputs/ (survey-region MAP
# PfPR, UNICEF immunisation panel) and the network fetch scripts in R_inputs/fetch/.
#
# Exact-line subset of R_dhs/00_config.R from the analysis project: only the
# definitions these scripts use are kept (tools/check_trimmed_config.R checks
# that every kept definition is unchanged). Deliberate edits: the repository-root
# check names this file; raw DHS recodes live in data/raw/dhs (no rdhs cache
# fallback) and local_recode_path() returns repository-relative paths; the UNICEF
# dump is the immunisation extract made by R_inputs/trim_unicef_fusion.R; status
# tables go to results/inputs.
# Run all scripts from the repository root.
# =============================================================================

options(stringsAsFactors = FALSE)

REPO_ROOT <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(REPO_ROOT, "R_inputs", "00_config.R"))) {
  stop("Run the input scripts from the repository root.")
}


DATA_DIR       <- file.path(REPO_ROOT, "data")
DERIVED_DIR    <- file.path(DATA_DIR, "derived_dhs")
RESULTS_DIR    <- file.path(REPO_ROOT, "results", "inputs")
DHS_LOCAL_DIR  <- file.path(DATA_DIR, "raw", "dhs")
BOUNDARY_DIR   <- file.path(DATA_DIR, "dhs_boundaries")
MAP_RASTER_DIR <- file.path(DATA_DIR, "map_annual")
MAP_REGION_DIR <- file.path(DATA_DIR, "map_region_cache")
UNICEF_GLOBAL_CSV <- file.path(
  DATA_DIR, "unicef", "fusion_GLOBAL_DATAFLOW_UNICEF_1.0_immunisation_subset.csv"
)
UNICEF_IMMUNISATION_CSV <- file.path(
  DERIVED_DIR, "unicef_immunisation_country_year.csv"
)
UNICEF_IMMUNISATION_SUMMARY_CSV <- file.path(
  RESULTS_DIR, "unicef_immunisation_extraction_summary.csv"
)

for (d in c(DERIVED_DIR, RESULTS_DIR, BOUNDARY_DIR, MAP_RASTER_DIR, MAP_REGION_DIR)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

DHS_START_YEAR <- 2000L
DHS_END_YEAR   <- 2025L

MAP_DATASET_ID <- "Malaria__202508_Global_Pf_Parasite_Rate"
MAP_AFRICA_EXTENT <- matrix(c(-18, -35, 52, 38), nrow = 2)
GPW_TIF <- file.path(
  DATA_DIR, "pop",
  "gpw_v4_population_density_rev11_2020_2.5m.tif"
)

SURVEY_REGISTRY_CSV <- file.path(DERIVED_DIR, "survey_registry.csv")
MAP_REGION_CSV      <- file.path(DERIVED_DIR, "map_pfpr_by_survey_region.csv")
MAP_STATUS_CSV      <- file.path(RESULTS_DIR, "map_extraction_status.csv")

STATCOMPILER_CSV    <- file.path(DERIVED_DIR, "statcompiler_covariates.csv")
STATCOMPILER_INDICATORS <- c(
  imp_water = "WS_SRCE_H_IMP",   # households using an improved water source (%)
  imp_sanit = "WS_TLET_H_IMP",   # households with an improved sanitation facility (%)
  wasting   = "CN_NUTS_C_WH2"    # children under 5 with weight-for-height < -2 SD (%)
)

required_packages <- function(packages) {
  missing <- packages[
    !vapply(packages, requireNamespace, logical(1), quietly = TRUE)
  ]
  if (length(missing)) {
    stop(
      "Missing required packages: ", paste(missing, collapse = ", "),
      ". Install only after confirming they are on the approved package list."
    )
  }
  invisible(TRUE)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

.CP1250_TO_LATIN1 <- local({
  bytes <- as.raw(128:255)
  decode <- function(from) {
    vapply(bytes, function(b) {
      tryCatch(iconv(rawToChar(as.raw(b)), from, "UTF-8"),
               error = function(e) NA_character_)
    }, character(1))
  }
  cp1250 <- decode("CP1250")
  latin1 <- decode("ISO-8859-1")
  keep <- !is.na(cp1250) & !is.na(latin1) &
    grepl("^[[:alpha:]]$", cp1250) & grepl("^[[:alpha:]]$", latin1) &
    is.na(suppressWarnings(iconv(cp1250, "UTF-8", "ISO-8859-1")))
  list(from = paste(cp1250[keep], collapse = ""),
       to = paste(latin1[keep], collapse = ""))
})

rkey <- function(x) {
  s <- as.character(x)
  if (nzchar(.CP1250_TO_LATIN1$from)) {
    s <- chartr(.CP1250_TO_LATIN1$from, .CP1250_TO_LATIN1$to, s)
  }
  # sub = "" drops any character iconv cannot transliterate instead of
  # returning NA for the whole string, which would silently void the key and
  # drop the region. Transliterable accents are unaffected.
  gsub(
    "[^a-z0-9]", "",
    tolower(iconv(s, "", "ASCII//TRANSLIT", sub = ""))
  )
}

survey_key <- function(filename) {
  x <- toupper(sub("\\..*$", "", basename(filename)))
  paste0(substr(x, 1, 2), substr(x, 5, 8))
}

local_recode_path <- function(no_extension) {
  # Repository-relative path to a raw DHS recode (data/raw/dhs), NA if absent.
  candidate <- file.path("data", "raw", "dhs", paste0(no_extension, ".rds"))
  if (file.exists(candidate)) candidate else NA_character_
}

wb_fetch <- function(indicator, date = "2000:2025") {
  required_packages(c("httr", "jsonlite"))
  url <- sprintf(
    paste0(
      "https://api.worldbank.org/v2/country/all/indicator/%s",
      "?date=%s&format=json&per_page=20000"
    ),
    indicator, date
  )
  for (attempt in seq_len(4)) {
    response <- tryCatch(
      httr::GET(url, httr::timeout(180)),
      error = function(e) NULL
    )
    if (!is.null(response) && httr::status_code(response) == 200) {
      parsed <- jsonlite::fromJSON(
        httr::content(response, "text", encoding = "UTF-8"),
        simplifyDataFrame = TRUE
      )
      # A retired or renamed indicator still returns HTTP 200, with the reason
      # in a one-element "message" payload rather than the usual two-element
      # [metadata, data] list. Report that instead of failing on a subscript.
      if (is.data.frame(parsed) && "message" %in% names(parsed)) {
        stop(
          "World Bank rejected indicator ", indicator, ": ",
          tryCatch(parsed$message[[1]]$value[1],
                   error = function(e) "unknown reason")
        )
      }
      if (!is.list(parsed) || length(parsed) < 2 || is.null(parsed[[2]])) {
        stop("World Bank returned no data for indicator ", indicator)
      }
      payload <- parsed[[2]]
      out <- data.frame(
        iso3 = payload$countryiso3code,
        year = as.integer(payload$date),
        value = as.numeric(payload$value)
      )
      return(out[is.finite(out$value) & nchar(out$iso3) == 3, ])
    }
    message("World Bank retry ", attempt, " for ", indicator)
  }
  stop("World Bank fetch failed: ", indicator)
}

read_or_fetch_wb <- function(filename, indicator, value_name) {
  path <- file.path(DATA_DIR, filename)
  if (file.exists(path)) {
    out <- read.csv(path, stringsAsFactors = FALSE)
  } else {
    message("Fetching World Bank indicator ", indicator, " -> ", filename)
    # An indicator the Bank has archived must not abort the whole rebuild. The
    # covariate simply stays missing and the existing missingness rule drops it,
    # which is what already happens to any series we cannot populate.
    out <- tryCatch(wb_fetch(indicator), error = function(e) {
      warning("World Bank indicator ", indicator, " unavailable (",
              conditionMessage(e), "); ", value_name,
              " will be left missing.", call. = FALSE)
      NULL
    })
    if (is.null(out)) {
      empty <- data.frame(iso3 = character(0), year = integer(0),
                          stringsAsFactors = FALSE)
      empty[[value_name]] <- numeric(0)
      return(empty)
    }
    names(out)[names(out) == "value"] <- value_name
    write.csv(out, path, row.names = FALSE)
  }
  if (!value_name %in% names(out) && "value" %in% names(out)) {
    names(out)[names(out) == "value"] <- value_name
  }
  out
}


statcompiler_clean_label <- function(x) {
  x <- as.character(x)
  x <- gsub("\\([^)]*\\)", " ", x)
  x <- gsub("^[. ]+", "", x)
  x <- gsub("(^| )(19|20)[0-9]{2}( |$)", " ", x)
  x <- gsub("[[:space:]]+", " ", x)
  trimws(x)
}
