# FADS v0.4.0: inference calibration validation

This release does not change the estimator or bootstrap algorithm from 0.3.7.
It adds a reproducible long-running validation driver and a checkpoint reader.

## On Mac RStudio

1. Install package from source and restart R. Check `packageVersion("FADS")`.
2. Run a pilot first: `FADS_M <- 5L; FADS_B <- 30L; source(system.file("validation/run_calibration.R", package="FADS"))`.
3. For the larger study: `FADS_M <- 100L; FADS_B <- 100L; source(system.file("validation/run_calibration.R", package="FADS"))`.
4. To inspect saved results: `source(system.file("validation/calibration_diagnostics.R",package="FADS")); out <- fads_calibration_diagnostics("fads040_calibration_M100_B100_stratum.rds"); print(out$summary)`.

The study can take many hours. Each finished Monte Carlo dataset is checkpointed.
Re-running with the same filename and settings resumes; failures already recorded are not automatically retried.
Checkpoints are written with saveRDS; interruption during a write could corrupt the checkpoint, so keep backup copies for long studies.

Interpret coverage carefully: M=100 still has ~2.2 percentage-point Monte Carlo SE when true coverage is 95%. B=100 is a practical compromise, not definitive bootstrap accuracy.

Do not present these simulation findings as reproduction of the paper's Table 1: simulation design differs.
