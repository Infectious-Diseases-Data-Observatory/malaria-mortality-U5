# 20 — Population-weighted PfPR2-10 (2024) at admin-1 for Nigeria & DR Congo
# ---------------------------------------------------------------------------
# Same method as script 07 (national) but per admin-1 unit. Boundaries from
# malariaAtlas::getShp; weight = GPW v4 density; PfPR from MAP 2024 surface.
# Output: data/pfpr_admin1_ng_cd_2024.csv (country, iso3, area, pfpr_pct)
# ---------------------------------------------------------------------------
suppressMessages({library(malariaAtlas); library(terra); library(sf)})
PROJ <- getwd()   # run from the repository root
GPW  <- file.path(PROJ, "data", "pop", "gpw_v4_population_density_rev11_2020_2.5m.tif")   # originally a scratch copy of the same GPW v4 2020 raster

pf_full <- rast(file.path(PROJ, "data", "pfpr_2to10_africa_2024.tif"))
den_full <- rast(GPW)

pfpr_admin1 <- function(iso, label) {
  shp <- sf::st_make_valid(getShp(ISO = iso, admin_level = "admin1"))
  v   <- terra::makeValid(terra::vect(shp))
  pf  <- crop(pf_full, v)
  den <- resample(crop(den_full, pf), pf, method = "bilinear")
  w   <- mask(den, pf)
  num <- pf * w
  an  <- terra::extract(num, v, fun = sum, na.rm = TRUE, exact = TRUE, ID = FALSE)
  aw  <- terra::extract(w,   v, fun = sum, na.rm = TRUE, exact = TRUE, ID = FALSE)
  data.frame(country = label, iso3 = iso, area = shp$name_1,
             pfpr_pct = 100 * an[[1]] / aw[[1]], stringsAsFactors = FALSE)
}

res <- rbind(pfpr_admin1("NGA", "Nigeria"), pfpr_admin1("COD", "DR Congo"))
res <- res[is.finite(res$pfpr_pct), ]
write.csv(res, file.path(PROJ, "data", "pfpr_admin1_ng_cd_2024.csv"), row.names = FALSE)

cat(sprintf("admin-1 units: %d (NGA %d, COD %d)\n", nrow(res),
            sum(res$iso3 == "NGA"), sum(res$iso3 == "COD")))
cat("PfPR range NGA:", paste(round(range(res$pfpr_pct[res$iso3=="NGA"]),1), collapse="-"), "%\n")
cat("PfPR range COD:", paste(round(range(res$pfpr_pct[res$iso3=="COD"]),1), collapse="-"), "%\n")
cat("\nNGA sample:\n"); print(head(res[res$iso3=="NGA",c("area","pfpr_pct")],4), row.names=FALSE)
cat("COD sample:\n"); print(head(res[res$iso3=="COD",c("area","pfpr_pct")],4), row.names=FALSE)
