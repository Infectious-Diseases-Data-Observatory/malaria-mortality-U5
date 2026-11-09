#!/usr/bin/env Rscript
# Table of the countries in the Sahel subset (analysis units with centroid >= 10N; user request, 4 November 2026), one
# row per country: surveys, survey-units, deaths, and the median (interquartile range) across survey-units of PfPR2-10
# and of crude mortality by age band (deaths per 1,000 child-years). Rows for the whole subset and for the full primary
# sample follow, for comparison. A survey-unit is the model's survey x unit area; only its records in the subset count.
# The PfPR of a survey-unit is the child-year-weighted mean over its records (PfPR varies by calendar year); medians and
# quartiles are unweighted (each survey-unit counts once; R's default type 7). The units of each country that the
# subset includes are listed where they are not all of the country's units in the primary sample.
# Outputs (st$out): table_sahel_countries.csv, .md and .latex.txt (LaTeX source saved as text; no manuscript file
# is edited), and sahel_table_provenance.csv.
suppressPackageStartupMessages(library(data.table))
source("R_cbh/load_pipeline.R"); source("R_cbh/primary/settings.R"); source("R_cbh/sensitivity/subgroups/settings.R")
st <- cbh_subgroup_settings(); P <- cbh_primary_settings(st$primary_version)
s <- "sahel"; stopifnot(s %in% st$subgroups)
bound <- sprintf("%g\u00b0N", st$sahel$latitude_min)
paths <- c(data = P$data, sahel_units = file.path(st$out, "sahel_units.csv"), samples = file.path(st$out, "sample_summary.csv"),
  names = file.path(P$out, "analysis_units_map/analysis_units_by_polygon.csv"),
  script = "R_cbh/sensitivity/subgroups/05_sahel_country_table.R", settings = "R_cbh/sensitivity/subgroups/settings.R")
stopifnot(all(file.exists(paths)))

x <- readRDS(paths[["data"]])$data
d <- data.table(src = paste(as.character(x$country), as.character(x$survey), as.character(x$regkey), sep = ":"),
  country = as.character(x$country), survey = as.character(x$survey), area = as.character(x$region),
  unit = as.character(x$unit), age_band = as.character(x$age_band), death = as.integer(x$death), cy = x$band_years,
  pfpr = x$pfpr_pct)
rm(x); invisible(gc())
su <- as.data.table(cbh_read_csv(paths[["sahel_units"]]))
stopifnot(!anyDuplicated(su$unit), all(d$unit %in% su$unit))
d[, inside := unit %in% su[as.logical(sahel), unit]]
samp <- as.data.table(cbh_read_csv(paths[["samples"]]))[subgroup == s]
stopifnot(nrow(samp) == 1L, d[(inside), .N] == samp$records, d[(inside), sum(death)] == samp$deaths,
  d[(inside), uniqueN(area)] == samp$survey_regions, d[(inside), uniqueN(country)] == samp$countries)
ages <- cbh_config()$age_bands$age_band

## Survey-unit values, then median and quartiles by row -------------------------------------------------------------
summarise <- function(z, label, iso3) {
  a <- z[, .(pfpr = weighted.mean(pfpr, cy)), by = area]
  r <- z[, .(rate = 1000 * sum(death) / sum(cy)), by = .(area, age_band)]
  q <- function(v) setNames(as.numeric(quantile(v, c(.5, .25, .75), names = FALSE)), c("median", "q25", "q75"))
  out <- as.data.table(c(list(row = label, iso3 = iso3, surveys = uniqueN(z$survey), survey_units = nrow(a), deaths = sum(z$death)),
    as.list(setNames(q(a$pfpr), paste0("pfpr_", c("median", "q25", "q75"))))))
  for (b in ages) { v <- r[age_band == b, rate]
    out <- cbind(out, as.data.table(as.list(setNames(c(q(v), length(v)), paste0("rate_", b, "_", c("median", "q25", "q75", "n")))))) }
  out
}
inn <- d[(inside)]
countries <- sort(unique(inn$country))
cname <- setNames(countrycode::countrycode(countries, "iso3c", "country.name"), countries)
rows <- rbindlist(c(lapply(countries[order(cname[countries])], function(k) summarise(inn[country == k], cname[[k]], k)),
  list(summarise(inn, sprintf("Sahel (\u2265%s), all %d countries", bound, length(countries)), "sahel"),
       summarise(d, sprintf("Full primary sample (%d countries)", uniqueN(d$country)), "map_full"))))
# Every survey-unit has records in every age band (the medians are over the same survey-units in each column).
stopifnot(all(as.matrix(rows[, paste0("rate_", ages, "_n"), with = FALSE]) == rows$survey_units))
stopifnot(nrow(rows) == length(countries) + 2L, rows[iso3 == "sahel", deaths] == samp$deaths, sum(rows[iso3 %in% countries, deaths]) == samp$deaths)

## Units included, for the countries only partly in the subset --------------------------------------------------------
ru <- d[, .(records = .N, records_in = sum(inside)), by = .(country, unit)]
pp <- ru[, .(Admin_ID = strsplit(unit, "+", fixed = TRUE)[[1]]), by = .(country, unit, records, records_in)][
  , .(records = sum(records), records_in = sum(records_in)), by = .(country, Admin_ID)]
nm <- as.data.table(cbh_read_csv(paths[["names"]]))
pp[nm, on = "Admin_ID", name := i.unit_name]; stopifnot(!anyNA(pp$name))
# "All" when every unit is in; the excluded units when fewer than the included ones ("All except"); else the included.
describe_units <- function(name, records, records_in) {
  full <- records_in == records; none <- records_in == 0; part <- !full & !none
  if (all(full)) return("All")
  parts <- if (any(part)) paste0(paste(sort(name[part]), collapse = ", "), " (part)") else character()
  if (sum(none) < sum(!none)) return(paste0("All except ", paste(sort(name[none]), collapse = ", "), if (length(parts)) paste0("; ", parts) else ""))
  paste(c(sort(name[full]), parts), collapse = ", ")
}
loc <- pp[country %in% countries, .(units_included = describe_units(name, records, records_in), units_in = sum(records_in > 0),
  units_country = .N), by = .(iso3 = country)]
rows[loc, on = "iso3", `:=`(units_included = i.units_included, units_in = i.units_in, units_country = i.units_country)]
cbh_atomic_csv(as.data.frame(rows), file.path(st$out, "table_sahel_countries.csv"))

## Formatted versions ------------------------------------------------------------------------------------------------
digits <- c(pfpr = 0, setNames(c(0, 0, 0, 1, 1, 1, 1), ages))
f <- function(v, k) formatC(v, format = "f", digits = k, big.mark = ",")
cell <- function(r, key, k, sep) sprintf("%s%s(%s%s%s)", f(r[[paste0(key, "_median")]], k), sep[1], f(r[[paste0(key, "_q25")]], k), sep[2],
  f(r[[paste0(key, "_q75")]], k))
age_head <- ifelse(ages == "<1", "<1", ages)
md <- c(paste0("| Country | Surveys | Survey-units | Deaths | PfPR2-10 (%) | ", paste(paste(age_head, "mo"), collapse = " | "), " | Units included |"),
  paste0("|---|", paste(rep("---:", 4 + length(ages)), collapse = "|"), "|---|"))
for (i in seq_len(nrow(rows))) { r <- rows[i]
  md <- c(md, paste0("| ", r$row, " | ", r$surveys, " | ", f(r$survey_units, 0), " | ", f(r$deaths, 0), " | ",
    cell(r, "pfpr", 0, c(" ", "–")), " | ", paste(vapply(ages, function(b) cell(r, paste0("rate_", b), digits[[b]], c(" ", "–")), ""), collapse = " | "),
    " | ", if (is.na(r$units_included)) "" else r$units_included, " |")) }
caption <- paste0("Countries in the Sahel sub-analysis (records whose analysis unit, an admin-1 unit or a union of units, has its centroid at or north of ", bound, " and west of ", st$sahel$longitude_max, "\u00b0E, excluding the Horn of Africa): ",
  "numbers of surveys, survey-units (a survey's records in one analysis unit) and deaths, and the median (interquartile range) across survey-units of ",
  "PfPR2-10 (MAP, the child-year-weighted mean over each survey-unit's records) and of crude mortality by age band (deaths per 1,000 child-years; ",
  "for the first month, 1,000 child-years correspond to about 12,000 births). Medians and quartiles are unweighted. The last two rows give the whole subset and the full primary sample.")
writeLines(c("# Table: countries in the Sahel sub-analysis", "", caption, "", md, "",
  paste0("Units included: the GADM admin-1 units with records in the subset; \"All\" where these are all the country's units in the primary sample, and \"All except\" where fewer are left out than included",
    if (any(grepl("(part)", rows$units_included, fixed = TRUE))) paste0("; \"(part)\" where only some of a unit's records are in the subset (its other records were placed in a union of units whose centroid lies south of ", bound, ")") else "", ".")),
  file.path(st$out, "table_sahel_countries.md"))

tex_escape <- function(z) gsub("&", "\\\\&", z)
two <- function(a, b) sprintf("\\begin{tabular}[t]{@{}r@{}}%s\\\\(%s)\\end{tabular}", a, b)
tcell <- function(r, key, k) two(f(r[[paste0(key, "_median")]], k), paste0(f(r[[paste0(key, "_q25")]], k), "--", f(r[[paste0(key, "_q75")]], k)))
body <- character()
for (i in seq_len(nrow(rows))) { r <- rows[i]
  # Summary rows on two lines, so that the label column is no wider than the country names.
  lab <- if (r$iso3 == "sahel") sprintf("\\begin{tabular}[t]{@{}l@{}}Sahel ($\\geq$%g\\textdegree N)\\\\(%d countries)\\end{tabular}", st$sahel$latitude_min, length(countries)) else
    if (r$iso3 == "map_full") sprintf("\\begin{tabular}[t]{@{}l@{}}Full sample\\\\(%d countries)\\end{tabular}", uniqueN(d$country)) else r$row
  if (i == length(countries) + 1L) body <- c(body, "\\midrule")
  body <- c(body, paste0(tex_escape(lab), " & ", r$surveys, " & ", f(r$survey_units, 0), " & ", f(r$deaths, 0), " & ", tcell(r, "pfpr", 0), " & ",
    paste(vapply(ages, function(b) tcell(r, paste0("rate_", b), digits[[b]]), ""), collapse = " & "), " \\\\[1pt]")) }
partial <- rows[iso3 %in% countries & units_included != "All"]
any_part <- any(grepl("(part)", partial$units_included, fixed = TRUE))
notes <- paste0("Units included where not all of a country's units are", if (any_part) paste0(" (``part'': only some of the unit's records are in the subset, the others placed in a union of units whose centroid lies south of ", st$sahel$latitude_min, "\\textdegree N)") else "", ": ",
  paste(sprintf("%s: %s", partial$row, tex_escape(sub("^All except", "all except", partial$units_included))), collapse = "; "), ". Every unit is included for the other countries.")
tex <- c("% Replacement table source; saved as plain text. No manuscript file is edited.",
  "% Generated by R_cbh/sensitivity/subgroups/05_sahel_country_table.R.",
  "\\begin{table}[p]", "\\centering", "\\scriptsize", "\\setlength{\\tabcolsep}{1.5pt}",
  paste0("\\caption{", gsub("PfPR2-10", "\\\\textit{Pf}PR$_{2-10}$", gsub("\u00b0([NE])", "\\\\textdegree \\1", caption)), "}"),
  "\\label{stab:sahel_countries}", "\\begin{tabular}{lrrrrrrrrrrr}", "\\toprule",
  "& & & & & \\multicolumn{7}{c}{Deaths per 1,000 child-years, by age (months)} \\\\", "\\cmidrule(lr){6-12}",
  paste0("Country & Surveys & \\begin{tabular}[b]{@{}c@{}}Survey-\\\\units\\end{tabular} & Deaths & \\begin{tabular}[b]{@{}c@{}}\\textit{Pf}PR$_{2-10}$\\\\(\\%)\\end{tabular} & ",
    paste(c("$<$1", "1--5", "6--11", "12--23", "24--35", "36--47", "48--59"), collapse = " & "), " \\\\"),
  "\\midrule", body, "\\bottomrule", "\\end{tabular}",
  "\\par\\smallskip", "\\begin{minipage}{\\linewidth}\\footnotesize", notes, "\\end{minipage}", "\\end{table}")
writeLines(tex, file.path(st$out, "table_sahel_countries.latex.txt"))
cbh_atomic_csv(data.frame(file = unname(paths), md5 = vapply(unname(paths), cbh_file_hash, "")), file.path(st$out, "sahel_table_provenance.csv"))
message("Sahel country table: ", file.path(st$out, "table_sahel_countries.md"))
