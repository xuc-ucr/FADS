#' Draw a two-phase FADS sample from a complete cohort
#'
#' @param data Complete cohort data frame; X is available here only to simulate selection.
#' @param time,status,auxiliary Column names for observed time, event indicator, and auxiliary variable.
#' @param expensive Column names of expensive covariates to mask outside validation.
#' @param n_srs Size of initial simple random sample.
#' @param n_corner Supplemental sample size per corner stratum (four corners).
#' @param probs Cutoff quantiles of event times and continuous auxiliary values.
#' @param seed Optional random seed.
#' @return Data frame with .fads_group and .fads_stratum; expensive variables masked for nonvalidation.
#' @export
fads_design <- function(data, time, status, auxiliary, expensive, n_srs,
                        n_corner, probs = c(.3, .7), seed = NULL) {
  stopifnot(is.data.frame(data), length(probs) == 2L,
            all(probs > 0 & probs < 1), probs[1] < probs[2])
  cols <- c(time, status, auxiliary, expensive)
  if (!all(cols %in% names(data))) stop('Missing required columns')
  if (anyNA(data[, cols, drop = FALSE])) stop('Design requires complete cohort inputs')
  if (!all(data[[status]] %in% c(0, 1))) stop('status must be 0/1')
  n <- nrow(data)
  if (n_srs < 1L || n_srs > n) stop('Invalid n_srs')
  if (n_corner < 0L) stop('n_corner must be nonnegative')
  if (!is.null(seed)) set.seed(seed)
  ev <- data[[status]] == 1
  if (sum(ev) < 4L) stop('Insufficient cases for stratification')
  tbreak <- as.numeric(stats::quantile(data[[time]][ev], probs))
  if (anyDuplicated(tbreak)) stop('Event-time quantiles are tied')
  # Right-closed intervals: observations exactly on a cutoff remain in the lower stratum.
  tv <- findInterval(data[[time]], c(-Inf, tbreak, Inf),
                     left.open = TRUE, rightmost.closed = TRUE)
  w <- data[[auxiliary]]
  levels_w <- sort(unique(w))
  if (length(levels_w) == 2L) {
    wv <- match(w, levels_w)
    nw <- 2L
  } else {
    wb <- as.numeric(stats::quantile(w[ev], probs))
    if (anyDuplicated(wb)) stop('Auxiliary quantiles are tied; use binary or a continuous variable')
    wv <- findInterval(w, c(-Inf, wb, Inf),
                       left.open = TRUE, rightmost.closed = TRUE)
    nw <- 3L
  }
  stratum <- ifelse(ev, (tv - 1L) * nw + wv, 3L * nw + 1L)
  srs <- sample.int(n, n_srs)
  corner <- c(1L, nw, 2L * nw + 1L, 3L * nw)
  supplement <- integer()
  for (k in corner) {
    eligible <- setdiff(which(stratum == k), srs)
    if (length(eligible) < n_corner) stop(sprintf('Stratum %d has only %d eligible subjects', k, length(eligible)))
    if (n_corner > 0L) supplement <- c(supplement, sample(eligible, n_corner))
  }
  out <- data
  out$.fads_group <- 'nonvalidation'
  out$.fads_group[srs] <- 'srs'
  out$.fads_group[supplement] <- 'supplement'
  out$.fads_stratum <- stratum
  out$.fads_id <- seq_len(n)
  out[out$.fads_group == 'nonvalidation', expensive] <- NA
  attr(out, 'fads_design') <- list(time_breaks = tbreak, auxiliary_levels = if (nw == 2L) levels_w else NULL,
                                  n_srs = n_srs, n_supplement = length(supplement))
  out
}
