library(terra)
library(sf)
library(supercells)

# -----------------------------------------------------------------------------
# EVI application: regionalization with map-unit and compactness diagnostics.
#
# Strengths shown in this script:
# - Uses use_meters() so segmentation scale is defined in real map units
#   (50 km and 30 km), which is directly interpretable for regionalization.
# - Compares tuned and adaptive compactness at the same 30 km scale.
# - Keeps scale-focused and compactness-focused metrics in memory to support
#   transparent parameter choices during interactive analysis.
# - Works with partially missing rasters and reports NA burden for context.
#
# Typical applications:
# - Building regional units from vegetation dynamics time-series.
# - Creating reproducible, scale-aware segmentation over large areas.
# -----------------------------------------------------------------------------

evi = rast("data/poland_evi_2020_bimonthly_filled.tif")

step_50km = use_meters(50000)
step_30km = use_meters(30000)

tune_50km = sc_tune_compactness(
    evi,
    step = step_50km,
    metric = "local"
)
tune_30km = sc_tune_compactness(
    evi,
    step = step_30km,
    metric = "local"
)

sc_50km_tuned = sc_slic(
    evi,
    step = step_50km,
    compactness = tune_50km$compactness[[1]],
    outcomes = c("supercells", "values")
)

sc_30km_tuned = sc_slic(
    evi,
    step = step_30km,
    compactness = tune_30km$compactness[[1]],
    outcomes = c("supercells", "values")
)

sc_30km_auto = sc_slic(
    evi,
    step = step_30km,
    compactness = use_adaptive(),
    outcomes = c("supercells", "values")
)

metrics_global = rbind(
    transform(sc_metrics_global(evi, sc_50km_tuned), run = "50km_tuned"),
    transform(sc_metrics_global(evi, sc_30km_tuned), run = "30km_tuned"),
    transform(sc_metrics_global(evi, sc_30km_auto), run = "30km_auto")
)
metrics_scale = subset(metrics_global, run %in% c("50km_tuned", "30km_tuned"))
metrics_compactness = subset(metrics_global, run %in% c("30km_tuned", "30km_auto"))

metrics_supercells_30km = sc_metrics_supercells(evi, sc_30km_tuned)
metrics_supercells_30km_auto = sc_metrics_supercells(evi, sc_30km_auto)
tune_tbl = rbind(
    transform(tune_50km, run = "50km_tuned"),
    transform(tune_30km, run = "30km_tuned")
)

na_cells_layer1 = as.numeric(terra::global(is.na(evi[[1]]), "sum")[1, 1])
na_share_layer1 = na_cells_layer1 / ncell(evi[[1]])

evi_results = list(
    raster = evi,
    tune = tune_tbl,
    supercells_50km_tuned = sc_50km_tuned,
    supercells_30km_tuned = sc_30km_tuned,
    supercells_30km_auto = sc_30km_auto,
    metrics_global = metrics_global,
    metrics_scale = metrics_scale,
    metrics_compactness = metrics_compactness,
    metrics_supercells_30km_tuned = metrics_supercells_30km,
    metrics_supercells_30km_auto = metrics_supercells_30km_auto,
    na_cells_layer1 = na_cells_layer1,
    na_share_layer1 = na_share_layer1
)

print(tune_tbl)
print(metrics_scale)
print(metrics_compactness)

if (interactive()) {
    par(mfrow = c(1, 2))
    plot(evi[[1]], main = "EVI layer 1: 50 km tuned")
    plot(st_geometry(sc_50km_tuned), add = TRUE, border = "red", lwd = 0.4)
    plot(evi[[1]], main = "EVI layer 1: 30 km tuned")
    plot(st_geometry(sc_30km_tuned), add = TRUE, border = "yellow", lwd = 0.4)
    par(mfrow = c(1, 1))
}

cat("EVI workflow finished.\n")
cat("No files were written. Results are available in `evi_results`.\n")
cat("Input file:", infile, "\n")
cat("NA cells in first layer:", na_cells_layer1, "\n")
cat("NA share in first layer:", round(na_share_layer1, 4), "\n")
cat("50 km tuned supercells:", nrow(sc_50km_tuned), "\n")
cat("30 km tuned supercells:", nrow(sc_30km_tuned), "\n")
cat("30 km auto supercells:", nrow(sc_30km_auto), "\n")
