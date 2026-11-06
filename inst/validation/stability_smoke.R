# Run after library(FADS) and source(system.file('validation/simulation_validation.R', package='FADS'))
# Fresh checkpoint: v0.3.3 failure records should not be reused.
result <- fads_validation_run(M = 10, B = 0, N = 3000, n_srs = 400,
                              n_corner = 10, seed = 20261020L,
                              checkpoint = 'fads_stability_034.rds')
print(result$summary)
cat('Successful:', result$successful, '/', result$completed, '\n')
if (result$successful < result$completed) {
  print(vapply(result$failed, function(x) x$error, character(1)))
}
