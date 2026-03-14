\name{specs}
\alias{fp_text}
\alias{fp_text_ci}
\alias{fp_gap}
\alias{fp_spacer}
\alias{fp_bar}
\alias{fp_dot}
\alias{fp_ci}
\alias{fp_custom}
\alias{fp_aes}
\title{Panel Spec Constructors}
\usage{
fp_text(col, header = NULL, width = 1.5, align = "left",
        header_align = NULL, indent = NULL, indent_width = 0.08,
        formatter = NULL, fontface = NULL, colour = NULL,
        size = NULL, mapping = NULL)

fp_text_ci(est, lower, upper, header = NULL, width = 2.5,
           digits = 2, prefix = "", suffix = "", na = "",
           align = "left", header_align = NULL,
           fontface = NULL, colour = NULL, size = NULL,
           mapping = NULL)

fp_gap(width = 0.2, header = NULL, header_align = "center")

fp_spacer(width = 4, unit = "mm", header = NULL,
          header_align = "center")

fp_bar(col, header = NULL, header_align = "center", width = 2,
       baseline = 0, fill = BAR_DEFAULT_FILL, colour = NA_character_,
       alpha = 1, xlim = NULL, breaks = NULL)

fp_dot(col, lower = NULL, upper = NULL, header = NULL,
       header_align = "center", width = 2.5, ref_line = NULL,
       trans = c("identity", "log"), truncate = NULL,
       colour = NULL, fill = DOT_DEFAULT_FILL, shape = DOT_DEFAULT_SHAPE,
       point_size = NULL, line_width = CI_DEFAULT_LINE_WIDTH,
       breaks = NULL)

fp_ci(est, lower, upper, header = NULL, header_align = "center",
      width = 3, ref_line = CI_DEFAULT_REF_LINE,
      trans = c("identity", "log"),
      xlim = NULL, truncate = NULL, show_axis = FALSE,
      axis_label = NULL, favors_left = NULL, favors_right = NULL,
      labels = NULL, colour = NULL,
      fill = NULL, alpha = CI_DEFAULT_ALPHA, glyph = "point",
      summary_glyph = "diamond", shape = CI_DEFAULT_SHAPE,
      point_size = NULL, line_width = CI_DEFAULT_LINE_WIDTH,
      breaks = NULL, mapping = NULL,
      favors_span = FAVORS_ARROW_SPAN, favors_gap = FALSE,
      arrow_length = ARROW_LENGTH_INCHES,
      arrow_type = ARROW_TYPE, arrow_angle = ARROW_ANGLE)

fp_custom(plot_fn, header = NULL, width = 1.5, header_x = 0.5,
          header_align = "center")

fp_aes(colour = NULL, fill = NULL, alpha = NULL, glyph = NULL,
       shape = NULL, point_size = NULL, line_width = NULL,
       fontface = NULL, size = NULL)
}
\arguments{
\item{col}{Column name in the data frame.}

\item{est, lower, upper}{Column names for the point estimate, lower bound,
and upper bound.}

\item{header}{Optional header label displayed above the panel.}

\item{width}{Width in inches (for proportional panels) or absolute width
(for spacers, in units given by \code{unit}).}

\item{align}{Content alignment: \code{"left"}, \code{"center"}, or
\code{"right"}.}

\item{header_align}{Header alignment. Defaults to inheriting from
\code{align} for text panels or \code{"center"} for other panels.}

\item{indent}{Column name or numeric vector for indentation depth.}

\item{indent_width}{Width of one indentation level (0--1 scale).}

\item{formatter}{A function applied to the column values before display.}

\item{fontface, colour, size}{Static style overrides (scalar or vector).}

\item{mapping}{An \code{fp_aes} object mapping data columns to visual
properties. See \code{fp_aes}.}

\item{digits}{Number of decimal places for CI text formatting.}

\item{prefix, suffix}{Strings prepended/appended to each formatted CI.}

\item{na}{String used in place of missing values in CI text panels
(default \code{""}).}

\item{unit}{Grid unit string for spacer width, e.g. \code{"mm"}.}

\item{baseline}{Numeric baseline for bar charts.}

\item{fill}{Fill colour (string or \code{NA}).}

\item{alpha}{Opacity, a number between 0 and 1.}

\item{xlim}{Optional explicit x-axis limits (\code{c(min, max)}).}

\item{breaks, labels}{Custom axis breaks and labels.}

\item{ref_line}{Position of the reference line.}

\item{trans}{Scale transformation: \code{"identity"} or \code{"log"}.}

\item{truncate}{Truncation range \code{c(min, max)} for clipping CI whiskers.}

\item{show_axis}{Logical; show a bottom axis on the CI panel?}

\item{axis_label}{Optional axis title string.}

\item{glyph}{Default glyph: \code{"point"} or \code{"diamond"}.}

\item{summary_glyph}{Glyph used for summary rows (\code{NULL} to keep
the default glyph).}

\item{shape}{Numeric point shape (see \code{\link[graphics]{points}}).}

\item{point_size}{Point size in mm.}

\item{line_width}{Line width for CI whiskers.}

\item{plot_fn}{A function returning a \code{ggplot} object for custom
panels.}

\item{header_x}{Numeric x-position for the header in custom panels.}

\item{favors_left, favors_right}{Optional strings labelling the left/right
sides of the reference line (e.g. \code{"Favors Treatment"}).  When
supplied, a horizontal arrow and label are drawn below the axis.}

\item{favors_span}{Fraction (0, 1] controlling how far the favors arrows
extend from the reference line toward the panel edge.}

\item{favors_gap}{Fraction or \code{FALSE}/\code{TRUE} controlling the gap
between the reference line and the start of each favors arrow.}

\item{arrow_length}{Length of truncation arrowheads in inches (default
\code{0.08}).}

\item{arrow_type}{Arrowhead style: \code{"closed"} (filled) or
\code{"open"}.}

\item{arrow_angle}{Opening angle of the arrowhead in degrees, a number in
(0, 90) (default \code{30}).}
}
\value{
An \code{fp_spec} object (or \code{fp_aes} for \code{fp_aes()}).
}
\description{
Create specification objects that describe individual forest-plot panels.

\code{fp_aes()} creates column-to-aesthetic mappings passed to
\code{fp_ci()}, \code{fp_text()}, or \code{fp_text_ci()} via the
\code{mapping} argument.
}
\examples{
fp_text("label", header = "Subgroup", align = "left")
fp_ci("est", "lwr", "upr", trans = "log",
      mapping = fp_aes(colour = "ci_colour"))
fp_bar("events", header = "N")
}
