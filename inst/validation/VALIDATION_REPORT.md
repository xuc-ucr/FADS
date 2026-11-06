# Simulation validation report

## Scope

FADS implements a two-phase failure-time-auxiliary-dependent sampling estimator for right-censored survival outcomes. This public repository demonstrates the method with **simulated data only**. It does not claim to reproduce the original paper's simulation table exactly.

## Completed calibration experiment

The research team ran 100 independently simulated cohorts with 100 bootstrap attempts per cohort (N = 3,000, n_srs = 400, n_corner = 10, stratum-specific bandwidth; simulation seed = 20261020). Results were:

| Parameter | Truth | Mean estimate | Bias | Empirical SD | Mean bootstrap SE | 95% coverage |
|---|---:|---:|---:|---:|---:|---:|
| X | 0.693147 | 0.695365 | 0.002218 | 0.086689 | 0.088664 | 0.94 |
| Z | -0.500000 | -0.510334 | -0.010334 | 0.152220 | 0.147937 | 0.94 |

All 100 Monte Carlo datasets completed; some individual bootstrap fits failed (minimum 94 successful out of 100 for any dataset). The figures are the research team's recorded results, not a fresh run of this GitHub distribution. The study validates one simulation setting only.

## Reproduce

See `simulation_validation.R`, `run_calibration.R`, and `calibration_diagnostics.R` in this directory. The full experiment is computationally intensive; start with a small pilot. Checkpoint files are not included in the package.
