# Shapefile input of the MICS scripts. Sourced by 04, 05 and 06.
# Africa admin-1 shapefile from the Snow prevalence project: the source of the Guinea-Bissau
# and Central African Republic analysis regions and of the SNOW: boundaries (Senegal, Somalia,
# South Sudan). Set MICS_ADMIN1_SHP to use a copy elsewhere. These survey-region boundaries are
# unchanged by the GADM admin-1 units of analysis (v15, 3 November 2026): the Snow shapefile stays
# a reference input here.
mics_admin1_shp <- Sys.getenv("MICS_ADMIN1_SHP",
  "data/external/snow_admin1/Africa_New_Admin.shp")
