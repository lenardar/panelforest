load_local_package <- function() {
  root <- normalizePath(getwd())
  r_files <- list.files(file.path(root, "R"), pattern = "[.][Rr]$", full.names = TRUE)
  env <- globalenv()

  for (path in r_files) {
    sys.source(path, envir = env)
  }

  .register_builtin_builders()
  invisible(root)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

root <- load_local_package()
library(ggplot2)

out_dir <- file.path("man", "figures")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Richer dataset for a more impressive showcase
df <- data.frame(
  label = c(
    "Overall", "Age < 65", "Age \u2265 65",
    "Male", "Female",
    "ECOG 0", "ECOG 1\u20132",
    "Prior Therapy", "No Prior Therapy"
  ),
  n = c(247, 128, 119, 143, 104, 89, 158, 156, 91),
  HR = c(0.72, 0.65, 0.81, 0.69, 0.78, 0.58, 0.79, 0.74, 0.68),
  LCI = c(0.58, 0.48, 0.60, 0.51, 0.56, 0.39, 0.61, 0.56, 0.47),
  UCI = c(0.89, 0.88, 1.09, 0.93, 1.08, 0.86, 1.02, 0.98, 0.98),
  stringsAsFactors = FALSE
)

journal_theme <- fp_theme_journal(
  text_colour    = "#1a1a1a",
  header_colour  = "#1a1a1a",
  refline_colour = "#c8c8c8",
  text_size      = 3.4,
  header_size    = 3.55,
  plot_margin    = 5
)

plot_obj <- forest_plot(df, theme = journal_theme) |>
  add_stripe(c("#ffffff", "#f5f5f5")) |>
  add_summary(1) |>
  add_hline(1, colour = "#aaaaaa", linewidth = 0.4) |>
  add_text("label", header = "Subgroup", width = 1.7) |>
  add_bar("n", header = "N", width = 0.9, fill = "#b0bac5") |>
  add_ci(
    "HR", "LCI", "UCI",
    header = "Hazard Ratio",
    trans = "log",
    width = 2.8,
    show_axis = TRUE,
    xlim = c(0.4, 1.2),
    breaks = c(0.4, 0.6, 0.8, 1.0, 1.2),
    colour = "#1a1a1a",
    line_width = 0.5,
    point_size = 1.9
  ) |>
  add_spacer(3, unit = "mm") |>
  add_text_ci("HR", "LCI", "UCI", header = "HR (95% CI)", width = 1.3) |>
  edit(row = 1, panel = "Hazard Ratio", fill = "#1a1a1a", colour = "#1a1a1a") |>
  edit(row = 1, fontface = "bold")

size <- fp_size(plot_obj)

ggsave(
  filename = file.path(out_dir, "README-classic-forest.png"),
  plot = fp_render(plot_obj),
  width = size["width"],
  height = size["height"],
  dpi = 200,
  bg = "white"
)
