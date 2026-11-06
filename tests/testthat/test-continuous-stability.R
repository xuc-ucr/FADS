test_that('continuous auxiliary extreme targets retain nonzero donor support', {
  set.seed(20261020)
  n <- 600
  X <- rnorm(n)
  Z <- rbinom(n, 1, .5)
  W <- X + rnorm(n, sd = .8)
  failure <- rexp(n, rate = exp(log(2) * X - .5 * Z))
  censor <- runif(n, 0, 1.2)
  d <- data.frame(t = pmin(failure, censor), status = as.integer(failure <= censor), X, Z, W)
  s <- fads_design(d, 't', 'status', 'W', 'X', n_srs = 250, n_corner = 1, seed = 3)
  # Change an extreme auxiliary value for a nonvalidation subject while
  # keeping stratum labels fixed; only numerical stability is under test.
  j <- which(s$.fads_group == 'nonvalidation')[1]
  s$W[j] <- -20
  fit <- fads(survival::Surv(t, status) ~ X + Z, s, 'X', 'W', engine = 'vectorized')
  expect_true(all(is.finite(coef(fit))))
  expect_true(is.finite(fit$objective))
})

test_that('continuous auxiliary vectorized and reference objectives agree', {
  set.seed(810)
  n <- 700
  X <- rnorm(n); Z <- rbinom(n, 1, .5)
  W <- X + rnorm(n, sd = .8)
  failure <- rexp(n, rate = exp(.7 * X - .5 * Z))
  censor <- runif(n, 0, 1.5)
  d <- data.frame(t = pmin(failure, censor), status = as.integer(failure <= censor), X, Z, W)
  s <- fads_design(d, 't', 'status', 'W', 'X', n_srs = 300, n_corner = 1, seed = 5)
  f <- survival::Surv(t, status) ~ X + Z
  a <- fads(f, s, 'X', 'W', engine = 'reference')
  b <- fads(f, s, 'X', 'W', engine = 'vectorized')
  expect_equal(unname(coef(a)), unname(coef(b)), tolerance = 1e-3)
  expect_equal(a$objective, b$objective, tolerance = 1e-5)
})
