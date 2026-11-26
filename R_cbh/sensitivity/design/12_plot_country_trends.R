#!/usr/bin/env Rscript
# Country-specific year trends of an M3 model (05_spacetime_inla.R) for one age band: each country's hazard over
# calendar years relative to its own average (common year walk plus the country's departure, posterior means), drawn
# over the years in which the country has records, with the common trend in black. The countries whose departure from
# the common trend is largest are named at the end of their line.
# Arguments: band number (default settings$test_band), model (default M3_rw2_sqrt_ref1). Exploratory figure, not for
# the paper. Writes <out>/band_<k>_country_year_trends_<model>.png and prints each country's largest departure.
suppressPackageStartupMessages({library(data.table); library(ggplot2)})
source("R_cbh/sensitivity/design/settings.R"); S <- cbh_design_settings(); source("R_cbh/00_config.R"); bands <- as.character(cbh_config()$age_bands$age_band)
arg <- commandArgs(trailingOnly = TRUE); k <- if (length(arg)) as.integer(arg[1]) else match(S$test_band, bands)
show <- if (length(arg) > 1) arg[2] else "M3_rw2_sqrt_ref1"
e <- fread(file.path(S$out, paste0("band_", k, "_spacetime_year_effects.csv")))[model == show]; stopifnot(nrow(e) > 0)
common <- e[country == "All", .(year, common = log_hazard)]
d <- merge(e[country != "All"], common, by = "year")[, total := common + log_hazard][!is.na(records)]   # years with records only
setorder(d, country, year)
largest <- d[, .(largest_departure = log_hazard[which.max(abs(log_hazard))], year = year[which.max(abs(log_hazard))], years_with_records = .N,
  excludes_zero = any(lower_95 > 0 | upper_95 < 0)), by = country][order(-abs(largest_departure))]
named <- head(largest$country, 5)
ends <- d[country %in% named, .SD[.N], by = country]
p <- ggplot(d, aes(year, exp(total), group = country)) +
  geom_hline(yintercept = 1, linewidth = 0.3, colour = "grey50") +
  geom_line(data = d[!country %in% named], colour = "grey70", linewidth = 0.35) +
  geom_line(data = d[country %in% named], colour = "#c8571b", linewidth = 0.6) +
  geom_line(data = common, aes(year, exp(common), group = 1), colour = "black", linewidth = 1) +
  geom_label(data = ends, aes(label = country), hjust = 0, nudge_x = 0.25, size = 9 / 2.845, colour = "grey15", fill = "white", alpha = 0.85,
    linewidth = 0, label.padding = grid::unit(1.5, "pt")) +
  scale_y_log10(breaks = c(0.5, 0.67, 1, 1.5, 2, 3), labels = function(x) format(x, drop0trailing = TRUE)) +
  scale_x_continuous(breaks = seq(2000, 2024, 6), expand = expansion(mult = c(0.02, 0.09))) +
  labs(x = "Year", y = paste0("Hazard relative to the average year, ", bands[k], " months")) +
  theme_bw(base_size = 11) + theme(axis.text = element_text(size = 9), panel.grid.minor = element_blank())
ggsave(file.path(S$out, paste0("band_", k, "_country_year_trends_", show, ".png")), p, width = 6.5, height = 4.2, dpi = 200)
cat("departures (log hazard): sd over country-years with records", round(sd(d$log_hazard), 3), " range", round(range(d$log_hazard), 3), "\n")
cat("countries whose departure interval excludes zero in some year:", sum(largest$excludes_zero), "of", nrow(largest), "\n")
print(largest[, .(country, largest_departure = round(largest_departure, 3), hazard_ratio = round(exp(largest_departure), 2), year, years_with_records, excludes_zero)])
