library(geodata)
library(terra)

# WorldClim maximum temperature (tmax) for Poland ----------------------------
out_dir = "data/worldclim"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

pol_tmax = geodata::worldclim_country(
    country = "POL",
    var = "tmax",
    res = 10,
    path = out_dir
) |>
  project("EPSG:2180", res = 500)

pol_border = geodata::gadm(country = "POL", level = 0, path = out_dir)
pol_border_p = project(pol_border, crs(pol_tmax))

pol_tmax_c = mask(pol_tmax, pol_border_p)
names(pol_tmax_c) = month.name

writeRaster(
    pol_tmax_c,
    filename = "data/poland_tmax_monthly.tif",
    overwrite = TRUE,
    filetype = "COG",
    wopt = list(
        gdal = c(
            "COMPRESS=ZSTD",
            "LEVEL=19",
            "PREDICTOR=2",
            "BLOCKSIZE=512"
        )
    )
)
