.spec_panel_keys <- function(spec, index) {
  keys <- c(as.character(index), spec$header)

  if (identical(spec$type, "text")) {
    keys <- c(keys, spec$col)
  }

  if (identical(spec$type, "text_ci")) {
    keys <- c(keys, spec$est)
  }

  if (identical(spec$type, "bar")) {
    keys <- c(keys, spec$col)
  }

  if (identical(spec$type, "dot")) {
    keys <- c(keys, spec$col)
  }

  if (identical(spec$type, "ci")) {
    keys <- c(keys, spec$est)
  }

  keys <- unique(keys[!is.null(keys) & !is.na(keys) & nzchar(keys)])
  c(keys, sprintf("%s:%d", spec$type, index))
}

.resolve_panel_index <- function(plot, panel) {
  specs <- plot$specs

  if (is.numeric(panel) && length(panel) == 1L && !is.na(panel)) {
    panel <- as.integer(panel)
    if (panel < 1L || panel > length(specs)) {
      rlang::abort(sprintf("`panel` must be between 1 and %d.", length(specs)))
    }
    return(panel)
  }

  if (is.character(panel) && length(panel) == 1L && nzchar(panel)) {
    matches <- which(vapply(
      seq_along(specs),
      function(i) panel %in% .spec_panel_keys(specs[[i]], i),
      logical(1)
    ))

    if (!length(matches)) {
      rlang::abort(sprintf("Could not resolve `panel = \"%s\"` to any layout panel.", panel))
    }

    if (length(matches) > 1L) {
      rlang::abort(sprintf("`panel = \"%s\"` matched multiple panels. Use a numeric panel index instead.", panel))
    }

    return(matches[[1]])
  }

  rlang::abort("`panel` must be a single numeric index or a single panel identifier string.")
}

edit <- function(
  x,
  row = NULL,
  panel = NULL,
  fontface = NULL,
  colour = NULL,
  size = NULL,
  fill = NULL,
  alpha = NULL,
  glyph = NULL,
  point_size = NULL,
  line_width = NULL,
  shape = NULL,
  label = NULL,
  family = NULL,
  height = NULL
) {
  .validate_fp_plot(x)

  n_rows <- nrow(x$data)
  if (is.null(row)) {
    if (!is.null(height)) {
      rlang::abort("`height` cannot be used without specifying `row`.")
    }
    rows <- seq_len(n_rows)
  } else {
    rows <- .validate_rows(row, n_rows)
  }

  if (!is.null(glyph)) {
    .validate_ci_glyph(glyph, arg = "glyph")
  }

  if (!is.null(alpha)) {
    .validate_alpha_values(alpha, arg = "alpha")
  }

  if (!is.null(height)) {
    if (!is.numeric(height) || !length(height) || anyNA(height) || any(height <= 0)) {
      rlang::abort("`height` must be a positive number or a positive numeric vector.")
    }

    if (!(length(height) %in% c(1L, length(rows)))) {
      rlang::abort("`height` must have length 1 or match the number of selected rows.")
    }

    if (length(height) == 1L) {
      height <- rep(height, length(rows))
    }

    x$row_heights[rows] <- unname(height)
  }

  updates <- list(
    fontface = fontface,
    colour = colour,
    size = size,
    fill = fill,
    alpha = alpha,
    glyph = glyph,
    point_size = point_size,
    line_width = line_width,
    shape = shape,
    label = label,
    family = family
  )
  updates <- updates[!vapply(updates, is.null, logical(1))]

  if (!length(updates) && is.null(height)) {
    rlang::abort("`edit()` requires at least one edit parameter.")
  }

  if (!length(updates)) {
    return(x)
  }

  if (is.null(panel)) {
    for (r in rows) {
      x$row_styles[[r]] <- utils::modifyList(x$row_styles[[r]] %||% list(), updates)
    }
  } else {
    panel_index <- .resolve_panel_index(x, panel)
    for (r in rows) {
      panel_edits <- if (length(x$cell_edits) >= panel_index) x$cell_edits[[panel_index]] else NULL
      panel_edits <- panel_edits %||% vector("list", nrow(x$data))
      panel_edits[[r]] <- utils::modifyList(panel_edits[[r]] %||% list(), updates)
      x$cell_edits[[panel_index]] <- panel_edits
    }
  }

  x
}
