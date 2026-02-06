library(sf)
library(terra)
Sys.setenv(AWS_NO_SIGN_REQUEST = "YES")

# Landsat GLAD SWA ARD2 yearly p50 (2024) for study area --------------------

out_dir = "data/openlandmap"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# study area (same as 01-prepare-embeddings-muenster-2024.R)
ms_buf = data.frame(lon = 7.66, lat = 51.944) |>
    st_as_sf(coords = c("lon", "lat"), crs = 4326) |>
    st_buffer(5000)

base_cog_url = "/vsicurl/https://s3.opengeohub.org/arco"
bands = c("blue", "green", "red", "nir")

cog_urls = sprintf(
    "%s/%s_glad.landsat.ard2.swa_p50_30m_s_20240101_20241231_go_epsg.4326_v1.tif",
    base_cog_url,
    bands
)

r = rast(cog_urls)

ms_buf_p = st_transform(ms_buf, crs(r))
r = crop(r, ms_buf_p, mask = TRUE)
r = project(r, "EPSG:3035", res = 30)

names(r) = c("blue", "green", "red", "nir")

writeRaster(
    r,
    filename = "data/muenster-landsat_2024.tif",
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
