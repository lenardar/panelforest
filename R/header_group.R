add_header_group <- function(
  x,
  label,
  panels,
  align = "center",
  fontface = "bold",
  colour = NULL,
  size = NULL,
  family = NULL,
  background = NULL,
  height = NULL,
  border = FALSE,
  border_colour = HEADER_GROUP_BORDER_COLOUR,
  border_linewidth = HEADER_GROUP_BORDER_LINEWIDTH
) {
  .validate_fp_plot(x)

  if (!is.character(label) || length(label) != 1L || !nzchar(label)) {
    rlang::abort("`label` must be a single non-empty string.")
  }

  if (!is.numeric(panels) || length(panels) < 1L || anyNA(panels)) {
    rlang::abort("`panels` must be a non-empty integer vector.")
  }
  panels <- as.integer(panels)
  if (any(panels < 1L)) {
    rlang::abort("`panels` must contain positive integers.")
  }
  panels <- sort(unique(panels))
  if (length(panels) > 1L && !identical(panels, seq(panels[1], panels[length(panels)]))) {
    rlang::abort("`panels` must be contiguous (e.g. 1:3, not c(1, 3)).")
  }

  .validate_align(align, arg = "align")

  if (!is.character(fontface) || length(fontface) != 1L || !nzchar(fontface)) {
    rlang::abort("`fontface` must be a single non-empty string.")
  }

  if (!is.null(colour) && (!is.character(colour) || length(colour) != 1L || !nzchar(colour))) {
    rlang::abort("`colour` must be `NULL` or a single non-empty string.")
  }

  if (!is.null(size) && (!is.numeric(size) || length(size) != 1L || is.na(size) || size <= 0)) {
    rlang::abort("`size` must be `NULL` or a single positive number.")
  }

  if (!is.null(family) && (!is.character(family) || length(family) != 1L)) {
    rlang::abort("`family` must be `NULL` or a single string.")
  }

  if (!is.null(background) && (!is.character(background) || length(background) != 1L || !nzchar(background))) {
    rlang::abort("`background` must be `NULL` or a single non-empty string.")
  }

  if (!is.null(height) && (!is.numeric(height) || length(height) != 1L || is.na(height) || height <= 0)) {
    rlang::abort("`height` must be `NULL` or a single positive number.")
  }

  if (!is.logical(border) || length(border) != 1L || is.na(border)) {
    rlang::abort("`border` must be `TRUE` or `FALSE`.")
  }

  if (!is.character(border_colour) || length(border_colour) != 1L || !nzchar(border_colour)) {
    rlang::abort("`border_colour` must be a single non-empty string.")
  }

  if (!is.numeric(border_linewidth) || length(border_linewidth) != 1L ||
      is.na(border_linewidth) || border_linewidth <= 0) {
    rlang::abort("`border_linewidth` must be a single positive number.")
  }

  group <- list(
    label = label,
    panels = panels,
    align = align,
    fontface = fontface,
    colour = colour,
    size = size,
    family = family,
    background = background,
    height = height,
    border = border,
    border_colour = border_colour,
    border_linewidth = border_linewidth
  )

  x$header_groups <- c(x$header_groups, list(group))
  x
}

.compute_header_levels <- function(groups) {
  n <- length(groups)
  if (n == 0L) return(integer(0))

  levels <- rep(1L, n)
  ranges <- lapply(groups, function(g) range(g$panels))

  changed <- TRUE
  while (changed) {
    changed <- FALSE
    for (i in seq_len(n)) {
      child_levels <- 0L
      for (j in seq_len(n)) {
        if (i == j) next
        if (ranges[[j]][1] >= ranges[[i]][1] && ranges[[j]][2] <= ranges[[i]][2] &&
            !(ranges[[j]][1] == ranges[[i]][1] && ranges[[j]][2] == ranges[[i]][2])) {
          child_levels <- max(child_levels, levels[j])
        }
      }
      new_level <- child_levels + 1L
      if (new_level > levels[i]) {
        levels[i] <- new_level
        changed <- TRUE
      }
    }
  }

  levels
}

.validate_header_groups <- function(groups, n_specs) {
  if (!length(groups)) return(invisible(NULL))

  for (i in seq_along(groups)) {
    g <- groups[[i]]
    if (any(g$panels > n_specs)) {
      rlang::abort(sprintf(
        "Header group \"%s\" references panel %d, but only %d panel(s) exist.",
        g$label, max(g$panels), n_specs
      ))
    }
  }

  levels <- .compute_header_levels(groups)

  for (lvl in unique(levels)) {
    idx <- which(levels == lvl)
    if (length(idx) < 2L) next
    for (a in seq_len(length(idx) - 1L)) {
      for (b in (a + 1L):length(idx)) {
        ga <- groups[[idx[a]]]
        gb <- groups[[idx[b]]]
        ra <- range(ga$panels)
        rb <- range(gb$panels)
        if (ra[1] <= rb[2] && rb[1] <= ra[2]) {
          rlang::abort(sprintf(
            "Header groups \"%s\" and \"%s\" overlap at the same level (%d).",
            ga$label, gb$label, lvl
          ))
        }
      }
    }
  }

  invisible(NULL)
}

.compute_level_heights <- function(groups, levels, header_height) {
  heights <- numeric(0)
  for (lvl in seq(max(levels), 1L)) {
    lvl_groups <- which(levels == lvl)
    h <- header_height
    for (gi in lvl_groups) {
      gh <- groups[[gi]]$height
      if (!is.null(gh)) h <- max(h, gh)
    }
    heights <- c(heights, h)
  }
  heights
}

.build_header_group_panel <- function(group, theme) {
  hjust <- .align_to_hjust(group$align)
  text_colour <- group$colour %||% theme$header_colour
  text_size <- group$size %||% theme$header_size
  text_family <- group$family %||% theme$base_family
  bg_fill <- group$background %||% "transparent"

  p <- ggplot2::ggplot() +
    ggplot2::annotate(
      "text",
      x = hjust,
      y = 0.5,
      label = group$label,
      hjust = hjust,
      vjust = 0.5,
      size = text_size,
      fontface = group$fontface,
      colour = text_colour,
      family = text_family
    )

  if (isTRUE(group$border)) {
    p <- p +
      ggplot2::annotate(
        "segment",
        x = 0, xend = 1,
        y = 0, yend = 0,
        colour = group$border_colour,
        linewidth = group$border_linewidth
      )
  }

  p +
    ggplot2::scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
    ggplot2::scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
    ggplot2::theme_void(base_family = text_family) +
    ggplot2::theme(
      plot.margin = ggplot2::margin(0, 0, 0, 0),
      plot.background = ggplot2::element_rect(fill = bg_fill, colour = NA),
      panel.background = ggplot2::element_rect(fill = bg_fill, colour = NA)
    ) +
    ggplot2::coord_cartesian(clip = "off")
}

.header_group_assembly <- function(main_panels, groups, specs, theme, header_height) {
  n_panels <- length(main_panels)
  levels <- .compute_header_levels(groups)
  max_level <- max(levels)

  char_pool <- c(LETTERS, letters, 0:9)
  total_slots <- n_panels + length(groups)
  if (total_slots > length(char_pool)) {
    rlang::abort(sprintf(
      "Too many panels + header groups (%d). Maximum supported is %d.",
      total_slots, length(char_pool)
    ))
  }

  main_chars <- char_pool[seq_len(n_panels)]
  next_char_idx <- n_panels + 1L

  plots <- stats::setNames(main_panels, main_chars)

  level_rows <- list()
  level_heights <- .compute_level_heights(groups, levels, header_height)
  level_idx <- 0L

  for (lvl in seq(max_level, 1L)) {
    level_idx <- level_idx + 1L
    row_chars <- rep("#", n_panels)
    lvl_groups <- which(levels == lvl)

    for (gi in lvl_groups) {
      g <- groups[[gi]]
      ch <- char_pool[next_char_idx]
      next_char_idx <- next_char_idx + 1L
      plots[[ch]] <- .build_header_group_panel(g, theme)

      for (col in g$panels) {
        row_chars[col] <- ch
      }
    }

    level_rows <- c(level_rows, list(paste(row_chars, collapse = "")))
  }

  main_row <- paste(main_chars, collapse = "")

  design_str <- paste(c(level_rows, main_row), collapse = "\n")

  widths <- .panel_layout_widths(specs)
  heights <- do.call(
    grid::unit.c,
    c(
      lapply(level_heights, function(h) grid::unit(h, "in")),
      list(grid::unit(1, "null"))
    )
  )

  list(
    plots = plots,
    design = design_str,
    widths = widths,
    heights = heights
  )
}
