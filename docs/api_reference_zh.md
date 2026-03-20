# panelforest v0.2.0 API 参考文档

> 本文档覆盖 panelforest 的全部公开 API。内部函数（以 `.` 开头）不在本文档范围内。

---

## 目录

- [核心流程](#核心流程)
- [面板规格构造器](#面板规格构造器)
  - [fp_text() — 文本面板](#fp_text)
  - [fp_text_ci() — CI 文本面板](#fp_text_ci)
  - [fp_pair() — 数值对面板](#fp_pair)
  - [fp_ci() — 置信区间面板](#fp_ci)
  - [fp_bar() — 柱状面板](#fp_bar)
  - [fp_dot() — 散点面板](#fp_dot)
  - [fp_gap() — 相对间距](#fp_gap)
  - [fp_spacer() — 固定间距](#fp_spacer)
  - [fp_custom() — 自定义面板](#fp_custom)
- [美学映射](#美学映射)
  - [fp_aes() — 列驱动映射](#fp_aes)
- [面板添加函数](#面板添加函数)
- [结构装饰](#结构装饰)
  - [add_stripe() — 行条纹](#add_stripe)
  - [add_summary() — 汇总行](#add_summary)
  - [add_group() — 分组行](#add_group)
  - [add_hline() — 水平分隔线](#add_hline)
  - [add_header_group() — 跨列分组标题](#add_header_group)
- [编辑层](#编辑层)
  - [edit() — 统一编辑接口](#edit)
  - [add_rule() — 条件样式](#add_rule)
- [主题](#主题)
- [格式化工具](#格式化工具)
- [扩展接口](#扩展接口)
- [数据辅助](#数据辅助)
- [典型用法示例](#典型用法示例)
- [从 v0.1.0 迁移](#从-v010-迁移)
- [内部实现](#内部实现)
- [对象模型](#对象模型)

---

## 核心流程

### `forest_plot()`

创建一个 `fp_plot` 对象，作为所有后续操作的起点。

```r
forest_plot(data, theme = fp_theme_default(), row_height = 1)
```

| 参数 | 类型 | 说明 |
|------|------|------|
| `data` | data.frame | 数据框，每行对应森林图中的一行 |
| `theme` | fp_theme | 主题对象，控制全局字体、颜色、边距 |
| `row_height` | 正数 | 默认行高（含标题行），后续可通过 `edit()` 逐行调整 |

返回 `fp_plot` 对象，支持管道操作。

### `fp_render()`

将 `fp_plot` 渲染为 patchwork 图形对象。

```r
fp_render(x)
```

| 参数 | 说明 |
|------|------|
| `x` | `fp_plot` 对象 |

返回 `patchwork` 对象，可直接打印或用 `ggsave()` 保存。

### `fp_size()`

估算绘图设备的建议宽高（英寸）。

```r
fp_size(x)
```

| 参数 | 说明 |
|------|------|
| `x` | `fp_plot` 对象 |

返回命名数值向量 `c(width = ..., height = ...)`，宽度 = 各面板英寸宽之和，高度 = 行高之和 + 标题行高 + 分组标题行高（如有）。

**典型用法：**

```r
p <- forest_plot(df) |> add_text("label") |> add_ci("est", "lwr", "upr")
size <- fp_size(p)
ggsave("plot.png", fp_render(p), width = size["width"], height = size["height"])
```

### `print.fp_plot()`

S3 方法。当 `fp_plot` 对象被直接打印时，自动调用 `fp_render()` 渲染。

---

## 面板规格构造器

每个面板类型有一个 `fp_*()` 构造器，返回 `fp_spec` 对象。通常不直接调用，而是通过 `add_*()` 系列函数间接调用。

<a id="fp_text"></a>
### `fp_text()` — 文本面板

显示数据框中某一列的文本内容。

```r
fp_text(
  col,                          # 列名（必填）
  header       = NULL,          # 表头标签
  width        = 1.5,             # 宽度（英寸）
  align        = "left",        # 内容对齐："left" / "center" / "right"
  header_align = NULL,          # 表头对齐（NULL 时继承 align）
  indent       = NULL,          # 缩进：列名或数值向量
  indent_width = 0.08,          # 单级缩进宽度 (0~1)
  formatter    = NULL,          # 格式化函数
  fontface     = NULL,          # 字体样式："plain" / "bold" / "italic"
  colour       = NULL,          # 文本颜色
  size         = NULL,          # 文本大小
  mapping      = NULL           # fp_aes() 映射
)
```

**缩进用法：**

```r
# 用数据列控制缩进深度
add_text("label", indent = "level")          # level 列: 0, 1, 1, 2, ...

# 固定缩进（所有行）
add_text("label", indent = 1)
```

**格式化用法：**

```r
# 用内置格式化器
add_text("n_events", header = "Events", formatter = fp_fmt_number())

# 自定义格式化函数
add_text("value", formatter = function(values) paste0(values, "%"))
```

<a id="fp_text_ci"></a>
### `fp_text_ci()` — CI 文本面板

自动将三列（估计值、下限、上限）格式化为 `"est (lower, upper)"` 形式。

```r
fp_text_ci(
  est, lower, upper,            # 三个列名（必填）
  header       = NULL,
  width        = 2.5,
  digits       = 2,             # 小数位数
  prefix       = "",            # 前缀（如 "HR = "）
  suffix       = "",            # 后缀
  align        = "left",
  header_align = NULL,
  fontface     = NULL,
  colour       = NULL,
  size         = NULL,
  mapping      = NULL
)
```

**示例：** `digits = 2` → `"0.92 (0.74, 1.14)"`

<a id="fp_pair"></a>
### `fp_pair()` — 数值对面板

将两列或多列数值格式化为单个文本列。

```r
fp_pair(
  cols,                         # 列名字符向量，length >= 1（必填）
  format       = "fraction",    # "fraction" / "percent" / function(data, cols)
  header       = NULL,
  width        = 1.5,
  digits       = 0,             # 整数或整数向量，循环补齐至 length(cols)
  pct_digits   = 1,             # percent 模式下百分比小数位
  sep          = "/",           # fraction 模式下的分隔符
  na           = "",            # NA 行显示的字符串
  align        = "right",
  header_align = NULL,
  fontface     = NULL,
  colour       = NULL,
  size         = NULL,
  mapping      = NULL
)
```

**三种 `format` 模式：**

| 模式 | 输出示例 | 限制 |
|------|----------|------|
| `"fraction"`（默认）| `"42/100"` | 支持 2 列以上，按 `sep` 拼接 |
| `"percent"` | `"42 (42.0%)"` | 恰好 2 列，`cols[1]/cols[2]*100` 自动计算 |
| `function(data, cols)` | 自定义 | 接收完整数据框和列名向量，返回字符向量 |

**`digits` 向量：**

```r
# 两列均保留 0 位小数
add_pair(c("events", "total"), digits = 0)

# 每列独立控制
add_pair(c("mean", "sd"), format = "fraction", sep = " ± ", digits = c(1, 2))
# → "3.4 ± 0.56"
```

**示例：**

```r
forest_plot(df) |>
  add_text("label", header = "Subgroup", width = 1.8) |>
  add_pair(c("events", "total"),
           header = "Events/N", digits = 0, width = 0.9) |>
  add_pair(c("events", "total"),
           format = "percent", header = "Events (%)",
           digits = 0, pct_digits = 1, width = 1.1) |>
  add_ci("HR", "LCI", "UCI", header = "HR", trans = "log") |>
  fp_render()

# 自定义格式（3 列）
add_pair(
  c("events", "total", "pop"),
  format = function(data, cols) {
    paste0(data[[cols[1]]], "/", data[[cols[2]]], " [n=", data[[cols[3]]], "]")
  },
  header = "Events/N [Pop]"
)
```

<a id="fp_ci"></a>
### `fp_ci()` — 置信区间面板

绘制点估计 + 区间线（whisker），支持菱形图示符、截断箭头、对数变换。

```r
fp_ci(
  est, lower, upper,            # 三个列名（必填）
  header        = NULL,
  header_align  = "center",
  width         = 3,
  ref_line      = 1,            # 参考线位置（log 变换时通常为 1）
  trans         = "identity",   # "identity" 或 "log"
  xlim          = NULL,         # 显示范围 c(min, max)
  truncate      = NULL,         # 截断范围 c(min, max)，超出部分显示箭头
  show_axis     = FALSE,        # 是否显示底部坐标轴
  axis_label    = NULL,         # 坐标轴标题
  favors_left   = NULL,         # 参考线左侧方向性标注（如 "Favors Treatment"）
  favors_right  = NULL,         # 参考线右侧方向性标注（如 "Favors Control"）
  labels        = NULL,         # 自定义刻度标签
  colour        = NULL,         # 边框/线条颜色
  fill          = NULL,         # 填充颜色（菱形专用）
  alpha         = 0.9,          # 透明度
  glyph         = "point",      # 默认图示符："point" 或 "diamond"
  summary_glyph = "diamond",    # 汇总行图示符（NULL 保持默认）
  shape         = 19,           # 点形状（ggplot2 pch 编号）
  point_size    = NULL,         # 点大小
  line_width    = 0.6,          # 线宽
  breaks        = NULL,         # 自定义刻度位置
  mapping       = NULL          # fp_aes() 映射
)
```

**显示范围 vs 截断范围：**

- `xlim` 控制坐标轴显示范围
- `truncate` 控制 CI 线的裁剪范围，超出部分显示截断箭头
- 两者可以不同：`xlim = c(0.1, 10), truncate = c(0.5, 5)` 意味着坐标轴从 0.1 到 10，但 CI 线在 0.5~5 之外被截断并显示箭头

**对数变换注意：** 当 `trans = "log"` 时，`est`、`lower`、`upper`、`ref_line`、`xlim`、`truncate`、`breaks` 都必须为正值。

<a id="fp_bar"></a>
### `fp_bar()` — 柱状面板

显示水平柱状图。

```r
fp_bar(
  col,                          # 数值列名（必填）
  header       = NULL,
  header_align = "center",
  width        = 2,
  baseline     = 0,             # 柱子起始值
  fill         = "#a8c5b8",     # 填充颜色
  colour       = NA,            # 边框颜色
  alpha        = 1,             # 透明度
  xlim         = NULL,          # 显示范围
  breaks       = NULL           # 刻度
)
```

<a id="fp_dot"></a>
### `fp_dot()` — 散点面板

显示散点（可选区间线），适合展示均值或率。

```r
fp_dot(
  col,                          # 数值列名（必填）
  lower        = NULL,          # 下限列名（可选，与 upper 成对出现）
  upper        = NULL,          # 上限列名
  header       = NULL,
  header_align = "center",
  width        = 2.5,
  ref_line     = NULL,          # 参考线
  trans        = "identity",    # 变换
  truncate     = NULL,          # 截断范围
  colour       = NULL,
  fill         = "#ffffff",
  shape        = 21,
  point_size   = NULL,
  line_width   = 0.6,
  breaks       = NULL
)
```

<a id="fp_gap"></a>
### `fp_gap()` — 相对间距

在面板之间插入按比例缩放的空白列。

```r
fp_gap(width = 0.2, header = NULL, header_align = "center")
```

<a id="fp_spacer"></a>
### `fp_spacer()` — 固定间距

在面板之间插入固定物理宽度的空白列。

```r
fp_spacer(width = 4, unit = "mm", header = NULL, header_align = "center")
```

| 参数 | 说明 |
|------|------|
| `width` | 数值宽度 |
| `unit` | grid 单位字符串：`"mm"`, `"cm"`, `"in"`, `"pt"` |

**`fp_gap` vs `fp_spacer`：** gap 参与比例分配，宽度随画布大小变化；spacer 为固定物理宽度，适合精确控制间距。

<a id="fp_custom"></a>
### `fp_custom()` — 自定义面板

插入用户自定义的 ggplot 面板。

```r
fp_custom(
  plot_fn,                      # 返回 ggplot 对象的函数（必填）
  header       = NULL,
  width        = 1.5,
  header_x     = 0.5,          # 表头 x 坐标
  header_align = "center"
)
```

`plot_fn` 可接受以下命名参数的任意子集：`data`, `spec`, `n_rows`, `row_heights`, `theme`。

**示例：**

```r
pval_panel <- fp_custom(
  plot_fn = function(data, n_rows) {
    ggplot2::ggplot(
      data.frame(x = 0.5, y = rev(seq_len(n_rows)),
                 label = sprintf("%.3f", data$p)),
      ggplot2::aes(x = x, y = y, label = label)
    ) + ggplot2::geom_text(size = 3.2)
  },
  header = "P value"
)

forest_plot(df) |>
  add_text("label") |>
  add_custom(pval_panel) |>
  fp_render()
```

---

<a id="fp_aes"></a>
## 美学映射

### `fp_aes()` — 列驱动映射

将数据列映射到视觉属性，替代旧版 `colour_by`、`fill_by` 等参数。

```r
fp_aes(
  colour     = NULL,    # 颜色列名
  fill       = NULL,    # 填充列名
  alpha      = NULL,    # 透明度列名（数值型）
  glyph      = NULL,    # 图示符列名（"point" / "diamond"）
  shape      = NULL,    # 形状列名（数值型）
  point_size = NULL,    # 点大小列名（数值型）
  line_width = NULL,    # 线宽列名（数值型）
  fontface   = NULL,    # 字体样式列名
  size       = NULL     # 文本大小列名（数值型）
)
```

所有参数均为字符串（数据列名）。返回 `fp_aes` 对象。

**适用范围：**

| 面板类型 | 可用映射 |
|----------|----------|
| `fp_ci()` | colour, fill, alpha, glyph, shape, point_size, line_width |
| `fp_text()` | fontface, colour, size |
| `fp_text_ci()` | fontface, colour, size |

**示例：**

```r
df$ci_colour <- c("#1d4ed8", "#b42318", "#1d4ed8")
df$ci_fill   <- c("#93c5fd", "#fecaca", "#93c5fd")

forest_plot(df) |>
  add_ci("est", "lwr", "upr",
         mapping = fp_aes(colour = "ci_colour", fill = "ci_fill")) |>
  fp_render()
```

---

## 面板添加函数

这些函数是 `fp_*()` 构造器的管道友好包装：

| 函数 | 对应构造器 | 说明 |
|------|-----------|------|
| `add_text(x, ...)` | `fp_text()` | 添加文本面板 |
| `add_text_ci(x, ...)` | `fp_text_ci()` | 添加 CI 文本面板 |
| `add_pair(x, ...)` | `fp_pair()` | 添加数值对面板 |
| `add_ci(x, ...)` | `fp_ci()` | 添加置信区间面板 |
| `add_bar(x, ...)` | `fp_bar()` | 添加柱状面板 |
| `add_dot(x, ...)` | `fp_dot()` | 添加散点面板 |
| `add_gap(x, ...)` | `fp_gap()` | 添加相对间距 |
| `add_spacer(x, ...)` | `fp_spacer()` | 添加固定间距 |
| `add_custom(x, spec)` | — | 添加自定义面板（需先用 `fp_custom()` 创建 spec） |

`x` 为 `fp_plot` 对象，`...` 传递给对应构造器。

---

## 结构装饰

<a id="add_stripe"></a>
### `add_stripe()` — 行条纹

设置行交替背景颜色。

```r
add_stripe(x, colors)
```

| 参数 | 说明 |
|------|------|
| `colors` | 至少两个颜色值的字符向量，循环应用 |

```r
add_stripe(c("white", "#f4f7f5"))           # 白/浅绿交替
add_stripe(c("white", "#f0f0f0", "#e8e8e8")) # 三色循环
```

<a id="add_summary"></a>
### `add_summary()` — 汇总行

标记汇总行。汇总行的文本自动加粗，CI 面板默认使用菱形图示符。

```r
add_summary(x, rows)
```

| 参数 | 说明 |
|------|------|
| `rows` | 行索引整数向量 |

<a id="add_group"></a>
### `add_group()` — 分组行

标记分组标题行。分组行的文本加粗加大，CI/dot 面板不渲染数据点。

```r
add_group(x, rows, fontface = "bold", size = NULL, colour = NULL, fill = NULL)
```

| 参数 | 说明 |
|------|------|
| `rows` | 行索引 |
| `fontface` | 字体样式（默认 `"bold"`） |
| `size` | 字号覆盖 |
| `colour` | 文本颜色覆盖 |
| `fill` | 行背景颜色 |

```r
add_group(c(1, 8), fill = "#f0f4f1")       # 第 1、8 行为分组标题
```

<a id="add_hline"></a>
### `add_hline()` — 水平分隔线

在指定行下方绘制横线，跨越所有面板。

```r
add_hline(x, rows, colour = "#d9dde2", linewidth = 0.45, linetype = 1)
```

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `rows` | — | 行索引（在这些行下方画线） |
| `colour` | `"#d9dde2"` | 线条颜色 |
| `linewidth` | 0.45 | 线宽 |
| `linetype` | 1 | 线型（1=实线, 2=虚线, ...） |

<a id="add_header_group"></a>
### `add_header_group()` — 跨列分组标题

在面板标题行上方添加跨面板的父级标题，支持多层嵌套。层级自动推断：包含其他分组的分组自动升至更高层。

```r
add_header_group(
  x,
  label,                         # 标题文本（必填）
  panels,                        # 跨越的面板索引，必须连续（如 1:3）
  align           = "center",    # 文本对齐："left" / "center" / "right"
  fontface        = "bold",      # 字体样式
  colour          = NULL,        # 文本颜色（NULL 继承主题）
  size            = NULL,        # 字号（NULL 继承主题）
  family          = NULL,        # 字体族（NULL 继承主题）
  background      = NULL,        # 背景色（NULL 为透明）
  height          = NULL,        # 该层行高（NULL 使用 header_height）
  border          = FALSE,       # 是否显示底部分隔线
  border_colour   = "#d0d7de",   # 分隔线颜色
  border_linewidth = 0.4         # 分隔线宽度
)
```

**自动层级推断：**

```r
add_header_group("Treatment", panels = 1:2)   # → level 1
add_header_group("Arms", panels = 1:3)        # 包含 Treatment → level 2
```

同层分组不可重叠（渲染时校验）。面板索引在渲染时校验（调用时面板可能尚未添加完毕）。

**示例：**

```r
forest_plot(df) |>
  add_text("a", header = "Drug A") |>
  add_text("b", header = "Drug B") |>
  add_text("c", header = "Placebo") |>
  add_ci("est", "lwr", "upr", header = "HR") |>
  add_header_group("Treatment", panels = 1:2, border = TRUE) |>
  add_header_group("Arms", panels = 1:3) |>
  fp_render()
```

---

<a id="edit"></a>
## 编辑层

### `edit()` — 统一编辑接口

统一了旧版 `edit_cell()`、`add_row_style()`、`add_row_height()` 三个函数。

```r
edit(
  x,                            # fp_plot 对象
  row        = NULL,            # 行索引（整数或向量）；NULL = 全部行
  panel      = NULL,            # 面板标识（NULL = 行级编辑）
  fontface   = NULL,
  colour     = NULL,
  size       = NULL,
  fill       = NULL,
  alpha      = NULL,
  glyph      = NULL,            # "point" / "diamond"
  point_size = NULL,
  line_width = NULL,
  shape      = NULL,
  label      = NULL,            # 覆盖文本内容
  family     = NULL,            # 字体族
  height     = NULL             # 行高
)
```

**四种模式：**

| 模式 | 条件 | 效果 |
|------|------|------|
| 行级编辑 | `row` 指定，`panel = NULL` | 样式应用于这些行的所有面板 |
| 单元格编辑 | `row` 和 `panel` 均指定 | 样式仅应用于这些行的该面板 |
| 列级编辑 | `row = NULL`，`panel` 指定 | 样式应用于该面板的全部行 |
| 行高调整 | 设置 `height` | 修改行高；必须同时指定 `row` |

行级、单元格级和行高模式可在同一次调用中组合。

**面板标识方式：**

- 整数索引：`panel = 2`（第二个面板）
- 表头字符串：`panel = "Hazard Ratio"`
- 列名字符串：`panel = "est"`

**示例：**

```r
forest_plot(df) |>
  add_text("label", header = "Subgroup") |>
  add_ci("est", "lwr", "upr", header = "Hazard Ratio") |>

  # 1. 单元格编辑：第 1 行的 CI 面板使用菱形
  edit(row = 1, panel = "Hazard Ratio", glyph = "diamond", fill = "#dbeafe") |>

  # 2. 行级编辑：第 2~4 行斜体
  edit(row = 2:4, fontface = "italic") |>

  # 3. 行高调整：第 5 行加高
  edit(row = 5, height = 1.5) |>

  fp_render()
```

<a id="add_rule"></a>
### `add_rule()` — 条件样式

根据数据条件为匹配的行应用样式，在渲染时对条件求值。

```r
add_rule(
  x,
  when,                         # 条件（必填，见下）
  panel      = NULL,            # 面板标识（NULL = 行级，指定则为单元格级）
  fontface   = NULL,
  colour     = NULL,
  size       = NULL,
  fill       = NULL,
  alpha      = NULL,
  glyph      = NULL,            # "point" / "diamond"
  point_size = NULL,
  line_width = NULL,
  shape      = NULL,
  label      = NULL,
  family     = NULL,
  height     = NULL             # 行高（单一正数）
)
```

**`when` 参数的三种形式：**

| 形式 | 示例 | 说明 |
|------|------|------|
| 单侧公式 | `~ p_value < 0.05` | 列名直接在作用域内，可用 `!!` 注入外部变量 |
| 函数 | `function(data) data$p < 0.05` | 接收完整数据框，返回逻辑向量 |
| 逻辑向量 | `c(TRUE, FALSE, TRUE)` | 长度必须等于 `nrow(data)` |

**优先级（由低到高）：**

```
spec 默认值  <  fp_aes()  <  add_rule()  <  edit()
```

多条规则按声明顺序应用，后声明的规则覆盖先声明的（针对同一属性）。显式的 `edit()` 调用始终优先于任何规则。

**示例：**

```r
forest_plot(df) |>
  add_text("label", header = "Subgroup") |>
  add_ci("est", "lwr", "upr", header = "HR (95% CI)", trans = "log") |>

  # 行级：显著行全行加粗变红
  add_rule(~ p_value < 0.05, fontface = "bold", colour = "#b42318") |>

  # 行级：无估计值的分组标题行变灰
  add_rule(~ is.na(est), colour = "grey60") |>

  # 单元格级：仅 CI 面板的颜色受影响
  add_rule(~ p_value < 0.01, panel = "HR (95% CI)", colour = "#7f1d1d") |>

  fp_render()
```

---

## 主题

### `fp_theme_default()`

```r
fp_theme_default(
  base_family     = "",         # 字体族
  text_size       = 3.6,        # 正文大小
  text_colour     = "#1f1f1f",  # 正文颜色
  header_size     = 3.8,        # 表头大小
  header_fontface = "bold",     # 表头字体
  header_colour   = "#1f1f1f",  # 表头颜色
  refline_colour  = "#9aa1a6",  # 参考线颜色
  stripe_alpha    = 1,          # 条纹透明度
  plot_margin     = 4           # 外边距（点）
)
```

### `fp_theme_journal()`

期刊风格主题，使用衬线字体、较小字号、更紧凑的边距。

```r
fp_theme_journal(
  base_family     = "serif",
  text_size       = 3.4,
  text_colour     = "#202124",
  header_size     = 3.6,
  header_fontface = "bold",
  header_colour   = "#111111",
  refline_colour  = "#7f8891",
  stripe_alpha    = 1,
  plot_margin     = 3
)
```

---

## 格式化工具

格式化工厂函数，返回可传给 `fp_text()` 的 `formatter` 参数的函数。

### `fp_fmt_number()`

```r
fp_fmt_number(digits = 2, big_mark = "", prefix = "", suffix = "", na = "")
```

```r
fp_fmt_number(digits = 1, big_mark = ",")(c(1000, 12.34))
# → "1,000.0"  "12.3"
```

### `fp_fmt_percent()`

```r
fp_fmt_percent(digits = 1, scale = 100, suffix = "%", prefix = "", na = "")
```

```r
fp_fmt_percent()(c(0.125, 0.34))
# → "12.5%"  "34.0%"
```

### `fp_fmt_pvalue()`

```r
fp_fmt_pvalue(digits = 3, threshold = 0.001, prefix = "p = ", na = "")
```

```r
fp_fmt_pvalue()(c(0.12, 0.0005))
# → "p = 0.120"  "p = < 0.001"
```

---

## 扩展接口

### `fp_register()`

注册自定义构建器到内部注册表。

```r
fp_register(type, builder, overwrite = FALSE)
```

| 参数 | 说明 |
|------|------|
| `type` | 规格类型字符串 |
| `builder` | 函数，签名为 `function(ctx, spec, cell_edits)`，返回 ggplot 对象 |
| `overwrite` | 是否覆盖已有注册 |

`ctx`（BuildContext）包含以下字段：

| 字段 | 说明 |
|------|------|
| `ctx$data` | 数据框 |
| `ctx$n_rows` | 行数 |
| `ctx$row_heights` | 行高向量 |
| `ctx$layout` | 行布局（ymin, ymax, centers, ...） |
| `ctx$row_styles` | 行样式覆盖列表 |
| `ctx$summary_mask` | 汇总行布尔向量 |
| `ctx$group_mask` | 分组行布尔向量 |
| `ctx$hlines` | 水平线列表 |
| `ctx$theme` | 主题对象 |

---

## 数据辅助

### `panelforest_example_data()`

加载内置示例数据集。

```r
panelforest_example_data(name = "classic")
```

目前仅有 `"classic"` 数据集，包含以下列：

| 列 | 类型 | 说明 |
|----|------|------|
| `label` | character | 亚组名称 |
| `n_events` | integer | 事件数 |
| `HR` | numeric | 风险比（点估计） |
| `LCI` | numeric | 95% CI 下限 |
| `UCI` | numeric | 95% CI 上限 |
| `hr_ci` | character | 预格式化的 HR (CI) 文本 |

---

## 典型用法示例

### 基础森林图

```r
library(panelforest)
df <- panelforest_example_data()

forest_plot(df) |>
  add_stripe(c("white", "#f4f7f5")) |>
  add_summary(1) |>
  add_hline(1) |>
  add_text("label", header = "Subgroup", width = 2.5,
           align = "left", header_align = "center") |>
  add_bar("n_events", header = "Events", width = 2) |>
  add_ci("HR", "LCI", "UCI", header = "Hazard Ratio",
         trans = "log", width = 3) |>
  add_text_ci("HR", "LCI", "UCI", header = "HR (95% CI)",
              width = 2.5, align = "left", header_align = "center") |>
  fp_render()
```

### 带美学映射和编辑的完整示例

```r
df <- panelforest_example_data()
df$ci_colour <- c("#111827", "#1d4ed8", "#1d4ed8", "#111827", "#b42318")
df$ci_fill   <- c("#d1d5db", "#bfdbfe", "#bfdbfe", "#d1d5db", "#fecaca")

forest_plot(df, theme = fp_theme_journal()) |>
  add_stripe(c("white", "#f5f7f6")) |>
  add_summary(1) |>
  add_group(c(), fill = "#eef2ef") |>
  add_hline(1) |>
  add_text("label", header = "Subgroup", width = 2.5,
           align = "left", header_align = "center") |>
  add_ci("HR", "LCI", "UCI", header = "Hazard Ratio",
         trans = "log", width = 3,
         mapping = fp_aes(colour = "ci_colour", fill = "ci_fill")) |>
  add_text_ci("HR", "LCI", "UCI", header = "HR (95% CI)",
              width = 2.5, align = "left", header_align = "center") |>
  edit(row = 1, panel = "Hazard Ratio",
       glyph = "diamond", fill = "#dbeafe") |>
  edit(row = 5, panel = "Hazard Ratio",
       point_size = 3.4) |>
  fp_render()
```

### 保存到文件

```r
p <- forest_plot(df) |>
  add_text("label", header = "Subgroup") |>
  add_ci("HR", "LCI", "UCI", header = "HR", trans = "log")

size <- fp_size(p)
ggsave("forest_plot.pdf", fp_render(p),
       width = size["width"], height = size["height"])
```

### 带分组标题的森林图

```r
forest_plot(df) |>
  add_stripe(c("white", "#f8f9fa")) |>
  add_text("label", header = "Subgroup", width = 2.2) |>
  add_gap(0.15) |>
  add_text("n_events", header = "Events", width = 0.8, align = "center") |>
  add_text("hr_ci", header = "HR (95% CI)", width = 1.8, align = "center") |>
  add_gap(0.15) |>
  add_ci("HR", "LCI", "UCI", header = "Hazard Ratio",
         trans = "log", width = 3, show_axis = TRUE) |>
  add_header_group("Statistics", panels = 3:4, border = TRUE) |>
  add_header_group("Results", panels = 3:6, border = TRUE) |>
  fp_render()
```

---

## 从 v0.1.0 迁移

| v0.1.0 旧接口 | v0.2.0 新接口 |
|----------------|---------------|
| `add_summary_rows(rows)` | `add_summary(rows)` |
| `add_group_rows(rows, ...)` | `add_group(rows, ...)` |
| `add_hline(fp_hline(rows, ...))` | `add_hline(rows, ...)` |
| `edit_cell(row, panel, ...)` | `edit(row, panel, ...)` |
| `add_row_style(rows, ...)` | `edit(row, ...)`（panel = NULL） |
| `add_row_height(rows, height)` | `edit(row, height = h)` |
| `colour_by = "col"` | `mapping = fp_aes(colour = "col")` |
| `fill_by = "col"` | `mapping = fp_aes(fill = "col")` |
| `hjust = 0` | `align = "left"` |
| `header_hjust = 0.5` | `header_align = "center"` |
| `fp_layout(...)` | 已移除，直接用 `add_*()` |
| `plot$layout$specs` | `plot$specs` |

---

## 内部实现

> 面向贡献者和高级用户。不要在包外代码中依赖这些内部实现——它们可能在不通知的情况下发生变化。

### 文件职责

| 文件 | 职责 |
|------|------|
| `constants.R` | 命名常量（魔法数字、默认值） |
| `validate.R` | 全包共用的输入验证函数 |
| `geometry.R` | 行布局、坐标系、面板 ggplot 主题 |
| `style.R` | `.resolve_attr()` — 样式解析管道 |
| `build_context.R` | `.build_context()` 工厂；汇总行/分组行掩码 |
| `ci_helpers.R` | CI 数学：范围计算、截断、菱形几何 |
| `header_group.R` | 分组标题逻辑：层级检测、校验、组装 |
| `panel.R` | 面板收尾：条纹、水平线、标题行 |
| `builders.R` | 全部 8 个内置构建器（text、text_ci、pair、gap、ci、bar、dot、custom） |
| `rule.R` | `add_rule()`、`.evaluate_rule_when()`、`.apply_rules()` |
| `registry.R` | 构建器注册表（`fp_register`、`.fp_dispatch`） |

### 样式解析优先级

每个渲染单元格的属性按以下优先级解析（由低到高）：

1. Spec 级默认值（在 `fp_*()` 构造器中设置）
2. `fp_aes()` 列驱动映射
3. `add_rule()` 条件覆盖（渲染时求值，后声明的规则优先）
4. `edit()` 显式覆盖（始终优先——在规则之上重新应用）

### 渲染流程

```
fp_render(x)
  ├── .validate_spec()          — 校验所有 spec 与数据的一致性
  ├── .apply_rules(x)           — 求值条件，写入 row_styles / cell_edits
  ├── .build_context(x)         — 计算行布局、掩码、条纹填充
  └── 遍历每个 spec：
        .fp_dispatch(spec)      — 从注册表查找构建器
        builder(ctx, spec, cell_edits)
              ↓
        .resolve_attr()         — 合并 spec 默认值 + fp_aes + row_styles + cell_edits
              ↓
        ggplot2 对象
  └── patchwork::wrap_plots()   — 拼合所有面板
  └── 分组标题组装               — 如有 add_header_group() 调用
```

---

## 对象模型

### `fp_plot`

| 字段 | 类型 | 说明 |
|------|------|------|
| `data` | data.frame | 输入数据框 |
| `specs` | fp_spec 列表 | 从左到右排列的面板规格 |
| `theme` | fp_theme | 主题对象 |
| `stripe_colors` | character 或 NULL | 交替条纹颜色 |
| `summary_rows` | integer 向量 | 汇总行索引 |
| `group_rows` | integer 向量 | 分组行索引 |
| `row_heights` | numeric 向量 | 逐行高度（长度 = nrow） |
| `header_height` | numeric | 标题行高度 |
| `row_styles` | 列表的列表 | 行级样式覆盖（由 `edit()` 和 `add_group()` 写入） |
| `cell_edits` | 列表的列表 | 面板 → 行 → 样式覆盖（由 `edit(panel = ...)` 写入） |
| `hlines` | 列表 | 水平线定义 |
| `header_groups` | 列表 | 跨列分组标题定义 |
| `rules` | fp_rule 列表 | 条件样式规则（由 `add_rule()` 写入，渲染时应用） |

### `fp_spec_*`

所有 spec 共享 `type` 和 `width` 字段。每个具体 spec 携带面板特有字段。类向量为 `c("fp_spec_<type>", "fp_spec")`。

### `fp_aes`

将美学名称（`colour`、`fill` 等）映射到列名字符串的命名列表，类为 `"fp_aes"`。

### `fp_rule`

| 字段 | 说明 |
|------|------|
| `when` | 公式、函数或逻辑向量——条件 |
| `panel` | NULL（行级）或面板标识符（单元格级） |
| `style` | 样式属性的命名列表 |
| `height` | 行高覆盖值或 NULL |
