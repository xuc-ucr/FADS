# FADS

**Semiparametric inference for two-phase failure-time-auxiliary-dependent sampling**

FADS is a research R package implementing two-phase sampling, a semiparametric pseudo-likelihood estimator for right-censored Cox models with expensive covariates measured on a validation subsample, and cohort-bootstrap inference. This public repository uses **simulation examples only**.

## Install from GitHub

```r
install.packages("remotes")
remotes::install_github("xuc-ucr/FADS", build_vignettes = FALSE)
library(FADS)
```

The repository will be hosted at https://github.com/xuc-ucr/FADS once published.

## Quick start: simulated data

```r
library(FADS)
library(survival)
set.seed(123)
N <- 1500L
X <- rnorm(N)
Z <- rbinom(N, 1, 0.5)
W <- X + rnorm(N, sd = 0.8)
T <- rexp(N, rate = exp(log(2) * X - 0.5 * Z))
C <- runif(N, 0, 0.5)
d <- data.frame(time = pmin(T, C), status = as.integer(T <= C), X, Z, W)
s <- fads_design(d, "time", "status", "W", "X",
                 n_srs = 300, n_corner = 5, seed = 123)
fit <- fads(Surv(time, status) ~ X + Z, s,
            expensive = "X", auxiliary = "W",
            bandwidth_method = "stratum")
coef(fit)
# Bootstrap inference (can take several minutes)
# fit_boot <- fads_bootstrap(fit, B = 30)
# summary(fit_boot)
```

For an extended tutorial, see `vignettes/intro.Rmd`. Simulation generation, checkpointed Monte Carlo studies, and calibration diagnostics are under `inst/validation/`.

## Numerical validation

A research-team simulation of 100 independent cohorts, each with 100 bootstrap attempts (N = 3000, SRS = 400, 10 supplemental cases per selected corner stratum, stratum-specific bandwidth), produced:

| Parameter | Bias | Empirical SD | Mean bootstrap SE | Nominal 95% CI coverage |
|---|---:|---:|---:|---:|
| X | 0.002218 | 0.086689 | 0.088664 | 94% |
| Z | -0.010334 | 0.152220 | 0.147937 | 94% |

These results support the estimator under this setting; they do not establish performance for every design. See `inst/validation/VALIDATION_REPORT.md`.

## Development checks

```r
# From a local checkout of this repository:
# install.packages("devtools")
devtools::check(document = FALSE)
```

`NAMESPACE` and `man/*.Rd` are currently maintained manually. The preceding version passed a full R CMD check on R 4.2.3 (macOS) with zero errors, zero warnings, and one local-time verification note; **this GitHub-focused revision has not yet been independently checked in R**. GitHub Actions is configured to run checks on pushes and pull requests.

## Citation

If you use the FADS package in your research, please cite:

Cao, X., Zhou, Q., Cai, J., & Zhou, H. (2025). Semiparametric inference for a two-phase failure-time-auxiliary-dependent sampling design. *Statistics in Medicine, 44*(18–19), e70239. https://doi.org/10.1002/sim.70239

## Authors and Maintainer

**Package authors:** Xu Cao, Qingning Zhou, Jianwen Cai, and Haibo Zhou.

**Maintainer:** Xu Cao (xuc@ucr.edu).

## License

MIT (see `LICENSE`).
