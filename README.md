# supercells demo datasets

These are small, ready-to-use geospatial raster datasets for `supercells` vignettes and examples.
**supercells** is an R package for building compact, spatially coherent regions (supercells) from rasters; see
CRAN (https://CRAN.R-project.org/package=supercells) and GitHub (https://github.com/Nowosad/supercells).

## Datasets (data/)

- `muenster_embeddings_2024.tif` - A compact embedding raster for the Muenster area in 2024; a 64-band feature raster stack that is a realistic high-dimensional input for supercells.
- `muenster-landsat_2024.tif` - A simple 4-band Landsat composite (blue/green/red/nir) for 2024, useful for quick visual checks and classic remote-sensing examples.
- `poland_evi_2020_bimonthly.tif` - Six bimonthly EVI layers for Poland in 2020; good for showing how supercells behave on seasonal vegetation dynamics.
- `poland_tmax_monthly.tif` - Monthly maximum temperature climatology for Poland; a smooth, low-noise surface.

## Scripts (R/)

- `01-prepare-embeddings-muenster-2024.R` - downloads/dequantizes/crops embeddings; writes `muenster_embeddings_2024.tif`.
- `02-prepare-tmax-poland.R` - downloads/warps tmax; writes `poland_tmax_monthly.tif`.
- `03-prepare-evi-poland-2020.R` - downloads/warps EVI; writes `poland_evi_2020_bimonthly.tif`.
- `04-prepare-landsat-muenster-2024.R` - downloads/warps Landsat composite; writes `muenster-landsat_2024.tif`.

## Data sources

- AEF embeddings (Source Cooperative): https://data.source.coop/tge-labs/aef/
- OpenLandMap STAC catalog: https://stac.openlandmap.org/
- WorldClim: https://www.worldclim.org/

## License

This dataset bundle is released under CC0 1.0.
Upstream data sources may have their own terms; see the sources above.
