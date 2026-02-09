# Robust paths with here (use from project root)
# Example: read_raster(here("data_raw", "eobs", "tg_0.25deg_reg_v27.0e.nc"))

# Paths (call here::here() inside your scripts, not at package load)
#   data_raw/   -> downloads
#   data_proc/  -> processed rasters/vectors
#   outputs/maps/
#   outputs/tables/

# In scripts:
#   here::here("data_raw", "some_file.nc")
#   here::here("data_proc", "admin1.gpkg")
#   here::here("outputs", "maps", "map1.png")
#   here::here("outputs", "tables", "summary.csv")
