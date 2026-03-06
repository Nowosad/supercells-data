library(terra)
library(sf)
library(supercells)

# -----------------------------------------------------------------------------
# Embeddings application: make high-dimensional features interpretable.
#
# Strengths shown in this script:
# - Uses cosine distance with value_scale = 1, which is often better suited to
#   embedding vectors than default Euclidean distance.
# - Compares tuned compactness and adaptive compactness under the same setup.
# - Keeps object-level outputs (supercells + metrics) in memory, enabling
#   interactive interpretation and downstream modeling with stable spatial units.
# - Adds optional PCA summaries (PC1-3) of supercell-mean embeddings for
#   visualization of dominant latent gradients.
#
# Typical applications:
# - Understanding foundation-model embeddings in spatial context.
# - Converting dense embedding rasters into regional units for analysis.
# -----------------------------------------------------------------------------
infile = "data/muenster_embeddings_2024.tif"
infile = "/home/jn/Science/sc-paper2026/ms_2024_c.tif"
emb = rast(infile)
step_size = 25

# Key settings for embeddings: cosine distance and value_scale = 1
tune_cosine = sc_tune_compactness(
    emb,
    step = step_size,
    metric = "balance_global",
    dist_fun = "cosine",
    iter = 3,
    value_scale = 1
)

sc_cosine_tuned = sc_slic(
    emb,
    step = step_size,
    # compactness = tune_cosine$compactness[[1]],
    compactness = 0.4,
    dist_fun = "cosine",
    outcomes = c("supercells", "values")
)

sc_cosine_auto = sc_slic(
    emb,
    step = step_size,
    compactness = use_adaptive(),
    dist_fun = "cosine",
    outcomes = c("supercells", "values")
)

metrics_global = rbind(
    transform(sc_metrics_global(emb, sc_cosine_tuned), run = "cosine_tuned"),
    transform(sc_metrics_global(emb, sc_cosine_auto), run = "cosine_auto")
)

metrics_supercells = sc_metrics_supercells(emb, sc_cosine_tuned)

# Optional PCA summary of supercell-level embedding means for interpretation
value_cols = intersect(names(sc_cosine_tuned), names(emb))
pca_var_tbl = data.frame()
if (length(value_cols) >= 3 && nrow(sc_cosine_tuned) > 3) {
    emb_means = st_drop_geometry(sc_cosine_tuned[, value_cols, drop = FALSE])
    pca_rank = min(3, ncol(emb_means), nrow(emb_means) - 1L)
    pca = prcomp(emb_means, center = TRUE, scale. = TRUE, rank. = pca_rank)
    pcs = as.data.frame(pca$x[, seq_len(pca_rank), drop = FALSE])
    names(pcs) = paste0("pc", seq_len(pca_rank))
    sc_cosine_tuned = cbind(sc_cosine_tuned, pcs)

    pca_var = (pca$sdev[seq_len(pca_rank)]^2) / sum(pca$sdev^2)
    pca_var_tbl = data.frame(
        component = paste0("pc", seq_len(pca_rank)),
        explained_variance = pca_var
    )
} else {
    warning("Skipping PCA (insufficient matching value columns or too few supercells).")
}

tune_tbl = data.frame(
    run = "cosine_value_scale_1",
    compactness = tune_cosine$compactness[[1]]
)

embeddings_results = list(
    raster = emb,
    tune = tune_tbl,
    supercells_tuned = sc_cosine_tuned,
    supercells_auto = sc_cosine_auto,
    metrics_global = metrics_global,
    metrics_supercells_tuned = metrics_supercells,
    pca_explained_variance = pca_var_tbl
)

print(tune_tbl)
print(metrics_global)
if (nrow(pca_var_tbl) > 0) {
    print(pca_var_tbl)
}

if (interactive()) {
    par(mfrow = c(1, 2))
    plot(emb[[1]], main = "Embeddings layer 1: cosine tuned")
    plot(st_geometry(sc_cosine_tuned), add = TRUE, border = "yellow", lwd = 0.4)
    plot(emb[[1]], main = "Embeddings layer 1: cosine auto")
    plot(st_geometry(sc_cosine_auto), add = TRUE, border = "cyan", lwd = 0.4)
    par(mfrow = c(1, 1))
}

cat("Embeddings workflow finished.\n")
cat("No files were written. Results are available in `embeddings_results`.\n")
cat("Tuned supercells:", nrow(sc_cosine_tuned), "\n")
cat("Auto supercells:", nrow(sc_cosine_auto), "\n")
