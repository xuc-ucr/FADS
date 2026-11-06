test_that('stratum-specific bandwidths are finite and stored', {
  set.seed(221)
  n <- 800
  X <- rnorm(n); Z <- rbinom(n, 1, 0.5)
  W <- X + rnorm(n, sd = 0.8)
  ft <- rexp(n, rate = exp(log(2) * X - 0.5 * Z))
  ct <- runif(n, 0, 1.3)
  d <- data.frame(time = pmin(ft, ct), status = as.integer(ft <= ct), X, Z, W)
  s <- fads_design(d, 'time', 'status', 'W', 'X', n_srs = 350,
                   n_corner = 1, seed = 12)
  f <- survival::Surv(time, status) ~ X + Z
  a <- fads(f, s, 'X', 'W', bandwidth_method = 'stratum', engine = 'reference')
  b <- fads(f, s, 'X', 'W', bandwidth_method = 'stratum', engine = 'vectorized')
  expect_equal(a$bandwidth_method, 'stratum')
  expect_true(all(is.finite(a$bandwidth_by_stratum$h_G)))
  expect_true(all(a$bandwidth_by_stratum$h_G > 0))
  expect_true(all(is.finite(a$bandwidth_by_stratum$h_pi)))
  expect_true(all(a$bandwidth_by_stratum$h_pi > 0))
  expect_equal(unname(coef(a)), unname(coef(b)), tolerance = 1e-3)
  expect_equal(a$objective, b$objective, tolerance = 1e-5)
})

test_that('fixed scalar bandwidth remains available in global mode', {
  set.seed(37)
  n <- 600
  X <- rnorm(n); Z <- rbinom(n, 1, 0.5)
  W <- X + rnorm(n)
  ft <- rexp(n, rate = exp(0.7 * X - 0.5 * Z))
  ct <- runif(n, 0, 1.3)
  d <- data.frame(time = pmin(ft, ct), status = as.integer(ft <= ct), X, Z, W)
  s <- fads_design(d, 'time', 'status', 'W', 'X', n_srs = 300,
                   n_corner = 1, seed = 8)
  f <- survival::Surv(time, status) ~ X + Z
  a <- fads(f, s, 'X', 'W', bandwidth = 0.4)
  expect_true(all(a$bandwidth_by_stratum$h_G == 0.4))
  expect_error(fads(f, s, 'X', 'W', bandwidth = 0.4,
                    bandwidth_method = 'stratum'), 'bandwidth = NULL')
})
