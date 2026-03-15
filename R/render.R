.fp_device_size <- function(x) {
  margin_in <- x$theme$plot_margin / 72  # pt → inches

  header_group_height <- 0
  if (length(x$header_groups)) {
    levels <- .compute_header_levels(x$header_groups)
    header_group_height <- sum(.compute_level_heights(x$header_groups, levels, x$header_height))
  }

  c(
    width = .panel_width_inches(x$specs) + 2 * margin_in,
    height = sum(x$row_heights) + x$header_height + header_group_height + 2 * margin_in
  )
}

fp_render <- function(x) {
  .validate_fp_plot(x)

  specs <- x$specs
  if (!length(specs)) {
    rlang::abort("Nothing to render. Add at least one panel spec with `add_*()` or `fp_layout()`.")
  }

  n_rows <- nrow(x$data)
  if (n_rows < 1L) {
    rlang::abort("`data` must contain at least one row.")
  }

  invisible(lapply(specs, .validate_spec, data = x$data, n_rows = n_rows))

  ctx <- .build_context(x)

  panels <- lapply(
    seq_along(specs),
    function(i) {
      spec <- specs[[i]]
      builder <- .fp_dispatch(spec)
      cell_edits <- if (length(x$cell_edits) >= i) x$cell_edits[[i]] else vector("list", n_rows)
      builder(ctx, spec, cell_edits)
    }
  )

  plot_margin_theme <- patchwork::plot_annotation(
    theme = ggplot2::theme(
      plot.margin = ggplot2::margin(
        t = x$theme$plot_margin,
        r = x$theme$plot_margin,
        b = x$theme$plot_margin,
        l = x$theme$plot_margin
      )
    )
  )

  if (length(x$header_groups)) {
    .validate_header_groups(x$header_groups, length(specs))
    assembly <- .header_group_assembly(panels, x$header_groups, specs, x$theme, x$header_height)
    composed <- patchwork::wrap_plots(assembly$plots) +
      patchwork::plot_layout(
        design = assembly$design,
        widths = assembly$widths,
        heights = assembly$heights
      ) +
      plot_margin_theme
  } else {
    composed <- patchwork::wrap_plots(panels, nrow = 1) +
      patchwork::plot_layout(widths = .panel_layout_widths(specs)) +
      plot_margin_theme
  }

  composed
}

fp_size <- function(x) {
  .validate_fp_plot(x)

  .fp_device_size(x)
}

print.fp_plot <- function(x, ...) {
  if (!length(x$specs)) {
    cat(
      "<fp_plot>\n",
      "Rows: ", nrow(x$data), "\n",
      "Panels: 0\n",
      "Use `add_text()`, `add_gap()`, or `add_ci()` before rendering.\n",
      sep = ""
    )
    return(invisible(x))
  }

  dims <- .fp_device_size(x)
  w <- unname(dims["width"])
  h <- unname(dims["height"])
  rendered <- fp_render(x)

  tryCatch(
    grDevices::dev.new(width = w, height = h, noRStudioGD = TRUE),
    error = function(e) NULL,
    warning = function(w) NULL
  )
  print(rendered, ...)

  invisible(x)
}
