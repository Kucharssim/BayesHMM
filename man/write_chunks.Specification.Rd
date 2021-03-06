% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/write.R
\name{write_chunks.Specification}
\alias{write_chunks.Specification}
\title{Write Stan code chunks to disk}
\usage{
\method{write_chunks}{Specification}(spec, noLogLike, writeDir)
}
\arguments{
\item{spec}{An object returned by either \code{\link{specify}} or \code{\link{hmm}}.}

\item{noLogLike}{A logical stating whether the log-likelihood should be excluded from the program. If TRUE, the Stan code will draw samples from the prior predictive density. If FALSE, the Stan code will draw samples from the posterior predictive density.}

\item{writeDir}{A character string with the path where the Stan file should be written. Useful to inspect and modify the Stan code manually.}
}
\value{
Nothing.
}
\description{
Write Stan code chunks to disk
}
\keyword{internal}
