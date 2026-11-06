# Long-running validation. Run in an R session with FADS >= 0.3.8 installed.
# This script NEVER starts automatically on package load.
# Set FADS_M and FADS_B in your R session to override defaults.
# The checkpoint is saved after every independently simulated dataset.

if (packageVersion('FADS') < '0.4.0') stop('Install FADS >= 0.4.0 first')
source(system.file('validation/simulation_validation.R', package='FADS'))
M <- if (exists('FADS_M', inherits=TRUE)) get('FADS_M', inherits=TRUE) else 30L
B <- if (exists('FADS_B', inherits=TRUE)) get('FADS_B', inherits=TRUE) else 100L
if (!is.numeric(M) || M < 2 || M != as.integer(M) ||
    !is.numeric(B) || B < 2 || B != as.integer(B)) stop('M and B must be integers >= 2')
checkpoint <- sprintf('fads040_calibration_M%d_B%d_stratum.rds', M, B)
cat('Starting/resuming:', checkpoint, '\n')
cat('Monte Carlo datasets:', M, 'bootstrap replicates per dataset:', B, '\n')
cat('Note: this may take hours. Checkpoints save after each completed dataset.\n')
res <- fads_validation_run(M=M, B=B, N=3000L, n_srs=400L,
                           n_corner=10L, seed=20261020L,
                           bandwidth_method='stratum',
                           checkpoint=checkpoint)
print(res$summary)
cat('Successful datasets:', res$successful, 'of', res$completed, '\n')
cat('Bootstrap successes per dataset:\n')
print(res$bootstrap_successes)
