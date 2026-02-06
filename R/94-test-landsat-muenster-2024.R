library(terra)
library(supercells)

r = rast("data/muenster-landsat_2024.tif")
r_rgb = r[[c("red", "green", "blue")]]
vals = values(r_rgb)
rng = range(vals, na.rm = TRUE)
vals01 = (vals - rng[1]) / (rng[2] - rng[1])

lab_vals = grDevices::convertColor(vals01, from = "sRGB", to = "Lab")
r_lab = setValues(rast(r_rgb), lab_vals)
names(r_lab) = c("L", "a", "b")

tune = sc_tune_compactness(r_lab, step = 16, metrics = "local")
sc = sc_slic(r_lab, step = 16, compactness = tune$compactness_local)

rgb_back = grDevices::convertColor(lab_vals, from = "Lab", to = "sRGB")
r_rgb_back = setValues(rast(r_rgb), rgb_back)

plotRGB(r_rgb_back, r = 1, g = 2, b = 3, stretch = "lin")
plot(sc[0], add = TRUE, border = "red")
