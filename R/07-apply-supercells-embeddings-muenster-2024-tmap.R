library(terra)
library(sf)
library(supercells)

emb <- rast("data/muenster_embeddings_2024.tif")

step_size <- 25

tune_cosine <- sc_tune_compactness(
  emb,
  step = step_size,
  dist_fun = "cosine",
  metric = "local_variability",
  stat = NULL
)

min_compactness_cosine <- min(tune_cosine$compactness, na.rm = TRUE)
median_compactness_cosine <- median(tune_cosine$compactness, na.rm = TRUE)

sc_cosine_min <- sc_slic(
  emb,
  step = step_size,
  compactness = min_compactness_cosine,
  dist_fun = "cosine",
  outcomes = c("supercells", "values")
)

sc_cosine_median <- sc_slic(
  emb,
  step = step_size,
  compactness = median_compactness_cosine,
  dist_fun = "cosine",
  outcomes = c("supercells", "values")
)

library(ggplot2)
library(tmap)
gghist = ggplot(tune_cosine, aes(x = compactness)) +
  geom_histogram(fill = "lightblue", alpha = 0.5) +
  geom_vline(xintercept = min_compactness_cosine, color = "red", linetype = "dashed") +
  geom_vline(xintercept = median_compactness_cosine, color = "blue", linetype = "dashed") +
  labs(x = "Compactness",
       y = "Density") +
  theme_minimal() +
  annotate("text", x = min_compactness_cosine, y = 32, label = "Min", color = "red", size = 8) +
  annotate("text", x = median_compactness_cosine, y = 32, label = "Median", color = "blue", size = 8)

ggsave("figs/muenster_histogram.png", gghist, width = 6, height = 4)

pca = prcomp(emb, center = TRUE, scale. = TRUE, maxcell = 5000)
pcs = predict(emb, pca, index = 1:3)

map_cosine_median = tm_shape(pcs) +
  tm_rgb(tm_vars(x = c(1, 2, 3), multivariate = TRUE),
         col.scale = tm_scale_rgb(stretch = TRUE, probs = c(0.02, 0.98))) +
  tm_shape(sc_cosine_median) +
  tm_borders(col = "white", lwd = 1) +
  tm_title("Cosine: Median compactness tuning") +
  tm_layout(frame = FALSE)

map_cosine_min = tm_shape(pcs) +
  tm_rgb(tm_vars(x = c(1, 2, 3), multivariate = TRUE),
         col.scale = tm_scale_rgb(stretch = TRUE, probs = c(0.02, 0.98))) +
  tm_shape(sc_cosine_min) +
  tm_borders(col = "white", lwd = 1) +
  tm_title("Cosine: Minimum compactness tuning") +
  tm_layout(frame = FALSE)

map_cosine = tmap_arrange(map_cosine_median, map_cosine_min)
tmap_save(map_cosine, "figs/muenster_supercells_cosine.png", 
          width = 1700, height = 1000, units = "px", dpi = 150)

