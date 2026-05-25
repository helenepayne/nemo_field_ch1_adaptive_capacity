# nemo_field_ch1_adaptive_capacity

Chapter 1 analysis code for a two-year field experiment with pedigreed seeds at four sites with natural populations of Baby Blue Eyes (*Nemophila menziesii* H. & A.), an annual wildflower native to western North America, to evaluate the correspondence between the magnitude of VA(W) and the realized adaptation in the following generation.

Code is adapted from Peschel and Shaw 2024.

This repository contains only the Rmarkdown analysis scripts. The raw and
processed data live in a Dryad data package (DOI
[10.5061/dryad.pvmcvdp1p](https://doi.org/10.5061/dryad.pvmcvdp1p)) and are
fetched on first run by `fetch_dryad.R`.

## Provenance

This repo was split from
[helenepayne/nemo_field](https://github.com/helenepayne/nemo_field) (now
archived). The full pre-split commit history of this chapter is preserved in
that monorepo.

## Sister repositories

- [nemo_field_ch2_evolvability](https://github.com/helenepayne/nemo_field_ch2_evolvability)
  — Chapter 2 (Evolvability, G matrices, using the MCMC animal model).
- [nemo_field_ch3_phenotypic_plasticity](https://github.com/helenepayne/nemo_field_ch3_phenotypic_plasticity)
  — Chapter 3 (Plasticity in focal traits)

## Layout

```
.
├── Aster6_*.Rmd           # main analysis Rmds (one per site)
├── Aster_Figures_BV.Rmd   # figure generation
├── Temp and Precip 2022 and 2023.Rmd
├── build.R                # end-to-end build (fetch + knit all Rmds)
├── fetch_dryad.R          # helper to download data from Dryad
├── data/                  # populated at runtime (gitignored)
├── figures/               # plot outputs (gitignored)
├── tables/                # CSV outputs from analyses (gitignored)
└── processed_data/        # aster model .rdata outputs (gitignored)
```

## Running the analyses

### One-shot build

```
Rscript build.R
```

Runs the full pipeline:

1. Fetches the data package from Dryad into `data/` (see "Getting the data"
   below).
2. Knits the four `Aster6_{Angelo,BlueOak,BodegaBay,Hastings}.Rmd` files to
   HTML in parallel — each writes per-site `*_bhat.Donor.mu.csv` files into
   `tables/`.
3. Knits `Aster_Figures_BV.Rmd` and `Temp and Precip 2022 and 2023.Rmd` to
   HTML in parallel, consuming the `tables/` outputs from step 2.

Per-render logs are written next to each Rmd as `<name>.build.log`. The
build halts immediately if any step fails.

### Knitting individual Rmds

The `.Rmd` files use `here::here()` to resolve paths, so opening the project
from the repo root in RStudio "just works". The first Rmd you knit calls
`fetch_dryad.R` to populate `data/`.

### Getting the data

`fetch_dryad.R` tries three sources in order; the first that has the file
wins:

1. **Local zip** (most reliable while the dataset is in peer review).
   Download the share-URL zip in your browser, then point the script at it:

   ```
   export DRYAD_ZIP_PATH=~/Downloads/dryad_share.zip
   ```

   A `dryad_share.zip` at the repo root is picked up automatically.

2. **Share URL** — set `DRYAD_SHARE_URL` to your Dryad private share link.
   Dryad fronts its download endpoint with an AWS WAF JavaScript challenge
   that frequently blocks scripted clients; if you hit a WAF challenge,
   fall back to mode 1.

   ```
   export DRYAD_SHARE_URL='https://datadryad.org/share/.../{TOKEN}'
   ```

3. **Public DOI** — once the dataset is published at
   [10.5061/dryad.pvmcvdp1p](https://doi.org/10.5061/dryad.pvmcvdp1p),
   no configuration is needed. `rdryad` enumerates and downloads the
   files.

Files already in `data/` are skipped — repeated runs only fetch what's
missing.

The expected layout of `data/` after a successful fetch:

```
data/
├── AC_compiledsheet_full_2022.csv
├── AC_compiledsheet_full_2023.csv
├── BB_compiledsheet_full_2022.csv
├── BB_compiledsheet_full_2023.csv
├── BO_compiledsheet_full_2022.csv
├── BO_compiledsheet_full_2023.csv
├── HR_compiledsheet_full_2022.csv
├── HR_compiledsheet_full_2023.csv
├── 2022-temp.csv
├── 2023-temp.csv
├── 2022-rainfall.csv
├── 2023-rainfall.csv
├── w_bothyears.csv
├── PRISM_tmean_30yr_normal.tif
└── PRISM_ppt_30yr_normal.tif
```

## Authors

Helen E. Payne, with guidance from Dr. Anna Peschel and Dr. Susan Mazer, and contributions from Devin Gamble (compiling datasheets). See `git log` for per-file attribution.
