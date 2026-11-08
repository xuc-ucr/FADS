# FADS v0.4.0 — Release Summary

## Completed

- [x] Implement the FADS estimator, two-phase sampling design, and bootstrap inference.
- [x] Complete the 100 × 100 Monte Carlo calibration study.
- [x] Include all four paper authors in the package metadata.
- [x] Configure Xu Cao (xuc@ucr.edu) as package maintainer.
- [x] Create the GitHub repository `xuc-ucr/FADS`.
- [x] Upload the simulation-focused package without the Wilms' Tumor Study application.
- [x] Pass the full local R CMD check with vignettes (0 errors, 0 warnings, 1 timestamp-related NOTE).
- [x] Successfully install FADS v0.4.0 from GitHub.
- [x] Pass the GitHub Actions R-CMD-check workflow.

## Public Release Completed

- [x] Obtain final approval from Dr. Zhou.
- [x] Change repository visibility from Private to Public.
- [x] Create the official GitHub release v0.4.0.
- [x] Verify installation from the public repository without authentication.

## Release Notes

FADS v0.4.0 provides semiparametric estimation and bootstrap inference for two-phase failure-time-auxiliary-dependent sampling designs.

The public package contains simulation-based examples and does not include the Wilms' Tumor Study application.

The package passed the full local R CMD check with no errors or warnings. The remaining NOTE concerned system-time verification. Installation directly from GitHub also succeeded.

The GitHub Actions R-CMD-check workflow completed successfully.

No CRAN submission is currently planned.

**Do not commit private research data, authentication credentials, or simulation checkpoint `.rds` files.**
