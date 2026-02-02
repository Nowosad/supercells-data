library(sf)
library(terra)
Sys.setenv(AWS_NO_SIGN_REQUEST = "YES")

# study area ------------------------
ms_buf = data.frame(lon = 7.66, lat = 51.944) |>
    st_as_sf(coords = c("lon", "lat"), crs = 4326) |>
    st_buffer(2500)

mapview::mapview(ms_buf)

ext_wkt = ms_buf |>
    st_geometry() |>
    st_as_text()

# index ------------------------
idx_pq = "/vsicurl/https://data.source.coop/tge-labs/aef/v1/annual/aef_index.parquet"

idx_ms = sf::read_sf(idx_pq, wkt_filter = ext_wkt)

mapview::mapview(idx_ms[0])

# prepare buffer for cropping --------------

# 2024 -------------------------
idx_ms_2024 = idx_ms |>
    dplyr::filter(year == 2024)

fp_2024 = gsub(
    "\\.(tiff?|TIFF?)$",
    ".vrt",
    gsub("^s3://", "/vsis3/", idx_ms_2024$path)
)
dequantize = function(x){
    ((x / 127.5) ^ 2) * sign(x)
}

dir.create("~/tmp")
terra::terraOptions(tempdir = "~/tmp/", todisk = TRUE)
ms_2024 = rast(fp_2024)
ms_2024_d = dequantize(ms_2024)
writeRaster(ms_2024_d, "ms_2024_dequantized.tif", overwrite = TRUE)
unlink("~/tmp")

ms_buf_p = st_transform(ms_buf, crs(ms_2024_d))
ms_2024_dc = crop(ms_2024_d, ms_buf_p, mask = TRUE)
writeRaster(ms_2024_dc, "ms_2024_dc.tif", overwrite = TRUE)

### test
library(terra)
library(supercells)
ms_2024_dc = rast("ms_2024_dc.tif")
sc_tune_compactness(ms_2024_dc, step = 25, metrics = "local")

sc = sc_slic(ms_2024_dc, step = 25, compactness =  0.05)
plotRGB(ms_2024_dc, r = 30, g = 20, b = 10, stretch = "lin")
plot(sc[0], add = TRUE, border = "red")
