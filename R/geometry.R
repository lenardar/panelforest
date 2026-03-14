.row_layout <- function(row_heights, header_height) {
  if (!is.numeric(row_heights) || !length(row_heights) || anyNA(row_heights) || any(row_heights <= 0)) {
    rlang::abort("`row_heights` must be a non-empty numeric vector of positive values.")
  }

  all_heights <- c(header_height, row_heights)
  n <- length(all_heights)
  cs <- cumsum(all_heights)
  cumulative_before <- c(0, cs[-n])
  total <- sum(all_heights)
  ymax <- total - cumulative_before
  ymin <- ymax - all_heights
  all_centers <- ymin + all_heights / 2

  data_idx <- 2:n
  list(
    heights = row_heights,
    ymin = ymin[data_idx],
    ymax = ymax[data_idx],
    centers = all_centers[data_idx],
    total_height = total,
    header_center = all_centers[1]
  )
}

.y_scale <- function(layout) {
  ggplot2::scale_y_continuous(
    breaks = layout$centers,
    labels = NULL,
    expand = ggplot2::expansion(mult = c(0, 0))
  )
}

.empty_panel <- function(layout) {
  ggplot2::ggplot() +
    .y_scale(layout) +
    ggplot2::theme_void()
}

.align_to_hjust <- function(value) {
  switch(
    value,
    left = 0,
    center = 0.5,
    right = 1
  )
}

.resolve_text_positions <- function(hjust, indent_values, indent_width) {
  direction <- if (hjust <= 0.5) 1 else -1
  positions <- hjust + direction * indent_values * indent_width
  pmin(pmax(positions, 0), 1)
}

.panel_layout_widths <- function(specs) {
  width_units <- lapply(
    specs,
    function(spec) {
      if (identical(spec$type, "spacer")) {
        return(grid::unit(spec$width, spec$unit))
      }

      grid::unit(spec$width, "null")
    }
  )

  do.call(grid::unit.c, width_units)
}

.panel_width_inches <- function(specs) {
  content_width <- sum(vapply(
    specs,
    function(spec) if (identical(spec$type, "spacer")) 0 else spec$width,
    numeric(1)
  ))

  spacer_width <- sum(vapply(
    specs,
    function(spec) {
      if (!identical(spec$type, "spacer")) {
        return(0)
      }

      grid::convertWidth(grid::unit(spec$width, spec$unit), "in", valueOnly = TRUE)
    },
    numeric(1)
  ))

  content_width + spacer_width
}

.panel_base_theme <- function(theme) {
  ggplot2::theme_void(base_family = theme$base_family) +
    ggplot2::theme(
      plot.margin = ggplot2::margin(t = 0, r = 0, b = 0, l = 0),
      plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
      panel.background = ggplot2::element_rect(fill = "transparent", colour = NA)
    )
}

.ci_axis_theme <- function(theme) {
  ggplot2::theme(
    axis.line.x = ggplot2::element_line(colour = theme$text_colour, linewidth = AXIS_LINE_WIDTH),
    axis.ticks.x = ggplot2::element_line(colour = theme$text_colour, linewidth = AXIS_LINE_WIDTH),
    axis.ticks.length.x = grid::unit(AXIS_TICK_LENGTH_INCHES, "inches"),
    axis.text.x = ggplot2::element_text(
      colour = theme$text_colour,
      size = theme$text_size * ggplot2::.pt,
      family = theme$base_family,
      margin = ggplot2::margin(t = AXIS_TEXT_MARGIN_TOP)
    ),
    axis.title.x = ggplot2::element_text(
      colour = theme$text_colour,
      size = (theme$text_size + AXIS_TITLE_SIZE_BOOST) * ggplot2::.pt,
      family = theme$base_family,
      margin = ggplot2::margin(t = AXIS_TITLE_MARGIN_TOP)
    )
  )
}
