#' Cohort bootstrap for FADS inference
#'
#' Resample phase-one subjects with replacement while preserving each subject's
#' original SRS/supplemental/nonvalidation designation. Refit all nuisance
#' quantities and the pseudo-likelihood on each replicate.
#'
#' @param object A fitted fads object.
#' @param B Number of replicates, at least two.
#' @param seed Optional random seed.
#' @return Updated fit containing covariance and bootstrap diagnostics.
#' @export
fads_bootstrap <- function(object, B = 200L, seed = NULL) {
  if (!inherits(object, 'fads')) stop('object must be a fads fit')
  if (!is.numeric(B) || length(B) != 1L || !is.finite(B) || B < 2 || B != as.integer(B)) stop('B must be an integer >= 2')
  if (!is.null(seed)) set.seed(seed)
  n <- nrow(object$data)
  out <- matrix(NA_real_, B, length(coef(object)), dimnames = list(NULL, names(coef(object))))
  failed <- character()
  method_used <- rep(NA_character_, B)
  engine_used <- rep(NA_character_, B)
  for (i in seq_len(B)) {
    d <- object$data[sample.int(n, n, replace = TRUE), , drop = FALSE]
    rownames(d) <- NULL
    fit <- tryCatch(fads(object$formula, d, object$expensive, object$auxiliary,
                         bandwidth = object$bandwidth_requested, bootstrap = 0L,
                         engine = if (is.null(object$engine)) 'reference' else object$engine,
                         bandwidth_method = if (is.null(object$bandwidth_method)) 'global' else object$bandwidth_method), error = identity)
    if (inherits(fit, 'error')) {
      failed <- c(failed, paste0(i, ': ', conditionMessage(fit)))
    } else if (fit$convergence != 0L || any(!is.finite(coef(fit)))) {
      failed <- c(failed, paste0(i, ': nonconverged optimizer'))
    } else {
      out[i, ] <- coef(fit)
      method_used[i] <- fit$bandwidth_method
      engine_used[i] <- fit$engine
    }
  }
  ok <- stats::complete.cases(out)
  if (sum(ok) < max(2L, ceiling(0.8 * B))) stop('Insufficient successful bootstrap replicates: ', sum(ok), '/', B)
  object$bootstrap_coefficients <- out
  object$covariance <- stats::cov(out[ok, , drop = FALSE])
  object$bootstrap_success <- sum(ok)
  object$bootstrap_failures <- failed
  object$bootstrap_bandwidth_methods <- method_used
  object$bootstrap_engines <- engine_used
  expected_method <- if (is.null(object$bandwidth_method)) 'global' else object$bandwidth_method
  if (any(method_used[ok] != expected_method))
    stop('Internal error: bootstrap did not preserve bandwidth_method')
  if (any(!ok)) warning(sum(!ok), ' bootstrap replicates failed')
  object
}
