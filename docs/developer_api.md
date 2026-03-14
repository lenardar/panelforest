# panelforest v0.2.0 Developer API Map

This note separates the package into three layers:

- Stable user-facing API: safe to document, demo, and evolve conservatively.
- Extension API: intended for advanced users and future custom panels.
- Internal implementation: subject to change and should not be relied on outside the package.

## 1. Stable User-Facing API

### Plot construction

- `forest_plot(data, theme = fp_theme_default(), row_height = 1)`
- `fp_render(x)`
- `fp_size(x, ...)`

### Panel spec constructors

- `fp_text()`, `fp_text_ci()`, `fp_gap()`, `fp_spacer()`
- `fp_bar()`, `fp_dot()`, `fp_ci()`
- `fp_aes()` — column-to-aesthetic mapping object

### Plot mutation helpers

- `add_text()`, `add_text_ci()`, `add_gap()`, `add_spacer()`
- `add_bar()`, `add_dot()`, `add_ci()`, `add_custom()`
- `add_stripe()`, `add_summary()`, `add_group()`, `add_hline()`
- `add_header_group()` — spanning parent headers with auto-leveling
- `edit()` — unified row/cell/height editing

### Theme and formatting helpers

- `fp_theme_default()`, `fp_theme_journal()`
- `fp_fmt_number()`, `fp_fmt_percent()`, `fp_fmt_pvalue()`

### Data helper

- `panelforest_example_data()`

## 2. Extension API

### Builder registry

- `fp_register(type, builder, overwrite = FALSE)`

Builders receive `(ctx, spec, cell_edits)` where `ctx` is a BuildContext list.

### Custom panels

- `fp_custom(plot_fn, ...)` + `add_custom(x, spec)`

`plot_fn` may accept any subset of `data`, `spec`, `n_rows`, `row_heights`, `theme`.

## 3. Internal Implementation

Files and their roles:

| File | Role |
|------|------|
| `constants.R` | Named constants (magic numbers) |
| `validate.R` | Input validators |
| `geometry.R` | Row layout, coordinate system, panel themes |
| `style.R` | `.resolve_attr()`, style resolution pipeline |
| `build_context.R` | BuildContext factory, summary/group masks |
| `ci_helpers.R` | CI math: limits, truncation, diamonds |
| `header_group.R` | Header group logic: levels, validation, assembly |
| `panel.R` | Panel finalization: stripes, hlines, headers |
| `builders.R` | All 7 builders (text, text_ci, gap, ci, bar, dot, custom) |

Internal rules:

- Do not document these as public usage.
- Do not write external code that depends on them.
- It is safe to refactor them when internal geometry or rendering needs change.

## 4. Object Model

### `fp_plot`

- `data` — input data.frame
- `specs` — flat list of `fp_spec` objects (no `fp_layout` wrapper)
- `theme` — `fp_theme`
- `stripe_colors` — character vector or NULL
- `summary_rows` — integer vector
- `group_rows` — integer vector
- `row_heights` — numeric vector (length = nrow)
- `row_styles` — list of lists (row-level overrides)
- `cell_edits` — list of lists (panel → row → overrides)
- `hlines` — list of `fp_hline` objects
- `header_groups` — list of header group definitions

### `fp_spec_*`

All specs share `type` and `width`. Each concrete spec carries panel-specific fields.

### `fp_aes`

A named list mapping aesthetic names to column names, with class `"fp_aes"`.

## 5. Changes from v0.1.0

- Removed: `fp_layout()`, `add_summary_rows()`, `add_group_rows()`, `add_row_style()`, `add_row_height()`, `edit_cell()`, `fp_hline()` (as export)
- Added: `fp_aes()`, `add_summary()`, `add_group()`, `edit()`
- Added: `add_header_group()` — spanning parent headers with auto-leveling and nesting
- Changed: `add_hline()` now takes rows + params directly
- Changed: `_by` params replaced by `mapping = fp_aes(...)`
- Changed: `hjust`/`header_hjust` replaced by `align`/`header_align` strings
- Structural: `plot$layout$specs` → `plot$specs`
- Builder signatures: 11 params → 3 params `(ctx, spec, cell_edits)`
