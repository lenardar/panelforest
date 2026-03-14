.onLoad <- function(libname, pkgname) {
  .register_builtin_builders()
}

utils::globalVariables(c("est", "group", "label", "lower", "upper", "value", "x", "y", "ymax", "ymin", "xmin", "xmax"))
