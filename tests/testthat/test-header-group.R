test_that("add_header_group stores group definitions correctly", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.9, 1.3),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.7)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Drug A") |>
    add_text("label", header = "Drug B") |>
    add_ci("est", "lwr", "upr", header = "HR") |>
    add_header_group("Treatment", panels = 1:2)

  expect_length(plot_obj$header_groups, 1)
  expect_equal(plot_obj$header_groups[[1]]$label, "Treatment")
  expect_equal(plot_obj$header_groups[[1]]$panels, 1:2)
  expect_equal(plot_obj$header_groups[[1]]$align, "center")
  expect_equal(plot_obj$header_groups[[1]]$fontface, "bold")
  expect_null(plot_obj$header_groups[[1]]$colour)
  expect_null(plot_obj$header_groups[[1]]$size)
  expect_null(plot_obj$header_groups[[1]]$height)
  expect_false(plot_obj$header_groups[[1]]$border)
})

test_that("add_header_group can chain multiple groups", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.9, 1.3),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.7)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Drug A") |>
    add_text("label", header = "Drug B") |>
    add_text("label", header = "Placebo") |>
    add_ci("est", "lwr", "upr", header = "HR") |>
    add_header_group("Treatment", panels = 1:2) |>
    add_header_group("Arms", panels = 1:3)

  expect_length(plot_obj$header_groups, 2)
  expect_equal(plot_obj$header_groups[[1]]$label, "Treatment")
  expect_equal(plot_obj$header_groups[[2]]$label, "Arms")
})

test_that("level computation works for nested groups", {
  groups <- list(
    list(label = "A", panels = 1:2),
    list(label = "B", panels = 3:4),
    list(label = "C", panels = 1:4)
  )

  levels <- panelforest:::.compute_header_levels(groups)

  expect_equal(levels, c(1L, 1L, 2L))
})

test_that("level computation handles deeply nested groups", {
  groups <- list(
    list(label = "Inner", panels = 1:2),
    list(label = "Mid", panels = 1:3),
    list(label = "Outer", panels = 1:4)
  )

  levels <- panelforest:::.compute_header_levels(groups)

  expect_equal(levels, c(1L, 2L, 3L))
})

test_that("level computation returns empty for no groups", {
  expect_equal(panelforest:::.compute_header_levels(list()), integer(0))
})

test_that("overlapping same-level groups are rejected", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.9, 1.3),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.7)
  )

  groups <- list(
    list(label = "X", panels = 1:2),
    list(label = "Y", panels = 2:3)
  )

  expect_error(
    panelforest:::.validate_header_groups(groups, 3),
    "overlap"
  )
})

test_that("out-of-bounds panel indices caught at render time", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.9, 1.3),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.7)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Label") |>
    add_ci("est", "lwr", "upr", header = "HR") |>
    add_header_group("Bad", panels = 1:5)

  expect_error(fp_render(plot_obj), "panel 5")
})

test_that("render with header groups returns patchwork", {
  df <- data.frame(
    label = c("A", "B", "C"),
    est = c(0.9, 1.3, 1.05),
    lwr = c(0.7, 1.0, 0.8),
    upr = c(1.1, 1.7, 1.4)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Drug A") |>
    add_text("label", header = "Drug B") |>
    add_ci("est", "lwr", "upr", header = "HR") |>
    add_header_group("Treatment", panels = 1:2)

  rendered <- fp_render(plot_obj)
  expect_true(inherits(rendered, "patchwork"))
})

test_that("fp_size includes parent header height", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.9, 1.3),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.7)
  )

  base_plot <- forest_plot(df) |>
    add_text("label", header = "Drug A") |>
    add_text("label", header = "Drug B") |>
    add_ci("est", "lwr", "upr", header = "HR")

  group_plot <- base_plot |>
    add_header_group("Treatment", panels = 1:2)

  base_size <- fp_size(base_plot)
  group_size <- fp_size(group_plot)

  expect_true(group_size["height"] > base_size["height"])
  expected_diff <- DEFAULT_ROW_HEIGHT
  expect_equal(
    unname(group_size["height"] - base_size["height"]),
    expected_diff,
    tolerance = 1e-6
  )
})

test_that("fp_size includes custom header group height", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.9, 1.3),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.7)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Drug A") |>
    add_text("label", header = "Drug B") |>
    add_ci("est", "lwr", "upr", header = "HR") |>
    add_header_group("Treatment", panels = 1:2, height = 0.6)

  base_plot <- forest_plot(df) |>
    add_text("label", header = "Drug A") |>
    add_text("label", header = "Drug B") |>
    add_ci("est", "lwr", "upr", header = "HR")

  expect_equal(
    unname(fp_size(plot_obj)["height"] - fp_size(base_plot)["height"]),
    0.6,
    tolerance = 1e-6
  )
})

test_that("no header groups renders identically to before", {
  df <- data.frame(
    label = c("A", "B", "C"),
    est = c(0.9, 1.3, 1.05),
    lwr = c(0.7, 1.0, 0.8),
    upr = c(1.1, 1.7, 1.4)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Subgroup", width = 1.8) |>
    add_ci("est", "lwr", "upr", header = "HR", width = 2.5)

  rendered <- fp_render(plot_obj)
  expect_true(inherits(rendered, "patchwork"))
  expect_equal(names(fp_size(plot_obj)), c("width", "height"))
})

test_that("argument validation for add_header_group", {
  df <- data.frame(label = "A", est = 1, lwr = 0.8, upr = 1.2)
  plot_obj <- forest_plot(df) |>
    add_text("label") |>
    add_ci("est", "lwr", "upr")

  expect_error(add_header_group(plot_obj, "", panels = 1:2), "non-empty string")
  expect_error(add_header_group(plot_obj, 123, panels = 1:2), "non-empty string")
  expect_error(add_header_group(plot_obj, "X", panels = c(1, 3)), "contiguous")
  expect_error(add_header_group(plot_obj, "X", panels = integer(0)), "non-empty")
  expect_error(add_header_group(plot_obj, "X", panels = c(0, 1)), "positive")
  expect_error(add_header_group(plot_obj, "X", panels = 1:2, align = "middle"), "align")
  expect_error(add_header_group(plot_obj, "X", panels = 1:2, fontface = ""), "non-empty string")
  expect_error(add_header_group(plot_obj, "X", panels = 1:2, colour = ""), "non-empty string")
  expect_error(add_header_group(plot_obj, "X", panels = 1:2, size = -1), "positive number")
  expect_error(add_header_group(plot_obj, "X", panels = 1:2, height = 0), "positive number")
  expect_error(add_header_group(plot_obj, "X", panels = 1:2, border = NA), "TRUE.*FALSE")
})

test_that("render with multi-level nesting works", {
  df <- data.frame(
    label = c("A", "B", "C"),
    est = c(0.9, 1.3, 1.05),
    lwr = c(0.7, 1.0, 0.8),
    upr = c(1.1, 1.7, 1.4)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Drug A") |>
    add_text("label", header = "Drug B") |>
    add_text("label", header = "Placebo") |>
    add_ci("est", "lwr", "upr", header = "HR") |>
    add_header_group("Treatment", panels = 1:2) |>
    add_header_group("Arms", panels = 1:3)

  rendered <- fp_render(plot_obj)
  expect_true(inherits(rendered, "patchwork"))
})

test_that("render with border option works", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.9, 1.3),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.7)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Drug A") |>
    add_text("label", header = "Drug B") |>
    add_ci("est", "lwr", "upr", header = "HR") |>
    add_header_group("Treatment", panels = 1:2, border = TRUE)

  rendered <- fp_render(plot_obj)
  expect_true(inherits(rendered, "patchwork"))
})

test_that("single-panel header group works", {
  df <- data.frame(
    label = c("A", "B"),
    est = c(0.9, 1.3),
    lwr = c(0.7, 1.0),
    upr = c(1.1, 1.7)
  )

  plot_obj <- forest_plot(df) |>
    add_text("label", header = "Label") |>
    add_ci("est", "lwr", "upr", header = "HR") |>
    add_header_group("Single", panels = 1)

  rendered <- fp_render(plot_obj)
  expect_true(inherits(rendered, "patchwork"))
})
