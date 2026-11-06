test_that('sampling labels and expensive-variable masking are correct', {
  set.seed(1)
  n <- 400
  d <- data.frame(t = runif(n, .01, 10), event = rbinom(n, 1, .7),
                  X = rnorm(n), W = rep(c(0, 1), length.out = n), Z = rnorm(n))
  s <- fads_design(d, 't', 'event', 'W', 'X', n_srs = 60, n_corner = 2, seed = 42)
  expect_equal(sum(s$.fads_group == 'srs'), 60)
  expect_equal(sum(s$.fads_group == 'supplement'), 8)
  expect_true(all(is.na(s$X[s$.fads_group == 'nonvalidation'])))
  expect_true(all(!is.na(s$X[s$.fads_group != 'nonvalidation'])))
})


test_that('observations exactly on event-time cutoffs use right-closed strata', {
  # Distinct 30th/70th percentiles with deliberately repeated cutoff values.
  d <- data.frame(t = rep(1:10, each = 10), event = 1L,
                  W = rep(c(0, 1), 50), X = seq_len(100))
  s <- fads_design(d, 't', 'event', 'W', 'X',
                   n_srs = 40, n_corner = 0, seed = 55)
  breaks <- as.numeric(stats::quantile(d$t, c(.3, .7)))
  expected_time <- cut(d$t, breaks = c(-Inf, breaks, Inf),
                       right = TRUE, include.lowest = TRUE, labels = FALSE)
  expected <- (expected_time - 1L) * 2L + match(d$W, c(0, 1))
  expect_equal(s$.fads_stratum, expected)
})
