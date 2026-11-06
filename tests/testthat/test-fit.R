test_that('continuous auxiliary estimator fits a small simulated cohort', {
  skip_on_cran()
  set.seed(23)
  n <- 240
  X <- rnorm(n)
  Z <- rbinom(n, 1, .5)
  W <- X + rnorm(n, sd = .5)
  fail <- rexp(n, rate = exp(.5 * X - .2 * Z))
  cens <- rexp(n, rate = .2)
  d <- data.frame(t = pmin(fail, cens), event = as.integer(fail <= cens), X, Z, W)
  s <- fads_design(d, 't', 'event', 'W', 'X', n_srs = 90, n_corner = 3, seed = 2)
  fit <- fads(survival::Surv(t, event) ~ X + Z, s, 'X', 'W')
  expect_length(coef(fit), 2L)
  expect_true(all(is.finite(coef(fit))))
  expect_equal(fit$convergence, 0L)
})

test_that('binary auxiliary uses observed donor X rather than hidden X', {
  skip_on_cran()
  set.seed(24)
  n <- 300
  X <- rbinom(n, 1, .5); W <- X
  Z <- rnorm(n)
  fail <- rexp(n, rate = exp(.6 * X + .2 * Z))
  cens <- rexp(n, rate = .2)
  d <- data.frame(t = pmin(fail, cens), event = as.integer(fail <= cens), X, W, Z)
  s <- fads_design(d, 't', 'event', 'W', 'X', 120, 4, seed = 2)
  fit <- fads(survival::Surv(t, event) ~ X + Z, s, 'X', 'W')
  expect_true(all(is.finite(coef(fit))))
})

test_that('vectorized and reference engines agree on a binary auxiliary', {
  set.seed(112)
  n <- 220
  X <- rbinom(n, 1, .4); W <- ifelse(runif(n) < .85, X, 1-X)
  Z <- rnorm(n)
  fail <- rexp(n, rate = exp(.7*X + .2*Z))
  cens <- rexp(n, rate = .3)
  d <- data.frame(t = pmin(fail,cens), event = as.integer(fail<=cens), X, W, Z)
  s <- fads_design(d, 't', 'event', 'W', 'X', 100, 2, seed = 4)
  fm <- survival::Surv(t,event) ~ X+Z
  a <- fads(fm, s, 'X', 'W', engine = 'reference')
  b <- fads(fm, s, 'X', 'W', engine = 'vectorized')
  expect_equal(unname(coef(a)), unname(coef(b)), tolerance = 1e-3)
  expect_equal(a$objective, b$objective, tolerance = 1e-5)
})
