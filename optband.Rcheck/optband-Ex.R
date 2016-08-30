pkgname <- "optband"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
library('optband')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
cleanEx()
nameEx("cumhaz.var")
### * cumhaz.var

flush(stderr()); flush(stdout())

### Name: cumhaz.var
### Title: Variance of the cumulative-hazard function
### Aliases: cumhaz.var
### Keywords: internal

### ** Examples


library(survival)
fit <- survfit(Surv(stop, event) ~ 1, data=bladder)
cumhaz.var(fit)




cleanEx()
nameEx("modify.surv.fun")
### * modify.surv.fun

flush(stderr()); flush(stdout())

### Name: modify.surv.fun
### Title: Truncate 'survfit' object
### Aliases: modify.surv.fun
### Keywords: internal

### ** Examples

library(survival)
fit <- survfit(Surv(stop, event) ~ 1, data=bladder)
fit2 <- modify.surv.fun(fit, .1, .9)




cleanEx()
nameEx("opt.ci")
### * opt.ci

flush(stderr()); flush(stdout())

### Name: opt.ci
### Title: Confidence bands optimized by area
### Aliases: opt.ci

### ** Examples

library(survival)
# fit and plot a Kaplan-Meier curve
fit <- survfit(Surv(stop, event) ~ 1, data=bladder)
plot(fit)
fit2 <- opt.ci(fit)
plot(fit2)




cleanEx()
nameEx("psi")
### * psi

flush(stderr()); flush(stdout())

### Name: psi
### Title: The psi function
### Aliases: psi
### Keywords: internal

### ** Examples

psi(.1)




cleanEx()
nameEx("riemsum")
### * riemsum

flush(stderr()); flush(stdout())

### Name: riemsum
### Title: Modified vector dot product
### Aliases: riemsum
### Keywords: internal

### ** Examples

x <- 1:10
riemsum(x,x)




cleanEx()
nameEx("surv.range")
### * surv.range

flush(stderr()); flush(stdout())

### Name: surv.range
### Title: Evaluate whether times are in an interval
### Aliases: surv.range
### Keywords: internal

### ** Examples

library(survival)
fit <- survfit(Surv(stop, event) ~ 1, data=bladder)
summary(fit)
surv.range(fit, .1, .9)




### * <FOOTER>
###
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
