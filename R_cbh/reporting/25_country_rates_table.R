#!/usr/bin/env Rscript
# Supplementary table (user request, 28 October 2026): one row per burden country in 2024 with national MAP
# PfPR[2-10]; all-cause under-five deaths per 1,000 child-years from UN IGME and IHME; PfPR-ACM malaria-attributable
# deaths per 1,000 child-years from each all-cause source; and the cause-specific malaria estimates of UN IGME
# (CA-CODE) and of IHME, each with its share of all under-five deaths in brackets. Child-years are each source's own:
# UN WPP population under 5 for UN IGME and CA-CODE, IHME-implied person-years for IHME. All-cause rates and PfPR-ACM
# estimates are the crisis-free values of R_cbh/burden/04_annual_comparison.R. The IHME malaria share is IHME malaria
# over IHME all-cause deaths; the CA-CODE share is CA-CODE's published fraction (its denominator is its own sum over
# causes, as in R_cbh/reporting/20_malaria_share_vs_pfpr.R). The last row is the 42-country population-weighted
# average (PfPR weighted by the WPP population under 5; rates as total deaths over total child-years).
# Every pair of columns runs UN IGME then IHME; the table has no notes (user request, 31 October 2026), so the IHME
# crisis year and the WHO-based CA-CODE countries are flagged in the CSV only. Caption as edited by the author.
# From 1 November 2026 (author request): national PfPR is MAP's own national estimate, and the PfPR-ACM cells carry the
# 95% uncertainty interval of R_cbh/burden/06_uncertainty_draws.R in parentheses, so every share is in square brackets.
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

f1 <- function(x) formatC(x, format = "f", digits = 1)
f2 <- function(x) formatC(x, format = "f", digits = 2)
# Shares of all-cause deaths to the nearest whole percent (user request, 28 October 2026).
cell <- function(rate, share) sprintf("%s [%s]", f2(rate), formatC(100 * share, format = "f", digits = 0))
# Interval bounds to one decimal so that the table keeps to the page width (checked by compiling it), and to two below 1
# per 1,000 so that small rates keep their own interval; a bound that rounds to -0.00 prints as 0.00.
fb <- function(x) sub("^-(0[.]0+)$", "\\1", ifelse(abs(x) < 1, f2(x), f1(x)))
cell_ui <- function(rate, lo, hi, share) sprintf("%s (%s--%s) [%s]", f2(rate), fb(lo), fb(hi), formatC(100 * share, format = "f", digits = 0))
stopifnot(!any(w$crisis_year_unigme))
rows <- w[, sprintf("%s & %s & %s & %s & %s & %s & %s & %s \\\\", country, f1(pfpr_pct), f1(allcause_rate_per1000_unigme),
  f1(allcause_rate_per1000_ihme), cell_ui(malaria_rate_per1000_unigme, malaria_rate_per1000_lower_unigme, malaria_rate_per1000_upper_unigme, malaria_fraction_unigme),
  cell_ui(malaria_rate_per1000_ihme, malaria_rate_per1000_lower_ihme, malaria_rate_per1000_upper_ihme, malaria_fraction_ihme), cell(cacode_malaria_rate, cacode_share),
  cell(ihme_malaria_rate, ihme_malaria_share))]
tex <- c("% Replacement table source; saved as plain text. No manuscript file is edited.",
  "% Generated by R_cbh/reporting/25_country_rates_table.R.",
  # Fits one page of the paper (12 pt article, 1 in margins: 6.5 x 9 in) with 42 rows at \footnotesize.
  "\\begin{table}[p]", "\\centering", "\\footnotesize", "\\setlength{\\tabcolsep}{1.75pt}", "\\renewcommand{\\arraystretch}{0.77}",
  sprintf("\\caption{National malaria prevalence (\\textit{Pf}PR$_{2-10}$, the Malaria Atlas Project's national estimates) and under-five mortality in %d, by country: all-cause deaths, \\textit{Pf}PR-ACM malaria-attributable deaths and cause-specific malaria deaths per 1,000 child-years (cy), with the share of all under-five deaths (\\%%) shown in square brackets and, for \\textit{Pf}PR-ACM, the 95\\%% uncertainty interval in parentheses.}", table_year),
  "\\label{stab:country_rates}",
  "\\begin{tabular}{lrrrrrrr}", "\\toprule",
  # Group headers on two lines each, so that none is wider than its two columns.
  paste(" & & \\multicolumn{2}{c}{\\begin{tabular}[b]{@{}c@{}}All-cause\\\\per 1000 cy\\end{tabular}}",
    "\\multicolumn{2}{c}{\\begin{tabular}[b]{@{}c@{}}\\textit{Pf}PR-ACM\\\\model (\\%)\\end{tabular}}",
    "\\multicolumn{2}{c}{\\begin{tabular}[b]{@{}c@{}}Malaria mortality\\\\models (\\%)\\end{tabular}} \\\\", sep = " & "),
  "\\cmidrule(lr){3-4} \\cmidrule(lr){5-6} \\cmidrule(lr){7-8}",
  "Country & \\begin{tabular}[b]{@{}c@{}}\\textit{Pf}PR$_{2-10}$\\\\(\\%)\\end{tabular} & UN IGME & IHME & \\begin{tabular}[b]{@{}c@{}}UN IGME-\\\\based\\end{tabular} & \\begin{tabular}[b]{@{}c@{}}IHME-\\\\based\\end{tabular} & UN IGME & IHME \\\\",
  "\\midrule", rows, "\\midrule",
  sprintf("All %d countries & %s & %s & %s & %s & %s & %s & %s \\\\", nrow(w), f1(avg$pfpr), f1(avg$ac_g), f1(avg$ac_i),
    cell_ui(avg$m_g, avg$m_g_lo, avg$m_g_hi, avg$f_g), cell_ui(avg$m_i, avg$m_i_lo, avg$m_i_hi, avg$f_i), cell(avg$cc, avg$cc_f), cell(avg$ih, avg$ih_f)),
  "\\bottomrule", "\\end{tabular}", "\\end{table}")
writeLines(tex, file.path(out, sprintf("country_rates_%d.latex.txt", table_year)))
provenance <- c(unname(paths), "R_cbh/reporting/25_country_rates_table.R", "R_cbh/primary/settings.R")
cbh_atomic_csv(data.frame(file = provenance, md5 = vapply(provenance, cbh_file_hash, "")), file.path(out, "provenance_country_rates.csv"))
message(sprintf("Country rates table for %d: %d countries", table_year, nrow(w)))
