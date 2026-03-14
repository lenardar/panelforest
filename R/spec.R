fp_aes <- function(colour = NULL, fill = NULL, alpha = NULL, glyph = NULL,
                   shape = NULL, point_size = NULL, line_width = NULL,
                   fontface = NULL, size = NULL) {
  mapping <- list(
    colour = colour, fill = fill, alpha = alpha, glyph = glyph,
    shape = shape, point_size = point_size, line_width = line_width,
    fontface = fontface, size = size
  )
  mapping <- mapping[!vapply(mapping, is.null, logical(1))]

  for (nm in names(mapping)) {
    val <- mapping[[nm]]
    if (!is.character(val) || length(val) != 1L || !nzchar(val)) {
      rlang::abort(sprintf("`%s` in `fp_aes()` must be a single column name.", nm))
    }
  }

  structure(mapping, class = "fp_aes")
}

.make_spec <- function(type, width, ...) {
  if (!is.character(type) || length(type) != 1L || !nzchar(type)) {
    rlang::abort("`type` must be a single non-empty string.")
  }

  if (!is.numeric(width) || length(width) != 1L || is.na(width) || width <= 0) {
    rlang::abort("`width` must be a single positive number.")
  }

  spec <- list(type = type, width = unname(width), ...)
  class(spec) <- c(paste0("fp_spec_", type), "fp_spec")
  spec
}

fp_text <- function(
  col,
  header = NULL,
  width = 1.5,
  align = "left",
  header_align = NULL,
  indent = NULL,
  indent_width = 0.08,
  formatter = NULL,
  fontface = NULL,
  colour = NULL,
  size = NULL,
  mapping = NULL
) {
  .validate_column(col)
  .validate_align(align, arg = "align")
  .validate_align(header_align, arg = "header_align", allow_null = TRUE)

  hjust <- .align_to_hjust(align)
  header_hjust <- if (!is.null(header_align)) .align_to_hjust(header_align) else NULL

  if (!is.null(indent) && !is.numeric(indent) && !(is.character(indent) && length(indent) == 1L && nzchar(indent))) {
    rlang::abort("`indent` must be `NULL`, numeric, or a single column name.")
  }

  if (is.numeric(indent)) {
    if (anyNA(indent) || any(indent < 0) || length(indent) != 1L) {
      rlang::abort("Numeric `indent` must be a single non-negative number.")
    }
  }

  if (!is.numeric(indent_width) || length(indent_width) != 1L || is.na(indent_width) || indent_width < 0) {
    rlang::abort("`indent_width` must be a single non-negative number.")
  }

  if (!is.null(formatter) && !is.function(formatter)) {
    rlang::abort("`formatter` must be `NULL` or a function.")
  }

  if (!is.null(mapping) && !inherits(mapping, "fp_aes")) {
    rlang::abort("`mapping` must be `NULL` or created by `fp_aes()`.")
  }

  .make_spec(
    "text",
    width = width,
    col = col,
    header = header,
    align = align,
    hjust = hjust,
    header_align = header_align,
    header_hjust = header_hjust,
    indent = indent,
    indent_width = indent_width,
    formatter = formatter,
    fontface = fontface,
    colour = colour,
    size = size,
    mapping = mapping
  )
}

fp_text_ci <- function(
  est,
  lower,
  upper,
  header = NULL,
  width = 2.5,
  digits = 2,
  prefix = "",
  suffix = "",
  na = "",
  align = "left",
  header_align = NULL,
  fontface = NULL,
  colour = NULL,
  size = NULL,
  mapping = NULL
) {
  cols <- c(est, lower, upper)
  if (!is.character(cols) || any(lengths(as.list(cols)) != 1L) || any(!nzchar(cols))) {
    rlang::abort("`est`, `lower`, and `upper` must be single non-empty strings.")
  }

  if (!is.numeric(digits) || length(digits) != 1L || is.na(digits) || digits < 0) {
    rlang::abort("`digits` must be a single non-negative number.")
  }

  if (!is.character(na) || length(na) != 1L) {
    rlang::abort("`na` must be a single string.")
  }

  .validate_align(align, arg = "align")
  .validate_align(header_align, arg = "header_align", allow_null = TRUE)

  hjust <- .align_to_hjust(align)
  header_hjust <- if (!is.null(header_align)) .align_to_hjust(header_align) else NULL

  if (!is.null(mapping) && !inherits(mapping, "fp_aes")) {
    rlang::abort("`mapping` must be `NULL` or created by `fp_aes()`.")
  }

  .make_spec(
    "text_ci",
    width = width,
    est = est,
    lower = lower,
    upper = upper,
    header = header,
    digits = as.integer(digits),
    prefix = prefix,
    suffix = suffix,
    na = na,
    align = align,
    hjust = hjust,
    header_align = header_align,
    header_hjust = header_hjust,
    fontface = fontface,
    colour = colour,
    size = size,
    mapping = mapping
  )
}

fp_gap <- function(width = 0.2, header = NULL, header_align = "center") {
  .validate_align(header_align, arg = "header_align")
  header_hjust <- .align_to_hjust(header_align)
  .make_spec("gap", width = width, header = header, header_align = header_align, header_hjust = header_hjust)
}

fp_spacer <- function(width = 4, unit = "mm", header = NULL, header_align = "center") {
  .validate_align(header_align, arg = "header_align")
  header_hjust <- .align_to_hjust(header_align)

  if (!is.character(unit) || length(unit) != 1L || !nzchar(unit)) {
    rlang::abort("`unit` must be a single non-empty string understood by `grid::unit()`.")
  }

  valid_unit <- tryCatch(
    {
      grid::unit(1, unit)
      TRUE
    },
    error = function(...) FALSE
  )

  if (!isTRUE(valid_unit)) {
    rlang::abort("`unit` must be a valid `grid::unit()` unit such as \"mm\", \"cm\", \"in\", or \"pt\".")
  }

  .make_spec("spacer", width = width, unit = unit, header = header, header_align = header_align, header_hjust = header_hjust)
}

fp_bar <- function(
  col,
  header = NULL,
  header_align = "center",
  width = 2,
  baseline = 0,
  fill = BAR_DEFAULT_FILL,
  colour = NA_character_,
  alpha = 1,
  xlim = NULL,
  breaks = NULL
) {
  .validate_column(col)
  .validate_align(header_align, arg = "header_align")
  header_hjust <- .align_to_hjust(header_align)

  if (!is.numeric(baseline) || length(baseline) != 1L || is.na(baseline)) {
    rlang::abort("`baseline` must be a single numeric value.")
  }

  if (!is.numeric(alpha) || length(alpha) != 1L || is.na(alpha) || alpha < 0 || alpha > 1) {
    rlang::abort("`alpha` must be a single number between 0 and 1.")
  }

  if (!is.null(xlim)) {
    if (!is.numeric(xlim) || length(xlim) != 2L || anyNA(xlim) || xlim[1] >= xlim[2]) {
      rlang::abort("`xlim` must be `NULL` or a numeric vector of length 2 with `xlim[1] < xlim[2]`.")
    }
  }

  .make_spec(
    "bar",
    width = width,
    col = col,
    header = header,
    header_align = header_align,
    header_hjust = header_hjust,
    baseline = baseline,
    fill = fill,
    colour = colour,
    alpha = alpha,
    xlim = xlim,
    breaks = breaks
  )
}

fp_dot <- function(
  col,
  lower = NULL,
  upper = NULL,
  header = NULL,
  header_align = "center",
  width = 2.5,
  ref_line = NULL,
  trans = c("identity", "log"),
  truncate = NULL,
  colour = NULL,
  fill = DOT_DEFAULT_FILL,
  shape = DOT_DEFAULT_SHAPE,
  point_size = NULL,
  line_width = CI_DEFAULT_LINE_WIDTH,
  breaks = NULL
) {
  trans <- match.arg(trans)
  .validate_column(col)
  .validate_align(header_align, arg = "header_align")
  header_hjust <- .align_to_hjust(header_align)

  interval_supplied <- xor(is.null(lower), is.null(upper))
  if (interval_supplied) {
    rlang::abort("`lower` and `upper` must either both be supplied or both be `NULL`.")
  }

  dot_cols <- c(col, lower, upper)
  dot_cols <- dot_cols[!is.null(dot_cols)]
  if (!all(vapply(dot_cols, function(x) is.character(x) && length(x) == 1L && nzchar(x), logical(1)))) {
    rlang::abort("`col`, `lower`, and `upper` must be single non-empty strings.")
  }

  if (!is.null(ref_line) && (!is.numeric(ref_line) || length(ref_line) != 1L || is.na(ref_line))) {
    rlang::abort("`ref_line` must be `NULL` or a single numeric value.")
  }

  if (!is.null(truncate)) {
    if (!is.numeric(truncate) || length(truncate) != 2L || anyNA(truncate) || truncate[1] >= truncate[2]) {
      rlang::abort("`truncate` must be `NULL` or a numeric vector of length 2 with `truncate[1] < truncate[2]`.")
    }
  }

  if (!is.numeric(line_width) || length(line_width) != 1L || is.na(line_width) || line_width <= 0) {
    rlang::abort("`line_width` must be a single positive number.")
  }

  .make_spec(
    "dot",
    width = width,
    col = col,
    lower = lower,
    upper = upper,
    header = header,
    header_align = header_align,
    header_hjust = header_hjust,
    ref_line = ref_line,
    trans = trans,
    truncate = truncate,
    colour = colour,
    fill = fill,
    shape = shape,
    point_size = point_size,
    line_width = line_width,
    breaks = breaks
  )
}

fp_ci <- function(
  est,
  lower,
  upper,
  header = NULL,
  header_align = "center",
  width = 3,
  ref_line = CI_DEFAULT_REF_LINE,
  trans = c("identity", "log"),
  xlim = NULL,
  truncate = NULL,
  show_axis = FALSE,
  axis_label = NULL,
  favors_left = NULL,
  favors_right = NULL,
  labels = NULL,
  colour = NULL,
  fill = NULL,
  alpha = CI_DEFAULT_ALPHA,
  glyph = "point",
  summary_glyph = "diamond",
  shape = CI_DEFAULT_SHAPE,
  point_size = NULL,
  line_width = CI_DEFAULT_LINE_WIDTH,
  breaks = NULL,
  mapping = NULL,
  favors_span = FAVORS_ARROW_SPAN,
  favors_gap = FALSE,
  arrow_length = ARROW_LENGTH_INCHES,
  arrow_type = ARROW_TYPE,
  arrow_angle = ARROW_ANGLE
) {
  trans <- match.arg(trans)

  cols <- c(est, lower, upper)
  if (!is.character(cols) || any(lengths(as.list(cols)) != 1L) || any(!nzchar(cols))) {
    rlang::abort("`est`, `lower`, and `upper` must be single non-empty strings.")
  }

  .validate_align(header_align, arg = "header_align")
  header_hjust <- .align_to_hjust(header_align)

  if (!is.numeric(ref_line) || length(ref_line) != 1L || is.na(ref_line)) {
    rlang::abort("`ref_line` must be a single numeric value.")
  }

  if (!is.logical(show_axis) || length(show_axis) != 1L || is.na(show_axis)) {
    rlang::abort("`show_axis` must be `TRUE` or `FALSE`.")
  }

  if (!is.null(axis_label) && !(is.character(axis_label) && length(axis_label) == 1L)) {
    rlang::abort("`axis_label` must be `NULL` or a single string.")
  }

  if (!is.null(favors_left) && !(is.character(favors_left) && length(favors_left) == 1L && nzchar(favors_left))) {
    rlang::abort("`favors_left` must be `NULL` or a single non-empty string.")
  }
  if (!is.null(favors_right) && !(is.character(favors_right) && length(favors_right) == 1L && nzchar(favors_right))) {
    rlang::abort("`favors_right` must be `NULL` or a single non-empty string.")
  }

  if (!is.null(xlim)) {
    if (!is.numeric(xlim) || length(xlim) != 2L || anyNA(xlim) || xlim[1] >= xlim[2]) {
      rlang::abort("`xlim` must be `NULL` or a numeric vector of length 2 with `xlim[1] < xlim[2]`.")
    }
    if (identical(trans, "log") && any(xlim <= 0)) {
      rlang::abort("`xlim` must contain only positive values when `trans = \"log\"`.")
    }
  }

  if (!is.null(truncate)) {
    if (!is.numeric(truncate) || length(truncate) != 2L || anyNA(truncate) || truncate[1] >= truncate[2]) {
      rlang::abort("`truncate` must be `NULL` or a numeric vector of length 2 with `truncate[1] < truncate[2]`.")
    }
    if (identical(trans, "log") && any(truncate <= 0)) {
      rlang::abort("`truncate` must contain only positive values when `trans = \"log\"`.")
    }
  }

  if (identical(trans, "log") && ref_line <= 0) {
    rlang::abort("`ref_line` must be positive when `trans = \"log\"`.")
  }

  if (!is.null(breaks)) {
    if (identical(trans, "log") && any(breaks <= 0, na.rm = TRUE)) {
      rlang::abort("`breaks` must contain only positive values when `trans = \"log\"`.")
    }
  }

  if (!is.null(breaks) && !is.null(labels)) {
    if (is.atomic(labels) && length(labels) != length(breaks)) {
      rlang::abort("`labels` must have the same length as `breaks` when both are supplied as vectors.")
    }
  }

  if (!is.numeric(alpha) || length(alpha) != 1L || is.na(alpha) || alpha < 0 || alpha > 1) {
    rlang::abort("`alpha` must be a single number between 0 and 1.")
  }

  if (!is.numeric(line_width) || length(line_width) != 1L || is.na(line_width) || line_width <= 0) {
    rlang::abort("`line_width` must be a single positive number.")
  }

  .validate_ci_glyph(glyph, arg = "glyph")
  .validate_ci_glyph(summary_glyph, arg = "summary_glyph", allow_null = TRUE)

  if (!is.null(mapping) && !inherits(mapping, "fp_aes")) {
    rlang::abort("`mapping` must be `NULL` or created by `fp_aes()`.")
  }

  if (!is.numeric(favors_span) || length(favors_span) != 1L || is.na(favors_span) ||
      favors_span <= 0 || favors_span > 1) {
    rlang::abort("`favors_span` must be a single number in (0, 1].")
  }

  if (!isFALSE(favors_gap)) {
    if (!isTRUE(favors_gap) &&
        !(is.numeric(favors_gap) && length(favors_gap) == 1L && !is.na(favors_gap) &&
          favors_gap > 0 && favors_gap < 1)) {
      rlang::abort("`favors_gap` must be `FALSE`, `TRUE`, or a single number in (0, 1).")
    }
  }

  if (!is.numeric(arrow_length) || length(arrow_length) != 1L || is.na(arrow_length) || arrow_length <= 0) {
    rlang::abort("`arrow_length` must be a single positive number (inches).")
  }

  valid_arrow_types <- c("open", "closed")
  if (!is.character(arrow_type) || length(arrow_type) != 1L || !arrow_type %in% valid_arrow_types) {
    rlang::abort('`arrow_type` must be "open" or "closed".')
  }

  if (!is.numeric(arrow_angle) || length(arrow_angle) != 1L || is.na(arrow_angle) ||
      arrow_angle <= 0 || arrow_angle >= 90) {
    rlang::abort("`arrow_angle` must be a single number in (0, 90).")
  }

  .make_spec(
    "ci",
    width = width,
    est = est,
    lower = lower,
    upper = upper,
    header = header,
    header_align = header_align,
    header_hjust = header_hjust,
    ref_line = ref_line,
    trans = trans,
    xlim = xlim,
    truncate = truncate,
    show_axis = show_axis,
    axis_label = axis_label,
    favors_left = favors_left,
    favors_right = favors_right,
    labels = labels,
    colour = colour,
    fill = fill,
    alpha = alpha,
    glyph = glyph,
    summary_glyph = summary_glyph,
    shape = shape,
    point_size = point_size,
    line_width = line_width,
    breaks = breaks,
    mapping = mapping,
    favors_span = favors_span,
    favors_gap = favors_gap,
    arrow_length = arrow_length,
    arrow_type = arrow_type,
    arrow_angle = arrow_angle
  )
}

fp_custom <- function(
  plot_fn,
  header = NULL,
  width = 1.5,
  header_x = 0.5,
  header_align = "center"
) {
  if (!is.function(plot_fn)) {
    rlang::abort("`plot_fn` must be a function.")
  }

  .validate_align(header_align, arg = "header_align")
  header_hjust <- .align_to_hjust(header_align)

  if (!is.numeric(header_x) || length(header_x) != 1L || is.na(header_x)) {
    rlang::abort("`header_x` must be a single numeric value.")
  }

  .make_spec(
    "custom",
    width = width,
    plot_fn = plot_fn,
    header = header,
    header_x = header_x,
    header_align = header_align,
    header_hjust = header_hjust
  )
}

.validate_layout_specs <- function(specs) {
  if (!is.list(specs) || !all(vapply(specs, inherits, logical(1), what = "fp_spec"))) {
    rlang::abort(
      "Only panelforest spec objects such as `fp_text()`, `fp_gap()`, `fp_ci()`, and `fp_custom()` are accepted."
    )
  }

  specs
}

.validate_spec <- function(data, spec, n_rows) {
  if (!inherits(spec, "fp_spec")) {
    rlang::abort("All layout entries must inherit from `fp_spec`.")
  }

  if (spec$type %in% c("gap", "spacer")) {
    return(invisible(spec))
  }

  required_cols <- switch(
    spec$type,
    text = spec$col,
    text_ci = c(spec$est, spec$lower, spec$upper),
    ci = c(spec$est, spec$lower, spec$upper),
    bar = spec$col,
    dot = c(spec$col, spec$lower, spec$upper),
    custom = character(),
    character()
  )

  if (!is.null(spec$mapping)) {
    required_cols <- c(required_cols, unlist(spec$mapping))
  }

  required_cols <- required_cols[!is.na(required_cols)]
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols)) {
    rlang::abort(sprintf(
      "Spec `%s` refers to missing column(s): %s.",
      spec$type,
      paste(missing_cols, collapse = ", ")
    ))
  }

  if (identical(spec$type, "custom") && !is.function(spec$plot_fn)) {
    rlang::abort("Custom specs must contain a valid `plot_fn`.")
  }

  invisible(spec)
}
