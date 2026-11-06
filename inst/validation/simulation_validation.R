# FADS simulation validation (paper-consistent estimator)
# Source this file after installing FADS >= 0.3.3.
# Designed for independent Monte Carlo cohorts and optional cohort bootstrap.
# Output is checkpointed after EVERY replicate; re-source to resume.
# NOTE: This does NOT reproduce the published Table 1 without matching all
# original design details, especially time cutoffs, censoring and RNG streams.

library(FADS)
library(survival)

fads_simulate_cohort <- function(N = 1500L, beta = c(X = log(2), Z = -0.5),
                                 sigma_e = 0.8, tau = 0.5) {
  stopifnot(N >= 50, length(beta) == 2L, sigma_e > 0, tau > 0)
  X <- rnorm(N)
  Z <- rbinom(N, 1, 0.5)
  W <- X + rnorm(N, sd = sigma_e)
  event_time <- rexp(N, rate = exp(beta[1] * X + beta[2] * Z))
  censor_time <- runif(N, min = 0, max = tau)
  data.frame(time = pmin(event_time, censor_time),
             status = as.integer(event_time <= censor_time), X = X, Z = Z, W = W)
}

fads_validation_run <- function(M = 20L, B = 0L, N = 1500L,
                                n_srs = 300L, n_corner = 15L,
                                sigma_e = 0.8, tau = 0.5,
                                seed = 20261020L,
                                checkpoint = 'fads_simulation_checkpoint.rds',
                                engine = 'vectorized', bandwidth_method = 'global') {
  stopifnot(M >= 1, B >= 0, B == as.integer(B),
            M == as.integer(M), N > n_srs, n_corner >= 0,
            engine %in% c('vectorized','reference'),
            bandwidth_method %in% c('global','stratum'))
  beta_true <- c(X = log(2), Z = -0.5)
  settings <- list(N = N, n_srs = n_srs, n_corner = n_corner,
                   sigma_e = sigma_e, tau = tau, seed = seed,
                   B = B, engine = engine, bandwidth_method = bandwidth_method)
  if (file.exists(checkpoint)) {
    state <- readRDS(checkpoint)
    if (!identical(state$settings, settings))
      stop('Existing checkpoint settings differ. Use another checkpoint filename.')
  } else {
    state <- list(settings = settings, records = list())
  }
  for (i in seq_len(M)) {
    key <- as.character(i)
    if (!is.null(state$records[[key]])) next
    set.seed(seed + i)
    started <- Sys.time()
    result <- tryCatch(withCallingHandlers({
      d <- fads_simulate_cohort(N, beta_true, sigma_e, tau)
      s <- fads_design(d, 'time', 'status', 'W', 'X', n_srs, n_corner)
      fit <- fads(Surv(time, status) ~ X + Z, s, 'X', 'W', engine = engine,
                  bandwidth_method = bandwidth_method)
      if (fit$convergence != 0L || any(!is.finite(coef(fit))))
        stop('Nonconvergent or nonfinite FADS fit')
      if (B >= 2L) {
        fit <- fads_bootstrap(fit, B = B)
        se <- sqrt(diag(vcov(fit)))
        boot_success <- fit$bootstrap_success
      } else {
        se <- c(X = NA_real_, Z = NA_real_)
        boot_success <- NA_integer_
      }
      list(ok = TRUE, estimate = coef(fit), se = se,
           boot_success = boot_success, event_rate = mean(d$status),
           validation_n = sum(s$.fads_group != 'nonvalidation'))
    }, warning = function(w) {
      # Keep warnings visible; don't turn a warning into a successful fit.
      message('Replicate ', i, ' warning: ', conditionMessage(w))
      invokeRestart('muffleWarning')
    }), error = function(e) list(ok = FALSE, error = conditionMessage(e)))
    result$elapsed_seconds <- as.numeric(difftime(Sys.time(), started, units = 'secs'))
    state$records[[key]] <- result
    saveRDS(state, checkpoint)
    message(sprintf('Replicate %d/%d: %s (%.1f sec); checkpoint: %s',
                    i, M, if (result$ok) 'OK' else paste('FAILED:',result$error),
                    result$elapsed_seconds, checkpoint))
  }
  fads_validation_summary(state, beta_true)
}

fads_validation_summary <- function(state, beta_true = c(X = log(2), Z = -0.5)) {
  rec <- state$records
  good <- vapply(rec, function(z) isTRUE(z$ok), logical(1))
  if (!any(good)) return(list(completed = length(rec), successful = 0L,
                              failed = rec, summary = NULL))
  estimates <- do.call(rbind, lapply(rec[good], function(z) z$estimate))
  ses <- do.call(rbind, lapply(rec[good], function(z) z$se))
  if (is.null(dim(estimates))) estimates <- matrix(estimates, nrow = 1L)
  if (is.null(dim(ses))) ses <- matrix(ses, nrow = 1L)
  colnames(estimates) <- names(beta_true)
  colnames(ses) <- names(beta_true)
  empirical_sd <- if (nrow(estimates) > 1L) apply(estimates, 2L, sd) else rep(NA_real_, 2L)
  mean_se <- if (all(is.na(ses))) rep(NA_real_, 2L) else colMeans(ses, na.rm = TRUE)
  coverage <- if (all(is.na(ses))) rep(NA_real_, 2L) else colMeans(
    abs(sweep(estimates, 2L, beta_true)) <= 1.96 * ses, na.rm = TRUE)
  tab <- data.frame(variable = names(beta_true), true = unname(beta_true),
                    mean_estimate = colMeans(estimates),
                    bias = colMeans(sweep(estimates, 2L, beta_true)),
                    empirical_sd = empirical_sd, mean_bootstrap_se = mean_se,
                    coverage_95 = coverage, row.names = NULL)
  list(completed = length(rec), successful = sum(good),
       failed = rec[!good], summary = tab,
       event_rate = mean(vapply(rec[good], `[[`, numeric(1), 'event_rate')),
       bootstrap_successes = vapply(rec[good], function(z) z$boot_success, integer(1)))
}

# FIRST: inexpensive smoke test, no bootstrap. Change checkpoint name to avoid
# mixing results with the full validation.
# smoke <- fads_validation_run(M = 3, B = 0, N = 600, n_srs = 180,
#                              n_corner = 5,
#                              checkpoint = 'fads_smoke.rds')
# print(smoke$summary)
#
# NEXT: point-estimator Monte Carlo, B = 0; increase M after the smoke test.
# result <- fads_validation_run(M = 20, B = 0,
#                               checkpoint = 'fads_point_validation.rds')
# print(result$summary)
#
# LATER: full inference validation, expensive: M cohorts x B bootstraps.
# result <- fads_validation_run(M = 100, B = 200,
#                               checkpoint = 'fads_inference_validation.rds')
