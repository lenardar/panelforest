test_that("spec constructors validate core arguments", {
  expect_error(fp_text("", width = 1), "single non-empty string")
  expect_error(fp_text("label", indent = -1), "single non-negative number")
  expect_error(fp_text("label", align = "middle"), "align")
  expect_error(fp_text("label", header_align = "middle"), "header_align")
  expect_error(fp_gap(width = 0), "positive number")
  expect_error(fp_bar("", width = 1), "single non-empty string")
  expect_error(fp_spacer(4, unit = ""), "single non-empty string")
  expect_error(fp_dot("est", lower = "lwr"), "both be supplied")
  expect_error(fp_ci("est", "lwr", "upr", xlim = c(2, 1)), "xlim")
  expect_error(fp_ci("est", "lwr", "upr", show_axis = NA), "show_axis")
  expect_error(fp_ci("est", "lwr", "upr", truncate = c(2, 1)), "truncate")
  expect_error(fp_ci("est", "lwr", "upr", trans = "log", xlim = c(0, 2)), "positive")
  expect_error(fp_ci("est", "lwr", "upr", trans = "log", breaks = c(0.1, 1, 0)), "positive")
  expect_error(fp_ci("est", "lwr", "upr", breaks = c(0.1, 1), labels = c("0.1")), "same length")
  expect_error(fp_ci("est", "lwr", "upr", glyph = "triangle"), "glyph")
  expect_error(fp_ci("est", "lwr", "upr", alpha = 2), "between 0 and 1")
})

test_that("text align options resolve to numeric hjust values", {
  text_spec <- fp_text("label", align = "center", header_align = "right")
  text_ci_spec <- fp_text_ci("est", "lwr", "upr", align = "right", header_align = "center")

  expect_equal(text_spec$hjust, 0.5)
  expect_equal(text_spec$header_hjust, 1)
  expect_equal(text_ci_spec$hjust, 1)
  expect_equal(text_ci_spec$header_hjust, 0.5)
})

test_that("fp_aes creates aesthetic mappings", {
  mapping <- fp_aes(colour = "ci_colour", fill = "ci_fill")
  expect_s3_class(mapping, "fp_aes")
  expect_equal(mapping$colour, "ci_colour")
  expect_equal(mapping$fill, "ci_fill")
  expect_error(fp_aes(colour = 123), "column name")
})

test_that("ci panels support aesthetic mappings via fp_aes", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.92, 1.08),
    lwr = c(0.74, 0.79),
    upr = c(1.14, 1.47),
    ci_colour = c("#1d4ed8", "#b42318"),
    ci_fill = c("#93c5fd", "#fecaca"),
    ci_alpha = c(0.6, 0.35),
    ci_glyph = c("point", "diamond"),
    ci_shape = c(17, 15),
    ci_size = c(2.5, 3.5),
    ci_line = c(0.4, 0.9)
  )

  ctx <- panelforest:::.build_context(
    structure(
      list(
        data = df,
        specs = list(),
        theme = fp_theme_default(),
        stripe_colors = NULL,
        summary_rows = integer(),
        group_rows = integer(),
        row_heights = rep(DEFAULT_ROW_HEIGHT, nrow(df)),
        row_styles = vector("list", nrow(df)),
        cell_edits = list(),
        hlines = list(),
        header_height = DEFAULT_ROW_HEIGHT
      ),
      class = "fp_plot"
    )
  )

  ci_panel <- panelforest:::.build_ci(
    ctx = ctx,
    spec = fp_ci(
      "est", "lwr", "upr",
      mapping = fp_aes(
        colour = "ci_colour",
        fill = "ci_fill",
        alpha = "ci_alpha",
        glyph = "ci_glyph",
        shape = "ci_shape",
        point_size = "ci_size",
        line_width = "ci_line"
      )
    ),
    cell_edits = vector("list", nrow(df))
  )

  built <- ggplot2::ggplot_build(ci_panel)
  expect_equal(unique(built$data[[1]]$colour), "#1d4ed8")
  expect_equal(unique(built$data[[1]]$linewidth), 0.4)
  expect_equal(unique(built$data[[2]]$shape), 17)
  expect_equal(unique(built$data[[2]]$size), 2.5)
  expect_equal(unique(built$data[[2]]$fill), "#93c5fd")
  expect_equal(unique(built$data[[2]]$alpha), 0.6)
  expect_equal(unique(built$data[[3]]$colour), "#b42318")
  expect_equal(unique(built$data[[3]]$fill), "#fecaca")
  expect_equal(nrow(built$data[[3]]), 4)
  expect_equal(unique(built$data[[3]]$alpha), 0.35)
})

test_that("edit stores and applies cell-level overrides", {
  df <- data.frame(
    label = c("Overall", "Age < 65"),
    est = c(0.92, 0.81),
    lwr = c(0.74, 0.61),
    upr = c(1.14, 1.07)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Subgroup") |>
    add_ci("est", "lwr", "upr", header = "HR") |>
    edit(row = 2, panel = "Subgroup", label = "Edited", colour = "#b42318") |>
    edit(row = 1, panel = "HR", shape = 17, point_size = 3.8)

  expect_equal(plot_obj$cell_edits[[1]][[2]]$label, "Edited")
  expect_equal(plot_obj$cell_edits[[2]][[1]]$shape, 17)

  ctx <- panelforest:::.build_context(plot_obj)
  text_panel <- panelforest:::.build_text(
    ctx = ctx,
    spec = plot_obj$specs[[1]],
    cell_edits = plot_obj$cell_edits[[1]]
  )
  text_built <- ggplot2::ggplot_build(text_panel)
  expect_true("Edited" %in% text_built$data[[1]]$label)
  expect_true("#b42318" %in% text_built$data[[1]]$colour)

  ci_panel <- panelforest:::.build_ci(
    ctx = ctx,
    spec = plot_obj$specs[[2]],
    cell_edits = plot_obj$cell_edits[[2]]
  )
  ci_built <- ggplot2::ggplot_build(ci_panel)
  expect_true(17 %in% ci_built$data[[2]]$shape)
  expect_true(3.8 %in% ci_built$data[[2]]$size)
})

test_that("summary rows and row-level overrides can draw CI diamonds", {
  df <- data.frame(
    label = c("Overall", "Age < 65", "Age >= 65"),
    est = c(0.92, 0.81, 1.08),
    lwr = c(0.74, 0.61, 0.79),
    upr = c(1.14, 1.07, 1.47)
  )

  plot_obj <- forest_plot(df) |>
    add_summary(1) |>
    edit(row = 3, glyph = "diamond", colour = "#b42318") |>
    add_ci("est", "lwr", "upr", summary_glyph = "diamond")

  ctx <- panelforest:::.build_context(plot_obj)
  ci_panel <- panelforest:::.build_ci(
    ctx = ctx,
    spec = plot_obj$specs[[1]],
    cell_edits = vector("list", nrow(df))
  )

  built <- ggplot2::ggplot_build(ci_panel)

  expect_equal(nrow(built$data[[1]]), 1)
  expect_equal(nrow(built$data[[2]]), 1)
  expect_equal(nrow(built$data[[3]]), 8)
  expect_equal(sort(unique(built$data[[3]]$colour)), c("#1f1f1f", "#b42318"))
  expect_equal(sum(built$data[[3]]$colour == "#b42318"), 4)
})

test_that("cell edits can control CI fill and alpha", {
  df <- data.frame(
    label = c("Overall", "Age < 65"),
    est = c(0.92, 0.81),
    lwr = c(0.74, 0.61),
    upr = c(1.14, 1.07)
  )

  plot_obj <- forest_plot(df) |>
    add_ci("est", "lwr", "upr", summary_glyph = NULL) |>
    edit(row = 1, panel = "est", glyph = "diamond", fill = "#dbeafe", alpha = 0.45) |>
    edit(row = 2, panel = "est", glyph = "diamond", fill = "#fee2e2", alpha = 0.3, colour = "#b42318")

  ctx <- panelforest:::.build_context(plot_obj)
  ci_panel <- panelforest:::.build_ci(
    ctx = ctx,
    spec = plot_obj$specs[[1]],
    cell_edits = plot_obj$cell_edits[[1]]
  )

  built <- ggplot2::ggplot_build(ci_panel)

  expect_equal(sort(unique(built$data[[1]]$fill)), c("#dbeafe", "#fee2e2"))
  expect_equal(sort(unique(built$data[[1]]$alpha)), c(0.3, 0.45))
  expect_equal(sum(built$data[[1]]$colour == "#b42318"), 4)
})

test_that("formatter helpers return expected text", {
  expect_equal(fp_fmt_number(digits = 1, big_mark = ",")(c(1000, 12.34)), c("1,000.0", "12.3"))
  expect_equal(fp_fmt_percent(digits = 1)(c(0.125, 0.34)), c("12.5%", "34.0%"))
  expect_equal(fp_fmt_pvalue(digits = 3)(c(0.12, 0.0005)), c("p = 0.120", "p = < 0.001"))
})

test_that("journal theme returns an fp_theme object", {
  theme <- fp_theme_journal()

  expect_s3_class(theme, "fp_theme")
  expect_equal(theme$base_family, "serif")
  expect_equal(theme$plot_margin, 3)
})

test_that("example data loader returns bundled dataset", {
  df <- panelforest_example_data()

  expect_s3_class(df, "data.frame")
  expect_true(all(c("label", "n_events", "HR", "LCI", "UCI", "hr_ci") %in% names(df)))
  expect_error(panelforest_example_data("missing"), "Unknown example dataset")
})

test_that("forest plot stores specs and stripes", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.9, 1.3),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.7)
  )

  plot_obj <- forest_plot(df) |>
    add_stripe(c("white", "#f3f6f4")) |>
    add_text("label", header = "Label", width = 1.8) |>
    add_gap(0.2) |>
    add_ci("est", "lwr", "upr", header = "HR", trans = "log", width = 2.5)

  expect_s3_class(plot_obj, "fp_plot")
  expect_equal(length(plot_obj$specs), 3)
  expect_equal(plot_obj$stripe_colors, c("white", "#f3f6f4"))
  expect_equal(plot_obj$row_heights, rep(DEFAULT_ROW_HEIGHT, 2))
})

test_that("spacer specs use absolute units and remain distinct from gap specs", {
  spec <- fp_spacer(4, unit = "mm")
  plot_obj <- forest_plot(data.frame(label = c("A", "B"))) |>
    add_text("label", header = "Label") |>
    add_spacer(4, unit = "mm")

  expect_s3_class(spec, "fp_spec_spacer")
  expect_equal(spec$width, 4)
  expect_equal(spec$unit, "mm")
  expect_equal(plot_obj$specs[[2]]$type, "spacer")
  expect_equal(plot_obj$specs[[2]]$width, 4)
  expect_equal(plot_obj$specs[[2]]$unit, "mm")
})

test_that("absolute spacer width is reflected in fp_size", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.9, 1.3),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.7)
  )

  base_plot <- forest_plot(df) |>
    add_text("label", header = "Label", width = 1.8) |>
    add_ci("est", "lwr", "upr", header = "HR", trans = "log", width = 2.5)

  spacer_plot <- base_plot |>
    add_spacer(5, unit = "mm")

  base_size <- fp_size(base_plot)
  spacer_size <- fp_size(spacer_plot)
  expected_diff <- grid::convertWidth(grid::unit(5, "mm"), "in", valueOnly = TRUE)

  expect_equal(unname(spacer_size["width"] - base_size["width"]), expected_diff, tolerance = 1e-6)
})

test_that("edit can set row heights", {
  df <- data.frame(
    label = c("Overall", "Age < 65", "Age >= 65"),
    est = c(0.92, 0.81, 1.08),
    lwr = c(0.74, 0.61, 0.79),
    upr = c(1.14, 1.07, 1.47)
  )

  plot_obj <- forest_plot(df, row_height = 0.5) |>
    edit(row = 2, height = 1.0)

  expect_equal(plot_obj$row_heights, c(0.5, 1.0, 0.5))
  margin_in <- fp_theme_default()$plot_margin / 72
  expect_equal(unname(fp_size(plot_obj)["height"]), sum(c(0.5, 1.0, 0.5)) + 0.5 + 2 * margin_in)
})

test_that("render returns a patchwork object", {
  df <- data.frame(
    label = c("A", "B", "C"),
    est = c(0.9, 1.3, 1.05),
    lwr = c(0.7, 1.0, 0.8),
    upr = c(1.1, 1.7, 1.4)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Subgroup", width = 1.8) |>
    add_gap(0.2) |>
    add_ci("est", "lwr", "upr", header = "HR", trans = "log", width = 2.5)

  rendered <- fp_render(plot_obj)

  expect_true(inherits(rendered, "patchwork"))
  expect_equal(names(fp_size(plot_obj)), c("width", "height"))
})

test_that("panel themes do not introduce internal white gutters", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.9, 1.3),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.7)
  )

  rendered <- forest_plot(df, theme = fp_theme_default(plot_margin = 6)) |>
    add_stripe(c("white", "#f3f6f4")) |>
    add_text("label", header = "Label") |>
    add_ci("est", "lwr", "upr", header = "HR") |>
    fp_render()

  internal_margin <- rendered$patches$plots[[1]]$theme$plot.margin
  outer_margin <- rendered$patches$annotation$theme$plot.margin

  expect_equal(as.numeric(internal_margin), c(0, 0, 0, 0))
  expect_equal(as.numeric(outer_margin), c(6, 6, 6, 6))
})

test_that("dot and bar panels render within the shared layout system", {
  df <- data.frame(
    label = c("A", "B", "C"),
    est = c(0.9, 1.3, 1.05),
    lwr = c(0.7, 1.0, 0.8),
    upr = c(1.1, 1.7, 1.4),
    events = c(14, 9, 11)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Subgroup", width = 1.8) |>
    add_bar("events", header = "Events", width = 1.2) |>
    add_dot("est", "lwr", "upr", header = "Mean", width = 1.5) |>
    add_ci("est", "lwr", "upr", header = "HR", trans = "log", width = 2.5)

  expect_true(inherits(fp_render(plot_obj), "patchwork"))
})

test_that("text panels support indentation and formatted ci labels", {
  df <- data.frame(
    label = c("Overall", "Age < 65", "Age >= 65"),
    level = c(0, 1, 1),
    est = c(0.92, 0.81, 1.08),
    lwr = c(0.74, 0.61, 0.79),
    upr = c(1.14, 1.07, 1.47)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Subgroup", indent = "level") |>
    add_text_ci("est", "lwr", "upr", header = "HR (95% CI)")

  expect_true(inherits(fp_render(plot_obj), "patchwork"))

  ctx <- panelforest:::.build_context(plot_obj)
  text_panel <- panelforest:::.build_text(
    ctx = ctx,
    spec = fp_text("label", indent = "level"),
    cell_edits = vector("list", nrow(df))
  )
  built_text <- ggplot2::ggplot_build(text_panel)
  expect_true(built_text$data[[1]]$x[[2]] > built_text$data[[1]]$x[[1]])

  ci_text_panel <- panelforest:::.build_text_ci(
    ctx = ctx,
    spec = fp_text_ci("est", "lwr", "upr", digits = 2),
    cell_edits = vector("list", nrow(df))
  )
  built_ci_text <- ggplot2::ggplot_build(ci_text_panel)
  expect_equal(built_ci_text$data[[1]]$label[[1]], "0.92 (0.74, 1.14)")
})

test_that("content and header alignment can be controlled independently", {
  df <- data.frame(
    label = c("Overall", "Age < 65"),
    value = c(12, 18),
    est = c(0.92, 0.81),
    lwr = c(0.74, 0.61),
    upr = c(1.14, 1.07)
  )

  ctx <- panelforest:::.build_context(
    structure(
      list(
        data = df,
        specs = list(),
        theme = fp_theme_default(),
        stripe_colors = NULL,
        summary_rows = integer(),
        group_rows = integer(),
        row_heights = rep(DEFAULT_ROW_HEIGHT, nrow(df)),
        row_styles = vector("list", nrow(df)),
        cell_edits = list(),
        hlines = list(),
        header_height = DEFAULT_ROW_HEIGHT
      ),
      class = "fp_plot"
    )
  )

  text_panel <- panelforest:::.build_text(
    ctx = ctx,
    spec = fp_text("label", header = "Subgroup", align = "left", header_align = "center"),
    cell_edits = vector("list", nrow(df))
  )
  built_text <- ggplot2::ggplot_build(text_panel)
  header_layer <- Filter(function(x) "label" %in% names(x) && identical(x$label[[1]], "Subgroup"), built_text$data)[[1]]

  expect_equal(header_layer$x[[1]], 0.5)
  expect_equal(header_layer$hjust[[1]], 0.5)

  bar_panel <- panelforest:::.build_bar(
    ctx = ctx,
    spec = fp_bar("value", header = "Events", header_align = "right"),
    cell_edits = vector("list", nrow(df))
  )
  built_bar <- ggplot2::ggplot_build(bar_panel)
  bar_header_layer <- Filter(function(x) "label" %in% names(x) && identical(x$label[[1]], "Events"), built_bar$data)[[1]]

  expect_equal(bar_header_layer$x[[1]], 18)
  expect_equal(bar_header_layer$hjust[[1]], 1)
})

test_that("ci panels can show a bottom axis", {
  df <- data.frame(
    label = c("Overall", "Age < 65"),
    est = c(0.92, 0.81),
    lwr = c(0.74, 0.61),
    upr = c(1.14, 1.07)
  )

  ctx <- panelforest:::.build_context(
    structure(
      list(
        data = df,
        specs = list(),
        theme = fp_theme_default(),
        stripe_colors = NULL,
        summary_rows = integer(),
        group_rows = integer(),
        row_heights = rep(DEFAULT_ROW_HEIGHT, nrow(df)),
        row_styles = vector("list", nrow(df)),
        cell_edits = list(),
        hlines = list(),
        header_height = DEFAULT_ROW_HEIGHT
      ),
      class = "fp_plot"
    )
  )

  ci_panel <- panelforest:::.build_ci(
    ctx = ctx,
    spec = fp_ci(
      "est", "lwr", "upr",
      trans = "log",
      xlim = c(0.1, 2),
      breaks = c(0.1, 0.5, 1, 2),
      labels = c("0.1", "0.5", "1", "2"),
      show_axis = TRUE,
      axis_label = "Hazard Ratio"
    ),
    cell_edits = vector("list", nrow(df))
  )

  expect_equal(ci_panel$labels$x, "Hazard Ratio")
  expect_false(inherits(ci_panel$theme$axis.text.x, "element_blank"))
  expect_false(inherits(ci_panel$theme$axis.title.x, "element_blank"))
  expect_equal(ci_panel$scales$get_scales("x")$breaks, c(0.1, 0.5, 1, 2))
})

test_that("ci display range can differ from truncation range", {
  df <- data.frame(
    label = c("Overall", "Age < 65"),
    est = c(0.92, 0.81),
    lwr = c(0.04, 0.61),
    upr = c(2.80, 1.07)
  )

  ctx <- panelforest:::.build_context(
    structure(
      list(
        data = df,
        specs = list(),
        theme = fp_theme_default(),
        stripe_colors = NULL,
        summary_rows = integer(),
        group_rows = integer(),
        row_heights = rep(DEFAULT_ROW_HEIGHT, nrow(df)),
        row_styles = vector("list", nrow(df)),
        cell_edits = list(),
        hlines = list(),
        header_height = DEFAULT_ROW_HEIGHT
      ),
      class = "fp_plot"
    )
  )

  ci_panel <- panelforest:::.build_ci(
    ctx = ctx,
    spec = fp_ci(
      "est", "lwr", "upr",
      trans = "log",
      xlim = c(0.1, 2),
      truncate = c(0.5, 1.5),
      breaks = c(0.1, 1, 2),
      show_axis = TRUE
    ),
    cell_edits = vector("list", nrow(df))
  )

  x_scale <- ci_panel$scales$get_scales("x")
  built <- ggplot2::ggplot_build(ci_panel)
  segment_layers <- Filter(function(x) all(c("x", "xend", "y", "yend") %in% names(x)), built$data)

  log_range <- log10(2) - log10(0.1)
  expected_limits <- c(
    log10(0.1) - CI_EXPANSION_MULT_LEFT * log_range,
    log10(2) + CI_EXPANSION_MULT * log_range
  )
  expect_equal(x_scale$limits, expected_limits)
  expect_equal(x_scale$breaks, c(0.1, 1, 2))
  expect_true(any(vapply(segment_layers, function(x) any(round(x$xend, 5) == round(log10(0.5), 5)), logical(1))))
  expect_true(any(vapply(segment_layers, function(x) any(round(x$x, 5) == round(log10(1.5), 5)), logical(1))))
})

test_that("render validates missing columns before ggplot fails", {
  df <- data.frame(label = "A", est = 1, lwr = 0.8, upr = 1.2)

  plot_obj <- forest_plot(df) |>
    add_text("missing_column")

  expect_error(fp_render(plot_obj), "missing column")
})

test_that("custom panels can be added and rendered", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.9, 1.2),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.4),
    p = c(0.01, 0.23)
  )

  pval_panel <- fp_custom(
    plot_fn = function(data, n_rows) {
      ggplot2::ggplot(
        data.frame(
          x = 0.5,
          y = rev(seq_len(n_rows)),
          label = sprintf("%.2f", data$p)
        ),
        ggplot2::aes(x = x, y = y, label = label)
      ) +
        ggplot2::geom_text()
    },
    header = "P"
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Label") |>
    add_custom(pval_panel)

  expect_true(inherits(fp_render(plot_obj), "patchwork"))
})

test_that("summary rows and row styles are stored and influence builders", {
  df <- data.frame(
    label = c("Overall", "A", "B"),
    est = c(1.00, 0.9, 1.2),
    lwr = c(0.85, 0.7, 1.0),
    upr = c(1.15, 1.1, 1.4)
  )

  plot_obj <- forest_plot(df) |>
    add_summary(1) |>
    edit(row = 2, colour = "#c0392b", fill = "#fff3cd") |>
    add_text("label", header = "Label") |>
    add_ci("est", "lwr", "upr", header = "HR")

  expect_equal(plot_obj$summary_rows, 1L)
  expect_equal(plot_obj$row_styles[[2]]$colour, "#c0392b")
  expect_equal(plot_obj$row_styles[[2]]$fill, "#fff3cd")

  ctx <- panelforest:::.build_context(plot_obj)
  text_panel <- panelforest:::.build_text(
    ctx = ctx,
    spec = fp_text("label", header = "Label"),
    cell_edits = vector("list", nrow(df))
  )
  built <- ggplot2::ggplot_build(text_panel)
  expect_equal(built$data[[2]]$fontface[[1]], "bold")
  expect_equal(built$data[[2]]$colour[[2]], "#c0392b")
  expect_equal(built$data[[1]]$fill[[1]], "#fff3cd")
})

test_that("group rows suppress CI glyphs and hlines are stored", {
  df <- data.frame(
    label = c("Demographics", "Age < 65", "Age >= 65", "Sex"),
    est = c(1.00, 0.92, 1.08, 1.00),
    lwr = c(0.85, 0.74, 0.79, 0.90),
    upr = c(1.15, 1.14, 1.47, 1.10)
  )

  plot_obj <- forest_plot(df) |>
    add_group(c(1, 4), fill = "#f6f7f8") |>
    add_hline(c(1, 3), colour = "#d0d7de") |>
    add_text("label", header = "Label") |>
    add_ci("est", "lwr", "upr", header = "HR")

  expect_equal(plot_obj$group_rows, c(1L, 4L))
  expect_equal(length(plot_obj$hlines), 1)

  ctx <- panelforest:::.build_context(plot_obj)
  ci_panel <- panelforest:::.build_ci(
    ctx = ctx,
    spec = fp_ci("est", "lwr", "upr", header = "HR"),
    cell_edits = vector("list", nrow(df))
  )
  built <- ggplot2::ggplot_build(ci_panel)
  segment_layer <- Filter(function(x) all(c("x", "xend", "y", "yend") %in% names(x)), built$data)[[1]]

  expect_equal(nrow(segment_layer), 2)
})

test_that("edit works as unified interface for row, cell, and height", {
  df <- data.frame(
    label = c("A", "B", "C"),
    est = c(0.9, 1.3, 1.05),
    lwr = c(0.7, 1.0, 0.8),
    upr = c(1.1, 1.7, 1.4)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Subgroup") |>
    add_ci("est", "lwr", "upr", header = "HR") |>
    edit(row = 1, panel = "HR", glyph = "diamond", fill = "#dbeafe") |>
    edit(row = 2:3, fontface = "italic") |>
    edit(row = 1, height = 0.6)

  expect_equal(plot_obj$row_heights, c(0.6, DEFAULT_ROW_HEIGHT, DEFAULT_ROW_HEIGHT))
  expect_equal(plot_obj$row_styles[[2]]$fontface, "italic")
  expect_equal(plot_obj$row_styles[[3]]$fontface, "italic")
  expect_equal(plot_obj$cell_edits[[2]][[1]]$glyph, "diamond")
  expect_equal(plot_obj$cell_edits[[2]][[1]]$fill, "#dbeafe")
})

test_that("favors_left and favors_right are stored in spec and render without error", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.9, 1.3),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.7)
  )

  spec <- fp_ci(
    "est", "lwr", "upr",
    show_axis = TRUE,
    favors_left = "Favors Treatment",
    favors_right = "Favors Control"
  )

  expect_equal(spec$favors_left, "Favors Treatment")
  expect_equal(spec$favors_right, "Favors Control")

  ctx <- panelforest:::.build_context(
    structure(
      list(
        data = df,
        specs = list(),
        theme = fp_theme_default(),
        stripe_colors = NULL,
        summary_rows = integer(),
        group_rows = integer(),
        row_heights = rep(DEFAULT_ROW_HEIGHT, nrow(df)),
        row_styles = vector("list", nrow(df)),
        cell_edits = list(),
        hlines = list(),
        header_height = DEFAULT_ROW_HEIGHT
      ),
      class = "fp_plot"
    )
  )

  ci_panel <- panelforest:::.build_ci(
    ctx = ctx,
    spec = spec,
    cell_edits = vector("list", nrow(df))
  )

  expect_s3_class(ci_panel, "ggplot")
  built <- ggplot2::ggplot_build(ci_panel)
  annotation_layers <- Filter(
    function(x) "label" %in% names(x) && any(x$label %in% c("Favors Treatment", "Favors Control")),
    built$data
  )
  expect_true(length(annotation_layers) >= 1)
})

test_that("favors works with only one side set", {
  spec_left <- fp_ci("est", "lwr", "upr", favors_left = "Favors A")
  spec_right <- fp_ci("est", "lwr", "upr", favors_right = "Favors B")

  expect_equal(spec_left$favors_left, "Favors A")
  expect_null(spec_left$favors_right)
  expect_null(spec_right$favors_left)
  expect_equal(spec_right$favors_right, "Favors B")

  df <- data.frame(
    est = c(0.9, 1.3),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.7)
  )

  ctx <- panelforest:::.build_context(
    structure(
      list(
        data = df,
        specs = list(),
        theme = fp_theme_default(),
        stripe_colors = NULL,
        summary_rows = integer(),
        group_rows = integer(),
        row_heights = rep(DEFAULT_ROW_HEIGHT, nrow(df)),
        row_styles = vector("list", nrow(df)),
        cell_edits = list(),
        hlines = list(),
        header_height = DEFAULT_ROW_HEIGHT
      ),
      class = "fp_plot"
    )
  )

  panel_left <- panelforest:::.build_ci(ctx = ctx, spec = spec_left, cell_edits = vector("list", nrow(df)))
  panel_right <- panelforest:::.build_ci(ctx = ctx, spec = spec_right, cell_edits = vector("list", nrow(df)))

  expect_s3_class(panel_left, "ggplot")
  expect_s3_class(panel_right, "ggplot")
})

test_that("favors validation rejects invalid inputs", {
  expect_error(fp_ci("est", "lwr", "upr", favors_left = ""), "non-empty string")
  expect_error(fp_ci("est", "lwr", "upr", favors_right = 123), "non-empty string")
  expect_error(fp_ci("est", "lwr", "upr", favors_left = c("a", "b")), "non-empty string")
})

test_that("fp_ci arrow parameters are validated and stored", {
  spec <- fp_ci("est", "lwr", "upr",
    arrow_length = 0.06, arrow_type = "open", arrow_angle = 20)
  expect_equal(spec$arrow_length, 0.06)
  expect_equal(spec$arrow_type, "open")
  expect_equal(spec$arrow_angle, 20)

  expect_error(fp_ci("est", "lwr", "upr", arrow_length = -1), "positive number")
  expect_error(fp_ci("est", "lwr", "upr", arrow_type = "filled"), '"open" or "closed"')
  expect_error(fp_ci("est", "lwr", "upr", arrow_angle = 0), "\\(0, 90\\)")
  expect_error(fp_ci("est", "lwr", "upr", arrow_angle = 90), "\\(0, 90\\)")
})

test_that("fp_save writes a file with correct dimensions", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.9, 1.3),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.7)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Label") |>
    add_ci("est", "lwr", "upr", header = "HR")

  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp), add = TRUE)

  result <- fp_save(plot_obj, tmp)
  expect_true(file.exists(tmp))
  expect_equal(result, tmp)
})

test_that("fp_save accepts custom width and height", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.9, 1.3),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.7)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Label") |>
    add_ci("est", "lwr", "upr", header = "HR")

  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp), add = TRUE)

  expect_no_error(fp_save(plot_obj, tmp, width = 10, height = 5))
  expect_true(file.exists(tmp))
})

test_that("fp_save rejects non-fp_plot input", {
  expect_error(fp_save(list(), tempfile()), class = "rlang_error")
})
