library(terra)
library(geodata)
Sys.setenv(AWS_NO_SIGN_REQUEST = "YES")

# OpenLandMap MOD13Q1 EVI (bi-monthly), Poland, year 2020 -------------------

out_dir = "data/openlandmap"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

periods_2020 = c(
    "20200101_20200228",
    "20200301_20200430",
    "20200501_20200630",
    "20200701_20200831",
    "20200901_20201031",
    "20201101_20201231"
)

base_cog_url = "/vsicurl/https://s3.openlandmap.org/arco"
cog_urls = sprintf(
    "%s/evi_mod13q1.tmwm.inpaint_p.90_250m_s_%s_go_epsg.4326_v20230608.tif",
    base_cog_url,
    periods_2020
)
rasters = rast(cog_urls)

pol_border = geodata::gadm(country = "POL", level = 0, path = out_dir)

r_2020 = crop(rasters, pol_border, mask = TRUE)
r_2020 = project(r_2020, "EPSG:2180", res = 250)
names(r_2020) = paste0("EVI_", seq(1, nlyr(r_2020)))
panel(r_2020)

writeRaster(
    r_2020,
    filename = "data/poland_evi_2020_bimonthly.tif",
    overwrite = TRUE,
    gdal = "COG",
    wopt = list(
        gdal = c(
            "COMPRESS=ZSTD",
            "LEVEL=19",
            "PREDICTOR=2",
            "BLOCKSIZE=512"
        )
    )
)

r_2020 = rast("data/poland_evi_2020_bimonthly.tif")

fill_small_na = function(x, max_patch_cells = 49, wins = c(3, 5, 7, 9)) {
  na = is.na(x)
  p = patches(na, values = TRUE, directions = 8)               # connected NA areas
  f = freq(p)
  ids_small = f$value[f$count <= max_patch_cells]
  small_mask = p %in% ids_small                 # TRUE only for small NA patches

  y = x
  for (k in wins) {
    neigh = focal(
      y,
      w = matrix(1, k, k),
      fun = "mean",                              # or mean
      na.rm = TRUE,
      na.policy = "only"
    )
    y = ifel(is.na(y) & small_mask, neigh, y)
  }
  y
}

system.time({
r_2020_filled = rast(lapply(1:nlyr(r_2020), function(i) fill_small_na(r_2020[[i]])))
names(r_2020_filled) = names(r_2020)
})

writeRaster(
    r_2020_filled,
    filename = "data/poland_evi_2020_bimonthly_filled.tif",
    overwrite = TRUE,
    gdal = "COG",
    wopt = list(
        gdal = c(
            "COMPRESS=ZSTD",
            "LEVEL=19",
            "PREDICTOR=2",
            "BLOCKSIZE=512"
        )
    )
)
