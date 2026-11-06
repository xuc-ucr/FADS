\name{fads_bootstrap}
\alias{fads_bootstrap}
\title{Bootstrap FADS estimates}
\usage{fads_bootstrap(object, B = 200L, seed = NULL)}
\arguments{\item{object}{A fitted fads object.}\item{B}{Number of bootstrap replicates, at least two.}\item{seed}{Optional seed.}}
\description{Resamples phase-one subjects with replacement, retains sampling designations, and refits the FADS estimator.}
\value{An updated fads object with covariance, bootstrap coefficients and failure diagnostics.}
