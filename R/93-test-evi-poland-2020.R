library(terra)
library(supercells)

r_2020 = rast("data/poland_evi_2020_bimonthly.tif")
tune = sc_tune_compactness(r_2020, step = 100, metrics = "local")

sc = sc_slic(r_2020, step = 100, compactness = tune$compactness_local)
plot(r_2020[[1]])
plot(sc[0], add = TRUE, border = "red")

system.time({
scm = supercells:::sc_merge_supercells(sc, method_opts = list(target_k = 1000))
})

system.time({
scm2 = supercells:::sc_merge_supercells(sc, method = "fh", method_opts = list(kappa = 1))
})

system.time({
scm3 = supercells:::sc_merge_supercells(sc, method = "mst", method_opts = list(target_k = 1000))
})

plot(r_2020[[1]])
plot(scm[0], add = TRUE, border = "red")

plot(r_2020[[1]])
plot(scm2[0], add = TRUE, border = "red")

plot(r_2020[[1]])
plot(scm3[0], add = TRUE, border = "red")

profvis::profvis({
scm = supercells:::sc_merge_supercells(sc, method_opts = list(target_k = 1000))
})

profvis::profvis({
scm = supercells:::sc_merge_supercells(sc, method = "fh", method_opts = list(kappa = 1))
})

profvis::profvis({
scm = supercells:::sc_merge_supercells(sc, method = "mst", method_opts = list(target_k = 1000))
})
