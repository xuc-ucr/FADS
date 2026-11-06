\name{fads}
\alias{fads}
\title{Fit the FADS semiparametric pseudo-likelihood estimator}
\usage{fads(formula, data, expensive, auxiliary, bandwidth = NULL, bootstrap = 0L, seed = NULL,
  engine = c("vectorized", "reference"),
  bandwidth_method = c("global", "stratum"))}
\arguments{
\item{formula}{A right-censored Cox survival formula.}
\item{data}{Full phase-one cohort with .fads_group and .fads_stratum.}
\item{expensive}{Character vector naming expensive numeric covariates.}
\item{auxiliary}{Name of the fully observed auxiliary variable.}
\item{bandwidth}{Optional positive bandwidth for continuous auxiliary variables.}
\item{bandwidth_method}{Choose \code{global} (default) or \code{stratum} for continuous auxiliary variables. Stratum mode uses separate bandwidths for full-cohort stratum probabilities and validation-donor conditional distributions, with a global fallback for degenerate strata.}
\item{bootstrap}{Number of bootstrap replicates; zero omits inference.}
\item{seed}{Optional bootstrap random seed.}
\item{engine}{Either \code{vectorized} or \code{reference}.}}
\description{Fits a Cox regression using plug-in semiparametric pseudo-likelihood for two-phase failure-time-auxiliary-dependent sampling.}
\value{A fitted object of class \code{fads}.}
\details{Requires right-censored data and supplemental samples containing cases only. Uses the SRS for baseline cumulative hazard estimation and conditional donor mixtures for nonvalidation likelihood terms.}
