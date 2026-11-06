# Paired Monte Carlo validation: global vs stratum bandwidths.
# Run once after installing FADS 0.3.5:
# source(system.file('validation/simulation_validation.R', package='FADS'))
# source(system.file('validation/bandwidth_comparison.R', package='FADS'))
# Each method uses identical simulated cohorts, sampling seeds, and settings.
# No bootstrap in this pilot; results are saved in separate checkpoints.
if (!exists('fads_validation_run', mode = 'function')) {
  source(system.file('validation/simulation_validation.R', package = 'FADS'))
}
run_global <- fads_validation_run(
  M = 10, B = 0, N = 3000, n_srs = 400, n_corner = 10,
  bandwidth_method = 'global', checkpoint = 'fads0351_global_10.rds'
)
run_stratum <- fads_validation_run(
  M = 10, B = 0, N = 3000, n_srs = 400, n_corner = 10,
  bandwidth_method = 'stratum', checkpoint = 'fads0351_stratum_10.rds'
)
cat('\nGLOBAL bandwidth results:\n')
print(run_global$summary)
cat('Successful:', run_global$successful, '/', run_global$completed, '\n')
cat('\nSTRATUM bandwidth results:\n')
print(run_stratum$summary)
cat('Successful:', run_stratum$successful, '/', run_stratum$completed, '\n')
