.resolve_stripe_fills <- function(n_rows, stripe_colors, row_styles) {
  fills <- rep(NA_character_, n_rows)

  if (!is.null(stripe_colors)) {
    fills <- stripe_colors[(seq_len(n_rows) - 1L) %% length(stripe_colors) + 1L]
  }

  fills <- .apply_row_overrides(fills, row_styles = row_styles, row_ids = seq_len(n_rows), attr = "fill")

  if (all(is.na(fills))) {
    return(NULL)
  }

  fills
}

.collect_hline_data <- function(hlines, layout) {
  n_rows <- length(layout$heights)
  if (!length(hlines)) {
    return(NULL)
  }

  pieces <- lapply(
    hlines,
    function(line) {
      if (!length(line$rows)) {
        return(NULL)
      }

      rows <- line$rows[line$rows <= n_rows]
      if (!length(rows)) {
        return(NULL)
      }

      data.frame(
        yintercept = layout$ymin[rows],
        colour = rep(line$colour, length(rows)),
        linewidth = rep(line$linewidth, length(rows)),
        linetype = rep(line$linetype, length(rows))
      )
    }
  )

  pieces <- Filter(Negate(is.null), pieces)
  if (!length(pieces)) {
    return(NULL)
  }

  do.call(rbind, pieces)
}

.add_hlines <- function(plot, hlines, layout) {
  line_df <- .collect_hline_data(hlines, layout)
  if (is.null(line_df) || !nrow(line_df)) {
    return(plot)
  }

  hline_layers <- lapply(
    seq_len(nrow(line_df)),
    function(i) {
      ggplot2::geom_hline(
        yintercept = line_df$yintercept[[i]],
        colour = line_df$colour[[i]],
        linewidth = line_df$linewidth[[i]],
        linetype = line_df$linetype[[i]]
      )
    }
  )

  plot$layers <- c(hline_layers, plot$layers)
  plot
}

.add_stripes <- function(plot, layout, stripe_colors, row_styles, theme, x_limits = c(-Inf, Inf), trans = "identity") {
  fills <- .resolve_stripe_fills(length(layout$heights), stripe_colors = stripe_colors, row_styles = row_styles)

  if (is.null(fills)) {
    return(plot)
  }

  stripe_df <- data.frame(
    ymin = layout$ymin,
    ymax = layout$ymax,
    fill = fills
  )
  stripe_df <- stripe_df[!is.na(stripe_df$fill), , drop = FALSE]

  if (!nrow(stripe_df)) {
    return(plot)
  }

  if (identical(trans, "log")) {
    xmin_val <- x_limits[1]
    xmax_val <- x_limits[2]
  } else {
    xmin_val <- -Inf
    xmax_val <- Inf
  }

  stripe_layer <- ggplot2::geom_rect(
    data = stripe_df,
    mapping = ggplot2::aes(
      xmin = xmin_val,
      xmax = xmax_val,
      ymin = ymin,
      ymax = ymax
    ),
    inherit.aes = FALSE,
    fill = stripe_df$fill,
    alpha = theme$stripe_alpha
  )

  plot$layers <- c(list(stripe_layer), plot$layers)
  plot
}

.add_header <- function(plot, spec, layout, theme, x = 0.5, hjust = 0.5) {
  header <- spec$header %||% NULL

  if (is.null(header)) {
    return(plot)
  }

  plot +
    ggplot2::annotate(
      "text",
      x = x,
      y = layout$header_center,
      label = header,
      hjust = hjust,
      vjust = 0.5,
      size = theme$header_size,
      fontface = theme$header_fontface,
      colour = theme$header_colour,
      family = theme$base_family
    )
}

.add_ref_line <- function(plot, ref_line, layout, theme) {
  if (is.null(ref_line) || !is.finite(ref_line)) {
    return(plot)
  }

  plot +
    ggplot2::annotate(
      "segment",
      x = ref_line,
      xend = ref_line,
      y = 0,
      yend = layout$ymax[1],
      linewidth = REFLINE_WIDTH,
      linetype = REFLINE_LINETYPE,
      colour = theme$refline_colour
    )
}

.finalize_panel <- function(
  plot,
  spec,
  layout,
  row_styles,
  hlines,
  theme,
  stripe_colors = NULL,
  x_limits = c(-Inf, Inf),
  header_x = 0.5,
  header_hjust = 0.5,
  trans = "identity"
) {
  plot <- .add_hlines(plot, hlines = hlines, layout = layout)
  plot <- .add_stripes(
    plot,
    layout = layout,
    stripe_colors = stripe_colors,
    row_styles = row_styles,
    theme = theme,
    x_limits = x_limits,
    trans = trans
  )
  plot <- .add_header(plot, spec = spec, layout = layout, theme = theme, x = header_x, hjust = header_hjust)
  plot + .panel_base_theme(theme) +
    ggplot2::coord_cartesian(ylim = c(0, layout$total_height), clip = "off")
}
