fp_theme_default <- function(
  base_family = "",
  text_size = 3.6,
  text_colour = "#1f1f1f",
  header_size = 3.8,
  header_fontface = "bold",
  header_colour = "#1f1f1f",
  refline_colour = "#9aa1a6",
  stripe_alpha = 1,
  plot_margin = 4
) {
  structure(
    list(
      base_family = base_family,
      text_size = text_size,
      text_colour = text_colour,
      header_size = header_size,
      header_fontface = header_fontface,
      header_colour = header_colour,
      refline_colour = refline_colour,
      stripe_alpha = stripe_alpha,
      plot_margin = plot_margin
    ),
    class = "fp_theme"
  )
}

fp_theme_journal <- function(
  base_family = "serif",
  text_size = 3.4,
  text_colour = "#202124",
  header_size = 3.6,
  header_fontface = "bold",
  header_colour = "#111111",
  refline_colour = "#7f8891",
  stripe_alpha = 1,
  plot_margin = 3
) {
  fp_theme_default(
    base_family = base_family,
    text_size = text_size,
    text_colour = text_colour,
    header_size = header_size,
    header_fontface = header_fontface,
    header_colour = header_colour,
    refline_colour = refline_colour,
    stripe_alpha = stripe_alpha,
    plot_margin = plot_margin
  )
}

.validate_theme <- function(theme) {
  if (!inherits(theme, "fp_theme")) {
    rlang::abort("`theme` must be created by `fp_theme_default()` or a compatible constructor.")
  }

  theme
}
