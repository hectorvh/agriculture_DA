# download_data_raw.R — Download data_raw.zip from Google Drive and unzip to data_raw/
# Called by R/setup.R; can also be run alone: source(here::here("R", "download_data_raw.R")); download_data_raw()

# Share link: https://drive.google.com/file/d/1TLU2tMSJ6exEXXrR_FwvIL6va9WXZlz6/view?usp=sharing
DATA_RAW_DRIVE_ID <- "1TLU2tMSJ6exEXXrR_FwvIL6va9WXZlz6"

#' Download data_raw.zip from Google Drive and unzip into data_raw/
#'
#' @param root_dir Project root (default: getwd()).
#' @param skip_if_exists If TRUE (default), do nothing when data_raw/ exists and is non-empty.
#' @return Invisible list with zip_path, out_dir, and whether download ran.
download_data_raw <- function(root_dir = getwd(), skip_if_exists = TRUE) {
  out_zip <- file.path(root_dir, "data_raw.zip")
  out_dir <- file.path(root_dir, "data_raw")

  if (isTRUE(skip_if_exists) &&
      dir.exists(out_dir) &&
      length(list.files(out_dir, recursive = TRUE)) > 0) {
    message("data_raw/ already exists and is non-empty; skipping download.")
    return(invisible(list(zip_path = NULL, out_dir = out_dir, downloaded = FALSE)))
  }

  message("Downloading data_raw.zip from Google Drive (one-time auth may be required) ...")
  if (!requireNamespace("googledrive", quietly = TRUE)) {
    stop("Install googledrive first: install.packages('googledrive')")
  }
  # Use read-only Drive scope so we can download; avoids 403 "insufficient scopes".
  # If you still get 403, clear the cached token and re-run so a new token is created:
  #   gargle::gargle_oauth_cache_clear("googledrive"); googledrive::drive_auth()
  googledrive::drive_auth(scopes = "https://www.googleapis.com/auth/drive.readonly")
  d <- googledrive::drive_download(
    googledrive::as_id(DATA_RAW_DRIVE_ID),
    path = out_zip,
    overwrite = TRUE
  )
  # Use actual path where the file was saved (in case googledrive alters it)
  out_zip <- as.character(d$local_path[1])
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  # Unzip to temp dir, then copy into data_raw/
  tmp_ex <- tempfile("unzip_data_raw")
  dir.create(tmp_ex, showWarnings = FALSE)
  unzip(out_zip, exdir = tmp_ex)
  top <- list.files(tmp_ex, full.names = TRUE)
  if (length(top) == 1L && dir.exists(top[1]) && basename(top[1]) == "data_raw") {
    file.copy(list.files(top[1], full.names = TRUE), out_dir, recursive = TRUE)
  } else {
    file.copy(top, out_dir, recursive = TRUE)
  }
  unlink(tmp_ex, recursive = TRUE)
  if (file.exists(out_zip)) {
    file.remove(out_zip)
  }
  message("data_raw/ populated from Google Drive.")
  invisible(list(zip_path = out_zip, out_dir = out_dir, downloaded = TRUE))
}
