.resolve_style <- function(value, n_rows, default, arg) {
  if (is.null(value)) {
    return(rep(default, n_rows))
  }

  if (length(value) == 1L) {
    return(rep(value, n_rows))
  }

  if (length(value) != n_rows) {
    rlang::abort(sprintf("`%s` must have length 1 or match the number of rows (%d).", arg, n_rows))
  }

  value
}

.resolve_mapped_style <- function(column, data, n_rows, arg, numeric_only = FALSE) {
  if (is.null(column)) {
    return(NULL)
  }

  if (!is.character(column) || length(column) != 1L || !nzchar(column)) {
    rlang::abort(sprintf("`%s` must be `NULL` or a single column name.", arg))
  }

  if (!column %in% names(data)) {
    rlang::abort(sprintf("Column `%s` supplied to `%s` was not found in `data`.", column, arg))
  }

  values <- data[[column]]
  if (length(values) != n_rows) {
    rlang::abort(sprintf("Column `%s` supplied to `%s` must have length %d.", column, arg, n_rows))
  }

  if (numeric_only && (!is.numeric(values) || anyNA(values))) {
    rlang::abort(sprintf("Column `%s` supplied to `%s` must be numeric without missing values.", column, arg))
  }

  values
}

.apply_row_overrides <- function(values, row_styles, row_ids, attr) {
  for (i in seq_along(row_ids)) {
    row_index <- row_ids[[i]]
    row_style <- if (length(row_styles) >= row_index) row_styles[[row_index]] else NULL
    if (!is.null(row_style) && !is.null(row_style[[attr]])) {
      values[[i]] <- row_style[[attr]]
    }
  }

  values
}

.apply_cell_overrides <- function(values, cell_edits, row_ids, attr) {
  if (!length(cell_edits)) {
    return(values)
  }

  for (i in seq_along(row_ids)) {
    row_index <- row_ids[[i]]
    cell_edit <- if (length(cell_edits) >= row_index) cell_edits[[row_index]] else NULL
    if (!is.null(cell_edit) && !is.null(cell_edit[[attr]])) {
      values[[i]] <- cell_edit[[attr]]
    }
  }

  values
}

.resolve_attr <- function(ctx, spec, cell_edits, attr, default = NULL,
                          numeric_only = FALSE, skip_row = FALSE) {
  n_rows <- ctx$n_rows
  row_ids <- seq_len(n_rows)

  mapped <- NULL
  if (!is.null(spec$mapping) && !is.null(spec$mapping[[attr]])) {
    mapped <- .resolve_mapped_style(
      spec$mapping[[attr]], ctx$data, n_rows, attr,
      numeric_only = numeric_only
    )
  }

  values <- mapped %||% .resolve_style(spec[[attr]], n_rows, default, attr)

  if (!skip_row) {
    values <- .apply_row_overrides(values, ctx$row_styles, row_ids, attr)
  }

  values <- .apply_cell_overrides(values, cell_edits, row_ids, attr)

  values
}

.resolve_indent <- function(indent, data, n_rows) {
  if (is.null(indent)) {
    return(rep(0, n_rows))
  }

  if (is.character(indent) && length(indent) == 1L) {
    if (!indent %in% names(data)) {
      rlang::abort(sprintf("Indent column `%s` was not found in `data`.", indent))
    }
    indent <- data[[indent]]
  }

  if (!is.numeric(indent)) {
    rlang::abort("Resolved `indent` values must be numeric.")
  }

  if (length(indent) == 1L) {
    indent <- rep(indent, n_rows)
  }

  if (length(indent) != n_rows || anyNA(indent) || any(indent < 0)) {
    rlang::abort(sprintf("`indent` must resolve to non-negative numeric values of length 1 or %d.", n_rows))
  }

  indent
}

# Summary / group modifiers

.summary_text_fontface <- function(fontface, summary_mask) {
  fontface[summary_mask] <- "bold"
  fontface
}

.group_text_fontface <- function(fontface, group_mask) {
  fontface[group_mask] <- "bold"
  fontface
}

.group_text_size <- function(size, group_mask) {
  size[group_mask] <- size[group_mask] + GROUP_TEXT_SIZE_BOOST
  size
}

.summary_ci_glyph <- function(glyph, summary_mask, summary_glyph = "diamond") {
  if (!is.null(summary_glyph)) {
    glyph[summary_mask] <- summary_glyph
  }
  glyph
}

.summary_ci_shape <- function(shape, summary_mask) {
  shape[summary_mask] <- 18
  shape
}

.summary_ci_point_size <- function(point_size, summary_mask) {
  point_size[summary_mask] <- point_size[summary_mask] + SUMMARY_POINT_SIZE_BOOST
  point_size
}

.summary_ci_line_width <- function(line_width, summary_mask) {
  line_width[summary_mask] <- pmax(
    line_width[summary_mask] * SUMMARY_LINE_WIDTH_FACTOR,
    line_width[summary_mask] + SUMMARY_LINE_WIDTH_MIN_BOOST
  )
  line_width
}
