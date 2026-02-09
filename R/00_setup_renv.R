# Run once to bootstrap the project:
#   1. Init renv (creates renv.lock from current R session)
#   2. Install project packages
#   3. Snapshot so renv.lock records versions
#
# Open the project in RStudio (or setwd to project root), then:
#   source("R/00_setup_renv.R")

stopifnot(
  "Run from project root (parent of R/)" = dir.exists("R"),
  "Install renv first: install.packages('renv')" = requireNamespace("renv", quietly = TRUE)
)

# Init renv if not already (creates renv/ and renv.lock)
if (!file.exists("renv.lock")) {
  renv::init(bare = TRUE)
}

# Install project packages (from R/packages.R)
source(file.path(getwd(), "R", "packages.R"))
pkgs <- get(".pkgs", envir = .GlobalEnv)
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p)
  }
}

# Record state in lockfile
renv::snapshot(prompt = FALSE)

message("Setup done. Restart R and use renv::activate() when opening the project.")
