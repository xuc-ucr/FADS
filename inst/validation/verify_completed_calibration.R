# Standalone checkpoint verification: no fitting, no expensive computation.
# Usage: source(system.file("validation/verify_completed_calibration.R", package="FADS"))
#        verify_completed_calibration("/path/to/fads038_calibration_M100_B100_stratum.rds")
verify_completed_calibration <- function(path, tolerance = 5e-5) {
  if (!file.exists(path)) stop("Checkpoint not found: ", path)
  source(system.file("validation/calibration_diagnostics.R", package="FADS"), local=TRUE)
  obj <- readRDS(path)
  if (!is.list(obj) || !all(c("settings", "records") %in% names(obj)))
    stop("Invalid checkpoint format")
  if (length(obj$records) != 100L) stop("Expected 100 Monte Carlo records")
  if (!all(vapply(obj$records, function(r) isTRUE(r$ok), logical(1))))
    stop("One or more Monte Carlo datasets failed")
  bs <- vapply(obj$records, function(r) as.integer(r$boot_success), integer(1))
  if (anyNA(bs) || any(bs < 2L) || any(bs > 100L)) stop("Invalid bootstrap success counts")
  result <- fads_calibration_diagnostics(path)
  s <- result$summary
  expected <- data.frame(variable=c("X", "Z"), mean_estimate=c(0.6953654, -0.5103336),
    bias=c(0.002218211, -0.010333587), empirical_sd=c(0.08668909, 0.15221986),
    mean_bootstrap_se=c(0.08866423, 0.14793702), coverage=c(0.94, 0.94))
  for (v in expected$variable) {
    a <- s[s$variable == v,,drop=FALSE]; b <- expected[expected$variable == v,,drop=FALSE]
    if (nrow(a) != 1L) stop("Missing parameter: ", v)
    for (nm in setdiff(names(expected), "variable")) {
      if (!isTRUE(all.equal(a[[nm]], b[[nm]], tolerance=tolerance)))
        stop("Calibration mismatch for ", v, ": ", nm, " (", a[[nm]], ")")
    }
  }
  cat("PASS: 100/100 datasets; minimum bootstrap successes:", min(bs), "/100\n")
  print(s)
  invisible(result)
}
