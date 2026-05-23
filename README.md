# nemo_field_ch1_adaptive_capacity

Chapter 1 analysis code for the *Nemophila menziesii* field
experiment: aster modeling of fitness components and adaptive capacity in
four California wildflower populations.

Code is adapted from Peschel and Shaw 2024.

This repository contains only the Rmarkdown analysis scripts. The raw and
processed data live in a Dryad data package (DOI
[10.5061/dryad.pvmcvdp1p](https://doi.org/10.5061/dryad.pvmcvdp1p)) and are
fetched on first run by `R/fetch_dryad.R`.

## Provenance

This repo was split from
[helenepayne/nemo_field](https://github.com/helenepayne/nemo_field) (now
archived). The full pre-split commit history of this chapter is preserved in
that monorepo.

## Sister repositories

- [nemo_field_ch2_evolvability](https://github.com/helenepayne/nemo_field_ch2_evolvability)
  — Chapter 2 (Quercus + MCMC animal model).
- [nemo_field_ch3_phenotypic_plasticity](https://github.com/helenepayne/nemo_field_ch3_phenotypic_plasticity)
  — Chapter 3.

## Layout

```
.
├── aster/                 # main analysis Rmds (one per site)
├── R/fetch_dryad.R        # helper to download data from Dryad
├── data/                  # populated at runtime (gitignored)
└── .mailmap               # unified author identities
```

## Running the analyses

1. Clone this repo.
2. Open the project in RStudio (the `.Rmd` files use `here::here()` to resolve
   paths, so it just needs to be opened from the repo root).
3. The first Rmd you knit will trigger `R/fetch_dryad.R`, which downloads the
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
   └── HR_compiledsheet_full_2023.csv
   ```

4. Knit any of `aster/Aster6_*.Rmd`.

## Authors

Helen E. Payne, with guidance from Dr. Anna Peschel and Dr. Susan Mazer, and contributions from Devin Gamble (compiling datasheets). See `git log` for per-file attribution.
