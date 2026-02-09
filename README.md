# Pollination

Spatio-temporal analysis project. R stack: simple, fast, reliable.

## Folder structure

- `data_raw/` — downloads (e.g. E-OBS NetCDF)
- `data_proc/` — processed rasters/vectors
- `outputs/maps/` — map outputs
- `outputs/tables/` — table outputs
- `R/` — scripts and utilities

## Data and sources

| Data | Source |
|------|--------|
| **NUTS (Admin) boundaries** | [GISCO – Territorial units for statistics (NUTS)](https://ec.europa.eu/eurostat/web/gisco/geodata/statistical-units/territorial-units-statistics). Eurostat GISCO. GeoPackage/SHP, NUTS 2021 (or chosen year), polygons. |
| **Crop production (2020)** | International Food Policy Research Institute (IFPRI), 2024, *Global Spatially-Disaggregated Crop Production Statistics Data for 2020 Version 2.0*, [https://doi.org/10.7910/DVN/SWPENT](https://doi.org/10.7910/DVN/SWPENT), Harvard Dataverse, V4. |
| **E-OBS (climate)** | *In-situ gridded observations Europe* via [Climate Data Store (CDS)](https://cds.climate.copernicus.eu/). Dataset `insitu-gridded-observations-europe`; variables e.g. mean temperature, precipitation, sea-level pressure, relative humidity, wind speed; grid 0.1°; period e.g. 2011–2023; version 28.0e. Download via CDS API (see below). |

**E-OBS download (Python, CDS API):**

```python
import cdsapi

dataset = "insitu-gridded-observations-europe"
request = {
    "product_type": "ensemble_mean",
    "variable": [
        "mean_temperature",
        "precipitation_amount",
        "sea_level_pressure",
        "relative_humidity",
        "wind_speed"
    ],
    "grid_resolution": "0_1deg",
    "period": "2011_2023",
    "version": ["28_0e"]
}

client = cdsapi.Client()
client.retrieve(dataset, request).download()
```

Store raw downloads under `data_raw/` (e.g. E-OBS NetCDF in `data_raw/eobs/`, NUTS in `data_raw/gisco/`, IFPRI in `data_raw/ifpri/`).

## R stack

| Role | Packages |
|------|----------|
| **Core spatial** | **terra** (raster: E-OBS NetCDF, masking, resampling, raster math, time summaries), **sf** (boundaries, Admin-1 polygons, joins, geometry) |
| **Zonal statistics** | **exactextractr** (fast, accurate polygon summaries of rasters: mean/median, area-weighted) |
| **Spatial autocorrelation** | **sfdep** (tidy) + **spdep** (engine): neighbors, weights, Global Moran's I, Local Moran (LISA) |
| **Data wrangling** | **dplyr**, **tidyr** |
| **Mapping** | **tmap** (main: thematic maps). Optional: ggplot2 + tidyterra (paper-style) |
| **Repro + paths** | **here** (`here("data_raw", ...)`), **renv** (lock package versions) |

Raster workflow: keep analyses in R; use **terra::project** / **terra::resample** with a **0.1° template** (see `R/utils_template.R`).

## Setup (one-time)

1. Open project in R (set working directory to project root or open `.Rproj` if you add one).
2. Install **renv** if needed: `install.packages("renv")`.
3. Run:
   ```r
   source("R/00_setup_renv.R")
   ```
   This inits **renv**, installs the stack, and creates `renv.lock`.
4. Restart R. Next time you open the project, renv will auto-activate (`.Rprofile`).

## Paths

Use **here** for paths so scripts work from project root:

```r
here::here("data_raw", "eobs", "file.nc")
here::here("data_proc", "admin1.gpkg")
here::here("outputs", "maps", "map1.png")
here::here("outputs", "tables", "summary.csv")
```

## 0.1° template

`R/utils_template.R` provides:

- `template_01deg()` — 0.1° WGS84 template (default Europe-style extent).
- `project_and_resample(r, template, method)` — align a SpatRaster to the template.

Source when needed: `source(here::here("R", "utils_template.R"))`.
