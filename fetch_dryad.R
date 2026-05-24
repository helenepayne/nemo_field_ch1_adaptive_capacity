# fetch_dryad.R --------------------------------------------------------------
# Download data files for this analysis from the Dryad package and cache them
# locally under `data/`. Intended to be sourced at the top of any Rmd that
# reads from data/.
#
# Usage:
#   source(here::here("fetch_dryad.R"))
#   fetch_dryad(c("AC_compiledsheet_full_2022.csv",
#                 "AC_compiledsheet_full_2023.csv"))
#
# Behaviour:
#   - First run: hits the Dryad API, downloads files into data/.
#   - Subsequent runs: skips files already present in data/.
#   - If the Dryad package is private/embargoed (HTTP 403/404), the function
#     warns and exits gracefully so that users with a local copy of the data
#     in data/ can still run analyses without internet access.
# ---------------------------------------------------------------------------

DRYAD_DOI <- "10.5061/dryad.pvmcvdp1p"

fetch_dryad <- function(files,
                        doi      = DRYAD_DOI,
                        data_dir = here::here("data"),
                        overwrite = FALSE) {
  if (!requireNamespace("rdryad", quietly = TRUE)) {
    stop("Package 'rdryad' is required. Install with install.packages('rdryad').")
  }
  dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

  missing <- if (overwrite) files
             else files[!file.exists(file.path(data_dir, files))]

  if (length(missing) == 0) {
    message("All requested files already present in ", data_dir)
    return(invisible(file.path(data_dir, files)))
  }

  manifest <- tryCatch(
    rdryad::dryad_files(doi = doi),
    error = function(e) {
      warning("Could not query Dryad for DOI ", doi, ": ", conditionMessage(e),
              "\nIf the dataset is private/embargoed, populate ", data_dir,
              " manually for now.")
      return(NULL)
    }
  )
  if (is.null(manifest)) return(invisible(NULL))

  for (f in missing) {
    url <- manifest$download_url[manifest$name == f]
    if (length(url) == 0) {
      warning("File '", f, "' not found in Dryad package ", doi)
      next
    }
    dest <- file.path(data_dir, f)
    message("Downloading ", f, " from Dryad...")
    tryCatch(
      utils::download.file(url[1], dest, mode = "wb", quiet = TRUE),
      error = function(e) warning("Download failed for ", f, ": ", conditionMessage(e))
    )
  }
  invisible(file.path(data_dir, files))
}
