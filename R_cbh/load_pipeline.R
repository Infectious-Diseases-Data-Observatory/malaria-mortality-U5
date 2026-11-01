# Source from the project root, then use cbh_config() or cbh_build().
cbh_source <- function(root = getwd(), envir = parent.frame()) {
  paths <- c("00_config.R", file.path("R", c("utils.R", "geography.R", "child_bands.R",
                                            "external_data.R", "build.R")))
  for (path in paths) sys.source(file.path(root, "R_cbh", path), envir = envir)
  invisible(NULL)
}
cbh_source()
