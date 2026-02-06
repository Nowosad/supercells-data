library(terra)
library(supercells)

ms_2024_dc = rast("data/muenster_embeddings_2024.tif")
tune = sc_tune_compactness(ms_2024_dc, step = 25, metrics = "local")
sc = sc_slic(ms_2024_dc, step = 25, compactness = tune$compactness_local)
plotRGB(ms_2024_dc, r = 30, g = 20, b = 10, stretch = "lin")
plot(sc[0], add = TRUE, border = "red")
