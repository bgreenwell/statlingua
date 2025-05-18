# statlingua

**WARNING:** This package is a work in progess! Use with caution.

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/dwyl/esta/issues)
[![R-CMD-check](https://github.com/bgreenwell/statlingua/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/bgreenwell/statlingua/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**statlingua** is an R package leveraging large language models to help convert complex statistical output into straightforward, understandable, and context-aware natural language descriptions. By feeding your statistical models and outcomes into this tool, you can effortlessly produce human-readable interpretations of coefficients, p-values, measures of model fit, and other key metrics, thereby democratizing statistical understanding for individuals with varying levels of technical expertise.

As of now, **statlingua** supports the following types of statistical models:

* Object of class `"htest"` (e.g., R's built in `t.test()` and `prop.test()` functions).
* Linear and generalized linear models (i.e., R's built-in `lm()` and `glm()` functions).
* Linear and generalized linear mixed-effects model from packages [nlme](https://cran.r-project.org/package=nlme) and [lme4](https://cran.r-project.org/package=lme4).
* Generalized additive models from package [mgcv](https://cran.r-project.org/package=mgcv).
* Survival regression models from package [survival](https://cran.r-project.org/package=survival).
* Proportional odds regression models from package [MASS](https://cran.r-project.org/package=MASS).

## Installation

The **statlingua** package is currently not available on CRAN, but you can install the development version from GitHub.

``` r
# Install the latest development version from GitHub:
if (!requireNamespace("remotes")) {
  install.packages("remotes")
}
remotes::install_github("bgreenwell/statlingua")
```
