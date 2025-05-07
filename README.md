
# statlingua

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/dwyl/esta/issues)
<!-- badges: end -->

**statlingua** is an R package leveraging large language models to help convert complex statistical output into straightforward, understandable, and context-aware natural language descriptions. By feeding your statistical models and outcomes into this tool, you can effortlessly produce human-readable interpretations of coefficients, p-values, measures of model fit, and other key metrics, thereby democratizing statistical understanding for individuals with varying levels of technical expertise.

## Installation

The **statlingua** package is currently not available on CRAN, but you can install the development version from GitHub.

``` r
# Install the latest development version from GitHub:
if (!requireNamespace("remotes")) {
  install.packages("remotes")
}
remotes::install_github("bgreenwell/statlingua")
```

## Example

The following example uses the generic function `explain()` to explain the output from a fitted [Poisson GLM](https://en.wikipedia.org/wiki/Poisson_regression) using simple Markdown syntax:

``` r
library(statlingua)

# Poisson regression example from ?stats::glm
counts <- c(18,17,15,20,10,20,25,13,12)
outcome <- gl(3,1,9)
treatment <- gl(3,3)
data.frame(treatment, outcome, counts) # showing data
glm.D93 <- glm(counts ~ outcome + treatment, family = poisson())

# Use Google Gemini to explain the output; requires an API key; see
# ?ellmer::chat_gemini for details
chat <- ellmer::chat_gemini()
explain(glm.D93, chat = chat)
```
```
Here's a breakdown of the Poisson GLM output you provided:

**Overall Description**

This output summarizes a Generalized Linear Model (GLM) with a Poisson 
distribution and a log link function. The model aims to predict the `counts` 
variable based on the categorical predictors `outcome` (with 3 levels) and 
`treatment` (with 3 levels). The model estimates the log of the expected 
count as a linear combination of the predictor variables.

The prediction equation is as follows:

log(E[counts]) = 3.045 + (-0.4543 * outcome2) + (-0.2930 * outcome3) + 
(-3.242e-16 * treatment2) + (-2.148e-16 * treatment3)

Where:

*   outcome2 = 1 if outcome is level 2, 0 otherwise
*   outcome3 = 1 if outcome is level 3, 0 otherwise
*   treatment2 = 1 if treatment is level 2, 0 otherwise
*   treatment3 = 1 if treatment is level 3, 0 otherwise

**Coefficient Interpretation**

*   **(Intercept):** The estimated log of the expected count when `outcome` 
and `treatment` are at their baseline levels is 3.045.  This corresponds to 
an expected count of exp(3.045) ≈ 21.00.
*   **outcome2:**  Compared to the baseline level of `outcome`, when 
`outcome` is level 2, the log of the expected count is estimated to decrease 
by 0.4543. This suggests the expected count is exp(-0.4543) ≈ 0.635 times the
expected count at the baseline level of outcome, holding all other variables 
constant.
*   **outcome3:** Compared to the baseline level of `outcome`, when `outcome`
is level 3, the log of the expected count is estimated to decrease by 0.2930.
This suggests the expected count is exp(-0.2930) ≈ 0.746 times the expected 
count at the baseline level of outcome, holding all other variables constant.
*   **treatment2:** The coefficient is essentially zero. There is no 
practical difference in the log of expected counts between treatment 2 and 
the baseline treatment, holding all other variables constant.
*   **treatment3:** The coefficient is essentially zero. There is no 
practical difference in the log of expected counts between treatment 3 and 
the baseline treatment, holding all other variables constant.

**Confidence Intervals**

To calculate the 95% confidence intervals, we'll use the estimated 
coefficient ± (1.96 * Standard Error).

*   **(Intercept):** 3.045 ± (1.96 * 0.1709)  =>  [2.710, 3.380]. We are 95% 
confident that the true log of the expected count when both outcome and 
treatment are at their baseline levels lies between 2.710 and 3.380.
*   **outcome2:** -0.4543 ± (1.96 * 0.2022) => [-0.8506, -0.0580]. We are 95%
confident that the true difference in the log of expected counts between 
outcome level 2 and the baseline level lies between -0.8506 and -0.0580.
*   **outcome3:** -0.2930 ± (1.96 * 0.1927) => [-0.669, 0.0857]. We are 95% 
confident that the true difference in the log of expected counts between 
outcome level 3 and the baseline level lies between -0.669 and 0.0857.
*   **treatment2:** -3.242e-16 ± (1.96 * 0.2000) => [-0.392, 0.392]. We are 
95% confident that the true difference in the log of expected counts between 
treatment level 2 and the baseline level lies between -0.392 and 0.392.
*   **treatment3:** -2.148e-16 ± (1.96 * 0.2000) => [-0.392, 0.392]. We are 
95% confident that the true difference in the log of expected counts between 
treatment level 3 and the baseline level lies between -0.392 and 0.392.

**AIC Interpretation**

The Akaike Information Criterion (AIC) is 56.761.  AIC is used to compare 
different models; lower AIC values indicate a better balance between model 
fit and complexity.  It's only meaningful when compared to the AIC of other 
models fitted to the same data.

**Deviance Interpretation**

*   **Null deviance:** 10.5814 on 8 degrees of freedom. This represents the 
deviance of the model with only the intercept (i.e., the total variability in
the data before any predictors are included).
*   **Residual deviance:** 5.1291 on 4 degrees of freedom. This represents 
the deviance of the model with the predictors included (i.e., the variability
remaining after the predictors are considered).

The difference between the null deviance and the residual deviance (10.5814 -
5.1291 = 5.4523) indicates the amount of deviance explained by the 
predictors.  A substantial reduction in deviance suggests that the predictors
are useful in explaining the variation in the counts.

**Overdispersion**

To assess overdispersion, we can compare the residual deviance to the 
residual degrees of freedom.  If the residual deviance is substantially 
larger than the degrees of freedom, it suggests overdispersion.  In this 
case, 5.1291 (residual deviance) is greater than 4 (residual degrees of 
freedom), but not by a large amount. A formal test for overdispersion (e.g., 
using a likelihood ratio test comparing the Poisson model to a quasi-Poisson 
model) would provide a more definitive answer.  If overdispersion is present,
the standard errors of the coefficients will be underestimated, potentially 
leading to incorrect conclusions about statistical significance.

**Zero Inflation**

Poisson models assume that the mean and variance are equal. For modeling 
count data, sometimes there are more zero counts than would be expected from 
a Poisson distribution. This is called *zero inflation*. The output you 
provided does not give any direct indication of zero inflation, and further 
investigation would be required to determine if this is a problem. Typically,
a zero-inflated Poisson (ZIP) model is fit and compared to the standard 
Poisson model. You can assess the need for zero inflation by:

1.  Examining the distribution of your `counts` variable.  Are there a 
surprisingly large number of zeros?
2.  Fitting a ZIP model and comparing its AIC and likelihood to the standard 
Poisson model.
3.  Performing a Vuong test to formally compare the Poisson and ZIP models.
```
