library(terra)
library(sf)
library(supercells)

evi <- rast("data/poland_evi_2020.tif")

tune_50km <- sc_tune_compactness(
  evi,
  step = use_meters(50000),
  metric = "local_variability"
)

sc_50km_tuned <- sc_slic(
  evi,
  step = use_meters(50000),
  compactness = tune_50km$compactness[[1]]
)

metrics_pixels_50km <- sc_metrics_pixels(evi, sc_50km_tuned)
metrics_supercells_50km <- sc_metrics_supercells(evi, sc_50km_tuned)
metrics_global_50km <- sc_metrics_global(evi, sc_50km_tuned)

library(tmap)
names(evi) = c(
  "Jan-Feb",
  "Mar-Apr",
  "May-Jun",
  "Jul-Aug",
  "Sep-Oct",
  "Nov-Dec"
)
tm_evi = tm_shape(evi) +
  tm_raster(
    col.scale = tm_scale_continuous(values = "purple_green", midpoint = 0.2),
    col.legend = tm_legend(
      position = tm_pos_out("center", "bottom", "center"),
      orientation = "landscape",
      frame = FALSE,
      title = "Vegetation Index (EVI)",
    ),
    col.free = FALSE) +
  tm_facets(nrow = 2)
# tm_evi
tm_sc = tm_evi +
  tm_shape(sc_50km_tuned) +
  tm_borders(col = "#FF2DAA", lwd = 0.5)
# tm_sc
tm_sc_mpix = tm_shape(metrics_pixels_50km[[1:3]]) +
  tm_raster(
      col.scale = tm_scale_continuous(values = "ArmyRose"),
      col.legend = tm_legend(title = "", frame = FALSE,
                        orientation = "landscape", text.size = 0.4),
                        
  ) +
  tm_shape(sc_50km_tuned) +
  tm_borders(col = "#FF2DAA", lwd = 0.25) +
  tm_facets(nrow = 1) +
  tm_layout(panel.labels = c("Spatial Compactness", "Value Homogeneity", "Combined Distance")) +
  tm_options(component.autoscale = FALSE)
# tm_sc_mpix

tm_sc_msc = tm_shape(metrics_supercells_50km) +
  tm_polygons(
    fill = c("mean_spatial_dist_scaled", "mean_value_dist_scaled", "mean_combined_dist"),
    fill.scale = tm_scale_continuous(values = "ArmyRose"),
    fill.legend = tm_legend(title = "", frame = FALSE,
                          position = tm_pos_out("center", "bottom", "center"),
                          orientation = "landscape"),
    fill.free = FALSE
) +
  tm_shape(sc_50km_tuned) +
  tm_borders(col = "#FF2DAA", lwd = 0.25) +
  tm_facets(nrow = 1) +
  tm_layout(
    # inner.margins = c(0.02, 0.2, 0.02, 0.02),
    panel.labels = c("Mean Spatial Compactness", "Mean Value Homogeneity", "Mean Combined Distance")
  )
# tm_sc_msc

dir.create("figs")
metrics_global_50km |>
  dplyr::select(step, compactness, n_supercells, 
         `Mean spatial distance (scaled)` = mean_spatial_dist_scaled,
         `Mean value distance (scaled)` = mean_value_dist_scaled,
         `Mean combined distance` = mean_combined_dist) |>
  knitr::kable(format = "latex") |>
  writeLines("figs/poland_evi_2020_50km_supercells_metrics.tex")

tmap_save(tm_sc, "figs/poland_evi_2020_50km_supercells.png",
          width = 1700, height = 1300, units = "px", dpi = 150)
tmap_save(tm_sc_mpix, "figs/poland_evi_2020_50km_supercells_pixels.png",
          width = 1700, height = 650, units = "px", dpi = 200)
tmap_save(tm_sc_msc, "figs/poland_evi_2020_50km_supercells_supercells.png",
          width = 1700, height = 650, units = "px", dpi = 200)
