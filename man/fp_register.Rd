\name{fp_register}
\alias{fp_register}
\title{Register a Custom Builder}
\usage{
fp_register(type, builder, overwrite = FALSE)
}
\arguments{
\item{type}{A single string identifying the spec type.}

\item{builder}{A function with signature \code{function(ctx, spec,
cell_edits)} that returns a \code{ggplot} object.}

\item{overwrite}{Logical; if \code{TRUE}, silently replaces an existing
registration.}
}
\value{
The \code{type} string, invisibly.
}
\description{
Register a builder function for a custom spec type in the internal
registry. This is an advanced extension point; most users should prefer
\code{\link{fp_custom}}.
}
\examples{
my_builder <- function(ctx, spec, cell_edits) {
  ggplot2::ggplot() + ggplot2::theme_void()
}
fp_register("my_type", my_builder, overwrite = TRUE)
}
