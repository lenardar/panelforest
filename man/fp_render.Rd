\name{fp_render}
\alias{fp_render}
\alias{fp_size}
\alias{fp_save}
\alias{print.fp_plot}
\title{Render a Forest Plot}
\usage{
fp_render(x)

fp_size(x)

fp_save(x, filename, width = NULL, height = NULL, dpi = 300, scale = 1, \dots)

\method{print}{fp_plot}(x, \dots)
}
\arguments{
\item{x}{An \code{fp_plot} object created by \code{\link{forest_plot}}.}

\item{filename}{File name to create on disk (passed to
\code{\link[ggplot2]{ggsave}}).}

\item{width, height}{Plot dimensions in inches.
If \code{NULL} (the default), values are obtained from \code{fp_size()}.}

\item{dpi}{Resolution in dots per inch (default 300).}

\item{scale}{Multiplicative scaling factor (default 1).}

\item{\dots}{For \code{fp_save}: additional arguments passed to
\code{\link[ggplot2]{ggsave}} (e.g.\ \code{device}, \code{bg}).
For \code{print.fp_plot}: arguments passed to the print method of the
rendered plot.}
}
\value{
\code{fp_render} returns a \pkg{patchwork} object.

\code{fp_size} returns a named numeric vector with elements \code{width} and
\code{height} (inches).

\code{fp_save} writes the plot to \code{filename} and returns
\code{filename} invisibly.

\code{print.fp_plot} renders and prints, returning \code{x} invisibly.
}
\description{
\code{fp_render} assembles all panels into a single patchwork graphic.
\code{fp_size} computes suggested device dimensions.
\code{fp_save} is a convenience wrapper that renders the plot and saves it
with correct dimensions in a single call.
}
\examples{
df <- data.frame(label = c("A", "B"), est = c(0.9, 1.3),
                 lwr = c(0.7, 1.0), upr = c(1.1, 1.7))
p <- forest_plot(df) |>
  add_text("label", header = "Label") |>
  add_ci("est", "lwr", "upr", header = "HR")
fp_render(p)
fp_size(p)

\dontrun{
fp_save(p, "forest.png")
fp_save(p, "forest.pdf", dpi = 600)
}
}
