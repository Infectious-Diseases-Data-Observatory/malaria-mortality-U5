#!/usr/bin/env Rscript
# Supplementary table (user request, 28 October 2026; simplified to UN IGME and CA-CODE on 18 November 2026): one row
# per burden country in 2024 with national MAP PfPR[2-10]; all-cause under-five deaths per 1,000 child-years (UN IGME);
# PfPR-ACM malaria-attributable deaths per 1,000 child-years with their 95% uncertainty interval
# (R_cbh/burden/06_uncertainty_draws.R) and share of all under-five deaths; and CA-CODE malaria deaths per 1,000
# child-years with their share. Child-years are the UN WPP population under 5. All-cause rates and PfPR-ACM estimates
# are the crisis-free values of R_cbh/burden/04_annual_comparison.R. The CA-CODE share is CA-CODE's published fraction
# (its denominator is its own sum over causes, as in R_cbh/reporting/20_malaria_share_vs_pfpr.R). The last row is the
# 42-country population-weighted average (PfPR weighted by the WPP population under 5; rates as total deaths over
# total child-years). Rows run from highest to lowest national PfPR; the table has no notes (user request, 31 October
# 2026), so the WHO-based CA-CODE countries are flagged in the CSV only.
# The CSV keeps the IHME-based columns (all-cause, PfPR-ACM and IHME malaria deaths over IHME person-years), which
# the IHME supplementary figure reads (R_cbh/reporting/27_model_vs_cause_specific.R); the LaTeX table has none.
# Outputs (<out>/tables/): country_rates_2024.csv, country_rates_2024.latex.txt (LaTeX source saved as text, like
# the other paper tables; no manuscript file is edited), provenance_country_rates.csv.
source("R_cbh/load_pipeline.R")
source("R_cbh/primary/settings.R")
suppressPackageStartupMessages(library(data.table))
st <- cbh_primary_settings(Sys.getenv("CBH_PRIMARY_VERSION", "gadm"))
out <- file.path(st$out, "tables"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
table_year <- 2024L
paths <- c(rates = file.path(st$out, "annual_comparison/source_country_rates_2000_2024.csv"),
  totals = file.path(st$out, "annual_comparison/source_annual_rates_2000_2024.csv"),
  estimates = file.path(st$out, "annual_comparison/country_estimates_2000_2024.csv"),
  cacode = "data/external/cacode/unicef_cacode_u5_malaria_fraction_2000_2024.csv",
  ui = file.path(st$out, "uncertainty/country_year_intervals_2000_2024.csv"),
  ui_annual = file.path(st$out, "uncertainty/annual_intervals_2000_2024.csv"))
stopifnot(all(file.exists(paths)))
r <- fread(paths[["rates"]])[year == table_year]
w <- dcast(r, iso3 + pfpr_pct ~ source, value.var = c("allcause_rate_per1000", "allcause_rate_per1000_reported",
  "malaria_rate_per1000", "malaria_fraction", "under5_person_years", "crisis_year"))
setnames(w, names(w), sub("_UN IGME$", "_unigme", sub("_IHME$", "_ihme", names(w))))
est <- fread(paths[["estimates"]])[year == table_year,
  .(iso3, ihme_malaria_deaths, who_cacode_deaths, ihme_allcause_deaths = allcause_deaths, ihme_py = under5_person_years)]
cacode <- fread(paths[["cacode"]])[TIME_PERIOD == table_year & nchar(REF_AREA) == 3L &
  INDICATOR == "FRACTION" & CAUSE_OF_DEATH == "MALARIA" & AGE_GROUP == "Y0T4" & SEX == "_T",
  .(iso3 = REF_AREA, cacode_share = OBS_VALUE / 100)]
cbh_unique(as.data.frame(cacode), "iso3", "CA-CODE malaria fraction")
ui <- fread(paths[["ui"]])[year == table_year]
uw <- dcast(ui, iso3 + pfpr_pct_lower + pfpr_pct_upper ~ source, value.var = c("malaria_rate_per1000", "malaria_rate_per1000_lower",
  "malaria_rate_per1000_upper"))
setnames(uw, names(uw), sub("_UN IGME$", "_unigme", sub("_IHME$", "_ihme", names(uw))))
setnames(uw, c("malaria_rate_per1000_unigme", "malaria_rate_per1000_ihme"), c("ui_point_unigme", "ui_point_ihme"))
w <- merge(merge(merge(w, est, by = "iso3"), cacode, by = "iso3"), uw, by = "iso3")
# The interval file must belong to the same point estimates.
stopifnot(max(abs(w$ui_point_unigme - w$malaria_rate_per1000_unigme)) < 1e-9, max(abs(w$ui_point_ihme - w$malaria_rate_per1000_ihme)) < 1e-9)
stopifnot(nrow(w) == 42L, !anyNA(w), max(abs(w$ihme_py / w$under5_person_years_ihme - 1)) < 1e-9)
w[, `:=`(ihme_malaria_rate = 1000 * ihme_malaria_deaths / ihme_py, ihme_malaria_share = ihme_malaria_deaths / ihme_allcause_deaths,
  cacode_malaria_rate = 1000 * who_cacode_deaths / under5_person_years_unigme)]
# CA-CODE takes malaria from WHO estimates in these low-burden countries (the published flag, as in
# R_cbh/reporting/20_malaria_share_vs_pfpr.R).
who_malaria <- c("BWA", "COM", "CPV", "DJI", "ERI", "ETH", "MDG", "SDN", "SOM", "STP", "SWZ", "ZAF", "ZWE")
w[, who_based := iso3 %in% who_malaria]
# Short names keep the country column no wider than "All 42 countries", so that the table with intervals fits the page.
names_short <- c(CAF = "C. African Rep.", CIV = "Côte d'Ivoire", COD = "DR Congo", COG = "Rep. of Congo",
  GMB = "The Gambia", GNQ = "Eq. Guinea", SWZ = "Eswatini", TZA = "Tanzania")
w[, country := fifelse(iso3 %in% names(names_short), names_short[iso3], countrycode::countrycode(iso3, "iso3c", "country.name"))]
# Rows from highest to lowest national PfPR (user request, 28 October 2026).
w <- w[order(-pfpr_pct, country)]
cols <- c("iso3", "country", "pfpr_pct", "pfpr_pct_lower", "pfpr_pct_upper", "allcause_rate_per1000_unigme", "allcause_rate_per1000_ihme",
  "allcause_rate_per1000_reported_ihme", "crisis_year_ihme", "crisis_year_unigme", "malaria_rate_per1000_unigme",
  "malaria_rate_per1000_lower_unigme", "malaria_rate_per1000_upper_unigme", "malaria_fraction_unigme", "malaria_rate_per1000_ihme",
  "malaria_rate_per1000_lower_ihme", "malaria_rate_per1000_upper_ihme", "malaria_fraction_ihme", "ihme_malaria_rate",
  "ihme_malaria_share", "cacode_malaria_rate", "cacode_share", "who_based")
cbh_atomic_csv(w[, ..cols], file.path(out, sprintf("country_rates_%d.csv", table_year)))

# 42-country population-weighted averages.
tot <- fread(paths[["totals"]])[year == table_year]
ti <- tot[source == "IHME"]; tg <- tot[source == "UN IGME"]
stopifnot(nrow(ti) == 1L, nrow(tg) == 1L, abs(sum(w$under5_person_years_unigme) - tg$under5_person_years) < 1)
avg <- list(pfpr = tg$pfpr_pct_wpp_weighted, ac_g = tg$allcause_rate_per1000, ac_i = ti$allcause_rate_per1000,
  m_g = tg$malaria_rate_per1000, f_g = tg$malaria_fraction, m_i = ti$malaria_rate_per1000, f_i = ti$malaria_fraction,
  ih = 1000 * sum(w$ihme_malaria_deaths) / sum(w$ihme_py), ih_f = sum(w$ihme_malaria_deaths) / sum(w$ihme_allcause_deaths),
  cc = 1000 * sum(w$who_cacode_deaths) / sum(w$under5_person_years_unigme),
  # CA-CODE's all-cause total is malaria deaths over its malaria share; where the share is 0 (no malaria deaths),
  # UN IGME's all-cause deaths stand in for it.
  cc_f = sum(w$who_cacode_deaths) / sum(ifelse(w$cacode_share > 0, w$who_cacode_deaths / w$cacode_share,
    w$allcause_rate_per1000_unigme * w$under5_person_years_unigme / 1000)))
ua <- fread(paths[["ui_annual"]])[scenario == "main" & year == table_year]
stopifnot(abs(ua[source == "UN IGME"]$malaria_rate_per1000 - avg$m_g) < 1e-9, abs(ua[source == "IHME"]$malaria_rate_per1000 - avg$m_i) < 1e-9)
avg$m_g_lo <- ua[source == "UN IGME"]$malaria_rate_per1000_lower; avg$m_g_hi <- ua[source == "UN IGME"]$malaria_rate_per1000_upper
avg$m_i_lo <- ua[source == "IHME"]$malaria_rate_per1000_lower; avg$m_i_hi <- ua[source == "IHME"]$malaria_rate_per1000_upper
stopifnot(all(w$who_cacode_deaths[w$cacode_share == 0] == 0), all(is.finite(unlist(avg))))

# Every rate per 1,000 child-years and its interval to one decimal (author request, 18 November 2026; two decimals
# before); a value that rounds to -0.0 prints as 0.0.
f1 <- function(x) sub("^-(0[.]0)$", "\\1", formatC(x, format = "f", digits = 1))
# Shares of all-cause deaths to the nearest whole percent (user request, 28 October 2026).
pct <- function(share) formatC(100 * share, format = "f", digits = 0)
rate_ui <- function(rate, lo, hi) sprintf("%s (%s--%s)", f1(rate), f1(lo), f1(hi))
stopifnot(!any(w$crisis_year_unigme))
# The LaTeX table (simplified on 18 November 2026, author request): UN IGME and CA-CODE only, one value per cell.
# The IHME-based columns were removed from the table; they stay in the CSV, which the IHME supplementary figure reads.
row <- function(name, pfpr, allcause, m, lo, hi, share, cc, cc_share)
  sprintf("%s & %s & %s & %s & %s & %s & %s \\\\", name, f1(pfpr), f1(allcause), rate_ui(m, lo, hi), pct(share), f1(cc), pct(cc_share))
rows <- w[, row(country, pfpr_pct, allcause_rate_per1000_unigme, malaria_rate_per1000_unigme, malaria_rate_per1000_lower_unigme,
  malaria_rate_per1000_upper_unigme, malaria_fraction_unigme, cacode_malaria_rate, cacode_share)]
two <- function(a, b) paste0("\\begin{tabular}[b]{@{}c@{}}", a, "\\\\", b, "\\end{tabular}")   # a two-line column header
tex <- c("% Replacement table source; saved as plain text. No manuscript file is edited.",
  "% Generated by R_cbh/reporting/25_country_rates_table.R.",
  # Fits one page of the paper (12 pt article, 1 in margins: 6.5 x 9 in) with 42 rows at \footnotesize.
  "\\begin{table}[p]", "\\centering", "\\footnotesize", "\\setlength{\\tabcolsep}{5pt}", "\\renewcommand{\\arraystretch}{0.85}",
  sprintf("\\caption{National malaria prevalence (\\textit{Pf}PR$_{2-10}$, MAP national estimates) and under-five mortality in %d, by country: all-cause deaths (UN IGME), \\textit{Pf}PR-ACM malaria-attributable deaths with 95\\%% uncertainty intervals, and CA-CODE malaria deaths, per 1,000 child-years, each with its share of all under-five deaths.}", table_year),
  "\\label{stab:country_rates}",
  "\\begin{tabular}{lrrrrrr}", "\\toprule",
  " & & & \\multicolumn{2}{c}{\\textit{Pf}PR-ACM model} & \\multicolumn{2}{c}{CA-CODE} \\\\",
  "\\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  paste0(paste("Country", two("\\textit{Pf}PR$_{2-10}$", "(\\%)"), two("All-cause deaths", "per 1,000"), two("Deaths per 1,000", "(95\\% UI)"),
    two("\\% of", "deaths"), two("Deaths", "per 1,000"), two("\\% of", "deaths"), sep = " & "), " \\\\"),
  "\\midrule", rows, "\\midrule",
  row(sprintf("All %d countries", nrow(w)), avg$pfpr, avg$ac_g, avg$m_g, avg$m_g_lo, avg$m_g_hi, avg$f_g, avg$cc, avg$cc_f),
  "\\bottomrule", "\\end{tabular}", "\\end{table}")
writeLines(tex, file.path(out, sprintf("country_rates_%d.latex.txt", table_year)))
provenance <- c(unname(paths), "R_cbh/reporting/25_country_rates_table.R", "R_cbh/primary/settings.R")
cbh_atomic_csv(data.frame(file = provenance, md5 = vapply(provenance, cbh_file_hash, "")), file.path(out, "provenance_country_rates.csv"))
message(sprintf("Country rates table for %d: %d countries", table_year, nrow(w)))
