# 05 — UN IGME all-cause under-5 mortality rate (U5MR) per country
# ---------------------------------------------------------------------------
# Source: World Bank indicator SH.DYN.MORT ("Mortality rate, under-5, per 1,000
# live births"), whose underlying estimates ARE the UN IGME series (World Bank
# republishes IGME). Public aggregate data. Fetched from api.worldbank.org.
# Output: data/igme_u5mr_by_country.csv  (iso3, country, u5mr, year)
# ---------------------------------------------------------------------------
suppressMessages({library(httr); library(jsonlite)})
PROJ <- getwd()   # run from the repository root

# 1) list of real countries (drop WB regional/income aggregates)
rc <- GET("https://api.worldbank.org/v2/country?format=json&per_page=400", timeout(60))
stopifnot(status_code(rc) == 200)
cj <- fromJSON(content(rc, "text", encoding = "UTF-8"), simplifyDataFrame = TRUE)[[2]]
countries <- data.frame(iso3 = cj$id, country = trimws(cj$name),
                        region = trimws(cj$region$value), stringsAsFactors = FALSE)
countries <- countries[countries$region != "Aggregates", ]

# 2) U5MR for recent years, all economies
u <- "https://api.worldbank.org/v2/country/all/indicator/SH.DYN.MORT?date=2015:2024&format=json&per_page=20000"
r <- GET(u, timeout(90))
stopifnot(status_code(r) == 200)
j <- fromJSON(content(r, "text", encoding = "UTF-8"), simplifyDataFrame = TRUE)[[2]]
d <- data.frame(iso3 = j$countryiso3code, year = as.integer(j$date),
                u5mr = as.numeric(j$value), stringsAsFactors = FALSE)
d <- d[!is.na(d$u5mr) & d$iso3 %in% countries$iso3, ]

# 3) most recent non-NA year per country
d <- d[order(d$iso3, -d$year), ]
latest <- d[!duplicated(d$iso3), ]
latest <- merge(latest, countries[, c("iso3", "country", "region")], by = "iso3")
latest <- latest[order(-latest$u5mr), ]

write.csv(latest[, c("iso3", "country", "region", "u5mr", "year")],
          file.path(PROJ, "data", "igme_u5mr_by_country.csv"), row.names = FALSE)
cat(sprintf("countries: %d  | year range: %d-%d  | U5MR range: %.1f-%.1f per 1,000\n",
            nrow(latest), min(latest$year), max(latest$year), min(latest$u5mr), max(latest$u5mr)))
cat("highest U5MR:\n"); print(head(latest[, c("country", "u5mr", "year")], 6), row.names = FALSE)
