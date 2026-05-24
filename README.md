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
├── fetch_dryad.R          # helper to download data from Dryad
├── data/                  # populated at runtime (gitignored)
├── figures/               # plot outputs (gitignored)
├── tables/                # CSV outputs from analyses (gitignored)
├── processed_data/        # aster model .rdata outputs (gitignored)
└── .mailmap               # unified author identities
```

## Running the analyses

1. Clone this repo.
2. Open the project in RStudio (the `.Rmd` files use `here::here()` to resolve
   paths, so it just needs to be opened from the repo root).
3. The first Rmd you knit will trigger `fetch_dryad.R`, which downloads the
   needed CSVs into `data/`. If the Dryad package is still private (it is
   embargoed until the manuscript is peer-reviewed), populate `data/` manually
   from your local copy:

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

4. Knit any of `Aster6_*.Rmd`.

## Authors

Helen E. Payne, with guidance from Dr. Anna Peschel and Dr. Susan Mazer, and contributions from Devin Gamble (compiling datasheets). See `git log` for per-file attribution.
