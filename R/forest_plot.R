forest_plot <- function(data, theme = fp_theme_default(), row_height = DEFAULT_ROW_HEIGHT,
                        convert_na = FALSE) {
  if (!is.data.frame(data)) {
    rlang::abort("`data` must be a data.frame.")
  }

  if (!is.logical(convert_na) || length(convert_na) != 1L || is.na(convert_na)) {
    rlang::abort("`convert_na` must be `TRUE` or `FALSE`.")
  }

  if (convert_na) {
    chr_cols <- vapply(data, is.character, logical(1))
    data[chr_cols] <- lapply(data[chr_cols], function(x) {
      x[x == "NA"] <- NA_character_
      x
    })
  }

  if (!is.numeric(row_height) || length(row_height) != 1L || is.na(row_height) || row_height <= 0) {
    rlang::abort("`row_height` must be a single positive number.")
  }

  theme <- .validate_theme(theme)

  structure(
    list(
      data = data,
      specs = list(),
      theme = theme,
      stripe_colors = NULL,
      header_groups = list(),
      summary_rows = integer(),
      group_rows = integer(),
      row_heights = rep(unname(row_height), nrow(data)),
      header_height = unname(row_height),
      row_styles = vector("list", nrow(data)),
      cell_edits = list(),
      hlines = list(),
      rules = list()
    ),
    class = "fp_plot"
  )
}
