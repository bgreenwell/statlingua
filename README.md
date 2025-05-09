# statlingua

**WARNING:** This package is a work in progess! Use with caution.

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

## Example: inappropriate use of two-sample t-test

The following example is taken from a [tutorial on paired t-tests](https://www.jmp.com/en/statistics-knowledge-portal/t-test/paired-t-test). Here we use an independent two-sample t-test to (inappropriately) analyze paired data.

``` r
context <- "
An instructor wants to use two exams in her classes next year. This year, she gives both exams to the students. She wants to know if the exams are equally difficult and wants to check this by comparing the two sets of scores. Here is the data:

 student exam_1_score exam_2_score
     Bob           63           69
    Nina           65           65
     Tim           56           62
    Kate          100           91
  Alonzo           88           78
    Jose           83           87
  Nikhil           77           79
   Julia           92           88
   Tohru           90           85
 Michael           84           92
    Jean           68           69
   Indra           74           81
   Susan           87           84
   Allen           64           75
    Paul           71           84
  Edwina           88           82
"

# Two-sample t-test
exam_scores <- read.csv("/Users/bgreenwell/Desktop/exam_scores.csv")
(res <- t.test(exam_scores$exam_1_score, y = exam_scores$exam_2_score))

#         Welch Two Sample t-test
#
# data:  exam_scores$exam_1_score and exam_scores$exam_2_score
# t = -0.33602, df = 27.307, p-value = 0.7394
# alternative hypothesis: true difference in means is not equal to 0
# 95 percent confidence interval:
#  -9.322782  6.697782
# sample estimates:
# mean of x mean of y
#   78.1250   79.4375

# Explain the output
chat <- ellmer::chat_gemini()
explain(res, chat = chat, context = context)
```
Here's an explanation of the Welch Two Sample t-test output you provided:

### 1. Summary of the Statistical Test

*   **Name of Test:** Welch Two Sample t-test (also known as an independent 
samples t-test with unequal variances).
*   **Purpose:** This test is used to compare the means of two independent 
groups. It determines if there's a statistically significant difference 
between the average values of a continuous variable (in this case, exam 
scores) for the two groups. The Welch's t-test is particularly useful when 
you suspect that the variances of the two groups might not be equal.
*   **Key Assumptions:**
    *   The data in each group are approximately normally distributed.
    *   The two groups are independent of each other. Note that while the 
standard independent samples t-test assumes equal variances between the two 
groups, the Welch's t-test relaxes this assumption.

### 2. Appropriateness of the Statistical Test

Based on the context, the Welch Two Sample t-test appears to be a reasonable 
choice. The instructor wants to compare the difficulty of two exams by 
comparing the scores of students who took both exams. Since each student took
both exams, the two samples of exam scores are **not independent**.

Using the *paired samples t-test* (using `t.test(exam_1_score, exam_2_score, 
paired = TRUE)`) may be more appropriate in this case, as it is designed for 
situations where the two sets of scores are related.

### 3. Suggestions for Checking Assumptions of the Statistical Test

Since the Welch Two Sample t-test was run on the data, and not the more 
appropriate paired samples t-test, the suggestions for checking assumptions 
will be based on the Welch Two Sample t-test.

Even though the Welch Two Sample t-test is more robust to violations of 
normality than the standard t-test, checking for normality is still 
important, especially with small sample sizes. Since the more appropriate 
paired samples t-test works by assessing the normality of the difference in 
exam scores, it is particularly important to check the normality assumption.

Here's how you can check the assumptions:

*   **Normality:**
    *   **Histograms:** Create histograms of the `exam_1_score` and 
`exam_2_score` variables separately. Look for a roughly bell-shaped 
distribution. Substantial skewness or multiple peaks could indicate a 
violation of normality. It is particularly important to examine a histogram 
of the differences in scores.
    *   **Q-Q Plots:** Create Q-Q plots for each variable (using `qqnorm()` 
in R). If the data are approximately normally distributed, the points should 
fall close to the diagonal line. Deviations from the line, especially at the 
ends, suggest non-normality.
    *   **Shapiro-Wilk Test:** You can use the Shapiro-Wilk test 
(`shapiro.test()`) to formally test for normality. However, be cautious when 
interpreting the results, especially with small sample sizes, as the test 
might not have enough power to detect deviations from normality. Use the 
Shapiro-Wilk test in conjunction with histograms and Q-Q plots.
*   **Independence:**
    *   Since each student took both exams, the two samples of exam scores 
are **not independent**. Using the *paired samples t-test* (using 
`t.test(exam_1_score, exam_2_score, paired = TRUE)`) may be more appropriate 
in this case.

### 4. Interpretation of the Output

Here's a breakdown of the output:

*   **`t = -0.33602`**: This is the calculated t-statistic. It measures the 
difference between the sample means relative to the variability within the 
samples. In other words, it's the signal-to-noise ratio.

*   **`df = 27.307`**: This represents the degrees of freedom for the test. 
Because a Welch's t-test was used, the degrees of freedom are not necessarily
a whole number.

*   **`p-value = 0.7394`**: This is the probability of observing a 
t-statistic as extreme as, or more extreme than, the one calculated 
(-0.33602), *assuming there is no true difference in the means of the two 
exam scores* (i.e., assuming the null hypothesis is true). In simpler terms, 
if the two exams were truly of equal difficulty, there's a 73.94% chance of 
seeing a difference in average scores as big as, or bigger than, the one 
observed in your sample.

*   **`alternative hypothesis: true difference in means is not equal to 0`**:
This states the alternative hypothesis being tested: that the population 
means of the two exam scores are different.

*   **`95 percent confidence interval: -9.322782  6.697782`**: This interval 
provides a range of plausible values for the *true difference* in population 
means (exam\_1\_score - exam\_2\_score). We are 95% confident that the true 
difference in means lies between -9.32 and 6.70. The fact that this interval 
contains 0 is consistent with the high p-value and suggests that the observed
difference in sample means is not statistically significant.

*   **`sample estimates: mean of x = 78.1250, mean of y = 79.4375`**: These 
are the sample means for `exam_1_score` and `exam_2_score`, respectively. On 
average, the `exam_1_score` was 78.13 and the `exam_2_score` was 79.44.

### 5. Overall Conclusion

Using a significance level of $\alpha = 0.05$, since the p-value (0.7394) is 
greater than 0.05, we **fail to reject the null hypothesis**. There is 
insufficient evidence to conclude that there is a statistically significant 
difference in the mean scores of the two exams. Based on this analysis, we 
cannot say that one exam is significantly more difficult than the other.

However, it is likely more appropriate to run the paired samples t-test 
instead, which may yield different results.

### 6. Caution

This explanation was generated by a Large Language Model. Critically review 
the output and consult additional statistical resources or experts to ensure 
correctness and a full understanding. Be sure to run the paired samples 
t-test for a more appropriate result.


## Example: Poisson regression

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
Here's a detailed explanation of the Poisson generalized linear model output 
you provided:

### 1. Summary of the Statistical Model

*   **Name of Model:** Poisson Regression with a log link function.
*   **Purpose:** Poisson regression is a statistical technique used to model 
count data, which are non-negative integers representing the number of times 
an event occurs within a specific time or space. The log link function 
connects the linear combination of predictor variables to the expected value 
of the count response. Specifically, it models the *logarithm* of the 
expected count as a linear function of the predictors. This ensures that the 
predicted counts are always non-negative.
*   **Key Assumptions:**
    *   **Poisson Distribution:** The response variable (counts) follows a 
Poisson distribution. A key characteristic of the Poisson distribution is 
that the mean and variance of the count data are assumed to be equal 
(equidispersion).
    *   **Independence:** Observations are independent of each other. This 
means that the count observed for one subject or unit does not influence the 
count observed for any other subject or unit.
    *   **Linearity:** The logarithm of the expected count is linearly 
related to the predictor variables. This is a consequence of using the log 
link function.
    *   **Normality of Residuals:** While not a strict requirement, the 
deviance residuals should be approximately normally distributed for the 
p-values to be reliable, especially with smaller sample sizes.

### 2. Appropriateness of the Statistical Model

Without additional context about the data, study design, or research 
question, it is impossible to definitively assess the appropriateness of the 
Poisson regression model. The appropriateness depends on several factors:

*   Is the response variable truly a count?
*   Is the independence assumption reasonable given the data collection 
process?
*   Is there evidence of overdispersion (variance significantly exceeding the
mean) or underdispersion (variance significantly less than the mean)? If so, 
a quasi-Poisson or negative binomial model might be more suitable.
*   Are there an excessive number of zeros in the data compared to what the 
Poisson model would predict? If so, a zero-inflated model may be more 
appropriate.

### 3. Suggestions for Checking Assumptions of the Statistical Model

Checking the assumptions of the Poisson regression model is essential for 
ensuring the validity of the results. Here's how you can check each 
assumption:

*   **Equidispersion:**
    *   Calculate the mean and variance of the response variable (counts). If
the variance is substantially larger than the mean (overdispersion) or 
substantially smaller than the mean (underdispersion), the standard Poisson 
model may be inappropriate. In the presence of overdispersion, consider using
a quasi-Poisson or negative binomial regression model.
*   **Independence:**
    *   The independence assumption is highly dependent on the study design 
and data collection process. Carefully consider whether the observations are 
truly independent. If the data involve repeated measurements on the same 
individuals or clustered data, the independence assumption is likely 
violated.
*   **Linearity and Model Fit:**
    *   **Residuals vs. Fitted Values Plot:** Create a scatter plot of the 
deviance residuals (or Pearson residuals) against the fitted values. Look for
any patterns in the plot, such as non-linear trends, heteroscedasticity 
(non-constant variance), or outliers. A random scatter of points around zero 
indicates that the model is a good fit.
    *   **Q-Q Plot of Residuals:** Generate a Q-Q plot of the deviance 
residuals to assess whether they are approximately normally distributed. 
Significant deviations from the diagonal line suggest a violation of the 
normality assumption.
*   **Influence:**
    *   **Cook's Distance:** Calculate Cook's distance for each observation 
to identify influential data points that may have a disproportionate impact 
on the model results. Observations with large Cook's distances (e.g., greater
than 1 or greater than 4/n, where n is the number of observations) should be 
investigated further to determine if they are unduly influencing the model.
*   **Zero Inflation:**
    *   Compare the observed proportion of zeros in your data to the 
proportion of zeros predicted by the Poisson model. If the observed 
proportion of zeros is substantially higher than the predicted proportion, 
this suggests zero inflation. Formal tests for zero inflation are also 
available.

### 4. Interpretation of the Output

Here's a detailed interpretation of the output:

*   **`Call: glm(formula = counts ~ outcome + treatment, family = 
poisson())`**: This line simply restates the model that was fitted, 
indicating that you used the `glm()` function to fit a Poisson regression 
model with `counts` as the response variable and `outcome` and `treatment` as
predictor variables. The `family = poisson()` argument specifies that a 
Poisson distribution with a log link function was used.
*   **`Deviance Residuals:`**: Deviance residuals are measures of the 
discrepancy between the observed counts and the counts predicted by the 
model. They are analogous to residuals in ordinary least squares regression. 
Large deviance residuals indicate a poor fit for those particular 
observations.

*   **`Coefficients:`**: This section contains the estimated coefficients, 
their standard errors, z-values, and p-values for each predictor variable in 
the model.

    *   **`(Intercept)  3.045e+00  1.709e-01  17.815   <2e-16 ***`**:
        *   `Estimate: 3.045e+00 = 3.045`: This is the estimated log of the 
expected count when all predictor variables are equal to zero (i.e., at their
reference levels).  To obtain the expected count, exponentiate this value: 
exp(3.045) ≈ 21.0. This means that when `outcome` and `treatment` are at 
their baseline levels, the expected count is approximately 21.0.
        *   `Std. Error: 1.709e-01 = 0.1709`: This is the standard error of 
the estimated intercept, which measures the precision of the intercept 
estimate.
        *   `z value: 17.815`: This is the z-statistic, calculated as the 
estimate divided by its standard error (3.045 / 0.1709). It tests the null 
hypothesis that the intercept is equal to zero.
        *   `Pr(>|z|): <2e-16`: This is the p-value associated with the 
z-statistic. It is extremely small (less than 2e-16, which is 
0.0000000000000002). This indicates very strong evidence against the null 
hypothesis that the intercept is zero. The probability of observing a z-value
as or more extreme than 17.815 if the intercept were truly zero is extremely 
small.

    *   **`outcome2    -4.543e-01  2.022e-01  -2.247   0.0246 *`**:
        *   `Estimate: -4.543e-01 = -0.4543`: This is the estimated 
coefficient for level '2' of the `outcome` variable, *relative to the 
reference level of outcome*. With a log link function, this coefficient 
represents the logarithm of the multiplicative change in the expected count 
for `outcome` = 2 compared to the reference level of `outcome`, holding all 
other variables constant. Exponentiating this value (exp(-0.4543) ≈ 0.635) 
means that, holding `treatment` constant, the expected count when `outcome` 
is 2 is approximately 63.5% of the expected count when `outcome` is at its 
reference level. Thus, outcome 2 decreases the expected count by 36.5% 
compared to the reference level.
        *   `Std. Error: 2.022e-01 = 0.2022`: This is the standard error of 
the coefficient for `outcome2`, which measures the precision of this 
coefficient estimate.
        *   `z value: -2.247`: This is the z-statistic for `outcome2`.
        *   `Pr(>|z|): 0.0246 *`: This is the p-value associated with the 
z-statistic. This p-value (0.0246) is statistically significant at the 
conventional alpha = 0.05 significance level. This suggests that there is a 
statistically significant difference in the expected counts between `outcome`
= 2 and the reference level of `outcome`, after controlling for `treatment`. 
If there were truly no difference in the mean counts between outcome 2 and 
the reference level, the probability of seeing a z-score as or more extreme 
than -2.247 is only 0.0246.

    *   **`outcome3    -2.930e-01  1.927e-01  -1.520   0.1285`**:
        *   `Estimate: -2.930e-01 = -0.2930`: This is the estimated 
coefficient for level '3' of the `outcome` variable, *relative to the 
reference level of outcome*. With a log link function, this coefficient 
represents the logarithm of the multiplicative change in the expected count 
for `outcome` = 3 compared to the reference level of `outcome`, holding all 
other variables constant. Exponentiating this value (exp(-0.2930) ≈ 0.746) 
means that, holding `treatment` constant, the expected count when `outcome` 
is 3 is approximately 74.6% of the expected count when `outcome` is at its 
reference level.
        *   `Pr(>|z|): 0.1285`: This p-value is not statistically significant
at the 0.05 level. This indicates that there is no statistically significant 
difference in the expected counts between `outcome` = 3 and the reference 
level of `outcome`, after controlling for `treatment`.

    *   **`treatment2  -3.242e-16  2.000e-01   0.000   1.0000`**:
        *   `Estimate: -3.242e-16 ≈ 0`: This is the estimated coefficient for
level '2' of the `treatment` variable, relative to the reference level of 
`treatment`. The estimated coefficient is essentially zero.
        *   `Pr(>|z|): 1.000`: This p-value is not statistically significant.
This indicates that there is no statistically significant difference in the 
expected counts between `treatment` = 2 and the reference level of 
`treatment`, after controlling for `outcome`.
    *   **`treatment3  -2.148e-16  2.000e-01   0.000   1.0000`**:
        *   `Estimate: -2.148e-16 ≈ 0`: This is the estimated coefficient for
level '3' of the `treatment` variable, relative to the reference level of 
`treatment`. The estimated coefficient is essentially zero.
        *   `Pr(>|z|): 1.000`: This p-value is not statistically significant.
This indicates that there is no statistically significant difference in the 
expected counts between `treatment` = 3 and the reference level of 
`treatment`, after controlling for `outcome`.

*   **`(Dispersion parameter for poisson family taken to be 1)`**: This 
indicates that the model is assuming equidispersion (i.e., the mean and 
variance of the counts are equal). If overdispersion is present, the standard
errors will be underestimated, leading to inflated z-values and potentially 
spurious statistical significance.
*   **`Null deviance: 10.5814  on 8  degrees of freedom`**: The null deviance
measures the difference between the saturated model (a perfect fit) and a 
model with only an intercept term. It indicates the total amount of variation
in the response variable that is not explained by the intercept alone.
*   **`Residual deviance:  5.1291  on 4  degrees of freedom`**: The residual 
deviance measures the difference between the saturated model and the fitted 
model. It indicates the amount of variation in the response variable that 
remains unexplained after including the predictor variables in the model.
*   **`AIC: 56.761`**: The Akaike Information Criterion (AIC) is a measure of
the goodness of fit of the model, taking into account both the model's 
ability to explain the data and the number of parameters in the model. Lower 
AIC values indicate a better balance between model fit and model complexity. 
AIC is useful for comparing different models fitted to the same data.
*   **`Number of Fisher Scoring iterations: 4`**: This indicates the number 
of iterations that the Fisher scoring algorithm (an iterative optimization 
algorithm) took to converge to the maximum likelihood estimates of the model 
parameters.

### 5. Additional Considerations for this type of model:

*   **Overdispersion:** A common issue with Poisson regression is 
overdispersion, where the variance of the counts is greater than the mean. 
Overdispersion can lead to underestimated standard errors and inflated 
z-values, potentially resulting in false positive findings. The residual 
deviance can be compared to the degrees of freedom to get a rough sense of 
whether overdispersion is present. A formal test, such as a likelihood ratio 
test comparing the Poisson model to a negative binomial model, is recommended
to assess overdispersion. The `dispersiontest()` function from the `AER` 
package provides a convenient way to test for overdispersion.
*   **Zero Inflation:** If there are more zeros in your data than would be 
expected under a Poisson distribution, a zero-inflated Poisson model may be 
more appropriate. You can assess zero inflation by comparing the observed 
number of zeros in your data to the number of zeros predicted by the model. 
Formal tests for zero inflation can also be conducted, and zero-inflated 
Poisson models can be fit using the `zeroinfl()` function in the `pscl` 
package.

### 6. Caution

This explanation was generated by a Large Language Model. Critically review 
the output and consult additional statistical resources or experts to ensure 
correctness and a full understanding. Make sure to formally test for 
overdispersion and zero inflation, and to carefully evaluate the model's fit 
using residual plots and other diagnostic tools.
