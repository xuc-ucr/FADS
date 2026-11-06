\name{fads-methods}
\alias{coef.fads}
\alias{vcov.fads}
\alias{confint.fads}
\alias{print.fads}
\alias{summary.fads}
\alias{print.summary.fads}
\title{Methods for FADS model fits}
\usage{\method{coef}{fads}(object, ...)
\method{vcov}{fads}(object, ...)
\method{confint}{fads}(object, parm, level = 0.95, ...)
\method{print}{fads}(x, ...)
\method{summary}{fads}(object, ...)
\method{print}{summary.fads}(x, ...)}
\arguments{\item{object}{Fitted FADS object.}\item{x}{Fitted or summarized FADS object.}\item{parm}{Coefficient names or indices.}\item{level}{Confidence level.}\item{...}{Unused additional arguments.}}
\description{Extract regression coefficients, bootstrap covariance, confidence intervals and model summaries.}
\value{Appropriate coefficient, covariance, interval or summary objects.}
