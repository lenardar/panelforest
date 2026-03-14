\name{panelforest_example_data}
\alias{panelforest_example_data}
\title{Load Example Data}
\usage{
panelforest_example_data(name = "classic")
}
\arguments{
\item{name}{Name of the example dataset. Currently only \code{"classic"} is
available.}
}
\value{
A data.frame.
}
\description{
Load a bundled example dataset for demonstrations and testing.
}
\examples{
df <- panelforest_example_data()
head(df)
}
