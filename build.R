#!/usr/bin/env Rscript
# build.R --------------------------------------------------------------------
# End-to-end build for this analysis.
#
#   1. Fetch Dryad data into data/ (no-op if files already present).
#   2. Create output directories (tables/, etc.).
#   3. Knit Aster6_{Angelo,BlueOak,BodegaBay,Hastings}.Rmd to HTML in parallel.
#   4. Knit Aster_Figures_BV.Rmd and "Temp and Precip 2022 and 2023.Rmd"
#      to HTML in parallel (depends on tables/ produced in step 3).
#
# Usage:  Rscript build.R
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(here)
  library(rmarkdown)
  library(callr)
})

setwd(here::here())

# ---- 1. Fetch Dryad ---------------------------------------------------------
message("\n=== Step 1: Fetch Dryad data ===")
dryad_files <- c(
  "AC_compiledsheet_full_2022.csv", "AC_compiledsheet_full_2023.csv",
  "BB_compiledsheet_full_2022.csv", "BB_compiledsheet_full_2023.csv",
  "BO_compiledsheet_full_2022.csv", "BO_compiledsheet_full_2023.csv",
  "HR_compiledsheet_full_2022.csv", "HR_compiledsheet_full_2023.csv",
  "2022-temp.csv",                  "2023-temp.csv",
  "2022-rainfall.csv",              "2023-rainfall.csv",
  "w_bothyears.csv",
  "PRISM_tmean_30yr_normal.tif",    "PRISM_ppt_30yr_normal.tif"
)
missing <- dryad_files[!file.exists(file.path(here::here("data"), dryad_files))]
if (length(missing) > 0) {
  source(here::here("fetch_dryad.R"))
  fetch_dryad(missing)
  missing <- dryad_files[!file.exists(file.path(here::here("data"), dryad_files))]
  if (length(missing) > 0) {
    stop("Missing required data files in data/: ",
         paste(missing, collapse = ", "),
         "\nPopulate data/ manually or wait for Dryad release.")
  }
} else {
  message("All required data files present in data/ — skipping Dryad download.")
}

# ---- helpers ----------------------------------------------------------------
# Render a list of Rmds concurrently, each in its own background R process,
# streaming logs to <basename>.build.log. Errors if any render fails.
render_parallel <- function(rmds) {
  message("Rendering ", length(rmds), " Rmd(s) in parallel: ",
          paste(basename(rmds), collapse = ", "))

  proj <- here::here()
  jobs <- lapply(rmds, function(rmd) {
    abs_rmd <- here::here(rmd)
    log <- here::here(sub("\\.Rmd$", ".build.log", basename(rmd)))
    if (file.exists(log)) file.remove(log)
    proc <- callr::r_bg(
      func = function(abs_rmd, proj) {
        setwd(proj)
        rmarkdown::render(abs_rmd, output_format = "html_document",
                          knit_root_dir = proj, quiet = TRUE)
      },
      args = list(abs_rmd = abs_rmd, proj = proj),
      stdout = log, stderr = log,
      supervise = TRUE
    )
    list(rmd = rmd, proc = proc, log = log)
  })

  # Poll until all finish
  repeat {
    alive <- vapply(jobs, function(j) j$proc$is_alive(), logical(1))
    if (!any(alive)) break
    Sys.sleep(2)
  }

  failures <- character()
  for (j in jobs) {
    # callr::r_bg exits 0 even when the wrapped function errors (the error
    # is serialized into the result file). Call get_result() to actually
    # surface chunk failures from rmarkdown::render.
    err <- tryCatch({ j$proc$get_result(); NULL },
                    error = function(e) conditionMessage(e))
    if (!is.null(err)) {
      failures <- c(failures, j$rmd)
      message("FAILED: ", basename(j$rmd), " — ", err)
      message("        log: ", j$log)
    } else {
      message("  OK: ", basename(j$rmd))
    }
  }
  if (length(failures) > 0) {
    stop("Render failed for: ", paste(basename(failures), collapse = ", "))
  }
  invisible(NULL)
}

# ---- 2. Create output directories -------------------------------------------
message("\n=== Step 2: Create output directories ===")
dir.create(here::here("tables"),         showWarnings = FALSE)
dir.create(here::here("figures"),        showWarnings = FALSE)
dir.create(here::here("processed_data"), showWarnings = FALSE)

# ---- 3. Aster6_*.Rmd in parallel -------------------------------------------
message("\n=== Step 3: Aster6_*.Rmd ===")
render_parallel(c(
  "Aster6_Angelo.Rmd",
  "Aster6_BlueOak.Rmd",
  "Aster6_BodegaBay.Rmd",
  "Aster6_Hastings.Rmd"
))

# ---- 4. Figures + Temp/Precip in parallel ----------------------------------
message("\n=== Step 4: Figures + Temp/Precip ===")
render_parallel(c(
  "Aster_Figures_BV.Rmd",
  "Temp and Precip 2022 and 2023.Rmd"
))

message("\nBuild complete.")
