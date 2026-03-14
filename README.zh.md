# panelforest

[English](README.md)

`panelforest` 是一个用于绘制森林图 (forest plot) 的 R 包，采用声明式布局、模块化面板设计，基于 ggplot2 和 patchwork 进行渲染。

![森林图示例](man/figures/README-classic-forest.png)

## 安装

本地安装：

```r
install.packages(".", repos = NULL, type = "source")
```

从 GitHub 安装：

```r
# install.packages("pak")
pak::pak("lenardar/panelforest")
```

## 特性

- 管道式组合：通过 `forest_plot()` 和 `add_*()` 系列函数逐步构建
- 内置面板：文本 (`fp_text`)、文本 CI (`fp_text_ci`)、间隔 (`fp_gap`)、固定间距 (`fp_spacer`)、柱状 (`fp_bar`)、散点 (`fp_dot`)、置信区间 (`fp_ci`)
- 行条纹、汇总行、分组行、水平分隔线等结构装饰
- 跨列分组标题 `add_header_group()`，支持自动多层嵌套
- 通过 `fp_aes()` 实现列驱动的美学映射，通过 `edit()` 统一编辑行/单元格
- 菱形 CI 图示符，支持独立控制边框色、填充色和透明度
- 自定义面板 `fp_custom()` 与自定义构建器 `fp_register()`
- 格式化工具：`fp_fmt_number()`、`fp_fmt_percent()`、`fp_fmt_pvalue()`

## 快速上手

```r
library(panelforest)

df <- panelforest_example_data()

forest_plot(df) |>
  add_stripe(c("white", "#f4f7f5")) |>
  add_summary(1) |>
  add_hline(1) |>
  add_text("label", header = "Subgroup", width = 2.5, align = "left", header_align = "center") |>
  add_bar("n_events", header = "Events", width = 2) |>
  add_ci("HR", "LCI", "UCI", header = "Hazard Ratio", trans = "log", width = 3) |>
  add_text_ci("HR", "LCI", "UCI", header = "HR (95% CI)", width = 2.5, align = "left", header_align = "center") |>
  fp_render()
```

## 通过 `fp_aes()` 映射美学属性

将数据列映射到 CI 面板的颜色、填充、形状等视觉属性：

```r
df$ci_colour <- c("#111827", "#1d4ed8", "#1d4ed8", "#111827", "#b42318")
df$ci_fill   <- c("#d1d5db", "#bfdbfe", "#bfdbfe", "#d1d5db", "#fecaca")
df$ci_shape  <- c(18, 19, 19, 19, 17)

forest_plot(df) |>
  add_text("label", header = "Subgroup", align = "left", header_align = "center") |>
  add_ci("HR", "LCI", "UCI", header = "Hazard Ratio", trans = "log",
         mapping = fp_aes(colour = "ci_colour", fill = "ci_fill", shape = "ci_shape")) |>
  edit(row = 1, panel = "Hazard Ratio", glyph = "diamond", fill = "#dbeafe") |>
  edit(row = 5, panel = "Hazard Ratio", point_size = 3.4) |>
  fp_render()
```

## 统一 `edit()` 编辑层

`edit()` 函数统一了旧版 `edit_cell()`、`add_row_style()` 和 `add_row_height()` 三个接口：

```r
forest_plot(df) |>
  add_text("label", header = "Subgroup") |>
  add_ci("HR", "LCI", "UCI", header = "HR") |>
  # 单元格级编辑（指定 panel）
  edit(row = 1, panel = "HR", glyph = "diamond", fill = "#dbeafe") |>
  # 行级编辑（不指定 panel，影响所有面板）
  edit(row = 2:4, fontface = "italic") |>
  # 行高调整
  edit(row = 5, height = 1.5) |>
  fp_render()
```

通过 `add_summary()` 标记的汇总行默认使用菱形图示符。设置 `summary_glyph = NULL` 可保持标准的点线样式。

## 间距控制

使用 `fp_spacer()` 添加固定物理宽度的间距列：

```r
plot_obj <- forest_plot(df) |>
  add_text("label", header = "Subgroup", width = 2.5, align = "left", header_align = "center") |>
  add_spacer(5, unit = "mm") |>
  add_bar("n_events", header = "Events", width = 2) |>
  add_ci("HR", "LCI", "UCI", header = "Hazard Ratio", trans = "log", width = 3)

size <- fp_size(plot_obj)
ggplot2::ggsave("forest.png", fp_render(plot_obj), width = size["width"], height = size["height"])
```

`fp_gap()` 用于相对比例间距，`fp_spacer()` 用于固定物理间距。

## 跨列分组标题

使用 `add_header_group()` 在面板标题上方添加跨面板的父级标题。层级自动推断——包含其他分组的分组自动升至更高层：

```r
forest_plot(df) |>
  add_text("label", header = "Drug A", width = 2) |>
  add_text("n_events", header = "Drug B", width = 1) |>
  add_text("hr_ci", header = "Placebo", width = 1.8) |>
  add_ci("HR", "LCI", "UCI", header = "HR", trans = "log", width = 2.5) |>
  add_header_group("Treatment", panels = 1:2, border = TRUE) |>
  add_header_group("Arms", panels = 1:3) |>
  fp_render()
```

每个分组标题支持独立样式：`colour`、`fontface`、`size`、`family`、`background`、`border`、`height`。

## 格式化工具

`fp_text()` 接受格式化函数，可以在绘图时将原始数值列转换为格式化文本：

```r
df$p_value <- c(0.004, 0.11, 0.13, 0.06, 0.002)

forest_plot(df) |>
  add_text("label", header = "Subgroup") |>
  add_text("n_events", header = "Events", formatter = fp_fmt_number()) |>
  add_text("p_value", header = "P value", formatter = fp_fmt_pvalue()) |>
  fp_render()
```

## 功能模块一览

| 类别     | 函数                                                                                          |
| -------- | --------------------------------------------------------------------------------------------- |
| 布局     | `forest_plot()`, `fp_render()`, `fp_size()`                                             |
| 文本面板 | `fp_text()`, `fp_text_ci()`                                                               |
| 数值面板 | `fp_bar()`, `fp_dot()`, `fp_ci()`                                                       |
| 结构面板 | `fp_gap()`（相对间距）, `fp_spacer()`（固定间距）                                         |
| 装饰     | `add_stripe()`, `add_summary()`, `add_group()`, `add_hline()`, `add_header_group()` |
| 美学映射 | `fp_aes()`                                                                                  |
| 编辑     | `edit()`（行级 / 单元格级 / 行高）                                                          |
| 主题     | `fp_theme_default()`, `fp_theme_journal()`                                                |
| 扩展     | `fp_custom()`, `fp_register()`                                                            |
| 格式化   | `fp_fmt_number()`, `fp_fmt_percent()`, `fp_fmt_pvalue()`                                |

## 状态

预发布版本 (v0.2.0)，API 在 v1.0 前可能调整。
