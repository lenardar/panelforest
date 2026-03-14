.resolve_ci_limits <- function(spec, est, lower, upper) {
  if (!is.null(spec$xlim)) {
    return(spec$xlim)
  }

  values <- c(est, lower, upper)
  values <- values[is.finite(values)]

  if (spec$trans == "log") {
    values <- values[values > 0]
  }

  if (!length(values)) {
    rlang::abort("Unable to infer x-axis limits from the CI columns.")
  }

  rng <- range(values)
  if (diff(rng) == 0) {
    if (spec$trans == "log") {
      rng <- rng * c(RANGE_LOG_SHRINK, RANGE_LOG_EXPAND)
    } else {
      rng <- rng + c(-RANGE_LINEAR_PAD, RANGE_LINEAR_PAD)
    }
  }

  rng
}

.resolve_ci_truncate <- function(spec, limits) {
  spec$truncate %||% limits
}

.clip_ci_values <- function(values, limits) {
  pmin(pmax(values, limits[1]), limits[2])
}

.header_anchor_for_limits <- function(limits, trans = "identity", hjust = 0.5) {
  if (!is.numeric(limits) || length(limits) != 2L || anyNA(limits)) {
    return(0.5)
  }

  if (hjust <= 0) {
    return(limits[1])
  }

  if (hjust >= 1) {
    return(limits[2])
  }

  if (identical(trans, "log")) {
    if (any(limits <= 0)) {
      return(mean(limits))
    }
    return(sqrt(limits[1] * limits[2]))
  }

  mean(limits)
}

.ci_diamond_half_height <- function(point_size, row_height) {
  pmin(row_height * DIAMOND_MAX_HEIGHT_RATIO, DIAMOND_BASE_OFFSET + point_size * DIAMOND_SIZE_SCALE)
}

.build_ci_diamond_data <- function(ci_data, row_heights) {
  if (!nrow(ci_data)) {
    return(NULL)
  }

  diamond_height <- .ci_diamond_half_height(
    point_size = ci_data$point_size,
    row_height = row_heights[ci_data$row_id]
  )

  pieces <- lapply(
    seq_len(nrow(ci_data)),
    function(i) {
      data.frame(
        group = ci_data$row_id[[i]],
        x = c(ci_data$lower[[i]], ci_data$est[[i]], ci_data$upper[[i]], ci_data$est[[i]]),
        y = c(
          ci_data$y[[i]],
          ci_data$y[[i]] + diamond_height[[i]],
          ci_data$y[[i]],
          ci_data$y[[i]] - diamond_height[[i]]
        ),
        colour = rep(ci_data$colour[[i]], 4),
        fill = rep(ci_data$fill[[i]], 4),
        alpha = rep(ci_data$alpha[[i]], 4),
        line_width = rep(ci_data$line_width[[i]], 4)
      )
    }
  )

  do.call(rbind, pieces)
}

.format_ci_text <- function(est, lower, upper, digits, prefix = "", suffix = "", na = "") {
  fmt <- function(x) formatC(x, format = "f", digits = digits)
  na_mask <- is.na(est) | is.na(lower) | is.na(upper)
  ifelse(na_mask, na, paste0(prefix, fmt(est), " (", fmt(lower), ", ", fmt(upper), ")", suffix))
}
