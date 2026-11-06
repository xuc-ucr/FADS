test_that("release API preserves bandwidth choice", {
  expect_true("bandwidth_method" %in% names(formals(FADS::fads)))
  expect_true("engine" %in% names(formals(FADS::fads)))
  expect_true("B" %in% names(formals(FADS::fads_bootstrap)))
})
