.invoke_text_formatter <- function(formatter, values, data) {
  if (is.null(formatter)) {
    return(as.character(values))
  }

  formatter_formals <- names(formals(formatter))
  available <- list(values = values, data = data)

  if (is.null(formatter_formals)) {
    out <- formatter()
  } else if ("..." %in% formatter_formals) {
    out <- do.call(formatter, available)
  } else {
    args <- available[intersect(formatter_formals, names(available))]
    out <- do.call(formatter, args)
  }

  out <- as.character(out)
  if (length(out) == 1L) {
    out <- rep(out, length(values))
  }

  if (length(out) != length(values)) {
    rlang::abort("`formatter` must return length 1 or the same length as the input data.")
  }

  out
}

# --- text builder ---

.build_text <- function(ctx, spec, cell_edits) {
  n_rows <- ctx$n_rows
  row_ids <- seq_len(n_rows)
  indent_values <- .resolve_indent(spec$indent, ctx$data, n_rows)

  fontface <- .resolve_attr(ctx, spec, cell_edits, "fontface", default = "plain")
  colour <- .resolve_attr(ctx, spec, cell_edits, "colour", default = ctx$theme$text_colour)
  size <- .resolve_attr(ctx, spec, cell_edits, "size", default = ctx$theme$text_size, numeric_only = TRUE)
  family <- .resolve_attr(ctx, spec, cell_edits, "family", default = ctx$theme$base_family)
  labels <- .invoke_text_formatter(spec$formatter, ctx$data[[spec$col]], ctx$data)

  fontface <- .summary_text_fontface(fontface, ctx$summary_mask)
  fontface <- .group_text_fontface(fontface, ctx$group_mask)
  size <- .group_text_size(size, ctx$group_mask)

  labels <- .apply_cell_overrides(labels, cell_edits, row_ids, "label")

  df <- data.frame(
    row_id = row_ids,
    x = .resolve_text_positions(spec$hjust, indent_values, spec$indent_width),
    y = ctx$layout$centers,
    label = labels,
    fontface = fontface,
    colour = colour,
    size = size,
    family = family
  )

  plot <- .empty_panel(ctx$layout) +
    ggplot2::geom_text(
      data = df,
      mapping = ggplot2::aes(x = x, y = y, label = label),
      inherit.aes = FALSE,
      hjust = spec$hjust,
      family = df$family,
      fontface = df$fontface,
      colour = df$colour,
      size = df$size
    ) +
    ggplot2::scale_x_continuous(limits = c(0, 1), expand = ggplot2::expansion(mult = c(0, 0)))

  .finalize_panel(
    plot,
    spec = spec,
    layout = ctx$layout,
    row_styles = ctx$row_styles,
    hlines = ctx$hlines,
    theme = ctx$theme,
    stripe_colors = ctx$stripe_colors,
    x_limits = c(0, 1),
    header_x = spec$header_hjust %||% spec$hjust,
    header_hjust = spec$header_hjust %||% spec$hjust
  )
}

# --- text_ci builder ---

.build_text_ci <- function(ctx, spec, cell_edits) {
  text_spec <- .make_spec(
    "text",
    width = spec$width,
    col = spec$est,
    header = spec$header,
    hjust = spec$hjust,
    header_hjust = spec$header_hjust,
    indent = NULL,
    indent_width = 0,
    formatter = function(values, data) {
      .format_ci_text(
        est = as.numeric(data[[spec$est]]),
        lower = as.numeric(data[[spec$lower]]),
        upper = as.numeric(data[[spec$upper]]),
        digits = spec$digits,
        prefix = spec$prefix,
        suffix = spec$suffix,
        na = spec$na %||% ""
      )
    },
    fontface = spec$fontface,
    colour = spec$colour,
    size = spec$size,
    mapping = spec$mapping
  )

  .build_text(ctx, text_spec, cell_edits)
}

# --- gap builder ---

.build_gap <- function(ctx, spec, cell_edits) {
  plot <- .empty_panel(ctx$layout) +
    ggplot2::scale_x_continuous(limits = c(0, 1), expand = ggplot2::expansion(mult = c(0, 0)))

  .finalize_panel(
    plot,
    spec = spec,
    layout = ctx$layout,
    row_styles = ctx$row_styles,
    hlines = ctx$hlines,
    theme = ctx$theme,
    stripe_colors = ctx$stripe_colors,
    x_limits = c(0, 1),
    header_x = spec$header_hjust %||% 0.5,
    header_hjust = spec$header_hjust %||% 0.5
  )
}

# --- ci builder ---

.build_ci <- function(ctx, spec, cell_edits) {
  n_rows <- ctx$n_rows
  row_ids <- seq_len(n_rows)
  est <- as.numeric(ctx$data[[spec$est]])
  lower <- as.numeric(ctx$data[[spec$lower]])
  upper <- as.numeric(ctx$data[[spec$upper]])

  if (spec$trans == "log" && any(c(est, lower, upper) <= 0, na.rm = TRUE)) {
    rlang::abort("`trans = \"log\"` requires positive `est`, `lower`, and `upper` values.")
  }

  limits <- .resolve_ci_limits(spec, est, lower, upper)
  truncate_limits <- .resolve_ci_truncate(spec, limits)
  clipped_est <- .clip_ci_values(est, truncate_limits)
  clipped_lower <- .clip_ci_values(lower, truncate_limits)
  clipped_upper <- .clip_ci_values(upper, truncate_limits)

  colour <- .resolve_attr(ctx, spec, cell_edits, "colour", default = ctx$theme$text_colour)
  fill <- .resolve_attr(ctx, spec, cell_edits, "fill", default = NA_character_, skip_row = TRUE)
  alpha <- .resolve_attr(ctx, spec, cell_edits, "alpha", default = CI_DEFAULT_ALPHA, numeric_only = TRUE, skip_row = TRUE)
  glyph <- .resolve_attr(ctx, spec, cell_edits, "glyph", default = "point")
  shape <- .resolve_attr(ctx, spec, cell_edits, "shape", default = CI_DEFAULT_SHAPE, numeric_only = TRUE)
  point_size <- .resolve_attr(ctx, spec, cell_edits, "point_size", default = CI_DEFAULT_POINT_SIZE, numeric_only = TRUE)
  line_width <- .resolve_attr(ctx, spec, cell_edits, "line_width", default = spec$line_width, numeric_only = TRUE)

  glyph <- .validate_ci_glyph_values(glyph, arg = "glyph")
  glyph <- .summary_ci_glyph(glyph, ctx$summary_mask, summary_glyph = spec$summary_glyph %||% "diamond")
  shape <- .summary_ci_shape(shape, ctx$summary_mask)
  point_size <- .summary_ci_point_size(point_size, ctx$summary_mask)
  line_width <- .summary_ci_line_width(line_width, ctx$summary_mask)

  df <- data.frame(
    row_id = row_ids,
    y = ctx$layout$centers,
    est = clipped_est,
    lower = clipped_lower,
    upper = clipped_upper,
    colour = colour,
    fill = ifelse(is.na(fill), colour, fill),
    alpha = alpha,
    glyph = glyph,
    shape = shape,
    point_size = point_size,
    line_width = line_width
  )
  draw_mask <- !ctx$group_mask & is.finite(df$est) & is.finite(df$lower) & is.finite(df$upper)
  draw_df <- df[draw_mask, , drop = FALSE]
  point_df <- draw_df[draw_df$glyph != "diamond", , drop = FALSE]
  diamond_df <- draw_df[draw_df$glyph == "diamond", , drop = FALSE]
  diamond_poly_df <- .build_ci_diamond_data(diamond_df, row_heights = ctx$row_heights)

  lower_trunc <- lower < truncate_limits[1]
  upper_trunc <- upper > truncate_limits[2]
  lower_trunc[ctx$group_mask] <- FALSE
  upper_trunc[ctx$group_mask] <- FALSE
  span <- truncate_limits[2] - truncate_limits[1]
  offset <- if (spec$trans == "log") truncate_limits[1] * ARROW_LOG_OFFSET_FACTOR else span * ARROW_LINEAR_OFFSET_FACTOR
  if (offset <= 0 || !is.finite(offset)) {
    offset <- ARROW_FALLBACK_OFFSET
  }

  if (identical(spec$trans, "log")) {
    log_range <- log10(limits[2]) - log10(limits[1])
    display_limits <- c(
      10^(log10(limits[1]) - CI_EXPANSION_MULT_LEFT * log_range),
      10^(log10(limits[2]) + CI_EXPANSION_MULT * log_range)
    )
  } else {
    display_limits <- limits
  }

  plot <- .empty_panel(ctx$layout) +
    ggplot2::scale_x_continuous(
      limits = display_limits,
      trans = if (spec$trans == "log") "log10" else "identity",
      breaks = spec$breaks %||% ggplot2::waiver(),
      labels = spec$labels %||% ggplot2::waiver(),
      expand = ggplot2::expansion(mult = c(0, 0)),
      guide = ggplot2::guide_axis(cap = "both")
    )

  if (nrow(point_df)) {
    plot <- plot +
      ggplot2::geom_segment(
        data = point_df,
        mapping = ggplot2::aes(x = lower, xend = upper, y = y, yend = y),
        inherit.aes = FALSE,
        linewidth = point_df$line_width,
        colour = point_df$colour
      ) +
      ggplot2::geom_point(
        data = point_df,
        mapping = ggplot2::aes(x = est, y = y),
        inherit.aes = FALSE,
        colour = point_df$colour,
        fill = point_df$fill,
        shape = point_df$shape,
        size = point_df$point_size,
        alpha = point_df$alpha
      )
  }

  if (!is.null(diamond_poly_df) && nrow(diamond_poly_df)) {
    plot <- plot +
      ggplot2::geom_polygon(
        data = diamond_poly_df,
        mapping = ggplot2::aes(x = x, y = y, group = group),
        inherit.aes = FALSE,
        fill = diamond_poly_df$fill,
        colour = diamond_poly_df$colour,
        linewidth = diamond_poly_df$line_width,
        alpha = diamond_poly_df$alpha
      )
  }

  plot <- .add_ref_line(plot, spec$ref_line, layout = ctx$layout, theme = ctx$theme)

  point_draw_mask <- draw_mask & glyph != "diamond"

  if (any(lower_trunc & point_draw_mask, na.rm = TRUE)) {
    plot <- plot +
      ggplot2::geom_segment(
        data = df[lower_trunc & point_draw_mask, , drop = FALSE],
        mapping = ggplot2::aes(
          x = if (spec$trans == "log") truncate_limits[1] * 1.1 else truncate_limits[1] + offset,
          xend = truncate_limits[1],
          y = y,
          yend = y
        ),
        inherit.aes = FALSE,
        linewidth = df$line_width[lower_trunc & point_draw_mask],
        colour = df$colour[lower_trunc & point_draw_mask],
        arrow = grid::arrow(
          length = grid::unit(spec$arrow_length, "inches"),
          type = spec$arrow_type,
          angle = spec$arrow_angle,
          ends = "last"
        )
      )
  }

  if (any(upper_trunc & point_draw_mask, na.rm = TRUE)) {
    plot <- plot +
      ggplot2::geom_segment(
        data = df[upper_trunc & point_draw_mask, , drop = FALSE],
        mapping = ggplot2::aes(
          x = truncate_limits[2],
          xend = if (spec$trans == "log") truncate_limits[2] / 1.1 else truncate_limits[2] - offset,
          y = y,
          yend = y
        ),
        inherit.aes = FALSE,
        linewidth = df$line_width[upper_trunc & point_draw_mask],
        colour = df$colour[upper_trunc & point_draw_mask],
        arrow = grid::arrow(
          length = grid::unit(spec$arrow_length, "inches"),
          type = spec$arrow_type,
          angle = spec$arrow_angle,
          ends = "first"
        )
      )
  }

  plot <- .finalize_panel(
    plot,
    spec = spec,
    layout = ctx$layout,
    row_styles = ctx$row_styles,
    hlines = ctx$hlines,
    theme = ctx$theme,
    stripe_colors = ctx$stripe_colors,
    x_limits = display_limits,
    header_x = .header_anchor_for_limits(limits, spec$trans, spec$header_hjust %||% 0.5),
    header_hjust = spec$header_hjust %||% 0.5,
    trans = spec$trans
  )

  if (isTRUE(spec$show_axis)) {
    plot <- plot +
      ggplot2::labs(x = spec$axis_label %||% NULL) +
      .ci_axis_theme(ctx$theme)
  }

  has_favors <- !is.null(spec$favors_left) || !is.null(spec$favors_right)
  if (has_favors) {
    plot <- plot + ggplot2::theme(
      axis.title.x = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(t = 0, r = 0, b = 45, l = 0)
    )

    # Compute arrow x endpoints based on scale
    favors_span <- spec$favors_span %||% FAVORS_ARROW_SPAN
    if (identical(spec$trans, "log")) {
      log_ref <- log10(spec$ref_line)
      log_lo  <- log10(display_limits[1])
      log_hi  <- log10(display_limits[2])
      arrow_left_x  <- 10^(log_ref - favors_span * (log_ref - log_lo))
      arrow_right_x <- 10^(log_ref + favors_span * (log_hi - log_ref))
    } else {
      left_half  <- spec$ref_line - display_limits[1]
      right_half <- display_limits[2] - spec$ref_line
      arrow_left_x  <- spec$ref_line - favors_span * left_half
      arrow_right_x <- spec$ref_line + favors_span * right_half
    }

    # Compute arrow start points (with optional gap)
    favors_gap <- spec$favors_gap %||% FALSE
    if (!isFALSE(favors_gap)) {
      gap_frac <- if (isTRUE(favors_gap)) FAVORS_GAP_DEFAULT else favors_gap
      if (identical(spec$trans, "log")) {
        arrow_start_left  <- 10^(log_ref - gap_frac * (log_ref - log_lo))
        arrow_start_right <- 10^(log_ref + gap_frac * (log_hi - log_ref))
      } else {
        arrow_start_left  <- spec$ref_line - gap_frac * left_half
        arrow_start_right <- spec$ref_line + gap_frac * right_half
      }
    } else {
      arrow_start_left  <- spec$ref_line
      arrow_start_right <- spec$ref_line
    }

    if (!is.null(spec$favors_left)) {
      plot <- plot +
        ggplot2::annotate(
          "segment",
          x = arrow_start_left, xend = arrow_left_x,
          y = -FAVORS_ARROW_Y_OFFSET, yend = -FAVORS_ARROW_Y_OFFSET,
          arrow = grid::arrow(length = grid::unit(FAVORS_ARROW_LENGTH_IN, "inches"),
                              type = "closed", ends = "last"),
          colour = ctx$theme$text_colour,
          linewidth = FAVORS_ARROW_LINEWIDTH
        ) +
        ggplot2::annotate(
          "text",
          x = spec$ref_line, y = -FAVORS_TEXT_Y_OFFSET,
          label = spec$favors_left,
          hjust = 1.08,
          size = ctx$theme$text_size,
          colour = ctx$theme$text_colour,
          family = ctx$theme$base_family
        )
    }
    if (!is.null(spec$favors_right)) {
      plot <- plot +
        ggplot2::annotate(
          "segment",
          x = arrow_start_right, xend = arrow_right_x,
          y = -FAVORS_ARROW_Y_OFFSET, yend = -FAVORS_ARROW_Y_OFFSET,
          arrow = grid::arrow(length = grid::unit(FAVORS_ARROW_LENGTH_IN, "inches"),
                              type = "closed", ends = "last"),
          colour = ctx$theme$text_colour,
          linewidth = FAVORS_ARROW_LINEWIDTH
        ) +
        ggplot2::annotate(
          "text",
          x = spec$ref_line, y = -FAVORS_TEXT_Y_OFFSET,
          label = spec$favors_right,
          hjust = -0.08,
          size = ctx$theme$text_size,
          colour = ctx$theme$text_colour,
          family = ctx$theme$base_family
        )
    }
  }

  plot
}

# --- bar builder (bug fix: geom_rect instead of geom_segment linewidth=6) ---

.build_bar <- function(ctx, spec, cell_edits) {
  n_rows <- ctx$n_rows
  row_ids <- seq_len(n_rows)
  values <- as.numeric(ctx$data[[spec$col]])
  draw_mask <- !ctx$group_mask & is.finite(values)

  fill <- .resolve_style(spec$fill, n_rows, BAR_DEFAULT_FILL, "fill")
  colour <- .resolve_style(spec$colour, n_rows, NA_character_, "colour")

  fill <- .apply_row_overrides(fill, ctx$row_styles, row_ids, "fill")
  colour <- .apply_row_overrides(colour, ctx$row_styles, row_ids, "colour")

  half_h <- ctx$row_heights * BAR_ROW_HEIGHT_FRACTION / 2

  df <- data.frame(
    row_id = row_ids,
    y = ctx$layout$centers,
    ymin = ctx$layout$centers - half_h,
    ymax = ctx$layout$centers + half_h,
    xmin = rep(spec$baseline, n_rows),
    xmax = values,
    fill = fill,
    colour = colour
  )
  draw_df <- df[draw_mask, , drop = FALSE]

  limits <- spec$xlim
  if (is.null(limits)) {
    valid <- c(spec$baseline, values[is.finite(values)])
    limits <- range(valid)
    if (diff(limits) == 0) {
      limits <- limits + c(-RANGE_LINEAR_PAD, RANGE_LINEAR_PAD)
    }
  }

  plot <- .empty_panel(ctx$layout) +
    ggplot2::geom_rect(
      data = draw_df,
      mapping = ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
      inherit.aes = FALSE,
      fill = draw_df$fill,
      colour = draw_df$colour,
      alpha = spec$alpha
    ) +
    ggplot2::scale_x_continuous(
      limits = limits,
      breaks = spec$breaks %||% ggplot2::waiver(),
      expand = ggplot2::expansion(mult = c(CI_EXPANSION_MULT, CI_EXPANSION_MULT)),
      guide = ggplot2::guide_axis(cap = "both")
    )

  .finalize_panel(
    plot,
    spec = spec,
    layout = ctx$layout,
    row_styles = ctx$row_styles,
    hlines = ctx$hlines,
    theme = ctx$theme,
    stripe_colors = ctx$stripe_colors,
    x_limits = limits,
    header_x = .header_anchor_for_limits(limits, "identity", spec$header_hjust %||% 0.5),
    header_hjust = spec$header_hjust %||% 0.5
  )
}

# --- dot builder ---

.build_dot <- function(ctx, spec, cell_edits) {
  n_rows <- ctx$n_rows
  row_ids <- seq_len(n_rows)
  value <- as.numeric(ctx$data[[spec$col]])
  lower <- if (is.null(spec$lower)) value else as.numeric(ctx$data[[spec$lower]])
  upper <- if (is.null(spec$upper)) value else as.numeric(ctx$data[[spec$upper]])

  if (spec$trans == "log" && any(c(value, lower, upper) <= 0, na.rm = TRUE)) {
    rlang::abort("`trans = \"log\"` requires positive values in `col`, `lower`, and `upper`.")
  }

  limits <- if (!is.null(spec$truncate)) spec$truncate else .resolve_ci_limits(
    list(trans = spec$trans, truncate = NULL, xlim = NULL),
    value,
    lower,
    upper
  )

  colour <- .resolve_style(spec$colour, n_rows, ctx$theme$text_colour, "colour")
  fill <- .resolve_style(spec$fill, n_rows, DOT_DEFAULT_FILL, "fill")
  shape <- .resolve_style(spec$shape, n_rows, DOT_DEFAULT_SHAPE, "shape")
  point_size <- .resolve_style(spec$point_size, n_rows, DOT_DEFAULT_POINT_SIZE, "point_size")
  line_width <- rep(spec$line_width, n_rows)

  shape <- .summary_ci_shape(shape, ctx$summary_mask)
  point_size <- .summary_ci_point_size(point_size, ctx$summary_mask)
  line_width <- .summary_ci_line_width(line_width, ctx$summary_mask)

  colour <- .apply_row_overrides(colour, ctx$row_styles, row_ids, "colour")
  fill <- .apply_row_overrides(fill, ctx$row_styles, row_ids, "fill")
  shape <- .apply_row_overrides(shape, ctx$row_styles, row_ids, "shape")
  point_size <- .apply_row_overrides(point_size, ctx$row_styles, row_ids, "point_size")
  line_width <- .apply_row_overrides(line_width, ctx$row_styles, row_ids, "line_width")

  df <- data.frame(
    row_id = row_ids,
    y = ctx$layout$centers,
    value = .clip_ci_values(value, limits),
    lower = .clip_ci_values(lower, limits),
    upper = .clip_ci_values(upper, limits),
    colour = colour,
    fill = fill,
    shape = shape,
    point_size = point_size,
    line_width = line_width
  )
  draw_mask <- !ctx$group_mask & is.finite(df$value)
  draw_df <- df[draw_mask, , drop = FALSE]

  plot <- .empty_panel(ctx$layout)
  if (!is.null(spec$ref_line)) {
    plot <- .add_ref_line(plot, spec$ref_line, layout = ctx$layout, theme = ctx$theme)
  }

  if (!is.null(spec$lower) && !is.null(spec$upper)) {
    plot <- plot +
      ggplot2::geom_segment(
        data = draw_df,
        mapping = ggplot2::aes(x = lower, xend = upper, y = y, yend = y),
        inherit.aes = FALSE,
        linewidth = draw_df$line_width,
        colour = draw_df$colour
      )
  }

  plot <- plot +
    ggplot2::geom_point(
      data = draw_df,
      mapping = ggplot2::aes(x = value, y = y),
      inherit.aes = FALSE,
      shape = draw_df$shape,
      size = draw_df$point_size,
      stroke = draw_df$line_width,
      colour = draw_df$colour,
      fill = draw_df$fill
    )

  if (identical(spec$trans, "log")) {
    log_range <- log10(limits[2]) - log10(limits[1])
    dot_display_limits <- c(
      10^(log10(limits[1]) - CI_EXPANSION_MULT * log_range),
      10^(log10(limits[2]) + CI_EXPANSION_MULT * log_range)
    )
  } else {
    dot_display_limits <- limits
  }

  plot <- plot +
    ggplot2::scale_x_continuous(
      limits = dot_display_limits,
      trans = if (spec$trans == "log") "log10" else "identity",
      breaks = spec$breaks %||% ggplot2::waiver(),
      expand = ggplot2::expansion(mult = c(0, 0))
    )

  .finalize_panel(
    plot,
    spec = spec,
    layout = ctx$layout,
    row_styles = ctx$row_styles,
    hlines = ctx$hlines,
    theme = ctx$theme,
    stripe_colors = ctx$stripe_colors,
    x_limits = dot_display_limits,
    header_x = .header_anchor_for_limits(limits, spec$trans, spec$header_hjust %||% 0.5),
    header_hjust = spec$header_hjust %||% 0.5,
    trans = spec$trans
  )
}

# --- custom builder ---

.invoke_custom_plot_fn <- function(plot_fn, data, spec, n_rows, row_heights, theme) {
  available <- list(
    data = data,
    spec = spec,
    n_rows = n_rows,
    row_heights = row_heights,
    theme = theme
  )

  fn_formals <- names(formals(plot_fn))
  if (is.null(fn_formals)) {
    return(plot_fn())
  }

  if ("..." %in% fn_formals) {
    return(do.call(plot_fn, available))
  }

  args <- available[intersect(fn_formals, names(available))]
  if (!length(args)) {
    rlang::abort(
      "Custom `plot_fn` must accept at least one of: `data`, `spec`, `n_rows`, `row_heights`, or `theme`."
    )
  }

  do.call(plot_fn, args)
}

.build_custom <- function(ctx, spec, cell_edits) {
  plot <- .invoke_custom_plot_fn(
    plot_fn = spec$plot_fn,
    data = ctx$data,
    spec = spec,
    n_rows = ctx$n_rows,
    row_heights = ctx$row_heights,
    theme = ctx$theme
  )

  if (!inherits(plot, "ggplot")) {
    rlang::abort("Custom `plot_fn` must return a ggplot object.")
  }

  plot <- plot + .y_scale(ctx$layout)

  .finalize_panel(
    plot,
    spec = spec,
    layout = ctx$layout,
    row_styles = ctx$row_styles,
    hlines = ctx$hlines,
    theme = ctx$theme,
    stripe_colors = ctx$stripe_colors,
    x_limits = c(0, 1),
    header_x = spec$header_x %||% 0.5,
    header_hjust = spec$header_hjust %||% 0.5
  )
}
