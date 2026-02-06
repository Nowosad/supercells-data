library(terra)
library(supercells)

pol_tmax_c = rast("data/poland_tmax_monthly.tif")
tune = sc_tune_compactness(pol_tmax_c, step = 50, metrics = "local")
sc = sc_slic(pol_tmax_c, step = 50, compactness = tune$compactness_local)

plot(pol_tmax_c[[1]])
plot(sc[0], add = TRUE, border = "red")

# par(mfrow = c(3, 4))
# for (i in 1:nlyr(pol_tmax_c)) {
#   plot(pol_tmax_c[[i]], main = names(pol_tmax_c)[i])
#   plot(sc[0], add = TRUE, border = "red")
# }

mapview::mapview(sc[0], alpha.regions = 0, lwd = 2, color = "red")
