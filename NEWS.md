# FADS 0.4.0

Initial GitHub release of the FADS R package implementing the two-phase failure-time-auxiliary-dependent sampling design and inference under the Cox model, as described in Cao, Zhou, Cai, and Zhou (2025).

## Main Features

- `fads_design()` implements the two-phase FADS sampling design.
- `fads()` computes the semiparametric pseudo-likelihood estimator of regression coefficients.
- `fads_bootstrap()` estimates standard errors using bootstrap.

## Documentation and Validation

- Includes documentation and reproducible examples demonstrating package usage.
- Provides simulation-based validation of the estimator and bootstrap inference.
- Includes automated package testing on Windows, macOS, and Linux.
