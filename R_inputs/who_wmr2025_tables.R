#!/usr/bin/env Rscript
# WHO World Malaria Report 2025 death estimates, transcribed by hand from the report
# (Table 2.1: global, all ages; Table 2.4: WHO African Region, all ages). Used only for the
# WHO rows of the source comparison table (R_cbh/reporting/12_source_comparison_table.R).
# Verbatim block from the analysis project's R/11_malaria_deaths_timeseries.R.
RESULTS <- "results"
dir.create(RESULTS, showWarnings = FALSE)
who_glob <- data.frame(year = 2000:2024,
  point = c(864,873,840,811,806,767,771,747,708,715,693,655,610,583,579,578,576,574,575,567,621,601,598,598,610)*1000,
  lo    = c(833,840,809,781,770,734,739,717,679,683,659,625,583,554,546,543,542,540,536,527,575,558,554,550,561)*1000,
  hi    = c(904,916,881,854,863,815,818,790,745,762,744,696,651,625,632,635,634,638,649,649,736,716,722,725,738)*1000)
write.csv(who_glob, file.path(RESULTS, "who_wmr2025_global_deaths.csv"), row.names = FALSE)
who_af <- data.frame(year = 2000:2024,
  point = c(804,815,786,758,751,712,723,704,666,673,650,618,578,556,550,550,546,548,552,545,598,577,573,567,579)*1000,
  lo    = c(781,789,761,733,722,686,695,677,641,646,620,592,552,526,518,517,513,513,514,505,553,535,530,520,531)*1000,
  hi    = c(834,851,819,792,803,755,766,742,700,716,698,658,616,598,601,605,602,608,624,626,711,691,698,694,706)*1000)
write.csv(who_af, file.path(RESULTS, "who_wmr2025_africa_deaths.csv"), row.names = FALSE)
