# Package stack for pollination analysis (simple + fast + reliable)
# Run 00_setup_renv.R once to init renv and install these.

# Core spatial
# terra  -> raster work (E-OBS NetCDF, masking, resampling, raster math, time summaries)
# sf     -> boundaries (Admin-1), joins, geometry

# Zonal statistics (Admin-1 summaries)
# exactextractr -> polygon summaries of rasters (mean/median, area-weighted)

# Spatial autocorrelation (Global Moran's I + LISA)
# sfdep (tidy) + spdep (engine) -> neighbors, weights, Moran's I, Local Moran

# Data wrangling
# dplyr, tidyr

# Mapping (main: tmap; optional: ggplot2, tidyterra)
# tmap -> thematic maps

# Repro + paths
# here  -> robust paths: here("data_raw", ...)
# renv  -> lock versions (init via 00_setup_renv.R)
# googledrive -> authenticated Google Drive downloads (ZIP datasets)

.pkgs <- c(
  "terra",
  "sf",
  "exactextractr",
  "sfdep",
  "spdep",
  "dplyr",
  "tidyr",
  "tmap",
  "here",
  "googledrive"
)

# Optional (paper-style plots): "ggplot2", "tidyterra"
