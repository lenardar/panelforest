test_that("basic forest composition has a stable visual shape", {
  if (!requireNamespace("vdiffr", quietly = TRUE)) {
    skip("{vdiffr} is not installed")
  }

  df <- data.frame(
    label = c("Overall", "Demographics", "Age < 65", "Age >= 65"),
    est = c(0.92, 1.00, 0.81, 1.08),
    lwr = c(0.74, 0.85, 0.61, 0.79),
    upr = c(1.14, 1.15, 1.07, 1.47),
    events = c(120, 0, 63, 57)
  )

  plot_obj <- forest_plot(df) |>
    add_stripe(c("white", "#f4f7f5")) |>
    add_group(2, fill = "#eef2ef") |>
    add_summary(1) |>
    add_hline(c(1, 2)) |>
    add_text("label", header = "Subgroup", width = 2.3) |>
    add_bar("events", header = "Events", width = 1.2) |>
    add_dot("est", "lwr", "upr", header = "Estimate", width = 1.6) |>
    add_ci("est", "lwr", "upr", header = "HR", trans = "log", width = 2.4)

  getExportedValue("vdiffr", "expect_doppelganger")("basic-forest-layout", fp_render(plot_obj))
})
