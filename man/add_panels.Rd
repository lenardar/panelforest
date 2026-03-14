\name{add_panels}
\alias{add_text}
\alias{add_text_ci}
\alias{add_gap}
\alias{add_spacer}
\alias{add_bar}
\alias{add_dot}
\alias{add_ci}
\alias{add_custom}
\alias{add_header_group}
\title{Add Panels to a Forest Plot}
\usage{
add_text(x, \dots)
add_text_ci(x, \dots)
add_gap(x, \dots)
add_spacer(x, \dots)
add_bar(x, \dots)
add_dot(x, \dots)
add_ci(x, \dots)
add_custom(x, spec)
add_header_group(x, label, panels, align = "center",
                 fontface = "bold", colour = NULL, size = NULL,
                 family = NULL, background = NULL, height = NULL,
                 border = FALSE,
                 border_colour = HEADER_GROUP_BORDER_COLOUR,
                 border_linewidth = HEADER_GROUP_BORDER_LINEWIDTH)
}
\arguments{
\item{x}{An \code{fp_plot} object created by \code{\link{forest_plot}}.}

\item{\dots}{Arguments passed to the corresponding spec constructor
(\code{\link{fp_text}}, \code{\link{fp_ci}}, etc.).}

\item{spec}{An \code{fp_spec_custom} object created by
\code{\link{fp_custom}}.}

\item{label}{Header group label string.}

\item{panels}{Integer vector of contiguous panel indices that the group
spans (e.g. \code{2:4}).}

\item{align}{Label alignment: \code{"left"}, \code{"center"}, or
\code{"right"}.}

\item{fontface}{Font face for the group label (default \code{"bold"}).}

\item{colour}{Text colour.  Defaults to the theme header colour.}

\item{size}{Text size.  Defaults to the theme header size.}

\item{family}{Font family.  Defaults to the theme base family.}

\item{background}{Background fill colour for the group cell.}

\item{height}{Row height (inches) for this group level.  Defaults to the
plot \code{header_height}.}

\item{border}{Logical; draw a bottom border line under the group cell?}

\item{border_colour}{Border line colour.}

\item{border_linewidth}{Border line width.}
}
\value{
The modified \code{fp_plot} object (invisibly supports piping).
}
\description{
Append a panel specification to the plot layout. Each function is a
thin wrapper around its \code{fp_*()} spec constructor.

\code{add_header_group()} adds a spanning header row above one or more
adjacent panels, useful for grouping related columns under a common
label.
}
\examples{
df <- data.frame(label = c("A", "B"), est = c(0.9, 1.3),
                 lwr = c(0.7, 1.0), upr = c(1.1, 1.7))
forest_plot(df) |>
  add_text("label", header = "Label") |>
  add_ci("est", "lwr", "upr", header = "HR") |>
  fp_render()
}
