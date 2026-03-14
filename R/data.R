panelforest_example_data <- function(name = "classic") {
  if (!is.character(name) || length(name) != 1L || !nzchar(name)) {
    rlang::abort("`name` must be a single non-empty string.")
  }

  path <- switch(
    name,
    classic = system.file("extdata", "example_classic.csv", package = "panelforest"),
    ""
  )

  if (!nzchar(path)) {
    local_path <- switch(
      name,
      classic = file.path(getwd(), "inst", "extdata", "example_classic.csv"),
      ""
    )

    if (nzchar(local_path) && file.exists(local_path)) {
      path <- local_path
    }
  }

  if (!nzchar(path)) {
    rlang::abort(sprintf(
      "Unknown example dataset `%s`. Available datasets: %s.",
      name,
      "classic"
    ))
  }

  utils::read.csv(path, stringsAsFactors = FALSE)
}
