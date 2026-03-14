\name{fp_formatters}
\alias{fp_fmt_number}
\alias{fp_fmt_percent}
\alias{fp_fmt_pvalue}
\title{Text Formatting Helpers}
\usage{
fp_fmt_number(digits = 2, big_mark = "", prefix = "", suffix = "",
              na = "")

fp_fmt_percent(digits = 1, scale = 100, suffix = "\%", prefix = "",
               na = "")

fp_fmt_pvalue(digits = 3, threshold = 0.001, prefix = "p = ", na = "")
}
\arguments{
\item{digits}{Number of decimal places.}
\item{big_mark}{Thousands separator.}
\item{prefix, suffix}{Strings prepended/appended to each value.}
\item{na}{String used for missing values.}
\item{scale}{Multiplier applied before formatting (default 100 for
percentages).}
\item{threshold}{P-values below this are shown as \code{"< threshold"}.}
}
\value{
A function that accepts a numeric vector and returns a character
vector of formatted strings.
}
\description{
Factory functions that return formatters suitable for the \code{formatter}
argument of \code{\link{fp_text}}.
}
\examples{
fp_fmt_number(digits = 1, big_mark = ",")(c(1000, 12.34))
fp_fmt_percent()(c(0.125, 0.34))
fp_fmt_pvalue()(c(0.12, 0.0005))
}
