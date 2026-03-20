#' Apply conditional styling to forest plot rows
#'
#' `add_rule()` lets you style rows based on a condition evaluated against the
#' plot data. The condition is evaluated at render time, so it always reflects
#' the current state of the data.
#'
#' @param x An `fp_plot` object created by [forest_plot()].
#' @param when A condition specifying which rows to style. One of:
#'   - A one-sided formula like `~ p_value < 0.05`, evaluated with column names
#'     in scope. Use `!!` to inject external variables: `~ value < !!threshold`.
#'   - A function `function(data) ...` that receives the full data frame and
#'     returns a logical vector of length `nrow(data)`.
#'   - A logical vector of length `nrow(data)`.
#' @param panel Optional. Target a specific panel for cell-level styling.
#'   A single numeric index or a panel identifier string (header or column name).
#'   If `NULL` (default), styles are applied at row level across all panels.
#' @param fontface Font face. One of `"plain"`, `"bold"`, `"italic"`,
#'   `"bold.italic"`.
#' @param colour Text or glyph colour as a colour string.
#' @param size Font size in points.
#' @param fill Background fill colour.
#' @param alpha Opacity between 0 and 1.
#' @param glyph CI glyph shape. One of `"point"` or `"diamond"`.
#' @param point_size Size of the CI centre point.
#' @param line_width Width of the CI whisker line.
#' @param shape Point shape (for dot panels).
#' @param label Override the displayed text label.
#' @param family Font family string.
#' @param height Row height in inches. Applied to matched rows.
#'
#' @return The modified `fp_plot` object.
#'
#' @seealso [edit()] for applying explicit row/cell edits by index.
#'
#' @examples
#' \dontrun{
#' df <- panelforest_example_data()
#'
#' # Bold rows where the confidence interval excludes 1 (log scale p < 0.05)
#' forest_plot(df) |>
#'   add_text("label", header = "Subgroup") |>
#'   add_ci("est", "lo", "hi", header = "HR (95% CI)") |>
#'   add_rule(~ p_value < 0.05, fontface = "bold", colour = "#b42318") |>
#'   fp_render()
#'
#' # Grey out rows with missing estimates
#' forest_plot(df) |>
#'   add_text("label", header = "Subgroup") |>
#'   add_ci("est", "lo", "hi", header = "HR (95% CI)") |>
#'   add_rule(function(data) !is.finite(data$est), colour = "grey70") |>
#'   fp_render()
#' }
#'
#' @export
add_rule <- function(
  x,
  when,
  panel = NULL,
  fontface = NULL,
  colour = NULL,
  size = NULL,
  fill = NULL,
  alpha = NULL,
  glyph = NULL,
  point_size = NULL,
  line_width = NULL,
  shape = NULL,
  label = NULL,
  family = NULL,
  height = NULL
) {
  .validate_fp_plot(x)

  # Validate `when`
  if (inherits(when, "formula")) {
    if (length(when) != 2L) {
      rlang::abort("`when` must be a one-sided formula, e.g. `~ p_value < 0.05`.")
    }
  } else if (!is.function(when) && !is.logical(when)) {
    rlang::abort(
      "`when` must be a one-sided formula (e.g. `~ p_value < 0.05`), a function, or a logical vector."
    )
  }

  if (!is.null(glyph)) {
    .validate_ci_glyph(glyph, arg = "glyph")
  }

  if (!is.null(alpha)) {
    .validate_alpha_values(alpha, arg = "alpha")
  }

  if (!is.null(height)) {
    if (!is.numeric(height) || !length(height) || anyNA(height) || any(height <= 0)) {
      rlang::abort("`height` must be a positive number.")
    }
    if (length(height) != 1L) {
      rlang::abort("`height` in `add_rule()` must be a single positive number.")
    }
  }

  updates <- list(
    fontface   = fontface,
    colour     = colour,
    size       = size,
    fill       = fill,
    alpha      = alpha,
    glyph      = glyph,
    point_size = point_size,
    line_width = line_width,
    shape      = shape,
    label      = label,
    family     = family
  )
  updates <- updates[!vapply(updates, is.null, logical(1))]

  if (!length(updates) && is.null(height)) {
    rlang::abort("`add_rule()` requires at least one style parameter.")
  }

  rule <- structure(
    list(when = when, panel = panel, style = updates, height = height),
    class = "fp_rule"
  )

  x$rules <- c(x$rules, list(rule))
  x
}

# Evaluate the `when` predicate and return matched row indices.
.evaluate_rule_when <- function(when, data) {
  n <- nrow(data)

  if (inherits(when, "formula")) {
    env <- rlang::f_env(when) %||% parent.frame()
    mask <- rlang::as_data_mask(data)
    result <- rlang::eval_tidy(rlang::f_rhs(when), data = mask, env = env)
  } else if (is.function(when)) {
    result <- when(data)
  } else {
    result <- when
  }

  if (!is.logical(result)) {
    rlang::abort("The condition in `add_rule()` must evaluate to a logical vector.")
  }

  if (length(result) != n) {
    rlang::abort(sprintf(
      "The condition in `add_rule()` evaluated to length %d but the data has %d rows.",
      length(result), n
    ))
  }

  if (anyNA(result)) {
    rlang::abort(
      "The condition in `add_rule()` produced NA values. ",
      "Ensure all comparisons handle missing data, e.g. `~ !is.na(x) & x > 0`."
    )
  }

  which(result)
}

# Apply all stored rules to the fp_plot object just before rendering.
#
# Precedence (lowest → highest):
#   spec defaults < fp_aes() < add_rule() < edit()
#
# Rules are applied in declaration order (later rule wins over earlier rule for
# the same attribute), then explicit edit() values are restored on top so that
# an explicit edit always beats any conditional rule.
.apply_rules <- function(x) {
  if (!length(x$rules)) {
    return(x)
  }

  # Snapshot the explicit edit() values so we can restore them after rules run.
  original_row_styles <- x$row_styles
  original_cell_edits <- x$cell_edits

  for (rule in x$rules) {
    matched <- .evaluate_rule_when(rule$when, x$data)

    if (!length(matched)) {
      next
    }

    # Apply height separately (stored in row_heights, not row_styles).
    # edit() does not currently support height via row_styles, so no conflict.
    if (!is.null(rule$height)) {
      x$row_heights[matched] <- rule$height
    }

    updates <- rule$style
    if (!length(updates)) {
      next
    }

    if (is.null(rule$panel)) {
      for (r in matched) {
        x$row_styles[[r]] <- utils::modifyList(x$row_styles[[r]] %||% list(), updates)
      }
    } else {
      panel_index <- .resolve_panel_index(x, rule$panel)
      for (r in matched) {
        panel_edits <- if (length(x$cell_edits) >= panel_index) x$cell_edits[[panel_index]] else NULL
        panel_edits <- panel_edits %||% vector("list", nrow(x$data))
        panel_edits[[r]] <- utils::modifyList(panel_edits[[r]] %||% list(), updates)
        x$cell_edits[[panel_index]] <- panel_edits
      }
    }
  }

  # Restore explicit edit() values on top: edit() wins over any rule.
  for (r in seq_along(original_row_styles)) {
    if (length(original_row_styles[[r]])) {
      x$row_styles[[r]] <- utils::modifyList(
        x$row_styles[[r]] %||% list(),
        original_row_styles[[r]]
      )
    }
  }

  for (panel_index in seq_along(original_cell_edits)) {
    orig_panel <- original_cell_edits[[panel_index]]
    if (!length(orig_panel)) next
    cur_panel <- if (length(x$cell_edits) >= panel_index) x$cell_edits[[panel_index]] else NULL
    cur_panel <- cur_panel %||% vector("list", nrow(x$data))
    for (r in seq_along(orig_panel)) {
      if (length(orig_panel[[r]])) {
        cur_panel[[r]] <- utils::modifyList(cur_panel[[r]] %||% list(), orig_panel[[r]])
      }
    }
    x$cell_edits[[panel_index]] <- cur_panel
  }

  x
}
