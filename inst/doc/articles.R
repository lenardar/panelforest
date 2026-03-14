## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(panelforest)
library(ggplot2)

## ----data---------------------------------------------------------------------
df <- data.frame(
  subgroup = c("Overall", "Age < 65", "Age >= 65",
               "Male", "Female", "ECOG 0", "ECOG 1-2"),
  n        = c(312L, 163L, 149L, 180L, 132L, 108L, 204L),
  events   = c(187L, 91L, 96L, 104L, 83L, 58L, 129L),
  HR       = c(0.68, 0.61, 0.76, 0.64, 0.74, 0.53, 0.76),
  LCI      = c(0.54, 0.44, 0.57, 0.47, 0.53, 0.34, 0.59),
  UCI      = c(0.85, 0.83, 1.01, 0.86, 1.04, 0.82, 0.98),
  pval     = c(0.001, 0.003, 0.062, 0.008, 0.098, 0.044, 0.012),
  resp_rate = c(0.42, 0.46, 0.38, 0.44, 0.40, 0.51, 0.38),
  mean_diff = c(-0.32, -0.41, -0.22, -0.36, -0.27, -0.48, -0.25),
  lci_diff  = c(-0.55, -0.68, -0.46, -0.60, -0.52, -0.75, -0.48),
  uci_diff  = c(-0.09,  -0.14, 0.02, -0.12, 0.02, -0.21, -0.02),
  stringsAsFactors = FALSE
)

## ----log-axis, fig.width = 8, fig.height = 3.4--------------------------------
p1 <- forest_plot(df) |>
  add_text("subgroup", header = "Subgroup", width = 2) |>
  add_text_ci("HR", "LCI", "UCI", header = "HR (95% CI)", width = 2) |>
  add_ci("HR", "LCI", "UCI",
    trans      = "log",
    xlim       = c(0.2, 3),
    breaks     = c(0.25, 0.5, 1, 2),
    show_axis  = TRUE,
    axis_label = "Hazard Ratio (log scale)",
    ref_line   = 1,
    header     = "Forest Plot"
  )

size <- fp_size(p1)
fp_render(p1)

## ----truncation, fig.width = 8, fig.height = 3.4------------------------------
# Age >= 65 and Female have UCI > 1 — their upper whiskers will be clipped
# at 0.95 while the axis still shows up to 1.2.
p2 <- forest_plot(df) |>
  add_text("subgroup", header = "Subgroup", width = 2) |>
  add_ci("HR", "LCI", "UCI",
    trans        = "log",
    xlim         = c(0.2, 1.2),
    truncate     = c(0.2, 0.95),
    breaks       = c(0.25, 0.5, 1),
    show_axis    = TRUE,
    ref_line     = 1,
    header       = "HR (truncated at 0.95)",
    arrow_length = 0.1,
    arrow_type   = "open",
    arrow_angle  = 25
  )

fp_render(p2)

## ----favors, fig.width = 8, fig.height = 4.2----------------------------------
p3 <- forest_plot(df) |>
  add_text("subgroup", header = "Subgroup", width = 2) |>
  add_ci("HR", "LCI", "UCI",
    trans         = "log",
    xlim          = c(0.2, 3),
    breaks        = c(0.25, 0.5, 1, 2),
    ref_line      = 1,
    show_axis     = TRUE,
    axis_label    = "Hazard Ratio",
    favors_left   = "Favors Treatment",
    favors_right  = "Favors Control",
    favors_span   = 0.65,
    favors_gap    = 0.05,
    header        = "HR (95% CI)"
  )

fp_render(p3)

## ----fp-aes, fig.width = 8, fig.height = 3.4----------------------------------
df_aes <- df
df_aes$ci_colour <- ifelse(df$pval < 0.05, "#c0392b", "#2c3e50")
df_aes$ci_fill   <- ifelse(df$pval < 0.05, "#e74c3c", "#7f8c8d")
df_aes$lbl_face  <- ifelse(df$subgroup == "Overall", "bold", "plain")

p4 <- forest_plot(df_aes) |>
  add_text("subgroup",
    header  = "Subgroup",
    width   = 2,
    mapping = fp_aes(fontface = "lbl_face")
  ) |>
  add_ci("HR", "LCI", "UCI",
    trans    = "log",
    xlim     = c(0.2, 3),
    breaks   = c(0.25, 0.5, 1, 2),
    ref_line = 1,
    show_axis = TRUE,
    header   = "HR (95% CI)",
    mapping  = fp_aes(colour = "ci_colour", fill = "ci_fill")
  )

fp_render(p4)

## ----header-group, fig.width = 9.5, fig.height = 3.8--------------------------
df2 <- df
df2$HR2  <- df$HR  * runif(7, 0.85, 1.15)
df2$LCI2 <- df$LCI * runif(7, 0.85, 1.15)
df2$UCI2 <- df$UCI * runif(7, 0.85, 1.15)

set.seed(42)
df2$HR2  <- df$HR  * runif(7, 0.85, 1.15)
df2$LCI2 <- pmax(df2$HR2 - (df$UCI - df$HR) * runif(7, 0.9, 1.1), 0.1)
df2$UCI2 <- df2$HR2 + (df$UCI - df$HR) * runif(7, 0.9, 1.1)

p5 <- forest_plot(df2) |>
  add_text("subgroup", header = "Subgroup", width = 2) |>             # panel 1
  add_gap(width = 0.1) |>                                              # panel 2
  add_ci("HR",  "LCI",  "UCI",                                        # panel 3
    trans = "log", xlim = c(0.2, 3), breaks = c(0.5, 1, 2),
    ref_line = 1, show_axis = TRUE, header = "Endpoint A") |>
  add_ci("HR2", "LCI2", "UCI2",                                       # panel 4
    trans = "log", xlim = c(0.2, 3), breaks = c(0.5, 1, 2),
    ref_line = 1, show_axis = TRUE, header = "Endpoint B") |>
  add_header_group("Primary Endpoints", panels = 3:4,
    background = "#f0f4ff", border = TRUE)

fp_render(p5)

## ----fp-custom, fig.width = 9, fig.height = 3.4-------------------------------
pval_panel <- fp_custom(
  plot_fn = function(data, n_rows, theme) {
    df_p <- data.frame(
      x     = 0.5,
      y     = rev(seq_len(n_rows)),
      label = ifelse(
        is.na(data$pval), "",
        ifelse(data$pval < 0.001, "< 0.001",
               sprintf("%.3f", data$pval))
      )
    )
    ggplot(df_p, aes(x = x, y = y, label = label)) +
      geom_text(
        size   = theme$text_size,
        colour = theme$text_colour,
        family = theme$base_family
      ) +
      scale_x_continuous(limits = c(0, 1), expand = expansion(0)) +
      theme_void()
  },
  header = "P-value",
  width  = 1.2
)

p6 <- forest_plot(df) |>
  add_text("subgroup", header = "Subgroup", width = 2) |>
  add_ci("HR", "LCI", "UCI",
    trans = "log", xlim = c(0.2, 3), breaks = c(0.25, 0.5, 1, 2),
    ref_line = 1, show_axis = TRUE, header = "HR (95% CI)") |>
  add_custom(pval_panel)

fp_render(p6)

## ----formatters, fig.width = 9, fig.height = 3.4------------------------------
p7 <- forest_plot(df) |>
  add_text("subgroup", header = "Subgroup", width = 2) |>
  add_text("n",
    header    = "N",
    width     = 0.8,
    align     = "right",
    formatter = fp_fmt_number(digits = 0, big_mark = ",")
  ) |>
  add_text("resp_rate",
    header    = "Response",
    width     = 1.1,
    align     = "right",
    formatter = fp_fmt_percent(digits = 1)
  ) |>
  add_text("pval",
    header    = "P-value",
    width     = 1.2,
    align     = "right",
    formatter = fp_fmt_pvalue(digits = 3, threshold = 0.001)
  ) |>
  add_ci("HR", "LCI", "UCI",
    trans = "log", xlim = c(0.2, 3), breaks = c(0.25, 0.5, 1, 2),
    ref_line = 1, show_axis = TRUE, header = "HR (95% CI)")

fp_render(p7)

## ----fp-register, eval = FALSE------------------------------------------------
# original_ci_builder <- getFromNamespace(".build_ci", "panelforest")
# 
# my_ci_builder <- function(ctx, spec, cell_edits) {
#   spec$line_width <- max(spec$line_width, 0.8)
#   original_ci_builder(ctx, spec, cell_edits)
# }
# 
# fp_register("ci", my_ci_builder, overwrite = TRUE)
# 
# # Restore the default when done
# fp_register("ci", original_ci_builder, overwrite = TRUE)

## ----dot-panel, fig.width = 8.5, fig.height = 3.4-----------------------------
p9 <- forest_plot(df) |>
  add_text("subgroup", header = "Subgroup", width = 2) |>
  add_ci("HR", "LCI", "UCI",
    trans = "log", xlim = c(0.2, 3), breaks = c(0.25, 0.5, 1, 2),
    ref_line = 1, show_axis = TRUE, header = "HR (95% CI)") |>
  add_gap(width = 0.1) |>
  add_dot("mean_diff",
    lower      = "lci_diff",
    upper      = "uci_diff",
    header     = "Mean Difference",
    ref_line   = 0,
    trans      = "identity",
    colour     = "#2563eb",
    shape      = 21,
    fill       = "#bfdbfe",
    point_size = 2.5,
    breaks     = c(-0.75, -0.5, -0.25, 0, 0.25)
  )

fp_render(p9)

## ----spacer-gap, fig.width = 9, fig.height = 3.4------------------------------
p10 <- forest_plot(df) |>
  add_text("subgroup", header = "Subgroup", width = 2) |>
  add_gap(width = 0.15) |>
  add_text("n", header = "N", width = 0.7, align = "right",
           formatter = fp_fmt_number(digits = 0)) |>
  add_spacer(width = 5, unit = "mm") |>
  add_ci("HR", "LCI", "UCI",
    trans = "log", xlim = c(0.2, 3), breaks = c(0.25, 0.5, 1, 2),
    ref_line = 1, show_axis = TRUE, header = "HR (95% CI)")

fp_render(p10)

## ----multi-ci, fig.width = 10, fig.height = 3.8-------------------------------
set.seed(1)
df3 <- df
df3$HR_pfs  <- df$HR * runif(7, 0.80, 1.20)
df3$LCI_pfs <- pmax(df3$HR_pfs - (df$UCI - df$LCI) / 2 * runif(7, 0.9, 1.1), 0.1)
df3$UCI_pfs <- df3$HR_pfs + (df$UCI - df$LCI) / 2 * runif(7, 0.9, 1.1)

p11 <- forest_plot(df3) |>
  add_text("subgroup", header = "Subgroup", width = 2) |>
  add_ci("HR", "LCI", "UCI",
    trans     = "log",
    xlim      = c(0.2, 3),
    breaks    = c(0.25, 0.5, 1, 2),
    ref_line  = 1,
    show_axis = TRUE,
    axis_label = "OS  HR",
    header    = "Overall Survival",
    colour    = "#1d4ed8"
  ) |>
  add_gap(width = 0.15) |>
  add_ci("HR_pfs", "LCI_pfs", "UCI_pfs",
    trans     = "log",
    xlim      = c(0.2, 3),
    breaks    = c(0.25, 0.5, 1, 2),
    ref_line  = 1,
    show_axis = TRUE,
    axis_label = "PFS  HR",
    header    = "Progression-Free Survival",
    colour    = "#15803d"
  ) |>
  add_header_group("Time-to-Event Endpoints", panels = 2:4,
    background = "#f8fafc", border = TRUE)

fp_render(p11)

## ----combined, fig.width = 11, fig.height = 4.2-------------------------------
df_full <- df
df_full$ci_colour <- ifelse(df$pval < 0.05, "#991b1b", "#374151")
df_full$lbl_face  <- ifelse(df$subgroup == "Overall", "bold", "plain")

sig_panel <- fp_custom(
  plot_fn = function(data, n_rows, theme) {
    df_s <- data.frame(
      x     = 0.5,
      y     = rev(seq_len(n_rows)),
      label = ifelse(data$pval < 0.05, "*", "")
    )
    ggplot(df_s, aes(x = x, y = y, label = label)) +
      geom_text(size = theme$text_size * 1.4, colour = "#c0392b",
                family = theme$base_family) +
      scale_x_continuous(limits = c(0, 1), expand = expansion(0)) +
      theme_void()
  },
  header = "",
  width  = 0.4
)

p_full <- forest_plot(df_full) |>
  add_text("subgroup",
    header  = "Subgroup",
    width   = 2,
    mapping = fp_aes(fontface = "lbl_face")
  ) |>
  add_text("n",
    header    = "N",
    width     = 0.7,
    align     = "right",
    formatter = fp_fmt_number(digits = 0, big_mark = ",")
  ) |>
  add_text("resp_rate",
    header    = "Response",
    width     = 1.1,
    align     = "right",
    formatter = fp_fmt_percent(digits = 1)
  ) |>
  add_gap(width = 0.12) |>
  add_ci("HR", "LCI", "UCI",
    trans         = "log",
    xlim          = c(0.2, 3),
    breaks        = c(0.25, 0.5, 1, 2),
    ref_line      = 1,
    show_axis     = TRUE,
    axis_label    = "Hazard Ratio (log scale)",
    favors_left   = "Favors Treatment",
    favors_right  = "Favors Control",
    favors_span   = 0.60,
    favors_gap    = 0.06,
    header        = "HR (95% CI)",
    mapping       = fp_aes(colour = "ci_colour")
  ) |>
  add_text("pval",
    header    = "P-value",
    width     = 1.2,
    align     = "right",
    formatter = fp_fmt_pvalue(digits = 3, threshold = 0.001)
  ) |>
  add_custom(sig_panel) |>
  add_header_group("Summary Statistics", panels = 2:3,
    background = "#f0fdf4", border = TRUE) |>
  add_header_group("Efficacy", panels = 5:7,
    background = "#eff6ff", border = TRUE)

fp_render(p_full)

