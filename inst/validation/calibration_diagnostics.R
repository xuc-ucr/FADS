# Inspect any checkpoint created by run_calibration.R without refitting.
fads_calibration_diagnostics <- function(path) {
  s <- readRDS(path)
  if (!all(c('settings','records') %in% names(s))) stop('Unexpected checkpoint structure')
  true <- c(X=log(2), Z=-0.5)
  records <- s$records
  rows <- lapply(seq_along(records), function(i) {
    r <- records[[i]]
    if (!isTRUE(r$ok)) return(data.frame(replicate=i, variable=NA_character_,
      estimate=NA_real_, se=NA_real_, covered=NA, boot_success=NA_integer_,
      failure=if (is.null(r$error)) 'unknown' else r$error))
    do.call(rbind, lapply(names(true), function(v) {
      est <- unname(r$estimate[v]); se <- unname(r$se[v])
      data.frame(replicate=i, variable=v, estimate=est, se=se,
        covered=if (is.finite(se) && se > 0) abs(est-true[v]) <= 1.96*se else NA,
        boot_success=as.integer(r$boot_success), failure=NA_character_)
    }))
  })
  detail <- do.call(rbind, rows)
  good <- detail[!is.na(detail$variable),,drop=FALSE]
  aggregate_rows <- lapply(names(true), function(v) {
    q <- good[good$variable==v,,drop=FALSE]
    n <- nrow(q)
    data.frame(variable=v, successful_datasets=n,
      mean_estimate=if(n) mean(q$estimate) else NA_real_,
      bias=if(n) mean(q$estimate)-true[v] else NA_real_,
      empirical_sd=if(n>1) sd(q$estimate) else NA_real_,
      mean_bootstrap_se=if(n) mean(q$se) else NA_real_,
      rms_bootstrap_se=if(n) sqrt(mean(q$se^2)) else NA_real_,
      coverage=if(n) mean(q$covered) else NA_real_,
      coverage_mcse=if(n) sqrt(mean(q$covered)*(1-mean(q$covered))/n) else NA_real_,
      min_bootstrap_success=if(n) min(q$boot_success) else NA_integer_)
  })
  list(summary=do.call(rbind,aggregate_rows), detail=detail, settings=s$settings)
}
