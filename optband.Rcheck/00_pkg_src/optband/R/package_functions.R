#' The psi function
#'
#' \code{psi} returns \deqn{\psi(x)=\sqrt{-W_{-1}(-x^2)}} using the Lambert W function
#' (see \url{https://en.wikipedia.org/wiki/Lambert_W_function}).
#'
#' @param x a numeric value, possibly vectorized.
#' @return A numeric value, possibly vectorized.
#' @keywords internal
#' export

psi <- function(x) sqrt(-suppressWarnings(LambertW::W(-x^2, branch = -1)))

#' Modified vector dot product
#'
#' \code{riemsum} returns a modified dot product described by two vectors.
#'
#' @param x a numeric 'width' vector.
#' @param y a numeric 'height' vector.
#'
#' @return A numeric value.
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
#' @keywords internal
#' @export

cumhaz.var <- function(survi) {
    a <- survi$n.event/(survi$n.risk * (survi$n.risk - survi$n.event))
    return(survi$n * cumsum(a))
}

#' Truncate times
#'
#' \code{surv.range} truncates survival times by upper and lower bounds.
#'
#' @param survi a \code{survfit} object.
#' @param tl the lower bound.
#' @param tu the upper bound.
#'
#' @return A \code{survfit} object with truncated survival times.
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
#'
#' @details Produces an approximate solution based on local time arguments.
#'
#' @return A \code{survfit} object with optimized confidence bands.
#' @export

opt.ci <- function(survi, conf.level = 0.95, fun = "surv", tl = NA, tu = NA) {
    ## Error catching
    if (conf.level <= 0 || conf.level >= 1)
        stop("Confidence level must be between 0 and 1")
    if (data.class(survi) != "survfit")
        stop("Survi must be a survival object")

    ## Default: no truncation
    if (is.na(tl) & is.na(tu)) {
        tl <- min(survi$time[survi$n.event > 0])
        tu <- max(survi$time[survi$n.event > 0 & survi$n.risk > survi$n.event])
    }

    ## Constants
    a = -0.4272
    b = 0.2848
    idx = surv.range(survi, tl, tu)

    ## Confidence bands
    if (fun == "surv") {
        ## Confidence band for estimated survival function

        tot = sum(idx)
        idx1 = 1:(tot - 1)
        idx2 = 2:tot
        sigma_2 = cumhaz.var(survi)[idx]

        survi <- modify.surv.fun(survi, tl, tu)
        surv.mid = (survi$surv[idx1] + survi$surv[idx2])/2
        sigma_2_u = utils::tail(sigma_2, 1)

        # Coefficients of empirical relationship
        a1 = a * utils::tail(surv.mid, 1)^2
        b1 = (a + b * rev(sigma_2)[2]/sigma_2_u) * utils::tail(surv.mid, 1) - b/sigma_2_u *
            riemsum(utils::head(sigma_2, -2), utils::head(surv.mid, -1))
        c1 = 1 - conf.level

        # Apply quadratic formula
        kappa = (-b1 - sqrt(b1^2 - 4 * a1 * c1))/(2 * a1)

        s = sigma_2/sigma_2_u
        c_t = psi(kappa * survi$surv * s) * sqrt(sigma_2/survi$n)
        survi$lower = pmax(survi$surv * (1 - c_t), 0)
        survi$upper = pmin(survi$surv * (1 + c_t), 1)

    } else if (fun == "cumhaz") {
        ## Confidence band for estimated cumulative-hazard function

        sigma_2 = cumhaz.var(survi)[idx]
        sigma_2_u = utils::tail(sigma_2, n = 1)
        s = sigma_2/sigma_2_u
        L = s[1]
        kappa = (-(a + b * L) - sqrt((a + b * L)^2 - 4 * a * (1 - conf.level)))/(2 *
            a)  #Empirical relationship

        ## truncate
        survi <- modify.surv.fun(survi, tl, tu)
        c_t = psi(kappa * s) * sqrt(sigma_2/survi$n)

        ## transform
        survi$lower = pmax(survi$surv * exp(-c_t), 0)
        survi$upper = pmin(survi$surv * exp(c_t), 1)

    } else stop("Either 'surv' or 'cumhaz' required for function argument")

    return(survi)
}
