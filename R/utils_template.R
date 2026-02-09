# 0.1° template and project/resample helpers (terra)
# Use for consistent grid: project/resample rasters to this template.

#' Create a 0.1° WGS84 template for Europe (E-OBS-style extent)
#'
#' @param xmin,xmax,ymin,ymax Extent in lon/lat (default: coarse Europe).
#' @param crs Character or terra crs (default WGS84).
#' @return SpatRaster with 0.1° resolution, 1 layer, NA values.
template_01deg <- function(xmin = -31, xmax = 40, ymin = 27, ymax = 72,
                           crs = "EPSG:4326") {
  r <- terra::rast(
    nrows = (ymax - ymin) / 0.1,
    ncols = (xmax - xmin) / 0.1,
    xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
    crs = crs,
    vals = NA
  )
  r
}

#' Project and resample a SpatRaster to a 0.1° template
#'
#' Uses terra::project() and terra::resample() so all rasters align.
#'
#' @param r SpatRaster to align.
#' @param template SpatRaster template (e.g. from template_01deg()).
#' @param method Resampling method for resample (e.g. "bilinear", "near").
#' @return SpatRaster with template grid and crs.
project_and_resample <- function(r, template, method = "bilinear") {
  if (!terra::same.crs(r, template)) {
    r <- terra::project(r, terra::crs(template), method = method)
  }
  terra::resample(r, template, method = method)
}
