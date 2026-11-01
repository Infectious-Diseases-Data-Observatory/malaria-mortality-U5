#!/usr/bin/env Rscript
# Regional covariates of each (DHS survey, Snow unit), recomputed from the recodes (user decision, 6 October 2026)
# with the definitions of the v9 covariates (ported from the analysis project's 07_covariates_dhs.R in its
# Snow-unit folder; only the grouping, paths and survey list differ; the v9 survey-region code that defined them,
# R_cbh/covariates/regional.R, 11_extract_first_birth_age.R and 17_recode_replacements.R, was removed on 1 November 2026):
#   BR (women's weight v005): mean maternal age at first birth (v212), education years (v133), wealth quintile (v190)
#     and urban % (v025) over mothers with a live birth in the 60 months before interview, one row per mother;
#     DTP3 (all of h3/h5/h7) and measles (h9) among living children 12-23 months; facility delivery (m15) among
#     births 0-59 months; short birth interval (b11 7-23 months) among non-first births 0-59 months.
#   PR (household weight hv005): improved water (hv201), improved sanitation (hv205) and electricity (hv206) over
#     households (one PR row per hv001/hv002); stunting (hc70) and wasting (hc72) < -2 SD among de facto children
#     0-59 months with a valid WHO z-score, from the HW file for surveys whose PR predates the WHO standards.
#   DTP3 counts at least three doses of any DTP-containing vaccine across h3/h5/h7 and the survey's extra series in
#     config/vaccine_series.csv; measles counts any measles-containing vaccine (h9 or the extra series).
#   Labels are classified by label_rules.R, then the reviewed survey-specific decisions in config/label_overrides.csv
#   (each reproduces the published national value). Unknown labels stop (label_rules.R). Blank items (not asked) are outside the
#   denominator; "missing" answers count as "no". Water labels without type information ("spring", "water vendor")
#   take, per survey, the classification whose national value is closest to the published national value.
# Placement (R_cbh/snow/R/placement.R): BR rows by their survey-region and finer location; PR rows by their cluster
# (hv001 = v001), located from the BR rows of that cluster; then their analysis unit (snow_assign, merge rule): one
# unit per row (weight = survey weight).
# Outputs: <private>/covariates_dhs_long.csv (survey x unit x variable; private) and, in <out>/covariates/:
#   dhs_national_validation.csv, dhs_region_consistency.csv, dhs_audit.csv.
# Optional: --survey=AO71FL,BF62FL to run a subset (outputs then carry a _subset suffix).
suppressPackageStartupMessages(library(data.table))
source("R_cbh/load_pipeline.R")
source("R_cbh/snow/R/settings.R"); source("R_cbh/snow/R/placement.R"); source("R_cbh/snow/R/dhs_files.R"); source("R_cbh/snow/R/label_rules.R")
S <- snow_dirs(snow_settings(), "covariates")
cfg <- cbh_config()
reg <- cbh_read_csv(cfg$registry); rules <- cbh_read_csv(cfg$survey_rules)
bounds <- unique(cbh_read_csv(cfg$boundary_regions)[c("svkey", "region", "regkey")]); ov <- cbh_read_csv(cfg$region_overrides)
priv <- S$private; out <- file.path(S$out, "covariates")
cls <- fread(file.path(S$out, "feasibility", "region_classification.csv"))
surveys <- intersect(snow_all_shards(), cls[programme == "DHS", unique(survey)])
only <- sub("^--survey=", "", grep("^--survey=", commandArgs(TRUE), value = TRUE))
suffix <- if (length(only)) "_subset" else ""
if (length(only)) surveys <- intersect(surveys, strsplit(only, ",")[[1]])
R <- snow_rules(S)
series <- fread("R_cbh/snow/config/vaccine_series.csv"); overrides <- fread("R_cbh/snow/config/label_overrides.csv")
overrides[, label := gsub('""', '"', label, fixed = TRUE)]   # CSV-escaped quotes as read by fread; labels carry single quotes
# Reviewed survey-specific label decisions take precedence; the general rules (f) classify the remaining labels, so a
# label covered by an override need not be known to label_rules.R (labels of the surveys added for the Snow units).
override <- function(sv, item, x, f) {
  o <- overrides[survey == sv & variable == item]; hit <- x %in% o$label
  out <- rep(NA_real_, length(x)); if (any(!hit)) out[!hit] <- f(x[!hit])
  out[hit] <- o$value[match(x[hit], o$label)]; out
}
extra_vars <- function(sv, ag) { v <- series[survey == sv & antigen == ag, variables]; if (length(v)) strsplit(v, ";", fixed = TRUE)[[1]] else character() }

# Published national values for validation (cached DHS API rows; StatCompiler for wasting).
pub <- fread("data/derived_cbh/regional_adjustment/published_indicators.csv")[level == "national"]
pub[is.na(ByVariableLabel), ByVariableLabel := ""]
statc <- fread("data/derived_dhs/statcompiler_covariates.csv")[level == "national"]
published <- function(id) {
  x <- pub[SurveyId == id]
  one <- function(i, by = "") { y <- x[IndicatorId == i & ByVariableLabel == by]; if (nrow(y) == 1) as.numeric(y$Value) else NA_real_ }
  fac <- one("RH_DELP_C_DHF", "Five years preceding the survey")
  if (is.na(fac)) fac <- one("RH_DELP_C_DHF", "Three years preceding the survey")
  if (is.na(fac)) fac <- one("RH_DELP_C_DHF", "Two years preceding the survey")
  w <- statc[SurveyId == id & IndicatorId == "CN_NUTS_C_WH2", as.numeric(Value)]
  c(dtp3_pct = one("CH_VACC_C_DP3"), measles_pct = one("CH_VACC_C_MSL"), facility_delivery_pct = fac,
    short_birth_interval_pct = one("FE_BINT_C_I07") + one("FE_BINT_C_I18"), improved_water_pct = one("WS_SRCE_H_IMP"),
    improved_sanitation_pct = one("WS_TLET_H_IMP"), electricity_pct = one("HC_ELEC_H_ELC"),
    wasting_pct = if (length(w) == 1) w else NA_real_)
}
lab <- function(d, v) if (v %in% names(d)) tolower(trimws(cbh_label(d[[v]]))) else rep(NA_character_, nrow(d))
num <- function(d, v) cbh_column(d, v, TRUE)
wmean <- function(x, w) { ok <- is.finite(x) & is.finite(w) & w > 0; if (any(ok)) sum(x[ok] * w[ok]) / sum(w[ok]) else NA_real_ }
# Weighted mean of a row-level value by unit over placed rows (id = row index or cluster id; pl from snow_assign).
by_unit <- function(sv, var, pop, value, mask, w, pl, key) {
  i <- match(pl$id, key); x <- value[i]; m <- mask[i]; ww <- w[i] * pl$w
  d <- data.table(unit = pl$unit, x, m, ww)[m %in% TRUE & is.finite(ww) & ww > 0]
  d[, .(value = if (any(is.finite(x))) sum(x[is.finite(x)] * ww[is.finite(x)]) / sum(ww[is.finite(x)]) else NA_real_,
        eligible_n = .N, observed_n = sum(is.finite(x)), weighted_n = sum(ww[is.finite(x)])), by = unit][
    , `:=`(survey = sv, variable = var, population = pop)]
}

long <- list(); natl <- list(); cons <- list(); audit <- list()
for (sv in surveys) {
  s <- reg[reg$svkey == sv, , drop = FALSE]; rule <- rules[rules$svkey == sv, , drop = FALSE]
  fv <- R$choice[survey == sv, variable]
  xd <- extra_vars(sv, "dtp"); xm <- extra_vars(sv, "measles")
  br <- cbh_read_recode(s$local_recode, unique(c(rule$region_var, rule$strata_var, "v212", "b19", "h3", "h5", "h7", "h9", "m15", fv, xd, xm)))
  stopifnot(all(c(xd, xm) %in% names(br)))
  geo <- cbh_geography(br, s, rule, bounds[bounds$svkey == sv, , drop = FALSE], ov, reg)
  n <- nrow(br); w_br <- num(br, "v005") / 1e6
  # Row-level BR values.
  age_m <- num(br, "v008") - num(br, "b3"); recent <- is.finite(age_m) & age_m >= 0 & age_m < 60
  mother <- trimws(cbh_column(br, "caseid")); if (all(is.na(mother))) mother <- cbh_key(br, c("v001", "v002", "v003"))
  mok <- !is.na(mother) & nzchar(mother)
  first <- recent & mok & !duplicated(ifelse(recent & mok, mother, NA_character_))
  urban <- cbh_decode_category(br$v025 %cbh_or% rep(NA, n), c("urban", "rural"), c(1, 2))
  wealth <- cbh_decode_category(br$v190 %cbh_or% rep(NA, n), c("poorest", "poorer", "middle", "richer", "richest", "lowest", "second", "fourth", "highest"), c(1:5, 1, 2, 4, 5))
  raw <- cbh_label(br$v190 %cbh_or% rep(NA, n)); bad <- !is.na(raw) & nzchar(trimws(raw)) & is.na(wealth)
  if (any(bad)) stop(sv, ": undecoded v190 labels: ", paste(unique(raw[bad]), collapse = ", "))
  educ <- num(br, "v133"); educ[!is.finite(educ) | educ < 0 | educ > 30] <- NA
  afb <- num(br, "v212"); afb[!is.finite(afb) | afb < 8 | afb > 49] <- NA
  age_c <- if ("b19" %in% names(br) && any(is.finite(num(br, "b19")))) num(br, "b19") else age_m
  alive <- cbh_decode_category(br$b5, c("no", "yes"), c(0, 1))
  child <- is.finite(age_c) & age_c >= 12 & age_c <= 23 & alive %in% 1
  births <- is.finite(age_c) & age_c >= 0 & age_c < 60
  hd <- lapply(c("h3", "h5", "h7", xd), function(v) snow_vacc(lab(br, v)))
  hm <- lapply(c("h9", xm), function(v) snow_vacc(lab(br, v)))
  asked <- Reduce(`|`, lapply(hd, Negate(is.na))); asked_m <- Reduce(`|`, lapply(hm, Negate(is.na)))
  dtp_doses <- Reduce(`+`, lapply(hd, function(z) z %in% 1)); measles_any <- Reduce(`|`, lapply(hm, function(z) z %in% 1))
  b11 <- num(br, "b11"); m15 <- lab(br, "m15"); fac <- override(sv, "m15", m15, snow_facility)
  bv <- list(mean_maternal_age_first_birth = afb, mean_maternal_education_years = educ, mean_wealth_quintile = wealth,
    urban_pct = 100 * (urban == 1), dtp3_pct = ifelse(asked, 100 * (dtp_doses >= 3), NA),
    measles_pct = ifelse(asked_m, 100 * measles_any, NA), facility_delivery_pct = 100 * fac, short_birth_interval_pct = ifelse(is.finite(b11), 100 * (b11 >= 7 & b11 <= 23), NA))
  bm <- list(first, first, first, first, child, child, births, births & is.finite(b11)); names(bm) <- names(bv)
  bp <- c(rep("mothers_with_birth_last_60_months", 4), rep("living_children_12_23_months", 2), "live_births_last_60_months", "non_first_births_last_60_months")
  # Placement of BR rows.
  fk <- if (length(fv)) snow_clean_key(cbh_column(br, fv)) else rep(NA_character_, n)
  known <- !is.na(geo$regkey) & paste(sv, geo$regkey) %in% paste(R$region$survey, R$region$regkey)
  pl <- snow_assign(snow_place(data.table(id = which(known), survey = sv, regkey = geo$regkey[known], finer_key = fk[known]), R), S)
  for (k in seq_along(bv)) long[[length(long) + 1]] <- by_unit(sv, names(bv)[k], bp[k], bv[[k]], bm[[k]], w_br, pl, seq_len(n))
  for (k in 1:4) cons[[length(cons) + 1]] <- data.table(regkey = geo$regkey, x = bv[[k]], m = bm[[k]], w = w_br)[m %in% TRUE & !is.na(regkey),
    .(value = wmean(x, w)), by = regkey][, `:=`(survey = sv, variable = names(bv)[k])]
  nat <- vapply(seq_along(bv), function(k) wmean(ifelse(bm[[k]], bv[[k]], NA), w_br), 0); names(nat) <- names(bv)

  # PR: households and children, placed by cluster.
  prp <- snow_pr_path(sv); if (is.na(prp)) stop(sv, ": no PR file")
  pr <- readRDS(prp); names(pr) <- tolower(names(pr)); cbh_require(pr, c("hv001", "hv002", "hv005"), paste(sv, "PR"))
  v001 <- num(br, "v001")
  cl <- data.table(cluster = v001, regkey = geo$regkey, finer_key = fk)[known & is.finite(v001)]
  cl <- cl[, .N, by = .(cluster, regkey, finer_key)][order(cluster, -N)][!duplicated(cluster)]
  cpl <- snow_assign(snow_place(cl[, .(id = as.character(cluster), survey = sv, regkey, finer_key)], R), S)
  hv001 <- as.character(num(pr, "hv001")); w_pr <- num(pr, "hv005") / 1e6
  hh <- !duplicated(paste(hv001, num(pr, "hv002")))
  wl <- lab(pr, "hv201"); pubv <- published(s$SurveyId)
  opts <- CJ(spring = if (any(wl[hh] == "spring", na.rm = TRUE)) c(0, 1) else 0, vendor = if (any(wl[hh] == "water vendor", na.rm = TRUE)) c(1, 0) else 1)
  opts[, nat := mapply(function(a, b) wmean(ifelse(hh, 100 * override(sv, "hv201", wl, function(z) snow_water(z, a, b)), NA), w_pr), spring, vendor)]
  pick <- if (nrow(opts) > 1 && is.finite(pubv[["improved_water_pct"]])) which.min(abs(opts$nat - pubv[["improved_water_pct"]])) else 1L
  sl <- lab(pr, "hv205")
  pv <- list(improved_water_pct = 100 * override(sv, "hv201", wl, function(z) snow_water(z, opts$spring[pick], opts$vendor[pick])),
    improved_sanitation_pct = 100 * override(sv, "hv205", sl, snow_sanitation), electricity_pct = 100 * snow_yesno(lab(pr, "hv206"), paste(sv, "hv206")))
  # WHO z-scores: PR hc70/hc72 when labelled WHO; otherwise the HW file (hwhhid, hwline = hhid, hvidx).
  zsrc <- "none"; z70 <- z72 <- rep(NA_real_, nrow(pr))
  lab70 <- attr(pr$hc70, "label"); if (is.null(lab70)) lab70 <- ""
  if ("hc70" %in% names(pr) && grepl("WHO", lab70)) { z70 <- num(pr, "hc70"); z72 <- num(pr, "hc72"); zsrc <- "PR (WHO)" } else {
    hwp <- snow_hw_path(sv)
    if (!is.na(hwp)) { hw <- readRDS(hwp); names(hw) <- tolower(names(hw))
      j <- match(paste(trimws(cbh_column(pr, "hhid")), num(pr, "hvidx")), paste(trimws(cbh_column(hw, "hwhhid")), num(hw, "hwline")))
      z70 <- num(hw, "hc70")[j]; z72 <- num(hw, "hc72")[j]; zsrc <- "HW (WHO)" } }
  hc1 <- num(pr, "hc1"); defacto <- snow_yesno(lab(pr, "hv103"), paste(sv, "hv103")) %in% 1
  under5 <- defacto & is.finite(hc1) & hc1 >= 0 & hc1 < 60
  pv$stunting_pct <- ifelse(is.finite(z70) & z70 < 9996, 100 * (z70 < -200), NA)
  pv$wasting_pct <- ifelse(is.finite(z72) & z72 < 9996, 100 * (z72 < -200), NA)
  pm <- list(hh, hh, hh, under5, under5); names(pm) <- names(pv)
  pp <- c(rep("households_PR_one_row_per_hv001_hv002", 3), rep("de_facto_children_0_59_months_valid_WHO_z", 2))
  rid <- as.character(seq_len(nrow(pr)))
  prpl <- merge(data.table(row = rid, cluster = hv001), cpl, by.x = "cluster", by.y = "id", allow.cartesian = TRUE)[, .(id = row, unit, w)]
  for (k in seq_along(pv)) long[[length(long) + 1]] <- by_unit(sv, names(pv)[k], pp[k], pv[[k]], pm[[k]], w_pr, prpl, rid)
  nat <- c(nat, vapply(seq_along(pv), function(k) wmean(ifelse(pm[[k]], pv[[k]], NA), w_pr), 0) |> setNames(names(pv)))
  natl[[sv]] <- data.table(survey = sv, SurveyId = s$SurveyId, variable = names(nat), recode_national = unname(nat),
                           published_national = unname(pubv[names(nat)]))
  audit[[sv]] <- data.table(survey = sv, SurveyId = s$SurveyId, br_rows = n, br_rows_placed = uniqueN(pl$id),
    br_rows_unmatched_region = sum(is.na(geo$regkey)), children_12_23 = sum(child), children_12_23_not_asked = sum(child & !asked),
    pr_households = sum(hh), pr_households_placed = sum(hh & hv001 %in% cpl$id), z_source = zsrc,
    water_spring = opts$spring[pick], water_vendor = opts$vendor[pick], under5_defacto = sum(under5),
    under5_valid_haz = sum(under5 & is.finite(pv$stunting_pct)))
  rm(br, pr, geo); invisible(gc(FALSE))
  message(sprintf("%-7s %3d units | z: %s", sv, uniqueN(pl$unit), zsrc))
}
long <- rbindlist(long); natl <- rbindlist(natl); cons <- rbindlist(cons); audit <- rbindlist(audit)
natl[, difference_pp := recode_national - published_national]
fwrite(long[, .(survey, unit, variable, value, eligible_n, observed_n, weighted_n, population)], file.path(priv, paste0("covariates_dhs_long", suffix, ".csv")))
fwrite(natl, file.path(out, paste0("dhs_national_validation", suffix, ".csv")))
fwrite(cons, file.path(out, paste0("dhs_region_consistency", suffix, ".csv")))
fwrite(audit, file.path(out, paste0("dhs_audit", suffix, ".csv")))
cat("\nNational recode vs published (percentage points): surveys with |difference| > 2, by variable\n")
print(natl[is.finite(difference_pp), .(surveys = .N, median_abs = round(median(abs(difference_pp)), 2), over_2pp = sum(abs(difference_pp) > 2),
                                     max_abs = round(max(abs(difference_pp)), 1)), by = variable])
