.validate_rows <- function(rows, n_rows) {
  if (!is.numeric(rows) || !length(rows) || anyNA(rows)) {
    rlang::abort("`rows` must be a non-empty numeric vector of row indices.")
  }

  rows <- as.integer(rows)
  if (any(rows < 1L | rows > n_rows)) {
    rlang::abort(sprintf("`rows` must be between 1 and %d.", n_rows))
  }

  unique(rows)
}

.validate_align <- function(value, arg = "align", allow_null = FALSE) {
  if (is.null(value) && allow_null) {
    return(value)
  }

  if (!is.character(value) || length(value) != 1L || !(value %in% c("left", "center", "right"))) {
    rlang::abort(sprintf("`%s` must be one of \"left\", \"center\", or \"right\".", arg))
  }

  value
}

.validate_ci_glyph <- function(value, arg = "glyph", allow_null = FALSE) {
  if (is.null(value) && allow_null) {
    return(value)
  }

  if (!is.character(value) || length(value) != 1L || !(value %in% c("point", "diamond"))) {
    rlang::abort(sprintf("`%s` must be one of \"point\" or \"diamond\".", arg))
  }

  value
}

.validate_ci_glyph_values <- function(values, arg = "glyph") {
  bad <- unique(values[!is.na(values) & !(values %in% c("point", "diamond"))])

  if (length(bad)) {
    rlang::abort(sprintf(
      "`%s` must contain only \"point\" or \"diamond\" values. Problematic value(s): %s.",
      arg,
      paste(bad, collapse = ", ")
    ))
  }

  values
}

.validate_alpha_values <- function(values, arg = "alpha") {
  bad <- !is.na(values) & (!is.numeric(values) | values < 0 | values > 1)

  if (any(bad)) {
    rlang::abort(sprintf("`%s` must contain only numeric values between 0 and 1.", arg))
  }

  values
}

.validate_column <- function(col, arg = "col") {
  if (!is.character(col) || length(col) != 1L || !nzchar(col)) {
    rlang::abort(sprintf("`%s` must be a single non-empty string.", arg))
  }

  col
}

.validate_fp_plot <- function(x) {
  if (!inherits(x, "fp_plot")) {
    rlang::abort("This function expects an object created by `forest_plot()`.")
  }

  x
}
