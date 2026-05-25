# fetch_dryad.R --------------------------------------------------------------
# Download data files for this analysis from the Dryad package and cache them
# locally under `data/`. Sourced at the top of analysis Rmds and by build.R.
#
# Three resolution modes, tried in order:
#
#   1. LOCAL ZIP  (most reliable while the dataset is in review)
#        Set env var DRYAD_ZIP_PATH to a zip you downloaded from your Dryad
#        share URL via a browser, e.g.
#            Sys.setenv(DRYAD_ZIP_PATH = "~/Downloads/dryad_share.zip")
#        Defaults to ./dryad_share.zip if that file exists.
#
#   2. SHARE URL  (in-review dataset, scripted download)
#        Set env var DRYAD_SHARE_URL to your private share link
#        (https://datadryad.org/share/.../{TOKEN}). The script parses the
#        share page for filename -> download URL pairs. Dryad's download
#        endpoint sits behind an AWS WAF JS challenge that frequently
#        blocks scripted clients (HTTP 202 + challenge page); if that
#        happens, fall back to mode 1.
#
#   3. PUBLIC DOI  (after the dataset is released)
#        Uses rdryad against DRYAD_DOI.
#
# Files already present in `data_dir` are always skipped (cache hit).
# ---------------------------------------------------------------------------

DRYAD_DOI <- "10.5061/dryad.pvmcvdp1p"

# Browser-like headers — Dryad's WAF will 403/202 plain curl-style requests.
.dryad_ua <- "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
.dryad_headers <- function(referer = NULL) {
  h <- c(
    "User-Agent"      = .dryad_ua,
    "Accept"          = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language" = "en-US,en;q=0.9"
  )
  if (!is.null(referer)) h <- c(h, "Referer" = referer)
  h
}

# Resolve a Dryad share page to a data.frame of file name + absolute URL.
.share_manifest <- function(share_url) {
  tmp <- tempfile(fileext = ".html")
  ok <- tryCatch({
    utils::download.file(share_url, tmp, quiet = TRUE,
                         headers = .dryad_headers())
    TRUE
  }, error = function(e) { warning("Share URL fetch failed: ", conditionMessage(e)); FALSE })
  if (!ok) return(NULL)
  html <- paste(readLines(tmp, warn = FALSE), collapse = "\n")
  # Each download link looks like:
  #   <a class="js-individual-dl" href="/downloads/file_stream/NNN?share=TOKEN">
  #     <i ...></i>FILENAME</a>
  pat <- '<a[^>]*class="js-individual-dl"[^>]*href="(/downloads/file_stream/[^"]+)"[^>]*>(?:<[^>]*>)*([^<]+)</a>'
  hits <- regmatches(html, gregexpr(pat, html, perl = TRUE))[[1]]
  if (length(hits) == 0) {
    warning("No file links found on share page (HTML may have changed).")
    return(NULL)
  }
  caps <- regmatches(hits, regexec(pat, hits, perl = TRUE))
  data.frame(
    name = trimws(vapply(caps, function(x) x[3], character(1))),
    url  = paste0("https://datadryad.org", vapply(caps, function(x) x[2], character(1))),
    stringsAsFactors = FALSE
  )
}

# Resolve a Dryad DOI to a manifest data.frame via rdryad (public datasets).
.doi_manifest <- function(doi) {
  if (!requireNamespace("rdryad", quietly = TRUE)) return(NULL)
  ds <- tryCatch(rdryad::dryad_dataset(dois = doi), error = function(e) NULL)
  if (is.null(ds) || length(ds) == 0) return(NULL)
  entry <- ds[[1]]
  if (!is.null(entry$message)) {
    warning("Dryad API: ", entry$message)
    return(NULL)
  }
  ds_id <- entry$id
  if (is.null(ds_id)) return(NULL)
  versions <- tryCatch(rdryad::dryad_versions(ids = ds_id), error = function(e) NULL)
  if (is.null(versions) || length(versions) == 0) return(NULL)
  vdf <- versions[[1]]
  version_id <- if (is.data.frame(vdf) && "id" %in% names(vdf)) tail(vdf$id, 1) else NULL
  if (is.null(version_id)) return(NULL)
  files <- tryCatch(rdryad::dryad_versions_files(ids = version_id), error = function(e) NULL)
  if (is.null(files) || length(files) == 0) return(NULL)
  fdf <- files[[1]]
  if (!is.data.frame(fdf)) return(NULL)
  name_col <- intersect(c("path", "name", "title"), names(fdf))[1]
  url_col  <- intersect(c("download", "download_url", "href"), names(fdf))[1]
  if (is.na(name_col) || is.na(url_col)) return(NULL)
  data.frame(name = fdf[[name_col]], url = fdf[[url_col]], stringsAsFactors = FALSE)
}

# Extract requested files from a local zip (mode 1).
.fetch_from_zip <- function(zip_path, files, data_dir, overwrite) {
  in_zip <- tryCatch(utils::unzip(zip_path, list = TRUE)$Name,
                     error = function(e) { warning("Bad zip: ", conditionMessage(e)); character() })
  if (length(in_zip) == 0) return(character())
  # Match by basename so we tolerate nested archives (e.g. "v20260525/foo.csv").
  base_to_path <- setNames(in_zip, basename(in_zip))
  fetched <- character()
  for (f in files) {
    dest <- file.path(data_dir, f)
    if (!overwrite && file.exists(dest)) { fetched <- c(fetched, f); next }
    if (is.na(base_to_path[f])) next
    message("Extracting ", f, " from ", basename(zip_path))
    utils::unzip(zip_path, files = base_to_path[[f]], exdir = data_dir, junkpaths = TRUE)
    if (file.exists(dest)) fetched <- c(fetched, f)
  }
  fetched
}

# Download requested files from a manifest (mode 2 or 3).
.fetch_from_manifest <- function(manifest, files, data_dir, overwrite, referer = NULL) {
  fetched <- character()
  for (f in files) {
    dest <- file.path(data_dir, f)
    if (!overwrite && file.exists(dest)) { fetched <- c(fetched, f); next }
    url <- manifest$url[manifest$name == f]
    if (length(url) == 0) {
      warning("File '", f, "' not found in Dryad manifest")
      next
    }
    message("Downloading ", f, " ...")
    ok <- tryCatch({
      utils::download.file(url[1], dest, mode = "wb", quiet = TRUE,
                           headers = .dryad_headers(referer = referer))
      # Reject anti-bot challenge pages (HTML when we expected data).
      # Dryad currently fronts /downloads/file_stream with an Anubis-style
      # challenge that returns ~2.5KB HTML; AWS WAF "goku" challenge is
      # similar. Real data never starts with '<', so use that as the test.
      head_bytes <- tryCatch(readBin(dest, what = "raw", n = 512),
                             error = function(e) raw(0))
      if (length(head_bytes) > 0) {
        head_txt <- rawToChar(head_bytes[head_bytes != as.raw(0)])
        is_html <- grepl("^\\s*<", head_txt) ||
                   grepl("doctype html|AwsWafIntegration|Validating\\.\\.\\.|<html", head_txt, ignore.case = TRUE)
        if (is_html) {
          stop("got anti-bot challenge page instead of file contents ",
               "(Dryad is blocking scripted downloads; use DRYAD_ZIP_PATH ",
               "with a browser-downloaded zip)")
        }
      }
      TRUE
    }, error = function(e) {
      message("  failed: ", conditionMessage(e))
      if (file.exists(dest)) file.remove(dest)
      FALSE
    })
    if (isTRUE(ok)) fetched <- c(fetched, f)
  }
  fetched
}

fetch_dryad <- function(files,
                        doi       = DRYAD_DOI,
                        share_url = Sys.getenv("DRYAD_SHARE_URL", unset = NA),
                        zip_path  = Sys.getenv("DRYAD_ZIP_PATH", unset = NA),
                        data_dir  = here::here("data"),
                        overwrite = FALSE) {
  dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

  needed <- if (overwrite) files else files[!file.exists(file.path(data_dir, files))]
  if (length(needed) == 0) {
    message("All requested files already present in ", data_dir)
    return(invisible(file.path(data_dir, files)))
  }

  # Default zip_path to ./dryad_share.zip if it happens to be there.
  if ((is.na(zip_path) || !nzchar(zip_path)) &&
      file.exists(here::here("dryad_share.zip"))) {
    zip_path <- here::here("dryad_share.zip")
  }

  remaining <- needed

  # Mode 1: local zip
  if (!is.na(zip_path) && nzchar(zip_path) && file.exists(zip_path)) {
    message("Resolving from local zip: ", zip_path)
    got <- .fetch_from_zip(zip_path, remaining, data_dir, overwrite)
    remaining <- setdiff(remaining, got)
  }

  # Mode 2: share URL
  if (length(remaining) > 0 && !is.na(share_url) && nzchar(share_url)) {
    message("Resolving from Dryad share URL.")
    sm <- .share_manifest(share_url)
    if (!is.null(sm)) {
      got <- .fetch_from_manifest(sm, remaining, data_dir, overwrite, referer = share_url)
      remaining <- setdiff(remaining, got)
    }
  }

  # Mode 3: public DOI
  if (length(remaining) > 0) {
    message("Resolving from public DOI ", doi, ".")
    dm <- .doi_manifest(doi)
    if (!is.null(dm)) {
      got <- .fetch_from_manifest(dm, remaining, data_dir, overwrite)
      remaining <- setdiff(remaining, got)
    }
  }

  if (length(remaining) > 0) {
    warning("Could not fetch: ", paste(remaining, collapse = ", "), "\n",
            "Options:\n",
            "  - Set DRYAD_ZIP_PATH=/path/to/zip after downloading the share-URL\n",
            "    zip in your browser (recommended while dataset is private).\n",
            "  - Set DRYAD_SHARE_URL=... (may be blocked by Dryad's WAF).\n",
            "  - Wait until the dataset is published on Dryad.")
  }
  invisible(file.path(data_dir, files))
}
