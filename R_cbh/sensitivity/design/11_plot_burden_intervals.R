#!/usr/bin/env Rscript
# Malaria-attributable deaths by year, 2000-2024, with 95% uncertainty intervals: a free-form INLA model
# (10_burden_draws.R; default M1_rw2_sqrt_ref1_int) against the paper's estimate. Columns: the all-cause death series
# (UN IGME, IHME). Rows: all under five, and 1-59 months. The dashed line is malaria deaths under five in the
# cause-of-death estimates the paper compares with (CA-CODE beside UN IGME, IHME's own beside IHME); it is the same
# under-five series in both rows. Points are the zero-noise estimates, bands the 2.5% and 97.5% quantiles of 500 draws.
# Saved at 6.5 in wide, the printed width of a full-width figure, so the sizes in the script are the printed sizes.
# Argument (optional): the model. Exploratory figure, not for the paper.
# Writes <out>/uncertainty_<model>/attributable_deaths_trend_with_intervals.png.
suppressPackageStartupMessages({library(data.table); library(ggplot2)})
source("R_cbh/sensitivity/design/settings.R"); S <- cbh_design_settings()
arg <- commandArgs(trailingOnly = TRUE); model <- if (length(arg)) arg[1] else "M1_rw2_sqrt_ref1_int"
dout <- file.path(S$out, paste0("uncertainty_", model))
a <- fread(file.path(dout, "annual_intervals_2000_2024.csv"))[scenario == "main" & age_group %in% c("Under 5", "1-59 months")]
stopifnot(setequal(a$estimate, c(model, "paper")), a[, .N, by = .(estimate, source, age_group)]$N == 25L)
comp <- fread(file.path(dout, "comparators_2000_2024.csv"))
lab_series <- c(new = "New model", paper = "Paper", comparator = "CA-CODE or IHME malaria deaths (under five)")
lab_age <- c(`Under 5` = "Under five", `1-59 months` = "1-59 months"); lab_source <- c(`UN IGME` = "UN IGME all-cause deaths", IHME = "IHME all-cause deaths")
d <- a[, .(series = lab_series[fifelse(estimate == "paper", "paper", "new")], source, age_group, year, deaths = attributable_deaths,
  lower = attributable_deaths_lower, upper = attributable_deaths_upper)]
d <- rbind(d, rbindlist(lapply(names(lab_age), function(g) comp[, .(series = lab_series[["comparator"]], source, age_group = g, year,
  deaths = malaria_deaths_under5, lower = NA_real_, upper = NA_real_)])))
d[, `:=`(series = factor(series, levels = unname(lab_series)), age = factor(lab_age[age_group], levels = unname(lab_age)),
  source = factor(lab_source[source], levels = unname(lab_source)))]
stopifnot(!anyNA(d[, .(series, age, source, deaths)]))
colours <- setNames(c("#c8571b", "grey25", "black"), lab_series)
p <- ggplot(d, aes(year, deaths / 1000, colour = series, fill = series)) +
  geom_ribbon(data = d[!is.na(lower)], aes(ymin = lower / 1000, ymax = upper / 1000), alpha = 0.2, colour = NA, show.legend = FALSE) +
  geom_line(aes(linetype = series, linewidth = series)) +
  facet_grid(age ~ source) +
  scale_x_continuous(breaks = seq(2000, 2024, 6)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.04)), breaks = seq(0, 1200, 300), labels = function(x) format(x, big.mark = ",")) +
  scale_colour_manual(values = colours) + scale_fill_manual(values = colours, guide = "none") +
  scale_linetype_manual(values = setNames(c("solid", "solid", "42"), lab_series)) + scale_linewidth_manual(values = setNames(c(0.8, 0.8, 0.5), lab_series)) +
  labs(x = "Year", y = "Malaria-attributable deaths (thousands)", colour = NULL, linetype = NULL, linewidth = NULL) +
  theme_bw(base_size = 11) + theme(axis.text = element_text(size = 9), strip.text = element_text(size = 9), legend.text = element_text(size = 9),
    panel.grid.minor = element_blank(), panel.spacing.x = grid::unit(12, "pt"), legend.position = "bottom", legend.margin = margin(t = -4),
    legend.key.width = grid::unit(22, "pt"))
ggsave(file.path(dout, "attributable_deaths_trend_with_intervals.png"), p, width = 6.5, height = 5.4, dpi = 200)
print(dcast(d[year %in% c(2000, 2015, 2024)], source + age + year ~ series, value.var = "deaths")[, lapply(.SD, function(x) if (is.numeric(x)) round(x) else x)])
