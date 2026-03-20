.append_spec <- function(x, spec) {
  .validate_fp_plot(x)
  x$specs <- c(x$specs, list(spec))
  x
}

add_text <- function(x, ...) {
  .append_spec(x, fp_text(...))
}

add_text_ci <- function(x, ...) {
  .append_spec(x, fp_text_ci(...))
}

add_gap <- function(x, ...) {
  .append_spec(x, fp_gap(...))
}

add_spacer <- function(x, ...) {
  .append_spec(x, fp_spacer(...))
}

add_bar <- function(x, ...) {
  .append_spec(x, fp_bar(...))
}

add_dot <- function(x, ...) {
  .append_spec(x, fp_dot(...))
}

add_ci <- function(x, ...) {
  .append_spec(x, fp_ci(...))
}

add_pair <- function(x, ...) {
  .append_spec(x, fp_pair(...))
}

add_custom <- function(x, spec) {
  .validate_fp_plot(x)

  if (!inherits(spec, "fp_spec_custom")) {
    rlang::abort("`spec` must be created by `fp_custom()`.")
  }

  .append_spec(x, spec)
}
