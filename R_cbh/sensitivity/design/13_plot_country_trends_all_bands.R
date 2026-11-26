#!/usr/bin/env Rscript
# Country-specific year trends of an M3 model (05_spacetime_inla.R) for every age band fitted: each country's hazard
# over calendar years relative to its own average (common year walk plus the country's departure, posterior means),
# over the years in which the country has records, with the common trend in black; one panel per age band.
# Argument (optional): the model (default M3_rw2_sqrt_ref1). Exploratory figure, not for the paper.
# Writes <out>/country_year_trends_all_bands_<model>.png and country_year_trends_summary_<model>.csv (by band: the SD
# of the country walks, the spread of the departures, and how many countries have a departure whose 95% interval
# excludes zero in some year).
suppressPackageStartupMessages({library(data.table); library(ggplot2)})
source("R_cbh/sensitivity/design/settings.R"); S <- cbh_design_settings(); source("R_cbh/00_config.R"); bands <- as.character(cbh_config()$age_bands$age_band)
arg <- commandArgs(trailingOnly = TRUE); show <- if (length(arg)) arg[1] else "M3_rw2_sqrt_ref1"
read <- function(k, what) { f <- file.path(S$out, paste0("band_", k, "_spacetime_", what, ".csv")); if (file.exists(f)) fread(f, colClasses = list(character = "age_band"))[model == show] else NULL }
e <- rbindlist(lapply(seq_along(bands), read, what = "year_effects")); stopifnot(nrow(e) > 0)
e[, age := factor(paste(age_band, "months"), levels = paste(bands, "months"))]
common <- e[country == "All", .(age, age_band, year, common = log_hazard)]
d <- merge(e[country != "All"], common, by = c("age", "age_band", "year"))[, total := common + log_hazard][!is.na(records)]
setorder(d, age, country, year)
p <- ggplot(d, aes(year, exp(total), group = country)) +
  geom_hline(yintercept = 1, linewidth = 0.3, colour = "grey50") +
  geom_line(colour = "grey65", linewidth = 0.3) +
  geom_line(data = common, aes(year, exp(common), group = 1), colour = "black", linewidth = 0.9) +
  facet_wrap(~age, nrow = 2) +
  scale_y_log10(breaks = c(0.5, 0.67, 1, 1.5, 2, 3), labels = function(x) format(x, drop0trailing = TRUE)) +
  scale_x_continuous(breaks = c(2000, 2010, 2020)) +
  labs(x = "Year", y = "Hazard relative to the average year") +
  theme_bw(base_size = 11) + theme(axis.text = element_text(size = 9), strip.text = element_text(size = 9), panel.grid.minor = element_blank(),
    panel.spacing.x = grid::unit(10, "pt"))
ggsave(file.path(S$out, paste0("country_year_trends_all_bands_", show, ".png")), p, width = 7.5, height = 4.6, dpi = 200)
h <- rbindlist(lapply(seq_along(bands), read, what = "hyperparameters"))
sdw <- function(term_name) h[term == term_name, .(age_band, txt = sprintf("%.2f (%.2f-%.2f)", mode, lower, upper))]
by_country <- d[, .(excludes_zero = any(lower_95 > 0 | upper_95 < 0)), by = .(age_band, country)]
s <- d[, .(country_years = .N, lowest_hazard_ratio = exp(min(log_hazard)), highest_hazard_ratio = exp(max(log_hazard))), by = age_band]
s <- merge(s, by_country[, .(countries = .N, countries_with_a_clear_departure = sum(excludes_zero)), by = age_band], by = "age_band")
s <- merge(merge(s, sdw("SD of year_c")[, .(age_band, sd_country_walks = txt)], by = "age_band"), sdw("SD of year_id")[, .(age_band, sd_common_walk = txt)], by = "age_band")
s <- s[match(bands, age_band)][!is.na(age_band)]
fwrite(s, file.path(S$out, paste0("country_year_trends_summary_", show, ".csv"))); print(s, digits = 3)
