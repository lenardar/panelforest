.fp_registry <- new.env(parent = emptyenv())

fp_register <- function(type, builder, overwrite = FALSE) {
  if (!is.character(type) || length(type) != 1L || !nzchar(type)) {
    rlang::abort("`type` must be a single non-empty string.")
  }

  if (!is.function(builder)) {
    rlang::abort("`builder` must be a function.")
  }

  if (exists(type, envir = .fp_registry, inherits = FALSE) && !isTRUE(overwrite)) {
    rlang::abort(sprintf("A builder for `%s` is already registered. Use `overwrite = TRUE` to replace it.", type))
  }

  assign(type, builder, envir = .fp_registry)
  invisible(type)
}

.fp_dispatch <- function(spec) {
  builder <- get0(spec$type, envir = .fp_registry, inherits = FALSE)
  if (is.null(builder)) {
    rlang::abort(sprintf("No builder has been registered for spec type `%s`.", spec$type))
  }

  builder
}

.register_builtin_builders <- function() {
  fp_register("text", .build_text, overwrite = TRUE)
  fp_register("text_ci", .build_text_ci, overwrite = TRUE)
  fp_register("gap", .build_gap, overwrite = TRUE)
  fp_register("spacer", .build_gap, overwrite = TRUE)
  fp_register("ci", .build_ci, overwrite = TRUE)
  fp_register("bar", .build_bar, overwrite = TRUE)
  fp_register("dot", .build_dot, overwrite = TRUE)
  fp_register("custom", .build_custom, overwrite = TRUE)
  invisible(NULL)
}
