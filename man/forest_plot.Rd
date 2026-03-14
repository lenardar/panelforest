\name{forest_plot}
\alias{forest_plot}
\title{Create a Forest Plot Object}
\usage{
forest_plot(data, theme = fp_theme_default(), row_height = DEFAULT_ROW_HEIGHT,
            convert_na = FALSE)
}
\arguments{
\item{data}{A data.frame containing the plot data. Each row corresponds to one
row in the rendered forest plot.}

\item{theme}{An \code{fp_theme} object created by \code{\link{fp_theme_default}} or
\code{\link{fp_theme_journal}}.}

\item{row_height}{A single positive number setting the default height (inches)
for every row. The header row shares this height. Individual data rows can
later be adjusted via \code{\link{edit}}.}

\item{convert_na}{Logical; if \code{TRUE}, \code{NA} values in character
columns are converted to empty strings before plotting (default
\code{FALSE}).}
}
\value{
An \code{fp_plot} object that can be passed to \code{add_*()},
\code{\link{edit}}, and \code{\link{fp_render}}.
}
\description{
Initialise an \code{fp_plot} object from a tidy data frame.
Panels are added later with \code{add_text()}, \code{add_ci()}, etc.
}
\examples{
df <- data.frame(label = c("A", "B"), est = c(0.9, 1.3),
                 lwr = c(0.7, 1.0), upr = c(1.1, 1.7))
forest_plot(df) |>
  add_text("label", header = "Subgroup") |>
  add_ci("est", "lwr", "upr", header = "HR") |>
  fp_render()
}
