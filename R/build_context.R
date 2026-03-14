.build_context <- function(plot) {
  n_rows <- nrow(plot$data)
  layout <- .row_layout(plot$row_heights, plot$header_height)

  list(
    data = plot$data,
    n_rows = n_rows,
    row_heights = plot$row_heights,
    header_height = plot$header_height,
    layout = layout,
    stripe_colors = plot$stripe_colors,
    row_styles = plot$row_styles,
    summary_mask = .summary_mask(plot$summary_rows, n_rows),
    group_mask = .group_mask(plot$group_rows, n_rows),
    hlines = plot$hlines,
    theme = plot$theme
  )
}

.summary_mask <- function(summary_rows, n_rows) {
  mask <- rep(FALSE, n_rows)
  if (length(summary_rows)) {
    mask[summary_rows] <- TRUE
  }
  mask
}

.group_mask <- function(group_rows, n_rows) {
  mask <- rep(FALSE, n_rows)
  if (length(group_rows)) {
    mask[group_rows] <- TRUE
  }
  mask
}
