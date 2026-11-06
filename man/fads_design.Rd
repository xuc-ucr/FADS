\name{fads_design}
\alias{fads_design}
\title{Generate a two-phase FADS sample}
\usage{
fads_design(
  data, time, status, auxiliary, expensive,
  n_srs, n_corner, probs = c(0.3, 0.7),
  seed = NULL
)
}
\arguments{
\item{data}{Complete cohort data frame.}
\item{time}{Observed follow-up time column name.}
\item{status}{Binary event indicator column name.}
\item{auxiliary}{Auxiliary variable column name.}
\item{expensive}{Names of expensive covariates.}
\item{n_srs}{Number selected into SRS.}
\item{n_corner}{Number of additional cases in each of four corner strata.}
\item{probs}{Two quantile cutoffs for event time and continuous auxiliary.}
\item{seed}{Optional random seed.}}
\description{Draws an SRS and four supplemental corner-stratum case samples, masking expensive covariates for nonvalidation observations.}
\value{A data frame containing .fads_group, .fads_stratum, and .fads_id.}
