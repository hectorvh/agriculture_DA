# Data cleaning setup: paths and helpers for raw → processed
# Sourced by the Quarto report and other scripts.

library(here)
library(sf)
library(dplyr)

# Raw data paths
path_nuts_gpkg <- here("data_raw", "NUTS_RG_20M_2024_3035.gpkg")

# Load NUTS from data_raw (EPSG:3035, 1:20M)
read_nuts_raw <- function(path = path_nuts_gpkg) {
  st_read(path, quiet = TRUE)
}
