# setup.R — Run once to install packages and download data_raw (via R/download_data_raw.R)
# Usage: from project root, in R: source(here::here("R", "setup.R"))

library(here)

# -----------------------------------------------------------------------------
# 1) Ensure we're in project root (main.qmd at root)
# -----------------------------------------------------------------------------
if (!file.exists(here::here("main.qmd"))) {
  stop("Run setup from the project root (directory containing main.qmd).")
}

# -----------------------------------------------------------------------------
# 2) Packages used in main.qmd + quarto (from packages.R + quarto + ggplot2)
# -----------------------------------------------------------------------------
repos <- "https://cloud.r-project.org"

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
  "googledrive",
  "quarto",
  "ggplot2"
)

message("Installing / checking packages ...")
for (p in .pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = repos)
  }
}

# -----------------------------------------------------------------------------
# 3) Download data_raw.zip from Google Drive and unzip to data_raw/
# -----------------------------------------------------------------------------
source(here::here("R", "download_data_raw.R"))
download_data_raw(root_dir = here::here(), skip_if_exists = TRUE)

message("Setup complete. You can run main.qmd (e.g. quarto::quarto_render('main.qmd')).")
