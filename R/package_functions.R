#' The psi function
#'
#' \code{psi} returns \deqn{\psi(x)=\sqrt{-W_{-1}(-x^2)}} using the Lambert W function
#' (see package LambertW).
#'
#' @param x a numeric value, possibly vectorized.
#' @return A numeric value, possibly vectorized.
#'
#' @examples
#' psi(.1)
#'
#' @keywords internal
#' @export

psi <- function(x) sqrt(-suppressWarnings(LambertW::W(-x^2, branch = -1)))

#' Modified vector dot product
#'
#' \code{riemsum} returns a modified dot product described by two vectors.
#'
#' @param x a numeric 'width' vector.
#' @param y a numeric 'height' vector.
#'
#' @return A numeric value.
#'
#' @examples
#' x <- 1:10
#' riemsum(x,x)
#'
#' @keywords internal
#' @export

riemsum <- function(x, y) {
    idx = 2:length(x)
    return(as.double((x[idx] - x[idx - 1]) %*% y[idx - 1]))
}

#' Variance of the cumulative-hazard function
#'
#' \code{cumhaz.var} estimates the cumulative-hazard function variance using Greenwood's
#' formula for a \code{survfit} object containing estimated survival curves.
#'
#' @param survi a \code{survfit} object.
#' @return A numeric vector.
#'
#' @examples
#'
#' library(survival)
#' fit <- survfit(Surv(stop, event) ~ 1, data=bladder)
#' cumhaz.var(fit)
#'
#' @keywords internal
#' @export

cumhaz.var <- function(survi) {
    a <- survi$n.event/(survi$n.risk * (survi$n.risk - survi$n.event))
    return(survi$n * cumsum(a))
}

#' Evaluate whether times are in an interval
#'
#' \code{surv.range} evaluates \code{survfit} object survival times by upper and lower bounds.
#'
#' @param survi a \code{survfit} object.
#' @param tl the lower bound.
#' @param tu the upper bound.
#'
#' @examples
#' library(survival)
#' fit <- survfit(Surv(stop, event) ~ 1, data=bladder)
#' summary(fit)
#' surv.range(fit, .1, .9)
#'
#' @return A boolean vector.
#' @keywords internal
#' @export

surv.range = function(survi, tl, tu) (survi$time >= tl & survi$time <= tu)

#' Truncate \code{survfit} object
#'
#' \code{modify.surv.fun} truncates \code{survfit} by upper and lower bounds.
#'
#' @param survi a \code{survfit} object.
#' @param tl the lower bound.
#' @param tu the upper bound.
#'
#' @examples
#' library(survival)
#' fit <- survfit(Surv(stop, event) ~ 1, data=bladder)
#' fit2 <- modify.surv.fun(fit, .1, .9)
#'
#' @return A truncated \code{survfit} object.
#' @keywords internal
#' @export

modify.surv.fun <- function(survi, tl, tu) {
    idx = surv.range(survi, tl, tu)

    survi$time <- survi$time[idx]
    survi$n.risk <- survi$n.risk[idx]
    survi$n.event <- survi$n.event[idx]
    survi$surv <- survi$surv[idx]
    survi$std.err <- survi$std.err[idx]
    survi$upper <- survi$upper[idx]
    survi$lower <- survi$lower[idx]

    return(survi)
}

#' Aggregate \code{survfit} object strata
#'
#' \code{func.sum} calculates the sum and aggregate time points of two
#' cumulative-hazard functions or their variances, designed for use with
#' a \code{survfit} object having two strata.
#'
#' @param f1 vector of cumulative-hazard estimates.
#' @param f2 vector of cumulative-hazard estimates.
#' @param f1time vector of survival times for f1.
#' @param f2time vector of survival times for f2.
#'
#' @examples
#' library(survival)
#' res <- summary(survfit(Surv(stop, event) ~ rx, data=bladder))
#' cols <- lapply(c(2:11) , function(x) res[x])
#' tbl <- do.call(data.frame, cols)
#' category = unique(tbl$strata)
#' temptbl1 = tbl[tbl$strata == category[1],]; temptbl1$n = res$n[1]
#' temptbl2 = tbl[tbl$strata == category[2],]; temptbl2$n = res$n[2]
#' sigma1_2 = cumhaz.var(temptbl1)
#' sigma2_2 = cumhaz.var(temptbl2)
#' func.sum(c(0, sigma1_2)/temptbl1$n[1], c(0, sigma2_2)/temptbl2$n[2],
#'   c(0, temptbl1$time), c(0, temptbl2$time))
#'
#' @return A list of two numeric vectors.
#' @keywords internal
#' @export

func.sum = function(f1, f2, f1time, f2time){
  agg.time = sort(unique(c(f1time, f2time)))
  mysum = f1[findInterval(agg.time, f1time)] + f2[findInterval(agg.time, f2time)]
  return(list(mysum, agg.time))
}

#' Confidence bands optimized by area
#'
#' \code{opt.ci} obtains simultaneous confidence bands for the survival or
#' cumulative-hazard functions such that the area between is minimized.
#'
#' @param survi a \code{survfit} object.
#' @param conf.level desired coverage level.
#' @param fun "surv" for survival function and "cumhaz" for the cumulative-hazard.
#' function, with "surv" as the default.
#' @param tl a lower bound for truncation.
#' @param tu an upper bound for truncation.
#' @param samples the number of groups (1 or 2).
#'
#' @details Produces an approximate solution based on local time arguments.
#'
#' @examples
#' library(survival)
#' # fit and plot a Kaplan-Meier curve
#' fit <- survfit(Surv(stop, event) ~ 1, data=bladder)
#' plot(fit)
#' fit2 <- opt.ci(fit)
#' plot(fit2)
#'
#' @return A \code{survfit} object with optimized confidence bands.
#' @export

opt.ci = function(survi, conf.level=0.95, fun = "surv", tl = NA, tu = NA, samples=1){
  ## Return estimated optimal confidence band for survival data

  ## Error catching
  if (conf.level <= 0 || conf.level >= 1)
    stop("Confidence level must be between 0 and 1")
  if (data.class(survi) != "survfit")
    stop("Survi must be a survival object")

  ## Default: no truncation
  if(is.na(tl)&is.na(tu))
  {
    tl <- min(survi$time[survi$n.event>0])
    tu <- max(survi$time[survi$n.event>0 & survi$n.risk>survi$n.event])
  }

  ## Constants
  a = -0.4272; b = 0.2848
  idx = surv.range(survi, tl, tu)

  ## Confidence bands
  if (fun == "surv"){
    ## Confidence band for estimated survival function

    tot = sum(idx)
    idx1 = 1:(tot-1)
    idx2 = 2:tot
    sigma_2 = cumhaz.var(survi)[idx]

    survi <- modify.surv.fun(survi, tl, tu)
    surv.mid = (survi$surv[idx1]+survi$surv[idx2])/2
    sigma_2_u = utils::tail(sigma_2, 1)

    #Coefficients of empirical relationship
    a1 = a*utils::tail(surv.mid, 1)^2
    b1 = (a + b*rev(sigma_2)[2]/sigma_2_u)*utils::tail(surv.mid, 1) - b/sigma_2_u*riemsum(utils::head(sigma_2, -2), utils::head(surv.mid, -1))
    c1 = 1 - conf.level

    #Apply quadratic formula
    kappa = (-b1 - sqrt(b1^2 - 4*a1*c1))/(2*a1)

    s = sigma_2/sigma_2_u
    c_t = psi(kappa*survi$surv*s)*sqrt(sigma_2/survi$n)
    survi$lower = pmax(survi$surv*(1-c_t), 0)
    survi$upper = pmin(survi$surv*(1+c_t), 1)

  } else if (fun == "cumhaz" && samples == 1){
    ## Confidence band for estimated cumulative-hazard function

    sigma_2 = cumhaz.var(survi)[idx]
    sigma_2_u = utils::tail(sigma_2, n = 1)
    s = sigma_2/sigma_2_u
    L = s[1]
    kappa = (-(a+b*L)-sqrt((a+b*L)^2-4*a*(1-conf.level)))/(2*a)  #Empirical relationship

    ## Truncate
    survi <- modify.surv.fun(survi, tl, tu)
    c_t = psi(kappa*s)*sqrt(sigma_2/survi$n)

    ## Transform
    survi$lower = pmax(survi$surv*exp(-c_t), 0)
    survi$upper = pmin(survi$surv*exp(c_t), 1)

  } else if (fun == "cumhaz" && samples == 2){
    ## Confidence band for estimated 2-sample cumulative-hazard function difference

    #Aggregate all strata
    res <- summary(survi)
    cols <- lapply(c(2:11) , function(x) res[x])
    tbl <- do.call(data.frame, cols)
    category = unique(tbl$strata)

    if (length(category) > 2)
      stop("There must be only two strata")

    ## Confidence bands

    temptbl1 = tbl[tbl$strata == category[1],]; temptbl1$n = survi$n[1]
    temptbl2 = tbl[tbl$strata == category[2],]; temptbl2$n = survi$n[2]
    sigma1_2 = cumhaz.var(temptbl1)
    sigma2_2 = cumhaz.var(temptbl2)

    sigma2funcsum = func.sum(c(0, sigma1_2)/temptbl1$n[1], c(0, sigma2_2)/temptbl2$n[2],
                             c(0, temptbl1$time), c(0, temptbl2$time))
    agg.time = sigma2funcsum[[2]]
    se2_agg = sigma2funcsum[[1]][agg.time >= tl & agg.time <= tu]
    survfuncration = func.sum(-log(c(1, temptbl1$surv)), log(c(1, temptbl2$surv)),
                              c(0, temptbl1$time), c(0, temptbl2$time))
    agg.time = survfuncration[[2]]
    surv_ratio = exp(survfuncration[[1]][agg.time >= tl & agg.time <= tu])

    sigma_2_u = utils::tail(se2_agg, n = 1)
    s = se2_agg/sigma_2_u
    L = s[1]
    kappa = (-(a+b*L)-sqrt((a+b*L)^2-4*a*(1-conf.level)))/(2*a)  #Empirical relationship

    c_t = psi(kappa*s)*sqrt(se2_agg)

    ## Transform
    survi$lower = surv_ratio*exp(-c_t)
    survi$upper = surv_ratio*exp(c_t)
    survi$difference <- -log(surv_ratio)
    survi$time <- agg.time[-c(length(agg.time))]

    return(survi)

  } else if (fun == "surv" && samples == 2)
      stop("2-sample bands are not available for the survival function")
    else
      stop("Either 'surv' or 'cumhaz' required for function argument, samples must be 1 or 2")

    return(survi)
}
