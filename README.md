
<!-- README.md is generated from README.Rmd. Please edit that file -->
README
------

This package approaches simultaneous confidence bands for survival functions purely from an optimization perspective: given a certain coverage level, obtain bands such that the area between is minimized. `optband` imports `LambertW` and `utils` and provides an approximate solution based off local time arguments for both the survival and cumulative-hazard functions.

Installation
------------

``` r
install.packages("devtools", repos="http://cran.rstudio.com/")
#> 
#> The downloaded binary packages are in
#>  /var/folders/0g/wnxynt411mj4nn_wmt2kj5n40000gn/T//RtmpGG74z5/downloaded_packages
library(devtools)
devtools::install_github("seasamgo/optband")
library(optband)
```

Methods
-------

`opt.ci(survi, conf.level = 0.95, fun = 'surv', tl = NA, tu = NA, samples = 1)`

`opt.ci` takes a `survfit` object from the `survival` package with the desired 1 − *α* coverage level, function of interest (either `'surv'` for the survival function or `'cumhaz'` for the cumulative-hazard function), optional upper or lower bounds for data truncation, and the number of samples to consider (1 or 2). Defaults are *α* = 0.05, `fun = 'surv'`, `tl = NA`, `tu = NA`, `samples = 1`.

Other methods/functions are internal and include `cumhaz.var`, `func.sum`, `modify.surv.fun`, `psi`, `riemsum`, and `surv.range`. For more, please view their corresponding help file.

Example
-------

Obtain confidence band for bladder cancer data set inherent to the `survival` package:

``` r
library(survival)

## 1-sample case
dat <- bladder[bladder$enum==1,]
S <- survival::survfit(Surv(stop, event) ~ 1, type = "kaplan-meier", data = dat)
opt.S <- optband::opt.ci(S)
```
