#!/usr/bin/env Rscript
# Test on one age band (band number 1-7 as the argument; default settings$test_band) of a cluster random effect in the hazards model, fitted with lme4 (sparse random
# effects; bam cannot hold about 70,000 cluster levels, and the installed INLA has no macOS binaries). The two fits
# differ only in the cluster effect, and are specified as in 02_cluster_effect_inla.R:
#   no cluster:  death ~ PfPR basis + calendar-year basis + 17 covariates + urban + (1|survey) + (1|country) + (1|unit)
#   cluster:     the same + (1|cluster)
# Binomial, cloglog link, offset log(band_years); the primary's cubic regression spline bases (same knots), entered
# unpenalised; records with the same cluster and covariates collapsed to binomial counts. nAGQ = 0 (fixed effects
# estimated within the penalised least squares step), the fast approximation, adequate for a feasibility test.
# Writes <out>/band_<k>_lme4_contrasts.csv and band_<k>_lme4_variances.csv.
suppressPackageStartupMessages({library(data.table); library(mgcv); library(lme4)})
source("R_cbh/primary/settings.R"); source("R_cbh/primary/specification.R"); source("R_cbh/sensitivity/design/settings.R")
P <- cbh_primary_settings(); S <- cbh_design_settings(); source("R_cbh/00_config.R"); bands <- as.character(cbh_config()$age_bands$age_band)
arg <- commandArgs(trailingOnly = TRUE); k <- if (length(arg)) as.integer(arg[1]) else match(S$test_band, bands)   # band number, 1-7
stopifnot(length(k) == 1, k %in% seq_along(bands)); band <- bands[k]
input <- readRDS(P$data)$data
d <- as.data.table(droplevels(input[input$age_band == band, , drop = FALSE])); rm(input); gc(FALSE)
design <- readRDS(S$design); i <- match(d$child_id, design$child_id); stopifnot(!anyNA(i))
d[, `:=`(urban = design$urban[i], psu = design$psu[i])]
manifest <- read.csv(file.path(P$out, "fit_manifest.csv"))
base <- readRDS(manifest$model_file[manifest$age_band == band])$fit
covs <- c(paste0("z_", cbh_primary_regional_spec(P)$covariates), "urban")
keys <- c("psu", "survey", "country", "region", "pfpr_pct", "calendar_year", "band_years", covs)
a <- d[, .(y = sum(death), n = .N), by = keys]
stopifnot(sum(a$n) == nrow(d), sum(a$y) == sum(d$death))
basis <- function(k, prefix) { B <- PredictMat(base$smooth[[k]], as.data.frame(a)); colnames(B) <- paste0(prefix, seq_len(ncol(B))); B }
B <- cbind(basis(1, "pf"), basis(2, "yr")); a <- cbind(a, B); pf <- grep("^pf", colnames(B), value = TRUE)
a[, psu := factor(psu)]
L <- function(from, to) drop(PredictMat(base$smooth[[1]], data.frame(pfpr_pct = to)) - PredictMat(base$smooth[[1]], data.frame(pfpr_pct = from)))
rhs <- c(colnames(B), covs, "(1 | survey)", "(1 | country)", "(1 | region)", "offset(log(band_years))")
fit <- function(label, terms) {
  t <- system.time(m <- glmer(as.formula(paste("cbind(y, n - y) ~", paste(terms, collapse = " + "))), data = a,
    family = binomial(link = "cloglog"), nAGQ = 0, control = glmerControl(calc.derivs = FALSE)))
  V <- as.matrix(vcov(m))[pf, pf]; b <- fixef(m)
  con <- rbindlist(lapply(list(c(20, 0), c(40, 20)), function(v) { l <- L(v[1], v[2])
    data.frame(model = label, age_band = band, contrast = paste0("PfPR ", v[1], " to ", v[2]), log_hazard_ratio = sum(l * b[pf]), se = sqrt(drop(l %*% V %*% l))) }))
  con[, `:=`(hazard_ratio = exp(log_hazard_ratio), lower_95 = exp(log_hazard_ratio - 1.96 * se), upper_95 = exp(log_hazard_ratio + 1.96 * se),
    urban_log_hr = b[["urban"]], urban_se = sqrt(vcov(m)["urban", "urban"]), minutes = unname(t["elapsed"]) / 60)]
  vc <- as.data.frame(VarCorr(m))
  list(contrasts = con, variances = data.frame(model = label, term = vc$grp, sd = vc$sdcor))
}
out <- list(fit("lme4, no cluster effect", rhs), fit("lme4, cluster effect", c(rhs, "(1 | psu)")))
res <- rbindlist(lapply(out, `[[`, "contrasts")); vars <- rbindlist(lapply(out, `[[`, "variances"))
fwrite(res, file.path(S$out, paste0("band_", k, "_lme4_contrasts.csv"))); fwrite(vars, file.path(S$out, paste0("band_", k, "_lme4_variances.csv")))
cat("collapsed rows", nrow(a), "of", nrow(d), "records; clusters", nlevels(a$psu), "\n"); print(res, digits = 4); print(vars, digits = 3)
