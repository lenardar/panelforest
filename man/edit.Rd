\name{edit}
\alias{edit}
\title{Edit Rows, Cells, or Heights}
\usage{
edit(x, row, panel = NULL, fontface = NULL, colour = NULL,
     size = NULL, fill = NULL, alpha = NULL, glyph = NULL,
     point_size = NULL, line_width = NULL, shape = NULL,
     label = NULL, family = NULL, height = NULL)
}
\arguments{
\item{x}{An \code{fp_plot} object.}

\item{row}{Integer vector of row indices to modify.}

\item{panel}{Panel identifier (integer index or header/column name string).
When \code{NULL}, edits apply at the row level across all panels.}

\item{fontface}{Font face override (e.g. \code{"italic"}, \code{"bold"}).}

\item{colour}{Text or CI border colour.}

\item{size}{Text size.}

\item{fill}{Fill colour. For row-level edits this sets the background; for
cell-level edits on a CI panel it sets the CI fill.}

\item{alpha}{Opacity (0--1) for CI glyphs.}

\item{glyph}{CI glyph: \code{"point"} or \code{"diamond"}.}

\item{point_size}{Point size for CI or dot glyphs.}

\item{line_width}{Line width for CI whiskers.}

\item{shape}{Numeric point shape.}

\item{label}{Override text label for a cell.}

\item{family}{Font family override for text cells.}

\item{height}{Row height (positive number). Only meaningful without a
\code{panel} specification.}
}
\value{
The modified \code{fp_plot} object.
}
\description{
A unified interface for row-level styling, cell-level overrides, and row
height adjustments.

When \code{panel} is \code{NULL}, style arguments are stored as row-level
overrides affecting all panels.
When \code{panel} is specified, overrides apply only to that panel
(cell-level).
\code{height} always adjusts the row height regardless of \code{panel}.
}
\examples{
df <- data.frame(label = c("A", "B", "C"),
                 est = c(0.9, 1.3, 1.05), lwr = c(0.7, 1.0, 0.8),
                 upr = c(1.1, 1.7, 1.4))
forest_plot(df) |>
  add_text("label", header = "Subgroup") |>
  add_ci("est", "lwr", "upr", header = "HR") |>
  edit(row = 1, panel = "HR", glyph = "diamond", fill = "#dbeafe") |>
  edit(row = 2:3, fontface = "italic") |>
  edit(row = 1, height = 1.5) |>
  fp_render()
}
