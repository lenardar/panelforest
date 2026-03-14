\name{decorations}
\alias{add_stripe}
\alias{add_summary}
\alias{add_group}
\alias{add_hline}
\title{Structural Decorations}
\usage{
add_stripe(x, colors)

add_summary(x, rows)

add_group(x, rows, fontface = "bold", size = NULL,
          colour = NULL, fill = NULL)

add_hline(x, rows, colour = HLINE_DEFAULT_COLOUR,
          linewidth = HLINE_DEFAULT_LINEWIDTH, linetype = 1)
}
\arguments{
\item{x}{An \code{fp_plot} object.}

\item{colors}{Character vector of at least two colours for alternating row
stripes.}

\item{rows}{Integer vector of row indices.}

\item{fontface}{Font face applied to group rows (default \code{"bold"}).}

\item{size, colour, fill}{Optional style overrides for group rows.}

\item{linewidth}{Line width for horizontal separators.}

\item{linetype}{Line type (numeric or character).}
}
\value{
The modified \code{fp_plot} object.
}
\description{
Add structural decorations that span all panels.

\code{add_stripe()} sets alternating row background colours.

\code{add_summary()} marks rows as summary rows, which receive bold text
and diamond CI glyphs by default.

\code{add_group()} marks rows as group-title rows. Group rows suppress
CI rendering and are styled with bold text.

\code{add_hline()} draws horizontal separators below the specified rows.
}
\examples{
df <- data.frame(label = c("Overall", "A", "B"),
                 est = c(1, 0.9, 1.2), lwr = c(0.85, 0.7, 1.0),
                 upr = c(1.15, 1.1, 1.4))
forest_plot(df) |>
  add_stripe(c("white", "#f4f7f5")) |>
  add_summary(1) |>
  add_hline(1) |>
  add_text("label", header = "Label") |>
  add_ci("est", "lwr", "upr", header = "HR") |>
  fp_render()
}
