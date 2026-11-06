#' Fit a two-phase FADS Cox model
#'
#' Implements the plug-in semiparametric pseudo-likelihood of Cao et al.
#' The baseline cumulative hazard is estimated from the initial SRS using
#' Breslow's method; missing expensive covariates are integrated over a
#' stratum-specific empirical/kernel conditional distribution.
#'
#' @param formula Right-censored survival formula, e.g. Surv(t,d) ~ X + Z.
#' @param data Full first-phase cohort with .fads_group and .fads_stratum.
#' @param expensive Names of numeric expensive covariates; missing only outside validation.
#' @param auxiliary Name of fully observed auxiliary variable (binary/factor or continuous).
#' @param bandwidth Optional positive scalar bandwidth for continuous auxiliary variables.
#' @param bandwidth_method 'global' (backward compatible) or 'stratum' (separate
#'   smoothing bandwidths for stratum probabilities and validation donor distributions).
#' @param bootstrap Number of cohort bootstrap replicates (0 to omit standard errors).
#' @param seed Optional bootstrap seed.
#' @param engine Computation engine: 'vectorized' (default) or 'reference' (original).
#' @return An object of class fads.
#' @export
fads <- function(formula, data, expensive, auxiliary, bandwidth = NULL,
                 bootstrap = 0L, seed = NULL, engine = c('vectorized', 'reference'),
                 bandwidth_method = c('global', 'stratum')) {
  engine <- match.arg(engine)
  bandwidth_method <- match.arg(bandwidth_method)
  if (!inherits(formula, 'formula') || length(formula) != 3L) stop('Provide a two-sided survival formula')
  if (!is.data.frame(data) || !nrow(data)) stop('data must be a nonempty data frame')
  if (!is.character(expensive) || !length(expensive) || anyDuplicated(expensive)) stop('Invalid expensive covariate names')
  if (length(auxiliary) != 1L || !is.character(auxiliary)) stop('auxiliary must be one column name')
  required <- c('.fads_group', '.fads_stratum', expensive, auxiliary, all.vars(formula))
  if (!all(required %in% names(data))) stop('Missing columns: ', paste(setdiff(required, names(data)), collapse = ', '))
  group <- as.character(data$.fads_group)
  if (anyNA(group) || !all(group %in% c('srs', 'supplement', 'nonvalidation'))) stop('Invalid .fads_group')
  if (anyNA(data$.fads_stratum)) stop('Missing stratum labels')
  if (!all(vapply(data[expensive], is.numeric, logical(1)))) stop('Expensive covariates must be numeric')
  if (!all(expensive %in% all.vars(formula))) stop('All expensive covariates must occur in formula')
  val <- which(group != 'nonvalidation'); nv <- which(group == 'nonvalidation'); srs <- which(group == 'srs')
  if (length(srs) < 10L) stop('Too few SRS observations')
  if (anyNA(data[val, expensive, drop = FALSE])) stop('Missing expensive covariates in validation sample')
  if (anyNA(data[, setdiff(all.vars(formula), expensive), drop = FALSE])) stop('Missing phase-one model variables')
  if (anyNA(data[[auxiliary]])) stop('Missing auxiliary values')
  if (!is.null(bandwidth) && (!is.numeric(bandwidth) || length(bandwidth) != 1L || !is.finite(bandwidth) || bandwidth <= 0)) stop('Invalid bandwidth')
  if (!is.numeric(bootstrap) || length(bootstrap) != 1L || !is.finite(bootstrap) || bootstrap < 0 || bootstrap != as.integer(bootstrap)) stop('Invalid bootstrap count')

  # Evaluate the response without constructing a model frame with missing X.
  response <- eval(formula[[2L]], envir = data, enclos = environment(formula))
  if (!inherits(response, 'Surv') || ncol(response) != 2L || attr(response, 'type') != 'right')
    stop('Only Surv(time, status) with right censoring is supported')
  time <- as.numeric(response[, 1L]); delta <- as.numeric(response[, 2L])
  if (anyNA(time) || anyNA(delta) || any(!delta %in% c(0, 1)) || any(!is.finite(time))) stop('Invalid survival response')
  if (any(group == 'supplement' & delta != 1)) stop('Supplemental observations must be cases for this implementation')

  cox <- survival::coxph(formula, data = data[srs, , drop = FALSE], ties = 'breslow', x = TRUE, model = TRUE)
  beta0 <- stats::coef(cox)
  if (!length(beta0) || any(!is.finite(beta0))) stop('SRS Cox fit has undefined coefficients')
  bh <- survival::basehaz(cox, centered = FALSE)
  hazard <- function(t) {
    pos <- findInterval(t, bh$time)
    ans <- numeric(length(t)); positive <- pos > 0L
    ans[positive] <- bh$hazard[pos[positive]]
    ans
  }
  H <- hazard(time)
  terms <- stats::delete.response(stats::terms(cox))
  mk <- function(d) {
    mm <- stats::model.matrix(terms, data = d, contrasts.arg = cox$contrasts,
                              xlev = cox$xlevels)
    mm[, colnames(mm) != '(Intercept)', drop = FALSE]
  }
  xv <- mk(data[val, , drop = FALSE])
  if (!identical(colnames(xv), names(beta0))) stop('Model matrix columns do not match Cox coefficients')

  requested_bandwidth <- bandwidth
  w <- data[[auxiliary]]
  discrete <- is.factor(w) || is.character(w) || is.logical(w) || length(unique(w)) == 2L
  if (!discrete && !is.numeric(w)) stop('Continuous auxiliary must be numeric')
  if (!discrete && is.null(bandwidth)) {
    bandwidth <- stats::sd(w) * length(w)^(-1/3) / 2
    if (!is.finite(bandwidth) || bandwidth <= 0) stop('Cannot calculate positive bandwidth')
  }
  if (!discrete && bandwidth_method == 'stratum' && !is.null(requested_bandwidth))
    stop('For stratum-specific bandwidths set bandwidth = NULL')
  strata <- as.character(data$.fads_stratum)
  strata_names <- unique(strata)
  # Kernel ratios are computed on a log scale. For an extreme continuous
  # auxiliary value, every ordinary Gaussian weight may underflow to zero;
  # subtracting the maximum log weight preserves the exact normalized ratio.
  # Each stratum-specific conditional distribution is normalized separately.
  donor <- vector('list', length(nv))
  stratum_all <- lapply(strata_names, function(k) which(strata == k))
  stratum_valid <- lapply(stratum_all, function(ix) intersect(ix, val))
  # In the original R implementation the stratum bandwidth is proportional to
  # n_k^(-1/3) * sd(W_k)/2, separately for the full cohort (pi) and validation
  # donors (G). Use a documented global fallback for constant or tiny strata.
  # A positive floor avoids division by zero; log-normalization handles tails.
  h_pi <- h_G <- rep(if (discrete) NA_real_ else bandwidth, length(strata_names))
  fallback_pi <- fallback_G <- rep(FALSE, length(strata_names))
  if (!discrete && bandwidth_method == 'stratum') {
    global_scale <- stats::sd(w)
    h_floor <- max(global_scale * 1e-6, .Machine$double.eps^0.5)
    calc_h <- function(ix, default) {
      if (length(ix) < 2L) return(default)
      candidate <- stats::sd(w[ix]) * length(ix)^(-1/3) / 2
      if (!is.finite(candidate) || candidate <= h_floor) default
      else candidate
    }
    for (r in seq_along(strata_names)) {
      h_pi[r] <- calc_h(stratum_all[[r]], bandwidth)
      h_G[r] <- calc_h(stratum_valid[[r]], bandwidth)
      fallback_pi[r] <- identical(h_pi[r], bandwidth)
      fallback_G[r] <- identical(h_G[r], bandwidth)
    }
  }
  logsumexp_finite <- function(z) {
    if (!length(z)) return(-Inf)
    m <- max(z)
    if (!is.finite(m)) return(-Inf)
    m + log(sum(exp(z - m)))
  }
  for (a in seq_along(nv)) {
    j <- nv[a]
    # Stratum-specific bandwidths require separate probability and donor
    # kernels. pi_k(u) uses the full phase-one stratum; G_k uses validation
    # donors. Normalize positive pi contributions to a probability simplex.
    logpk <- vapply(seq_along(strata_names), function(r) {
      ix <- stratum_all[[r]]
      if (!length(ix)) return(-Inf)
      if (discrete) {
        matches <- sum(w[ix] == w[j])
        if (!matches) return(-Inf)
        return(log(matches))
      }
      lw <- -0.5 * ((w[ix] - w[j]) / h_pi[r])^2
      logsumexp_finite(lw) - log(h_pi[r])
    }, numeric(1))
    normpk <- logsumexp_finite(logpk)
    if (!is.finite(normpk)) stop('No phase-one auxiliary support for observation ', j)
    logpk <- logpk - normpk
    ix_all <- integer(); wt_all <- numeric()
    for (r in seq_along(strata_names)) {
      # Ignore contributions whose probability is below machine-relevant
      # likelihood precision; never silently drop a meaningful empty stratum.
      if (!is.finite(logpk[r]) || logpk[r] <= log(1e-14)) next
      ix <- stratum_valid[[r]]
      if (!length(ix)) stop('No validation observations in stratum ', strata_names[r],
                            ' with appreciable auxiliary probability')
      logkw_donor <- if (discrete) {
        ifelse(w[ix] == w[j], 0, -Inf)
      } else {
        -0.5 * ((w[ix] - w[j]) / h_G[r])^2
      }
      logden <- logsumexp_finite(logkw_donor)
      if (!is.finite(logden)) {
        stop('No matching validation donors in stratum ', strata_names[r],
             ' for auxiliary value ', as.character(w[j]))
      }
      ww <- exp(logpk[r] + logkw_donor - logden)
      keep <- ww > 0
      ix_all <- c(ix_all, ix[keep])
      wt_all <- c(wt_all, ww[keep])
    }
    if (!length(ix_all) || sum(wt_all) <= 0)
      stop('No valid donors for observation ', j)
    donor[[a]] <- list(index = ix_all, weight = wt_all / sum(wt_all))
  }
  # Construct all design matrices once: only beta changes during optimization.
  xdonor <- lapply(seq_along(nv), function(a) {
    j <- nv[a]; ix <- donor[[a]]$index
    d <- data[rep(j, length(ix)), , drop = FALSE]
    for (v in expensive) d[[v]] <- data[[v]][ix]
    mm <- mk(d)
    if (!identical(colnames(mm), colnames(xv))) stop('Inconsistent donor design matrix')
    mm
  })
  logsumexp <- function(z) { m <- max(z); m + log(sum(exp(z - m))) }
  objective_reference <- function(beta) {
    eta <- drop(xv %*% beta)
    if (any(!is.finite(eta)) || any(eta > 700)) return(1e100)
    ll <- sum(delta[val] * eta - H[val] * exp(eta))
    for (a in seq_along(nv)) {
      j <- nv[a]
      et <- drop(xdonor[[a]] %*% beta)
      if (any(!is.finite(et)) || any(et > 700)) return(1e100)
      ll <- ll + logsumexp(log(donor[[a]]$weight) + delta[j] * et - H[j] * exp(et))
    }
    if (!is.finite(ll)) 1e100 else -ll
  }
  if (engine == 'vectorized' && length(nv)) {
    counts <- lengths(lapply(donor, `[[`, 'index'))
    group_id <- rep.int(seq_along(nv), counts)
    xstack <- do.call(rbind, xdonor)
    logweight <- log(unlist(lapply(donor, `[[`, 'weight'), use.names = FALSE))
    Hstack <- rep.int(H[nv], counts)
    dstack <- rep.int(delta[nv], counts)
    # The donor matrix and weights do not depend on beta; cache them once.
    # A global log shift prevents overflow; extremely small contributions
    # are handled by the reference log-sum-exp fallback.
    calc <- function(beta, gradient = FALSE) {
      eta <- drop(xv %*% beta)
      et <- drop(xstack %*% beta)
      if (any(!is.finite(eta)) || any(!is.finite(et)) ||
          any(eta > 700) || any(et > 700))
        return(if (gradient) rep(0, length(beta)) else 1e100)
      e <- exp(et)
      logterms <- logweight + dstack * et - Hstack * e
      shift <- max(logterms)
      weight <- exp(logterms - shift)
      sums <- as.numeric(rowsum(weight, group_id, reorder = TRUE))
      if (any(sums <= 0) || any(!is.finite(sums))) {
        if (gradient) return(gradient_reference(beta))
        return(objective_reference(beta))
      }
      if (!gradient) {
        ll <- sum(delta[val] * eta - H[val] * exp(eta)) +
          sum(log(sums)) + length(nv) * shift
        return(if (is.finite(ll)) -ll else 1e100)
      }
      gval <- colSums(xv * (delta[val] - H[val] * exp(eta)))
      score <- weight * (dstack - Hstack * e)
      gn <- rowsum(xstack * score, group_id, reorder = TRUE)
      -as.numeric(gval + colSums(gn / sums))
    }
    gradient_reference <- function(beta) {
      eta <- drop(xv %*% beta)
      result <- colSums(xv * (delta[val] - H[val] * exp(eta)))
      for (a in seq_along(nv)) {
        j <- nv[a]
        mat <- xdonor[[a]]
        et <- drop(mat %*% beta)
        e <- exp(et)
        lt <- log(donor[[a]]$weight) + delta[j] * et - H[j] * e
        ww <- exp(lt - max(lt)); ww <- ww / sum(ww)
        result <- result + colSums(mat * (ww * (delta[j] - H[j] * e)))
      }
      -as.numeric(result)
    }
    objective <- function(beta) calc(beta, FALSE)
    gradient <- function(beta) calc(beta, TRUE)
    opt <- stats::optim(beta0, objective, gr = gradient, method = 'BFGS',
                        control = list(maxit = 500L))
  } else {
    opt <- stats::optim(beta0, objective_reference, method = 'BFGS',
                        control = list(maxit = 500L))
  }
  ans <- list(coefficients = stats::setNames(opt$par, names(beta0)),
              convergence = opt$convergence, objective = opt$value,
              initial = beta0, baseline = bh, formula = formula,
              call = match.call(), data = data, expensive = expensive,
              auxiliary = auxiliary, bandwidth = bandwidth,
              bandwidth_requested = requested_bandwidth,
              bandwidth_method = bandwidth_method,
              bandwidth_by_stratum = if (discrete) NULL else data.frame(
                stratum = strata_names, h_pi = h_pi, h_G = h_G,
                fallback_pi = fallback_pi, fallback_G = fallback_G),
              engine = engine,
              covariance = NULL, bootstrap_coefficients = NULL)
  class(ans) <- 'fads'
  if (bootstrap > 0L) ans <- fads_bootstrap(ans, B = bootstrap, seed = seed)
  ans
}

#' @export
coef.fads <- function(object, ...) object$coefficients
#' @export
vcov.fads <- function(object, ...) {
  if (is.null(object$covariance)) stop('Run fads_bootstrap() for standard errors')
  object$covariance
}
#' @export
confint.fads <- function(object, parm, level = .95, ...) {
  if (length(level) != 1L || level <= 0 || level >= 1) stop('level must be between zero and one')
  b <- coef(object); se <- sqrt(diag(vcov(object)))
  z <- stats::qnorm((1 + level) / 2)
  ci <- cbind(lower = b - z * se, upper = b + z * se)
  if (!missing(parm)) ci <- ci[parm, , drop = FALSE]
  ci
}
#' @export
print.fads <- function(x, ...) {
  cat('FADS semiparametric pseudo-likelihood fit\n')
  print(x$coefficients)
  cat('Optimizer convergence:', x$convergence, '\n')
  invisible(x)
}
#' @export
summary.fads <- function(object, ...) {
  b <- coef(object)
  if (is.null(object$covariance)) return(structure(list(coefficients = b, inference = NULL), class = 'summary.fads'))
  se <- sqrt(diag(vcov(object)))
  tab <- cbind(estimate = b, se = se, HR = exp(b), z = b / se,
               p = 2 * stats::pnorm(-abs(b / se)))
  structure(list(coefficients = b, inference = tab), class = 'summary.fads')
}
#' @export
print.summary.fads <- function(x, ...) {
  if (is.null(x$inference)) print(x$coefficients) else print(x$inference)
  invisible(x)
}
