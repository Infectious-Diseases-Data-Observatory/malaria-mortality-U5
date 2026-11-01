# =============================================================================
# 01_fetch_data.R — fetch the committed GPW population raster, African admin-0
# boundaries and World Bank GDP per capita into data/ (idempotent: each block is
# skipped if its output already exists). Run from the repo root.
#
# The other blocks (MAP 202508 raster, IGME, live births, DTP3, DHS survey
# universe and microdata) and the model helpers of 00_utils.R fed nothing the
# pipeline reads and were removed on 1 November 2026. MAP rasters:
# fetch_map_release_rasters.R; DHS recodes: 01_access_dhs_data.R.
# =============================================================================
suppressMessages({
  library(terra); library(sf); library(jsonlite); library(httr)
})
DATA    <- "data"
GPW_TIF <- file.path(DATA, "pop", "gpw_v4_population_density_rev11_2020_2.5m.tif")  # GPW density weight
dir.create(file.path(DATA, "pop"), showWarnings = FALSE, recursive = TRUE)

## ---- World Bank API (long format, with retries) ----------------------------
wb_fetch <- function(indicator, date = "2000:2024") {
  u <- sprintf("https://api.worldbank.org/v2/country/all/indicator/%s?date=%s&format=json&per_page=20000",
               indicator, date)
  for (attempt in 1:4) {
    r <- tryCatch(GET(u, timeout(180)), error = function(e) NULL)
    if (!is.null(r) && status_code(r) == 200) {
      j <- fromJSON(content(r, "text", encoding = "UTF-8"), simplifyDataFrame = TRUE)[[2]]
      d <- data.frame(iso3 = j$countryiso3code, year = as.integer(j$date),
                      value = as.numeric(j$value), stringsAsFactors = FALSE)
      return(d[!is.na(d$value) & nchar(d$iso3) == 3, ])
    }
    message("  World Bank retry ", attempt, " for ", indicator)
  }
  stop("World Bank fetch failed: ", indicator)
}

## ---- 1. GPW population-density raster (2020, 2.5 arc-min) -------------------
if (!file.exists(GPW_TIF)) {
  message("Downloading GPW population raster...")
  suppressMessages(library(geodata))
  geodata::population(year = 2020, res = 2.5, path = file.path(DATA, "pop"))
  hit <- list.files(file.path(DATA, "pop"), pattern = "gpw.*2020.*2\\.5m\\.tif$",
                    recursive = TRUE, full.names = TRUE)[1]
  if (!is.na(hit) && normalizePath(hit) != normalizePath(GPW_TIF)) file.copy(hit, GPW_TIF, overwrite = TRUE)
}

## ---- 2. Country boundaries (admin-0, African countries) --------------------
ADM0 <- file.path(DATA, "africa_admin0.rds")
if (!file.exists(ADM0)) {
  message("Building admin-0 boundaries...")
  suppressMessages(library(geodata))
  w <- geodata::world(path = file.path(DATA, "pop"))
  w$iso <- w$GID_0
  saveRDS(sf::st_as_sf(w[, "iso"]), ADM0)
}

## ---- 3. GDP per capita (country x year) ------------------------------------
GDP <- file.path(DATA, "wb_gdp_pc.csv")
if (!file.exists(GDP)) {
  message("Fetching GDP per capita (World Bank NY.GDP.PCAP.CD)...")
  g <- wb_fetch("NY.GDP.PCAP.CD"); names(g)[3] <- "gdp_pc"
  write.csv(g, GDP, row.names = FALSE)
}
message("01_fetch_data.R complete.")
