fp_fmt_number <- function(digits = 2, big_mark = "", prefix = "", suffix = "", na = "") {
  if (!is.numeric(digits) || length(digits) != 1L || is.na(digits) || digits < 0) {
    rlang::abort("`digits` must be a single non-negative number.")
  }

  force(digits)
  force(big_mark)
  force(prefix)
  force(suffix)
  force(na)

  function(values) {
    values <- as.numeric(values)
    out <- ifelse(
      is.na(values),
      na,
      paste0(
        prefix,
        formatC(values, format = "f", digits = digits, big.mark = big_mark),
        suffix
      )
    )
    as.character(out)
  }
}

fp_fmt_percent <- function(digits = 1, scale = 100, suffix = "%", prefix = "", na = "") {
  if (!is.numeric(scale) || length(scale) != 1L || is.na(scale)) {
    rlang::abort("`scale` must be a single numeric value.")
  }

  number_formatter <- fp_fmt_number(
    digits = digits,
    big_mark = "",
    prefix = prefix,
    suffix = suffix,
    na = na
  )

  function(values) {
    number_formatter(as.numeric(values) * scale)
  }
}

fp_fmt_pvalue <- function(digits = 3, threshold = 0.001, prefix = "p = ", na = "") {
  if (!is.numeric(digits) || length(digits) != 1L || is.na(digits) || digits < 0) {
    rlang::abort("`digits` must be a single non-negative number.")
  }

  if (!is.numeric(threshold) || length(threshold) != 1L || is.na(threshold) || threshold <= 0) {
    rlang::abort("`threshold` must be a single positive number.")
  }

  force(digits)
  force(threshold)
  force(prefix)
  force(na)

  function(values) {
    values <- as.numeric(values)
    out <- ifelse(
      is.na(values),
      na,
      ifelse(
        values < threshold,
        paste0(prefix, "< ", formatC(threshold, format = "f", digits = digits)),
        paste0(prefix, formatC(values, format = "f", digits = digits))
      )
    )
    as.character(out)
  }
}
