# setup.R — Run once to install packages and download data_raw from Google Drive
# Usage: from project root, in R: source("setup.R")

# -----------------------------------------------------------------------------
# 1) Ensure we're in project root
# -----------------------------------------------------------------------------
if (!file.exists("main.qmd") && !file.exists("data_cleaning.R")) {
  stop("Run setup.R from the project root (directory containing main.qmd).")
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
# Share link: https://drive.google.com/file/d/1TLU2tMSJ6exEXXrR_FwvIL6va9WXZlz6/view?usp=sharing
drive_file_id <- "1TLU2tMSJ6exEXXrR_FwvIL6va9WXZlz6"
out_zip <- file.path(getwd(), "data_raw.zip")
out_dir <- file.path(getwd(), "data_raw")

if (!dir.exists(out_dir) || length(list.files(out_dir, recursive = TRUE)) == 0) {
  message("Downloading data_raw.zip from Google Drive (one-time auth may be required) ...")
  if (!requireNamespace("googledrive", quietly = TRUE)) {
    stop("Install googledrive first: install.packages('googledrive')")
  }
  googledrive::drive_auth()
  googledrive::drive_download(
    googledrive::as_id(drive_file_id),
    path = out_zip,
    overwrite = TRUE
  )
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  # Unzip: if archive has single top-level folder "data_raw", flatten into ./data_raw
  tmp_ex <- tempfile("unzip_data_raw")
  dir.create(tmp_ex, showWarnings = FALSE)
  unzip(out_zip, exdir = tmp_ex)
  top <- list.files(tmp_ex, full.names = TRUE)
  if (length(top) == 1L && dir.exists(top[1]) && basename(top[1]) == "data_raw") {
    # Archive was data_raw/<contents>
    file.copy(list.files(top[1], full.names = TRUE), out_dir, recursive = TRUE)
  } else {
    # Archive was <contents> at root
    file.copy(top, out_dir, recursive = TRUE)
  }
  unlink(tmp_ex, recursive = TRUE)
  if (file.exists(out_zip)) {
    file.remove(out_zip)
  }
  message("data_raw/ populated from Google Drive.")
} else {
  message("data_raw/ already exists and is non-empty; skipping download.")
}

message("Setup complete. You can run main.qmd (e.g. quarto::quarto_render('main.qmd')).")
