test_that('bootstrap preserves stratum bandwidth method', {
  set.seed(1007)
  n <- 400L
  X <- rnorm(n); Z <- rbinom(n, 1, .5)
  W <- X + rnorm(n, sd = .7)
  ft <- rexp(n, rate = exp(.7 * X - .5 * Z))
  ct <- runif(n, 0, 1.3)
  d <- data.frame(time = pmin(ft, ct), status = as.integer(ft <= ct), X, Z, W)
  s <- fads_design(d, 'time', 'status', 'W', 'X', n_srs = 220,
                   n_corner = 1, seed = 4)
  fit <- fads(survival::Surv(time, status) ~ X + Z, s, 'X', 'W',
              bandwidth_method = 'stratum', engine = 'vectorized')
  expect_identical(fit$bandwidth_method, 'stratum')
  b <- suppressWarnings(fads_bootstrap(fit, B = 3L, seed = 55))
  expect_true(all(b$bootstrap_bandwidth_methods[!is.na(b$bootstrap_bandwidth_methods)] == 'stratum'))
  expect_true(all(b$bootstrap_engines[!is.na(b$bootstrap_engines)] == 'vectorized'))
  expect_identical(nrow(b$bootstrap_coefficients), 3L)
})
