# panelforest API Reference

> Covers the full public API. Internal functions (prefixed with `.`) are excluded.
> Developer-facing sections (internals, object model) are appended at the end.

---

## Table of Contents

- [Core Workflow](#core-workflow)
- [Panel Spec Constructors](#panel-spec-constructors)
  - [fp_text() — text panel](#fp_text)
  - [fp_text_ci() — CI text panel](#fp_text_ci)
  - [fp_pair() — numeric pair panel](#fp_pair)
  - [fp_ci() — confidence interval panel](#fp_ci)
  - [fp_bar() — bar panel](#fp_bar)
  - [fp_dot() — dot panel](#fp_dot)
  - [fp_gap() — relative gap](#fp_gap)
  - [fp_spacer() — fixed spacer](#fp_spacer)
  - [fp_custom() — custom panel](#fp_custom)
- [Aesthetic Mappings](#aesthetic-mappings)
  - [fp_aes() — column-driven mapping](#fp_aes)
- [Panel Add Functions](#panel-add-functions)
- [Structural Decorations](#structural-decorations)
  - [add_stripe() — row stripes](#add_stripe)
  - [add_summary() — summary rows](#add_summary)
  - [add_group() — group title rows](#add_group)
  - [add_hline() — horizontal separator](#add_hline)
  - [add_header_group() — spanning parent headers](#add_header_group)
- [Edit Layer](#edit-layer)
  - [edit() — unified edit interface](#edit)
  - [add_rule() — conditional styling](#add_rule)
- [Themes](#themes)
- [Formatting Helpers](#formatting-helpers)
- [Extension API](#extension-api)
- [Data Helper](#data-helper)
- [Usage Examples](#usage-examples)
- [Migration from v0.1.0](#migration-from-v010)
- [Internal Implementation](#internal-implementation)
- [Object Model](#object-model)

---

## Core Workflow

### `forest_plot()`

Creates an `fp_plot` object — the starting point for all subsequent operations.

```r
forest_plot(data, theme = fp_theme_default(), row_height = 1, convert_na = FALSE)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `data` | data.frame | One row per forest plot row |
| `theme` | fp_theme | Controls global font, colour, and margins |
| `row_height` | positive number | Default row height in inches (including header); adjustable per row via `edit()` |
| `convert_na` | logical | If `TRUE`, converts the string `"NA"` in character columns to `NA_character_` |

Returns an `fp_plot` object. Supports pipe composition with `\|>`.

### `fp_render()`

Assembles the `fp_plot` into a patchwork object for display or saving.

```r
fp_render(x)
```

Returns a `patchwork` object. Can be printed directly or passed to `ggsave()`.

### `fp_size()`

Returns the recommended device width and height in inches.

```r
fp_size(x)
```

Returns a named numeric vector `c(width = ..., height = ...)`.

Width = sum of panel widths + 2 × margin. Height = sum of row heights + header height + header group heights (if any) + 2 × margin.

**Typical usage:**

```r
p    <- forest_plot(df) |> add_text("label") |> add_ci("est", "lwr", "upr")
size <- fp_size(p)
ggplot2::ggsave("plot.png", fp_render(p), width = size["width"], height = size["height"])
```

### `fp_save()`

One-liner save with auto-computed dimensions.

```r
fp_save(x, filename, width = NULL, height = NULL, dpi = 300, scale = 1, ...)
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `filename` | — | Output path; extension determines format |
| `width` / `height` | `fp_size()` values | Override auto-computed dimensions |
| `dpi` | 300 | Resolution |
| `scale` | 1 | Passed to `ggsave()` |
| `...` | — | Additional arguments passed to `ggsave()` |

```r
fp_save(plot_obj, "forest.png")
fp_save(plot_obj, "forest.png", dpi = 600, bg = "white")
```

### `print.fp_plot()`

S3 method. Automatically calls `fp_render()` when an `fp_plot` object is printed.

---

## Panel Spec Constructors

Each panel type has an `fp_*()` constructor returning an `fp_spec` object. These are typically called indirectly through `add_*()` functions.

<a id="fp_text"></a>
### `fp_text()` — text panel

Displays a character or numeric column as text.

```r
fp_text(
  col,                          # column name (required)
  header       = NULL,          # column header label
  width        = 1.5,           # width in inches
  align        = "left",        # content alignment: "left" / "center" / "right"
  header_align = NULL,          # header alignment (inherits align if NULL)
  indent       = NULL,          # column name or numeric vector for indentation depth
  indent_width = 0.08,          # width per indent level (0–1)
  formatter    = NULL,          # formatting function
  fontface     = NULL,          # "plain" / "bold" / "italic" / "bold.italic"
  colour       = NULL,          # text colour
  size         = NULL,          # font size in points
  mapping      = NULL           # fp_aes() mapping
)
```

**Indentation:**

```r
add_text("label", indent = "level")   # "level" column: 0, 1, 1, 2, ...
add_text("label", indent = 1)         # fixed indent for all rows
```

**Formatter:**

```r
add_text("n_events", formatter = fp_fmt_number())
add_text("value",    formatter = function(values) paste0(values, "%"))
```

The formatter receives `(values, data)` where `values` is the column vector and `data` is the full data frame.

<a id="fp_text_ci"></a>
### `fp_text_ci()` — CI text panel

Formats three columns (estimate, lower, upper) as `"est (lower, upper)"`.

```r
fp_text_ci(
  est, lower, upper,            # column names (required)
  header       = NULL,
  width        = 2.5,
  digits       = 2,             # decimal places
  prefix       = "",            # prefix string (e.g. "HR = ")
  suffix       = "",            # suffix string
  na           = "",            # string for NA rows
  align        = "left",
  header_align = NULL,
  fontface     = NULL,
  colour       = NULL,
  size         = NULL,
  mapping      = NULL
)
```

**Example:** `digits = 2` → `"0.92 (0.74, 1.14)"`

<a id="fp_pair"></a>
### `fp_pair()` — numeric pair panel

Formats two or more numeric columns into a single text column.

```r
fp_pair(
  cols,                         # character vector of column names (required, length >= 1)
  format       = "fraction",    # "fraction" / "percent" / function(data, cols)
  header       = NULL,
  width        = 1.5,
  digits       = 0,             # integer or integer vector, recycled to length(cols)
  pct_digits   = 1,             # decimal places for computed percentage (percent mode)
  sep          = "/",           # separator for fraction mode
  na           = "",            # string for NA rows
  align        = "right",
  header_align = NULL,
  fontface     = NULL,
  colour       = NULL,
  size         = NULL,
  mapping      = NULL
)
```

**Three `format` modes:**

| Mode | Output | Notes |
|------|--------|-------|
| `"fraction"` (default) | `"42/100"` | All cols joined by `sep`; supports 2+ cols |
| `"percent"` | `"42 (42.0%)"` | Requires exactly 2 cols; percentage is auto-computed |
| `function(data, cols)` | custom | Receives full data frame and column names vector; returns character vector |

**`digits` vector:**

```r
add_pair(c("events", "total"), digits = 0)                    # "42/100"
add_pair(c("mean", "sd"), sep = " ± ", digits = c(1, 2))      # "3.4 ± 0.56"
```

<a id="fp_ci"></a>
### `fp_ci()` — confidence interval panel

Draws point estimate + whisker line. Supports diamond glyphs, truncation arrows, and log scale.

```r
fp_ci(
  est, lower, upper,            # column names (required)
  header        = NULL,
  header_align  = "center",
  width         = 3,
  ref_line      = 1,            # reference line position (typically 1 on log scale)
  trans         = "identity",   # "identity" or "log"
  xlim          = NULL,         # display range c(min, max)
  truncate      = NULL,         # truncation range c(min, max); values outside show arrows
  show_axis     = FALSE,        # show bottom axis
  axis_label    = NULL,         # axis title
  favors_left   = NULL,         # directional label left of ref line
  favors_right  = NULL,         # directional label right of ref line
  labels        = NULL,         # custom tick labels
  colour        = NULL,
  fill          = NULL,         # fill colour (diamond only)
  alpha         = 0.9,
  glyph         = "point",      # default glyph: "point" or "diamond"
  summary_glyph = "diamond",    # glyph for summary rows (NULL keeps default)
  shape         = 19,           # point shape (ggplot2 pch)
  point_size    = NULL,
  line_width    = 0.6,
  breaks        = NULL,
  mapping       = NULL
)
```

**`xlim` vs `truncate`:**

- `xlim` sets the axis display range
- `truncate` clips CI lines; values outside the range show truncation arrows
- They can differ: `xlim = c(0.1, 10), truncate = c(0.5, 5)` shows axis from 0.1–10 but arrows appear outside 0.5–5

**Log scale note:** When `trans = "log"`, all of `est`, `lower`, `upper`, `ref_line`, `xlim`, `truncate`, and `breaks` must be positive.

<a id="fp_bar"></a>
### `fp_bar()` — bar panel

Draws a horizontal bar proportional to a numeric column.

```r
fp_bar(
  col,                          # numeric column name (required)
  header       = NULL,
  header_align = "center",
  width        = 2,
  baseline     = 0,             # bar origin
  fill         = "#a8c5b8",
  colour       = NA,            # border colour
  alpha        = 1,
  xlim         = NULL,
  breaks       = NULL
)
```

<a id="fp_dot"></a>
### `fp_dot()` — dot panel

Plots a point estimate with optional error bars; suitable for continuous outcomes.

```r
fp_dot(
  col,                          # numeric column name (required)
  lower        = NULL,          # lower bound column (paired with upper)
  upper        = NULL,
  header       = NULL,
  header_align = "center",
  width        = 2.5,
  ref_line     = NULL,
  trans        = "identity",
  truncate     = NULL,
  colour       = NULL,
  fill         = "#ffffff",
  shape        = 21,
  point_size   = NULL,
  line_width   = 0.6,
  breaks       = NULL
)
```

<a id="fp_gap"></a>
### `fp_gap()` — relative gap

Inserts a proportional-width empty column between panels.

```r
fp_gap(width = 0.2, header = NULL, header_align = "center")
```

<a id="fp_spacer"></a>
### `fp_spacer()` — fixed spacer

Inserts a column with a fixed physical width.

```r
fp_spacer(width = 4, unit = "mm", header = NULL, header_align = "center")
```

| Parameter | Description |
|-----------|-------------|
| `width` | Numeric width |
| `unit` | grid unit string: `"mm"`, `"cm"`, `"in"`, `"pt"` |

**`fp_gap` vs `fp_spacer`:** Gap participates in proportional layout; spacer is a fixed physical width.

<a id="fp_custom"></a>
### `fp_custom()` — custom panel

Inserts a user-defined ggplot panel.

```r
fp_custom(
  plot_fn,                      # function returning a ggplot object (required)
  header       = NULL,
  width        = 1.5,
  header_x     = 0.5,
  header_align = "center"
)
```

`plot_fn` may accept any subset of: `data`, `spec`, `n_rows`, `row_heights`, `theme`.

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

forest_plot(df) |> add_text("label") |> add_custom(pval_panel) |> fp_render()
```

---

<a id="fp_aes"></a>
## Aesthetic Mappings

### `fp_aes()` — column-driven mapping

Maps data columns to visual properties, replacing the old `colour_by`, `fill_by` parameters.

```r
fp_aes(
  colour     = NULL,    # column name for colour
  fill       = NULL,    # column name for fill
  alpha      = NULL,    # column name for alpha (numeric)
  glyph      = NULL,    # column name for glyph ("point" / "diamond")
  shape      = NULL,    # column name for shape (numeric)
  point_size = NULL,    # column name for point size (numeric)
  line_width = NULL,    # column name for line width (numeric)
  fontface   = NULL,    # column name for fontface
  size       = NULL     # column name for text size (numeric)
)
```

All parameters are strings (column names). Returns an `fp_aes` object.

**Supported mappings by panel type:**

| Panel type | Available mappings |
|------------|--------------------|
| `fp_ci()` | colour, fill, alpha, glyph, shape, point_size, line_width |
| `fp_text()` | fontface, colour, size |
| `fp_text_ci()` | fontface, colour, size |
| `fp_pair()` | fontface, colour, size |

---

## Panel Add Functions

Pipe-friendly wrappers around the `fp_*()` constructors:

| Function | Constructor | Description |
|----------|-------------|-------------|
| `add_text(x, ...)` | `fp_text()` | Add text panel |
| `add_text_ci(x, ...)` | `fp_text_ci()` | Add CI text panel |
| `add_pair(x, ...)` | `fp_pair()` | Add numeric pair panel |
| `add_ci(x, ...)` | `fp_ci()` | Add confidence interval panel |
| `add_bar(x, ...)` | `fp_bar()` | Add bar panel |
| `add_dot(x, ...)` | `fp_dot()` | Add dot panel |
| `add_gap(x, ...)` | `fp_gap()` | Add relative gap |
| `add_spacer(x, ...)` | `fp_spacer()` | Add fixed spacer |
| `add_custom(x, spec)` | — | Add custom panel (spec created by `fp_custom()`) |

`x` is an `fp_plot` object; `...` is forwarded to the constructor.

---

## Structural Decorations

<a id="add_stripe"></a>
### `add_stripe()` — row stripes

Sets alternating row background colours.

```r
add_stripe(x, colors)
```

| Parameter | Description |
|-----------|-------------|
| `colors` | Character vector of at least two colours, applied cyclically |

```r
add_stripe(c("white", "#f4f7f5"))            # white / light-green alternating
add_stripe(c("white", "#f0f0f0", "#e8e8e8")) # three-colour cycle
```

<a id="add_summary"></a>
### `add_summary()` — summary rows

Marks rows as summary rows: text is bolded automatically, and the CI glyph switches to a diamond.

```r
add_summary(x, rows)
```

<a id="add_group"></a>
### `add_group()` — group title rows

Marks rows as group header rows: text is bolded and enlarged; CI/dot glyphs are suppressed.

```r
add_group(x, rows, fontface = "bold", size = NULL, colour = NULL, fill = NULL)
```

| Parameter | Description |
|-----------|-------------|
| `rows` | Row indices |
| `fontface` | Font face (default `"bold"`) |
| `size` | Font size override |
| `colour` | Text colour override |
| `fill` | Row background colour |

```r
add_group(c(1, 8), fill = "#f0f4f1")
```

<a id="add_hline"></a>
### `add_hline()` — horizontal separator

Draws a thin rule below the specified rows, spanning all panels.

```r
add_hline(x, rows, colour = "#d9dde2", linewidth = 0.45, linetype = 1)
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `rows` | — | Rule is drawn below these rows |
| `colour` | `"#d9dde2"` | Line colour |
| `linewidth` | 0.45 | Line width |
| `linetype` | 1 | Line type (1 = solid, 2 = dashed, …) |

<a id="add_header_group"></a>
### `add_header_group()` — spanning parent headers

Adds parent headers above the panel header row. Levels are auto-detected — groups containing other groups are placed higher.

```r
add_header_group(
  x,
  label,                         # header text (required)
  panels,                        # panel indices spanned, must be contiguous (e.g. 1:3)
  align           = "center",
  fontface        = "bold",
  colour          = NULL,
  size            = NULL,
  family          = NULL,
  background      = NULL,
  height          = NULL,
  border          = FALSE,
  border_colour   = "#d0d7de",
  border_linewidth = 0.4
)
```

**Auto level detection:**

```r
add_header_group("Treatment", panels = 1:2)   # → level 1
add_header_group("Arms",      panels = 1:3)   # contains Treatment → level 2
```

Same-level groups must not overlap (validated at render time). Panel indices are validated at render time.

---

## Edit Layer

<a id="edit"></a>
### `edit()` — unified edit interface

Replaces the old `edit_cell()`, `add_row_style()`, and `add_row_height()`.

```r
edit(
  x,
  row,                          # row index or vector
  panel      = NULL,            # panel identifier (NULL = row-level)
  fontface   = NULL,
  colour     = NULL,
  size       = NULL,
  fill       = NULL,
  alpha      = NULL,
  glyph      = NULL,            # "point" / "diamond"
  point_size = NULL,
  line_width = NULL,
  shape      = NULL,
  label      = NULL,            # override display text
  family     = NULL,
  height     = NULL             # row height in inches
)
```

**Three modes:**

| Mode | Condition | Effect |
|------|-----------|--------|
| Row-level | `panel = NULL` | Style applied across all panels in the row |
| Cell-level | `panel` specified | Style applied to that panel only |
| Height | `height` set | Modifies row height (independent of `panel`) |

All three modes can be combined in one call.

**Panel identifier forms:**

- Integer index: `panel = 2`
- Header string: `panel = "Hazard Ratio"`
- Column name string: `panel = "est"`

<a id="add_rule"></a>
### `add_rule()` — conditional styling

Applies styles to rows matching a data condition, evaluated at render time. The declarative alternative to looking up row indices and calling `edit()` manually.

```r
add_rule(
  x,
  when,                         # condition (required, see below)
  panel      = NULL,            # panel identifier (NULL = row-level)
  fontface   = NULL,
  colour     = NULL,
  size       = NULL,
  fill       = NULL,
  alpha      = NULL,
  glyph      = NULL,
  point_size = NULL,
  line_width = NULL,
  shape      = NULL,
  label      = NULL,
  family     = NULL,
  height     = NULL
)
```

**Three `when` forms:**

| Form | Example | Notes |
|------|---------|-------|
| One-sided formula | `~ p_value < 0.05` | Column names are in scope; use `!!` to inject external variables |
| Function | `function(data) data$p < 0.05` | Receives full data frame; must return a logical vector |
| Logical vector | `c(TRUE, FALSE, TRUE)` | Length must equal `nrow(data)` |

**Precedence (low → high):**

```
spec defaults  <  fp_aes()  <  add_rule()  <  edit()
```

Multiple rules are applied in declaration order (later rule wins over earlier for the same attribute). Explicit `edit()` calls always win over any rule.

```r
forest_plot(df) |>
  add_text("label", header = "Subgroup") |>
  add_ci("est", "lwr", "upr", header = "HR (95% CI)", trans = "log") |>
  add_rule(~ p_value < 0.05, fontface = "bold", colour = "#b42318") |>
  add_rule(~ is.na(est),     colour = "grey60") |>
  fp_render()
```

---

## Themes

### `fp_theme_default()`

```r
fp_theme_default(
  base_family     = "",
  text_size       = 3.6,
  text_colour     = "#1f1f1f",
  header_size     = 3.8,
  header_fontface = "bold",
  header_colour   = "#1f1f1f",
  refline_colour  = "#9aa1a6",
  stripe_alpha    = 1,
  plot_margin     = 4            # outer margin in points
)
```

### `fp_theme_journal()`

Journal style: serif font, slightly smaller text, tighter margins.

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

## Formatting Helpers

Factory functions returning a formatter suitable for the `formatter` argument of `add_text()`.

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

## Extension API

### `fp_register()`

Registers a custom builder into the internal registry.

```r
fp_register(type, builder, overwrite = FALSE)
```

| Parameter | Description |
|-----------|-------------|
| `type` | Spec type string |
| `builder` | Function with signature `function(ctx, spec, cell_edits)`, returns a ggplot object |
| `overwrite` | Whether to overwrite an existing registration |

**BuildContext (`ctx`) fields:**

| Field | Description |
|-------|-------------|
| `ctx$data` | Data frame |
| `ctx$n_rows` | Number of rows |
| `ctx$row_heights` | Row height vector |
| `ctx$layout` | Row layout (ymin, ymax, centers, …) |
| `ctx$row_styles` | Row-level style override list |
| `ctx$summary_mask` | Logical vector for summary rows |
| `ctx$group_mask` | Logical vector for group rows |
| `ctx$hlines` | Horizontal line list |
| `ctx$theme` | Theme object |

---

## Data Helper

### `panelforest_example_data()`

```r
panelforest_example_data(name = "classic")
```

Currently only `"classic"` is available:

| Column | Type | Description |
|--------|------|-------------|
| `label` | character | Subgroup name |
| `n_events` | integer | Event count |
| `HR` | numeric | Hazard ratio (point estimate) |
| `LCI` | numeric | 95% CI lower bound |
| `UCI` | numeric | 95% CI upper bound |
| `hr_ci` | character | Pre-formatted HR (CI) string |

---

## Usage Examples

### Basic forest plot

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

### Aesthetic mappings and cell edits

```r
df$ci_colour <- c("#111827", "#1d4ed8", "#1d4ed8", "#111827", "#b42318")
df$ci_fill   <- c("#d1d5db", "#bfdbfe", "#bfdbfe", "#d1d5db", "#fecaca")

forest_plot(df, theme = fp_theme_journal()) |>
  add_stripe(c("white", "#f5f7f6")) |>
  add_summary(1) |>
  add_hline(1) |>
  add_text("label", header = "Subgroup", width = 2.5,
           align = "left", header_align = "center") |>
  add_ci("HR", "LCI", "UCI", header = "Hazard Ratio",
         trans = "log", width = 3,
         mapping = fp_aes(colour = "ci_colour", fill = "ci_fill")) |>
  add_text_ci("HR", "LCI", "UCI", header = "HR (95% CI)",
              width = 2.5, align = "left", header_align = "center") |>
  edit(row = 1, panel = "Hazard Ratio", glyph = "diamond", fill = "#dbeafe") |>
  fp_render()
```

### Numeric pair columns

```r
forest_plot(df) |>
  add_text("label", header = "Subgroup", width = 1.8) |>
  add_pair(c("events", "total"),
           header = "Events/N", digits = 0, width = 0.9) |>
  add_pair(c("events", "total"),
           format = "percent", header = "Events (%)",
           digits = 0, pct_digits = 1, width = 1.1) |>
  add_ci("HR", "LCI", "UCI", header = "Hazard Ratio", trans = "log") |>
  fp_render()
```

### Conditional styling with `add_rule()`

```r
forest_plot(df) |>
  add_text("label", header = "Subgroup") |>
  add_ci("HR", "LCI", "UCI", header = "HR (95% CI)", trans = "log") |>
  add_rule(~ p_value < 0.05, fontface = "bold", colour = "#b42318") |>
  add_rule(~ is.na(HR), colour = "grey60") |>
  fp_render()
```

### Spanning header groups

```r
forest_plot(df) |>
  add_stripe(c("white", "#f8f9fa")) |>
  add_text("label",    header = "Subgroup",   width = 2.2) |>
  add_text("n_events", header = "Events",     width = 0.8, align = "center") |>
  add_text("hr_ci",    header = "HR (95% CI)",width = 1.8, align = "center") |>
  add_ci("HR", "LCI", "UCI", header = "Hazard Ratio",
         trans = "log", width = 3, show_axis = TRUE) |>
  add_header_group("Statistics", panels = 3:4, border = TRUE) |>
  add_header_group("Results",    panels = 3:6, border = TRUE) |>
  fp_render()
```

### Saving

```r
p    <- forest_plot(df) |> add_text("label") |> add_ci("HR", "LCI", "UCI", trans = "log")
size <- fp_size(p)
ggplot2::ggsave("forest.pdf", fp_render(p), width = size["width"], height = size["height"])

# Or use fp_save() for a one-liner
fp_save(p, "forest.png")
fp_save(p, "forest.png", dpi = 600, bg = "white")
```

---

## Migration from v0.1.0

| v0.1.0 | v0.2.0+ |
|--------|---------|
| `add_summary_rows(rows)` | `add_summary(rows)` |
| `add_group_rows(rows, ...)` | `add_group(rows, ...)` |
| `add_hline(fp_hline(rows, ...))` | `add_hline(rows, ...)` |
| `edit_cell(row, panel, ...)` | `edit(row, panel, ...)` |
| `add_row_style(rows, ...)` | `edit(row, ...)` with `panel = NULL` |
| `add_row_height(rows, height)` | `edit(row, height = h)` |
| `colour_by = "col"` | `mapping = fp_aes(colour = "col")` |
| `fill_by = "col"` | `mapping = fp_aes(fill = "col")` |
| `hjust = 0` | `align = "left"` |
| `header_hjust = 0.5` | `header_align = "center"` |
| `fp_layout(...)` | Removed — use `add_*()` directly |
| `plot$layout$specs` | `plot$specs` |

---

## Internal Implementation

> For contributors and advanced users. Do not write external code that depends on these internals — they may change without notice.

### File map

| File | Role |
|------|------|
| `constants.R` | Named constants (magic numbers, defaults) |
| `validate.R` | Input validators shared across the package |
| `geometry.R` | Row layout, coordinate system, panel ggplot themes |
| `style.R` | `.resolve_attr()` — style resolution pipeline |
| `build_context.R` | `.build_context()` factory; summary/group masks |
| `ci_helpers.R` | CI math: limits, truncation, diamond geometry |
| `header_group.R` | Header group logic: level detection, validation, assembly |
| `panel.R` | Panel finalization: stripes, hlines, header row |
| `builders.R` | All 8 built-in builders (text, text_ci, pair, gap, ci, bar, dot, custom) |
| `rule.R` | `add_rule()`, `.evaluate_rule_when()`, `.apply_rules()` |
| `registry.R` | Builder registry (`fp_register`, `.fp_dispatch`) |

### Style resolution order

For each rendered cell, attributes are resolved in this priority order (lowest → highest):

1. Spec-level defaults (set in `fp_*()` constructor)
2. `fp_aes()` column-driven mappings
3. `add_rule()` conditional overrides (applied at render time, later rules win)
4. `edit()` explicit overrides (always win — re-applied on top of rules)

### Rendering pipeline

```
fp_render(x)
  ├── .validate_spec()          — validate all specs against data
  ├── .apply_rules(x)           — evaluate conditions, write into row_styles / cell_edits
  ├── .build_context(x)         — compute row layout, masks, stripe fills
  └── for each spec:
        .fp_dispatch(spec)      — look up builder in registry
        builder(ctx, spec, cell_edits)
              ↓
        .resolve_attr()         — merge spec defaults + fp_aes + row_styles + cell_edits
              ↓
        ggplot2 object
  └── patchwork::wrap_plots()   — assemble panels
  └── header group assembly     — if add_header_group() was called
```

---

## Object Model

### `fp_plot`

| Field | Type | Description |
|-------|------|-------------|
| `data` | data.frame | Input data |
| `specs` | list of fp_spec | Panel specs in left-to-right order |
| `theme` | fp_theme | Theme object |
| `stripe_colors` | character or NULL | Alternating stripe colours |
| `summary_rows` | integer vector | Summary row indices |
| `group_rows` | integer vector | Group row indices |
| `row_heights` | numeric vector | Per-row heights (length = nrow) |
| `header_height` | numeric | Header row height |
| `row_styles` | list of lists | Row-level style overrides (written by `edit()` and `add_group()`) |
| `cell_edits` | list of lists | Panel → row → style overrides (written by `edit(panel = ...)`) |
| `hlines` | list | Horizontal line definitions |
| `header_groups` | list | Spanning header group definitions |
| `rules` | list of fp_rule | Conditional style rules (written by `add_rule()`, applied at render time) |

### `fp_spec_*`

All specs share `type` and `width`. Each concrete spec carries panel-specific fields. The class vector is `c("fp_spec_<type>", "fp_spec")`.

### `fp_aes`

A named list mapping aesthetic names (`colour`, `fill`, …) to column name strings. Class: `"fp_aes"`.

### `fp_rule`

| Field | Description |
|-------|-------------|
| `when` | Formula, function, or logical vector — the condition |
| `panel` | NULL (row-level) or panel identifier (cell-level) |
| `style` | Named list of style attributes |
| `height` | Row height override or NULL |
