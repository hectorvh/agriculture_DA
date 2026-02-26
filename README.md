# Pollination

Spatio-temporal analysis project for pollination-relevant climate and crop data. R stack: simple, fast, reliable. Study area: DE–BE–NL. Outputs: E-OBS–based suitability (PSI), SPAM crop fractions, zonal stats by NUTS region, and spatial autocorrelation (Moran’s I, LISA).

---
Version 2

## Folder structure

| Path | Description |
|------|--------------|
| **`data_raw/`** | Raw data (not in git). Filled by `R/setup.R` or `R/download_data_raw.R` from a Google Drive zip. Contains e.g. `admin/`, `eobs/`, `spam/`. |
| **`data_proc/`** | Processed outputs: `rasters/`, `tables/`, `vectors/`. Written by `main.qmd`. |
| **`outputs/`** | Final deliverables: `maps/`, `tables/`. |
| **`R/`** | R scripts (setup, download, data cleaning, package list). |

**Root files**

- **`main.qmd`** — Main Quarto report: full pipeline from raw data to maps and tables.
- **`.gitignore`** — Ignores `data_raw/`, `data_raw.zip`, `.RData`, `.Rhistory`, `.Rprofile`, Rproj/renv artifacts.

---

## R scripts (`R/`)

| Script | Purpose |
|--------|---------|
| **`setup.R`** | One-time setup: checks project root, installs packages (terra, sf, exactextractr, sfdep, spdep, dplyr, tidyr, tmap, here, googledrive, quarto, ggplot2), then runs `download_data_raw()` to fetch and unzip `data_raw` from Google Drive. Run from project root: `source("R/setup.R")`. |
| **`download_data_raw.R`** | Downloads `data_raw.zip` from Google Drive (by file ID), unzips into `data_raw/`, then deletes the zip. Uses `googledrive::drive_auth(scopes = "https://www.googleapis.com/auth/drive.readonly")`. Skip if `data_raw/` already exists and is non-empty. Can be run alone: `source(here::here("R", "download_data_raw.R")); download_data_raw(root_dir = here::here(), skip_if_exists = TRUE)`. |
| **`data_cleaning.R`** | Defines `path_nuts_gpkg` and `read_nuts_raw()` for NUTS boundaries. Sourced by `main.qmd` in the setup chunk. |
| **`packages.R`** | Lists required packages (no execution); referenced by docs. Installation is done in `R/setup.R`. |

---

## Data and sources

| Data | Source |
|------|--------|
| **NUTS (Admin) boundaries** | [GISCO – Territorial units for statistics (NUTS)](https://ec.europa.eu/eurostat/web/gisco/geodata/statistical-units/territorial-units-statistics). GeoPackage, NUTS 2024, EPSG:3035. |
| **Crop production (2020)** | SPAM (Spatial Production Allocation Model). IFPRI, *Global Spatially-Disaggregated Crop Production Statistics Data for 2020 Version 2.0*, [Harvard Dataverse](https://doi.org/10.7910/DVN/SWPENT). GeoTIFFs in `data_raw/spam/` (e.g. harvested area for RAPE, TEMF, SUNF). |
| **E-OBS (climate)** | *In-situ gridded observations Europe* via [Climate Data Store (CDS)](https://cds.climate.copernicus.eu/). Dataset `insitu-gridded-observations-europe`; variables e.g. mean temperature (TG), precipitation (RR); grid 0.1°; NetCDF in `data_raw/eobs/`. |

**Getting `data_raw`**

- **Recommended:** Run `source("R/setup.R")` from project root once. This installs packages and downloads a pre-packed `data_raw.zip` from Google Drive, then unzips it into `data_raw/`. One-time Google authentication may be required (read-only Drive scope).
- **Manual:** Place E-OBS NetCDFs in `data_raw/eobs/`, NUTS GeoPackage in `data_raw/admin/`, SPAM GeoTIFFs in `data_raw/spam/` to match paths in `main.qmd`.

**E-OBS download (Python, CDS API)**

```python
import cdsapi
dataset = "insitu-gridded-observations-europe"
request = {
    "product_type": "ensemble_mean",
    "variable": ["mean_temperature", "precipitation_amount", "sea_level_pressure", "relative_humidity", "wind_speed"],
    "grid_resolution": "0_1deg",
    "period": "2011_2023",
    "version": ["28_0e"]
}
client = cdsapi.Client()
client.retrieve(dataset, request).download()
```

Save outputs under `data_raw/eobs/` (or adjust paths in `main.qmd`).

---

## R stack

| Role | Packages |
|------|----------|
| **Core spatial** | **terra** (raster: E-OBS NetCDF, masking, resampling, time summaries), **sf** (boundaries, NUTS polygons, geometry) |
| **Zonal statistics** | **exactextractr** (polygon summaries of rasters: mean/median, area-weighted) |
| **Spatial autocorrelation** | **sfdep** (tidy) + **spdep** (engine): neighbors, weights, Global Moran’s I, Local Moran (LISA) |
| **Data wrangling** | **dplyr**, **tidyr** |
| **Mapping** | **tmap** (thematic maps); **ggplot2** (time series, optional) |
| **Repro + paths** | **here** (`here("data_raw", ...)`), **googledrive** (download `data_raw` from Drive) |
| **Report** | **quarto** (render `main.qmd`) |

---

## Setup (one-time)

1. **Open the project** in R (working directory = project root).
2. **Run setup:**
   ```r
   source("R/setup.R")
   ```
   This installs/checks packages and downloads and unzips `data_raw` from Google Drive. If `data_raw/` already exists and is non-empty, the download is skipped.
3. **Render the report:**
   ```r
   quarto::quarto_render("main.qmd")
   ```
   Or open `main.qmd` and run chunks interactively.

**Optional:** To only re-download `data_raw` (e.g. after clearing it), uncomment and run the `run-download-data_raw` chunk in `main.qmd`, or run:
```r
source(here::here("R", "download_data_raw.R"))
download_data_raw(root_dir = here::here(), skip_if_exists = FALSE)
```

**Google Drive 403:** If you see “insufficient authentication scopes”, clear the cached token and re-authenticate:
```r
gargle::gargle_oauth_cache_clear("googledrive")
# Then run download again; approve read-only Drive access in the browser.
```

---

## Main workflow (`main.qmd`)

The report runs a single pipeline:

1. **Setup** — Source `R/setup.R` (if present), then `R/data_cleaning.R`. Set `PROJ_LIB` for terra, load libraries.
2. **Load and check** — E-OBS (TG, RR), NUTS admin, SPAM paths; inspect CRS, resolution, time.
3. **Study area** — Filter NUTS to DE–BE–NL, fix geometry, build mask.
4. **Clip E-OBS** — Mask/crop rasters to DE–BE–NL; save to `data_proc/rasters/`.
5. **Time window** — April–May (pollination window).
6. **Daily suitability (PSI)** — Binary suitability from E-OBS rules; temporal summaries (mean suitability, suitable days, SD).
7. **SPAM** — Load crop rasters (e.g. RAPE, TEMF, SUNF), project/resample to E-OBS grid, convert to crop fraction.
8. **Crop-weighted metrics** — Crop-weighted suitability and “bad days” (exposure).
9. **Zonal stats** — Aggregate rasters to NUTS regions with **exactextractr**; write tables to `data_proc/tables/` and `outputs/tables/`.
10. **Spatial autocorrelation** — Queen contiguity, Global Moran’s I, LISA (local Moran); join back to regions.
11. **Deliverables** — Maps (tmap), time series plots, ranking tables in `outputs/maps/` and `outputs/tables/`.

---

## Paths

Use **here** so paths work from the project root:

```r
here::here("data_raw", "eobs", "file.nc")
here::here("data_raw", "admin", "NUTS_RG_20M_2024_3035.gpkg")
here::here("data_raw", "spam", "spam2020_V2r0_global_H_RAPE_A.tif")
here::here("data_proc", "rasters", "tg_debenl.tif")
here::here("data_proc", "tables", "zonal_stats.csv")
here::here("outputs", "maps", "map_suit.png")
here::here("outputs", "tables", "ranking.csv")
```

---

## Git and ignored files

The repo does **not** track:

- **`.RData`**, **`.Rhistory`**, **`.Rprofile`** — Session and local config.
- **`data_raw/`**, **`data_raw.zip`** — Raw data (obtained via `R/setup.R` or `R/download_data_raw.R`).
- **`renv/library/`**, **`renv/local/`** — renv is not used; these are ignored in case you add it later.
- **`.Rproj.user`**, **`*.RprojREADME_files`** — IDE and Quarto cache.

Tracked: `main.qmd`, `R/*.R`, `README.md`, `.gitignore`, and any small config files you add.
