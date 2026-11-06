test_that('simulation validation script is installed with package', {
  path <- system.file('validation/simulation_validation.R', package = 'FADS')
  expect_true(nzchar(path))
})
