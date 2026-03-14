\name{fp_theme_default}
\alias{fp_theme_default}
\alias{fp_theme_journal}
\title{Forest Plot Themes}
\usage{
fp_theme_default(base_family = "", text_size = 3.6,
  text_colour = "#1f1f1f", header_size = 3.8,
  header_fontface = "bold", header_colour = "#1f1f1f",
  refline_colour = "#9aa1a6", stripe_alpha = 1, plot_margin = 4)

fp_theme_journal(base_family = "serif", text_size = 3.4,
  text_colour = "#202124", header_size = 3.6,
  header_fontface = "bold", header_colour = "#111111",
  refline_colour = "#7f8891", stripe_alpha = 1, plot_margin = 3)
}
\arguments{
\item{base_family}{Font family.}
\item{text_size}{Text size in ggplot2 units.}
\item{text_colour}{Default text colour.}
\item{header_size}{Header text size.}
\item{header_fontface}{Header font face.}
\item{header_colour}{Header text colour.}
\item{refline_colour}{Colour for reference lines.}
\item{stripe_alpha}{Alpha for stripe backgrounds.}
\item{plot_margin}{Outer margin in points.}
}
\value{
An \code{fp_theme} object.
}
\description{
\code{fp_theme_default()} creates a clean default theme.
\code{fp_theme_journal()} uses a serif font with tighter spacing suitable
for journal figures.
}
\examples{
fp_theme_default()
fp_theme_journal()
}
