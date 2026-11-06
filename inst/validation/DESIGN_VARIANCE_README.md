# FADS 0.3.7: fixed-cohort vs independent-cohort variation

This release preserves the **unchanged 0.3.6 estimation and bootstrap algorithms**.
The new `design_variance_audit.R` is a **simulation-only** diagnostic, not an alternative estimator or a bootstrap implementation.

## Run in a fresh R session

```r
library(FADS)
stopifnot(as.character(packageVersion('FADS')) == '0.3.7')
source(system.file('validation/design_variance_audit.R', package='FADS'))
audit <- fads_design_variance_audit(
  M=20, N=3000, n_srs=400, n_corner=10,
  checkpoint='fads037_design_pilot.rds')
print(audit$fixed$summary)
print(audit$independent$summary)
print(audit$comparison)
```

The fixed-cohort experiment regenerates the *same* full cohort on every run, but independently redraws the SRS and supplemental sample. The independent-cohort experiment generates a new cohort and independently redraws the two-phase sample. Both use identical sample sizes and model parameters. The full expensive covariate is used **only** for simulated sample construction, then masked before estimation. Separate, deterministic seeds are used for cohort generation and sampling. Both arms are checkpointed after each completed fit and resume without repeating finished runs.

**Interpretation:** The fixed-cohort SD measures phase-two selection variation *conditional on one generated cohort*. The independent-cohort SD measures total variation across independently generated cohorts and two-phase samples. Their ratio is descriptive; the variances are **not automatically additive** from these two small experiments. In particular, the fixed cohort is only one draw, and the two arms are not paired. This pilot cannot establish bootstrap validity or nominal confidence-interval coverage.

The next scientific step is to compare the actual cohort-bootstrap SEs with the appropriate repeated-sampling distribution, and separately audit the original paper's bootstrap target. This simulation-only comparison does not by itself validate an operational bootstrap for partially observed data.

No R runtime was available to execute this script during packaging. Check results on a machine with R before scientific use.
