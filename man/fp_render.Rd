\name{fp_render}
\alias{fp_render}
\alias{fp_size}
\alias{print.fp_plot}
\title{Render a Forest Plot}
\usage{
fp_render(x)

fp_size(x)

\method{print}{fp_plot}(x, \dots)
}
\arguments{
\item{x}{An \code{fp_plot} object created by \code{\link{forest_plot}}.}

\item{\dots}{Arguments passed to the print method of the rendered plot.}
}
\value{
\code{fp_render} returns a \pkg{patchwork} object.

\code{fp_size} returns a named numeric vector with elements \code{width} and
\code{height} (inches).

\code{print.fp_plot} renders and prints, returning \code{x} invisibly.
}
\description{
\code{fp_render} assembles all panels into a single patchwork graphic.
\code{fp_size} computes suggested device dimensions.
}
\examples{
df <- data.frame(label = c("A", "B"), est = c(0.9, 1.3),
                 lwr = c(0.7, 1.0), upr = c(1.1, 1.7))
p <- forest_plot(df) |>
  add_text("label", header = "Label") |>
  add_ci("est", "lwr", "upr", header = "HR")
fp_render(p)
fp_size(p)
}
