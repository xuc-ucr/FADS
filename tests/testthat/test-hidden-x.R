test_that('nonvalidation expensive values cannot influence fitted coefficients', {
  set.seed(24)
  n <- 260
  X <- rbinom(n, 1, .4)
  W <- ifelse(runif(n) < .9, X, 1-X)
  Z <- rnorm(n)
  fail <- rexp(n, rate = exp(.7*X + .2*Z))
  cens <- rexp(n, rate = .2)
  d <- data.frame(t=pmin(fail,cens), event=as.integer(fail<=cens), X, W, Z)
  s <- fads_design(d, 't', 'event', 'W', 'X', 120, 3, seed=2)
  form <- survival::Surv(t,event) ~ X+Z
  a <- fads(form, s, 'X', 'W', engine='vectorized')
  s$X[s$.fads_group == 'nonvalidation'] <- 999
  b <- fads(form, s, 'X', 'W', engine='vectorized')
  expect_equal(coef(a), coef(b), tolerance=1e-8)
})
