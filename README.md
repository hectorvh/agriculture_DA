# Pollination — Spatio-temporal analysis (DE–BE–NL)

Spatio-temporal analysis of **pollination-relevant climate** and **crop exposure** for the DE–BE–NL corridor. The pipeline computes a continuous **Pollination Suitability Index (PSI)** from E-OBS daily temperature and precipitation, uses **crop-specific flowering windows** (MM-DD) for rapeseed, temperate fruits, and sunflower, combines PSI with **SPAM 2020** crop fractions to produce crop-weighted suitability and deficit exposure, and aggregates to **NUTS2** with **Global Moran's I** and **LISA** per crop.

**R stack:** terra, sf, exactextractr, sfdep, spdep, dplyr, tidyr, tmap, ggplot2, here, quarto.

---

## Folder structure

| Path | Description |
|------|-------------|
| **`data_raw/`** | Raw data (not in git). Filled by `R/setup.R` or `R/download_data_raw.R` from a Google Drive zip. Expected: `admin/` (NUTS GeoPackage), `eobs/` (E-OBS NetCDFs), `spam/` (SPAM GeoTIFFs). |
| **`data_proc/rasters/`** | Clipped E-OBS, full-period daily PSI, per-window PSI summaries, crop fractions, crop-weighted rasters. |
| **`data_proc/tables/`** | Admin stats (`admin_pollination_stats.csv`), regional daily PSI (`psi_region_day_full.csv`, `psi_region_day_{crop}.csv`), clustering and exposure comparison CSVs. |
| **`data_proc/vectors/`** | `admin_stats_lisa.gpkg` (NUTS2 with LISA results per crop). |
| **`outputs/maps/`** | Baseline and per-crop tmap rasters (PSI mean, equiv days/year, interannual SD, crop fraction, crop suit, crop bad, LISA). |
| **`outputs/plots/`** | Time-series plots of daily regional mean PSI for 2020 crop windows (top 12 regions by crop_bad). |
| **`outputs/tables/`** | Top-10 rankings per crop/metric, `crop_exposure_comparison.csv`, `crop_exposure_summary.csv` (one row per crop: mean_bad, p90_bad, mean_suit). |
| **`R/`** | Setup, download, data-cleaning, and package-list scripts. |

**Root:** `main.qmd` (Quarto report, single pipeline), `README.md`, `.gitignore`.

---

## R scripts (`R/`)

| Script | Purpose |
|--------|---------|
| **`setup.R`** | One-time: check project root, install packages (terra, sf, exactextractr, sfdep, spdep, dplyr, tidyr, tmap, here, googledrive, quarto, ggplot2), then run `download_data_raw()` to fetch and unzip `data_raw` from Google Drive. Run: `source("R/setup.R")`. |
| **`download_data_raw.R`** | Downloads `data_raw.zip` from Google Drive (by file ID), unzips into `data_raw/`, deletes zip. Uses `drive_auth(scopes = "https://www.googleapis.com/auth/drive.readonly")`. Skips if `data_raw/` exists and is non-empty. |
| **`data_cleaning.R`** | Defines `path_nuts_gpkg`, `read_nuts_raw()`. Sourced by `main.qmd` setup. |
| **`packages.R`** | Package list (no execution); installation is in `R/setup.R`. |

---

## Data and sources

| Data | Source |
|------|--------|
| **NUTS** | [GISCO – NUTS](https://ec.europa.eu/eurostat/web/gisco/geodata/statistical-units/territorial-units-statistics). GeoPackage, NUTS 2024, EPSG:3035. Used at **NUTS2** (`LEVL_CODE == 2`). |
| **E-OBS** | [Climate Data Store](https://cds.climate.copernicus.eu/), `insitu-gridded-observations-europe`. Daily mean temperature (TG) and precipitation (RR), 0.1° grid; e.g. 2011–2022. NetCDF in `data_raw/eobs/`. |
| **SPAM 2020** | IFPRI, [Harvard Dataverse](https://doi.org/10.7910/DVN/SWPENT). Harvested area GeoTIFFs: RAPE, TEMF, SUNF in `data_raw/spam/`. |

**Getting `data_raw`:** Run `source("R/setup.R")` once (installs packages and downloads/unzips from Google Drive). One-time Google auth may be required. Alternatively run `download_data_raw()` after sourcing `R/download_data_raw.R` with `skip_if_exists = FALSE` to refresh.

---

## PSI (Pollination Suitability Index)

- **Computed once** over the full E-OBS period, then subset by crop window.
- **Continuous 0–1** per day: `temp_score × rain_score`, piecewise linear.
- **Temperature:** Optimum 19–30°C, zero at 10°C and 40°C (suitable for both cool-season and mid-summer flowering).
- **Rain:** Optimum ≤ 1 mm/day, zero at ≥ 5 mm/day.
- **Crop windows (MM-DD):**
  - **rape:** 04-01 to 05-31  
  - **temf:** 04-05 to 05-10  
  - **sunf:** 07-10 to 08-10  

Per-window summaries: mean PSI, equivalent suitable days (sum of daily PSI), equivalent suitable days per year, deficit days per year, interannual SD of yearly window means.

---

## Main workflow (`main.qmd`)

1. **Setup** — Source `R/setup.R`, `R/data_cleaning.R`; set `PROJ_LIB` for terra; load libraries.
2. **Load and check** — E-OBS TG/RR NetCDFs, NUTS admin; check CRS, resolution, time index.
3. **Study area** — Filter admin to DE–BE–NL, NUTS2; fix geometry; build mask (WGS84).
4. **Clip E-OBS** — Mask/crop to DE–BE–NL; save `tg_debenl.tif`, `rr_debenl.tif`.
5. **Time index and helpers** — Align dates; define `select_window_by_mmdd()`, `summarize_window()`, `make_crop_fraction()`, `plot_and_save_raster()`, `build_region_day_table()`.
6. **Daily PSI (full period)** — `compute_daily_psi(tg_clip, rr_clip)` → `psi_daily_full`; save `psi_daily_full.tif`.
7. **Baseline + crop windows** — Baseline Apr–May (04-01 to 05-31); per-crop windows (rape, temf, sunf). For each: mean, equiv_days, equiv_days_per_year, deficit_days_per_year, interannual_sd. Save all rasters to `data_proc/rasters/`.
8. **SPAM and crop fraction** — Load SPAM RAPE/TEMF/SUNF; align to template; crop fraction = harvested area / cell area (ha), clamped [0,1]. Save `crop_frac_{crop}.tif`.
9. **Crop-weighted metrics** — `crop_suit_{crop} = psi_mean_{crop} * crop_frac_{crop}` (fraction-based); `crop_bad_{crop} = psi_deficit_days_per_year_{crop} * crop_frac_{crop}` (day-based). Save `crop_suit_*.tif`, `crop_bad_*.tif`.
10. **Admin stats** — Zonal means with exactextractr into NUTS2; stable `region_id = NUTS_ID`. All crop-specific and baseline fields; NA crop fields replaced with 0. Save `admin_pollination_stats.csv`.
11. **Spatial autocorrelation** — Global Moran's I and LISA per crop (crop_bad, crop_suit). LISA cluster labels (HH/LH/LL/HL) from sfdep or fallback. Save `admin_stats_lisa.gpkg`, `crop_clustering_comparison.csv`.
12. **Maps** — Baseline (PSI mean, equiv days/year, interannual SD); per crop: PSI mean, equiv days/year, crop fraction, crop suit, crop bad, LISA (crop_bad). Titles include window dates (e.g. sunf: 07-10 to 08-10). All with NUTS2 + NUTS0 borders. Save to `outputs/maps/`.
13. **Time-series** — One extraction of regional daily mean PSI from `psi_daily_full` → `psi_region_day_full`; filter by crop window and 2020 for plots. Top 12 regions by crop_bad per crop; one plot per crop. Save `ts_psi_daily_top12_{crop}_bad_{start}_{end}_2020.png` to `outputs/plots/`.
14. **Ranking tables** — Top 10 per crop by crop_bad and crop_suit; `crop_exposure_comparison.csv` (stacked rankings). One-row-per-crop summary `crop_exposure_summary.csv` (mean_bad, p90_bad, mean_suit) for cross-crop comparison. Save to `outputs/tables/` and `data_proc/tables/`.

---

## Outputs produced

**Rasters (`data_proc/rasters/`):**  
`tg_debenl.tif`, `rr_debenl.tif`, `psi_daily_full.tif`, baseline `psi_*_am.tif`, per-crop `psi_*_{rape,temf,sunf}.tif`, `crop_frac_*.tif`, `crop_suit_*.tif`, `crop_bad_*.tif`.

**Tables (`data_proc/tables/`):**  
`admin_pollination_stats.csv`, `psi_region_day_full.csv`, `psi_region_day_{rape,temf,sunf}.csv`, `crop_clustering_comparison.csv`, `crop_exposure_comparison.csv`, `crop_exposure_summary.csv`, `window_summary.csv`.

**Vectors (`data_proc/vectors/`):**  
`admin_stats_lisa.gpkg`.

**Maps (`outputs/maps/`):**  
`map_psi_mean.png`, `map_psi_days.png`, `map_psi_interannual_sd.png`, and per crop: `map_psi_mean_*.png`, `map_psi_equiv_days_per_year_*.png`, `map_crop_frac_*.png`, `map_crop_suit_*.png`, `map_crop_bad_*.png`, `map_lisa_*_bad.png`.

**Plots (`outputs/plots/`):**  
`ts_psi_daily_top12_rape_bad_0401_0531_2020.png`, `ts_psi_daily_top12_temf_bad_0405_0510_2020.png`, `ts_psi_daily_top12_sunf_bad_0710_0810_2020.png`.

**Tables (`outputs/tables/`):**  
`top10_{rape,temf,sunf}_bad.csv`, `top10_{rape,temf,sunf}_suit.csv`, `crop_exposure_comparison.csv`, `crop_exposure_summary.csv`, `window_summary.csv`.

---

## R stack

| Role | Packages |
|------|----------|
| **Raster** | **terra** (E-OBS, PSI, SPAM, masking, app/summaries) |
| **Vector** | **sf** (NUTS, geometry, transform) |
| **Zonal** | **exactextractr** (regional means from rasters) |
| **Spatial stats** | **sfdep**, **spdep** (neighbors, weights, Global Moran's I, LISA) |
| **Wrangling** | **dplyr**, **tidyr**, **tibble** |
| **Mapping** | **tmap** (rasters + borders), **ggplot2** (time series) |
| **Paths / run** | **here**, **googledrive**, **quarto** |

---

## Setup (one-time)

1. Open project in R (working directory = project root).
2. Run:
   ```r
   source("R/setup.R")
   ```
   Installs packages and downloads/unzips `data_raw` from Google Drive if needed.
3. Render report:
   ```r
   quarto::quarto_render("main.qmd")
   ```
   Or run chunks in `main.qmd` interactively.

**Re-download data only:**  
`source(here::here("R", "download_data_raw.R")); download_data_raw(root_dir = here::here(), skip_if_exists = FALSE)`  

**Google Drive 403:**  
`gargle::gargle_oauth_cache_clear("googledrive")` then re-run download and approve read-only Drive access.

---

## Paths

Use **here** from project root:

```r
here::here("data_raw", "eobs", "tg_ens_mean_0.1deg_reg_2011-2022_v27.0e.nc")
here::here("data_raw", "admin", "NUTS_RG_20M_2024_3035.gpkg")
here::here("data_raw", "spam", "spam2020_V2r0_global_H_RAPE_A.tif")
here::here("data_proc", "rasters", "psi_daily_full.tif")
here::here("data_proc", "tables", "admin_pollination_stats.csv")
here::here("data_proc", "vectors", "admin_stats_lisa.gpkg")
here::here("outputs", "maps", "map_psi_mean_rape.png")
here::here("outputs", "plots", "ts_psi_daily_top12_rape_bad_0401_0531_2020.png")
here::here("outputs", "tables", "top10_rape_bad.csv")
```

---

## Git and ignored files

Not tracked: `.RData`, `.Rhistory`, `.Rprofile`, `data_raw/`, `data_raw.zip`, `renv/library/`, `renv/local/`, `.Rproj.user`, `*.RprojREADME_files`.

Tracked: `main.qmd`, `R/*.R`, `README.md`, `.gitignore`.
