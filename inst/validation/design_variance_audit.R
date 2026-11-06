# Simulation-only design-variance audit for FADS.
# Source this script after installing FADS >= 0.3.7.
# The complete X values are used ONLY to generate new two-phase samples.
# The estimator itself receives masked nonvalidation X via fads_design().

fads_design_variance_audit <- function(M = 20L, N = 3000L,
                                       n_srs = 400L, n_corner = 10L,
                                       sigma_e = 0.8, tau = 0.5,
                                       seed = 20261020L,
                                       bandwidth_method = c('global', 'stratum'),
                                       checkpoint = 'fads_design_variance_audit.rds') {
  bandwidth_method <- match.arg(bandwidth_method)
  if (!requireNamespace('survival', quietly = TRUE)) stop('survival is required')
  if (!requireNamespace('FADS', quietly = TRUE)) stop('FADS must be installed')
  if (M < 2L || M != as.integer(M) || N <= n_srs || n_corner < 0L)
    stop('Invalid simulation sizes')
  truth <- c(X = log(2), Z = -0.5)
  settings <- list(N = N, n_srs = n_srs, n_corner = n_corner,
                   sigma_e = sigma_e, tau = tau, seed = seed,
                   bandwidth_method = bandwidth_method,
                   protocol = 'fixed-vs-independent-cohort-v1')
  if (file.exists(checkpoint)) {
    state <- readRDS(checkpoint)
    if (!identical(state$settings, settings))
      stop('Checkpoint settings differ; choose a new checkpoint filename')
  } else {
    state <- list(settings = settings, fixed = list(), independent = list())
  }
  generate <- function() {
    X <- stats::rnorm(N)
    Z <- stats::rbinom(N, 1, 0.5)
    W <- X + stats::rnorm(N, sd = sigma_e)
    te <- stats::rexp(N, rate = exp(truth['X'] * X + truth['Z'] * Z))
    tc <- stats::runif(N, 0, tau)
    data.frame(time = pmin(te, tc), status = as.integer(te <= tc),
               X = X, Z = Z, W = W)
  }
  # Reconstruct the same fixed cohort independently on each invocation.
  # Do not store unmasked X in the checkpoint.
  set.seed(seed)
  fixed_cohort <- generate()
  fit_once <- function(full, sample_seed) {
    start <- proc.time()[['elapsed']]
    tryCatch({
      s <- FADS::fads_design(full, 'time', 'status', 'W', 'X',
                            n_srs, n_corner, seed = sample_seed)
      fit <- FADS::fads(survival::Surv(time, status) ~ X + Z,
                       s, 'X', 'W', engine = 'vectorized',
                       bandwidth_method = bandwidth_method)
      b <- stats::coef(fit)
      if (fit$convergence != 0L || any(!is.finite(b)))
        stop('Nonconverged or nonfinite fit')
      list(ok = TRUE, estimate = b,
           validation_n = sum(s$.fads_group != 'nonvalidation'),
           elapsed_seconds = proc.time()[['elapsed']] - start)
    }, error = function(e) list(ok = FALSE, error = conditionMessage(e),
                               elapsed_seconds = proc.time()[['elapsed']] - start))
  }
  for (i in seq_len(M)) {
    key <- as.character(i)
    if (is.null(state$fixed[[key]])) {
      state$fixed[[key]] <- fit_once(fixed_cohort, seed + 100000L + i)
      saveRDS(state, checkpoint)
      message(sprintf('Fixed cohort %d/%d: %s', i, M,
                      if (state$fixed[[key]]$ok) 'OK' else state$fixed[[key]]$error))
    }
    if (is.null(state$independent[[key]])) {
      set.seed(seed + 200000L + i)
      cohort <- generate()
      state$independent[[key]] <- fit_once(cohort, seed + 300000L + i)
      saveRDS(state, checkpoint)
      message(sprintf('Independent cohort %d/%d: %s', i, M,
                      if (state$independent[[key]]$ok) 'OK' else state$independent[[key]]$error))
    }
  }
  summarize <- function(recs) {
    recs <- recs[seq_len(M)]
    ok <- vapply(recs, function(r) isTRUE(r$ok), logical(1))
    if (sum(ok) < 2L) return(list(success = sum(ok), failure = sum(!ok),
                                  summary = NULL, failures = recs[!ok]))
    b <- do.call(rbind, lapply(recs[ok], `[[`, 'estimate'))
    b <- matrix(b, ncol = length(truth), dimnames = list(NULL, names(truth)))
    tab <- data.frame(variable = names(truth),
                      mean_estimate = colMeans(b),
                      empirical_sd = apply(b, 2, stats::sd),
                      bias = colMeans(sweep(b, 2, truth, '-')),
                      row.names = NULL)
    list(success = sum(ok), failure = sum(!ok), summary = tab,
         failures = recs[!ok])
  }
  fixed <- summarize(state$fixed)
  independent <- summarize(state$independent)
  ratio <- NULL
  if (!is.null(fixed$summary) && !is.null(independent$summary)) {
    ratio <- data.frame(variable = names(truth),
                        fixed_cohort_sd = fixed$summary$empirical_sd,
                        independent_cohort_sd = independent$summary$empirical_sd,
                        ratio = fixed$summary$empirical_sd / independent$summary$empirical_sd)
  }
  list(fixed = fixed, independent = independent, comparison = ratio,
       checkpoint = checkpoint)
}

# Suggested pilot (run manually, NOT automatically on source):
# result <- fads_design_variance_audit(M = 20L, checkpoint = 'fads037_design_pilot.rds')
# print(result$comparison)
