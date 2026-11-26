#!/usr/bin/env Rscript
# Test on one age band (band number 1-7 as the argument; default settings$test_band) of a cluster random effect in the hazards model, fitted with INLA (bam cannot hold
# about 70,000 cluster levels). Two fits that differ only in the cluster effect, so the comparison is not one of INLA
# against mgcv:
#   no cluster:  death ~ PfPR basis + calendar-year basis + 17 covariates + urban + iid(survey) + iid(country) + iid(unit)
#   cluster:     the same + iid(cluster)
# Binomial, cloglog link, offset log(band_years), as in the primary. The PfPR and calendar-year bases are the primary's
# cubic regression spline bases (same knots, 4 and 5 columns), entered unpenalised. Records with the same cluster and
# covariates are collapsed to binomial counts (same likelihood). Random-effect SDs have PC priors, P(sd > 1) = 0.01.
# The test uses int.strategy = "eb" (hyperparameters at their mode) to measure feasibility; a final fit would integrate.
# Writes <out>/band_<k>_inla_contrasts.csv and band_<k>_inla_hyperparameters.csv.
suppressPackageStartupMessages({library(data.table); library(mgcv); library(INLA)})
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
B <- cbind(basis(1, "pf"), basis(2, "yr")); a <- cbind(a, B)
pf <- grep("^pf", colnames(B), value = TRUE)
L <- function(from, to) drop(PredictMat(base$smooth[[1]], data.frame(pfpr_pct = to)) - PredictMat(base$smooth[[1]], data.frame(pfpr_pct = from)))
lc <- c(do.call(inla.make.lincomb, as.list(setNames(L(20, 0), pf))), do.call(inla.make.lincomb, as.list(setNames(L(40, 20), pf))))
names(lc) <- c("PfPR 20 to 0", "PfPR 40 to 20")
prior <- "list(prec = list(prior = 'pc.prec', param = c(1, 0.01)))"
re <- function(v) sprintf("f(%s, model = 'iid', hyper = %s)", v, prior)
for (v in c("psu", "survey", "country", "region")) a[, (v) := as.integer(factor(get(v)))]
rhs <- c(colnames(B), covs, re("survey"), re("country"), re("region"))
fit <- function(label, terms) {
  t <- system.time(m <- inla(as.formula(paste("y ~", paste(terms, collapse = " + "))), family = "binomial", Ntrials = a$n, data = as.data.frame(a),
    offset = log(a$band_years), control.family = list(control.link = list(model = "cloglog")), lincomb = lc,
    control.inla = list(int.strategy = "eb"), control.compute = list(config = FALSE), num.threads = "6:1", verbose = FALSE))
  h <- m$summary.hyperpar
  list(contrasts = data.frame(model = label, age_band = band, contrast = names(lc), log_hazard_ratio = m$summary.lincomb.derived$mean,
      sd = m$summary.lincomb.derived$sd, lower_95 = exp(m$summary.lincomb.derived$`0.025quant`), upper_95 = exp(m$summary.lincomb.derived$`0.975quant`),
      urban_log_hr = m$summary.fixed["urban", "mean"], urban_sd = m$summary.fixed["urban", "sd"], minutes = unname(t["elapsed"]) / 60),
    hyper = data.frame(model = label, term = sub("Precision for ", "", rownames(h)), sd_mode = 1 / sqrt(h$mode), sd_lower = 1 / sqrt(h$`0.975quant`), sd_upper = 1 / sqrt(h$`0.025quant`)))
}
out <- list(fit("INLA, no cluster effect", rhs), fit("INLA, cluster effect", c(rhs, re("psu"))))
res <- rbindlist(lapply(out, `[[`, "contrasts")); res[, hazard_ratio := exp(log_hazard_ratio)]
fwrite(res, file.path(S$out, paste0("band_", k, "_inla_contrasts.csv"))); fwrite(rbindlist(lapply(out, `[[`, "hyper")), file.path(S$out, paste0("band_", k, "_inla_hyperparameters.csv")))
cat("collapsed rows", nrow(a), "of", nrow(d), "records; clusters", uniqueN(a$psu), "\n"); print(res, digits = 4); print(rbindlist(lapply(out, `[[`, "hyper")), digits = 3)
