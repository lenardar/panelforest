add_stripe <- function(x, colors) {
  .validate_fp_plot(x)

  if (!is.character(colors) || length(colors) < 2L || anyNA(colors)) {
    rlang::abort("`colors` must be a character vector with at least two values.")
  }

  x$stripe_colors <- unname(colors)
  x
}

add_summary <- function(x, rows) {
  .validate_fp_plot(x)
  rows <- .validate_rows(rows, nrow(x$data))
  x$summary_rows <- sort(unique(c(x$summary_rows, rows)))
  x
}

add_group <- function(x, rows, fontface = "bold", size = NULL, colour = NULL, fill = NULL) {
  .validate_fp_plot(x)
  rows <- .validate_rows(rows, nrow(x$data))
  x$group_rows <- sort(unique(c(x$group_rows, rows)))

  updates <- list(
    fontface = fontface,
    size = size,
    colour = colour,
    fill = fill
  )
  updates <- updates[!vapply(updates, is.null, logical(1))]

  for (row in rows) {
    x$row_styles[[row]] <- utils::modifyList(x$row_styles[[row]] %||% list(), updates)
  }

  x
}

add_hline <- function(x, rows, colour = HLINE_DEFAULT_COLOUR, linewidth = HLINE_DEFAULT_LINEWIDTH, linetype = 1) {
  .validate_fp_plot(x)

  if (!is.numeric(rows) || !length(rows) || anyNA(rows)) {
    rlang::abort("`rows` must be a non-empty numeric vector of row indices.")
  }

  rows <- .validate_rows(as.integer(rows), nrow(x$data))

  if (!is.character(colour) || length(colour) != 1L || !nzchar(colour)) {
    rlang::abort("`colour` must be a single non-empty string.")
  }

  if (!is.numeric(linewidth) || length(linewidth) != 1L || is.na(linewidth) || linewidth <= 0) {
    rlang::abort("`linewidth` must be a single positive number.")
  }

  if (!(is.numeric(linetype) || is.character(linetype)) || length(linetype) != 1L || is.na(linetype)) {
    rlang::abort("`linetype` must be a single numeric or character value.")
  }

  line <- structure(
    list(
      rows = unique(rows),
      colour = colour,
      linewidth = linewidth,
      linetype = linetype
    ),
    class = "fp_hline"
  )

  x$hlines <- c(x$hlines, list(line))
  x
}
