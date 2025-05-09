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
Here's an explanation of the Poisson generalized linear model output you 
provided:

### 1. Summary of the Statistical Model

*   **Name of Model:** Poisson Regression with a log link function.
*   **Purpose:** Poisson regression is used to model count data, which are 
non-negative integers representing the number of times an event occurs. The 
log link function connects the linear combination of predictors to the 
expected value of the count response by modeling the logarithm of the 
expected count as a linear function of the predictors.
*   **Key Assumptions:**
    *   The response variable (counts) follows a Poisson distribution. This 
assumes that the mean and variance of the count data are equal 
(equidispersion).
    *   Observations are independent of each other.
    *   The logarithm of the expected count is linearly related to the 
predictors.
    *   The residuals are approximately normally distributed.

### 2. Appropriateness of the Statistical Model

Without additional context about the data, study design, or research 
question, I cannot comment on the appropriateness of the Poisson regression 
model. The appropriateness depends on knowing whether the response variable 
is indeed a count, whether the independence assumption is plausible, and 
whether there's evidence of overdispersion (variance significantly exceeding 
the mean), which might suggest the need for a quasi-Poisson or negative 
binomial model instead. It is also important to check if there is an excess 
of zeros, which may also violate the assumptions of the Poisson model.

### 3. Suggestions for Checking Assumptions of the Statistical Model

Checking the assumptions is crucial for validating the Poisson regression 
model. Here's what you should do:

*   **Equidispersion:**
    *   Calculate the mean and variance of the response variable (counts). If
the variance is substantially larger than the mean (overdispersion), or 
substantially smaller than the mean (underdispersion), the standard Poisson 
model might not be appropriate. In the case of overdispersion, quasi-Poisson 
or negative binomial regression might be considered.
*   **Independence:**
    *   This assumption depends on the data collection process. Consider 
whether observations are truly independent. For example, repeated 
measurements on the same subject would violate this assumption.
*   **Linearity and Model Fit:**
    *   **Residuals vs. Fitted Values Plot:** Plot the deviance residuals (or
Pearson residuals) against the fitted values. Look for any patterns, such as 
non-linear trends or heteroscedasticity (non-constant variance). A random 
scatter of points around zero suggests that the model is a good fit.
    *   **Q-Q Plot of Residuals:** Create a Q-Q plot of the deviance 
residuals to assess whether they are approximately normally distributed. 
Deviations from the diagonal line suggest non-normality.
*   **Influence:**
    *   **Cook's Distance:** Calculate Cook's distance for each observation 
to identify influential points that might be disproportionately affecting the
model results. Points with large Cook's distances (e.g., greater than 1 or 
greater than 4/n, where n is the number of observations) should be 
investigated further.
*   **Excess Zeros:**
    *   Compare the number of zeros in your data to the number of zeros 
predicted by the Poisson model. You can calculate the predicted counts for 
each observation and see how often the model predicts a very small (close to 
zero) count when the actual count is zero, and vice versa. If there are many 
more zeros in the observed data than predicted, a zero-inflated Poisson model
might be more appropriate.

### 4. Interpretation of the Output

Here's a detailed interpretation of the output:

*   **`Call: glm(formula = counts ~ outcome + treatment, family = 
poisson())`**: This restates the model you fitted. It indicates that you used
the `glm()` function to fit a Poisson regression model with the `counts` 
variable as the response, and `outcome` and `treatment` as predictors.
*   **`Deviance Residuals:`**: These are measures of the discrepancy between 
the observed counts and the counts predicted by the model. They are analogous
to residuals in linear regression. Large residuals suggest a poor fit for 
those particular observations.

*   **`Coefficients:`** This section is the most important part of the 
output.

    *   **`(Intercept)  3.045e+00  1.709e-01  17.815   <2e-16 ***`**:
        *   `Estimate: 3.045e+00 = 3.045`: This is the estimated log of the 
expected count when all predictor variables are at their reference levels. To
get the expected count, you would exponentiate this value: exp(3.045) ≈ 21.0.
This means that when `outcome` and `treatment` are at their baseline levels, 
the expected count is approximately 21.0.
        *   `Std. Error: 1.709e-01 = 0.1709`: This is the standard error of 
the estimated intercept. It measures the uncertainty in the estimate of the 
intercept.
        *   `z value: 17.815`: This is the z-statistic, calculated as the 
estimate divided by its standard error (3.045 / 0.1709). It tests the null 
hypothesis that the intercept is zero.
        *   `Pr(>|z|): <2e-16`: This is the p-value associated with the 
z-statistic. It's extremely small (less than 2e-16, which is 
0.0000000000000002). It indicates very strong evidence against the null 
hypothesis that the intercept is zero. In other words, the intercept is 
highly statistically significant.

    *   **`outcome2    -4.543e-01  2.022e-01  -2.247   0.0246 *`**:
        *   `Estimate: -4.543e-01 = -0.4543`: This is the estimated 
coefficient for the level '2' of the `outcome` variable, *relative to the 
reference level of outcome*.  Since we are using a log link, this coefficient
represents the *logarithm of the multiplicative change* in the expected count
for `outcome` = 2 compared to the reference level of outcome, holding all 
other variables constant. To get the multiplicative change, exponentiate this
value: exp(-0.4543) ≈ 0.635. This means that, holding `treatment` constant, 
the expected count when `outcome` is 2 is approximately 63.5% of the expected
count when `outcome` is at its reference level. This is a *decrease* in the 
expected count.
        *   `Std. Error: 2.022e-01 = 0.2022`: This is the standard error of 
the coefficient for `outcome2`.
        *   `z value: -2.247`: This is the z-statistic for `outcome2`.
        *   `Pr(>|z|): 0.0246 *`: This is the p-value for `outcome2`. If you 
use a significance level of 0.05, this p-value is statistically significant. 
It suggests that there's a statistically significant difference in the 
expected counts between `outcome` = 2 and the reference level of `outcome`, 
after controlling for `treatment`. More specifically, the probability of 
seeing a result as or more extreme than this if there were truly no 
difference between `outcome` = 2 and the reference level is only 0.0246, 
which is fairly unlikely.

    *   **`outcome3    -2.930e-01  1.927e-01  -1.520   0.1285`**:
        *   `Estimate: -2.930e-01 = -0.2930`: This is the estimated 
coefficient for `outcome` = 3, relative to the reference level of outcome. 
Exponentiating this gives exp(-0.2930) ≈ 0.746. Thus, holding `treatment` 
constant, the expected count when `outcome` is 3 is approximately 74.6% of 
the expected count when `outcome` is at its reference level.
        *   `Pr(>|z|): 0.1285`: This p-value is not statistically significant
at the 0.05 level. This suggests that there's no statistically significant 
difference in the expected counts between `outcome` = 3 and the reference 
level of `outcome`, after controlling for `treatment`.

    *   **`treatment2  -3.242e-16  2.000e-01   0.000   1.0000`**:
        *   `Estimate: -3.242e-16 ≈ 0`: This is the estimated coefficient for
the level '2' of the `treatment` variable, relative to the reference level of
treatment. Essentially, this coefficient is approximately zero.
        *   `Pr(>|z|): 1.000`: This p-value is not statistically significant.
This suggests that there's no statistically significant difference in the 
expected counts between `treatment` = 2 and the reference level of 
`treatment`, after controlling for `outcome`.
    *   **`treatment3  -2.148e-16  2.000e-01   0.000   1.0000`**:
        *   `Estimate: -2.148e-16 ≈ 0`: This is the estimated coefficient for
the level '3' of the `treatment` variable, relative to the reference level of
treatment. Essentially, this coefficient is approximately zero.
        *   `Pr(>|z|): 1.000`: This p-value is not statistically significant.
This suggests that there's no statistically significant difference in the 
expected counts between `treatment` = 3 and the reference level of 
`treatment`, after controlling for `outcome`.

*   **`(Dispersion parameter for poisson family taken to be 1)`**: This 
indicates that the model assumes equidispersion (mean equals variance). If 
overdispersion is present, the standard errors will be underestimated, 
leading to potentially incorrect conclusions.
*   **`Null deviance: 10.5814  on 8  degrees of freedom`**: The null deviance
measures the difference between the saturated model (a perfect fit) and a 
model with only an intercept. It indicates how well the response variable is 
predicted by the model with no predictors.
*   **`Residual deviance:  5.1291  on 4  degrees of freedom`**: The residual 
deviance measures the difference between the saturated model and the fitted 
model. It indicates how much unexplained variation remains after including 
the predictors in the model.
*   **`AIC: 56.761`**: The Akaike Information Criterion (AIC) is a measure of
model fit that penalizes model complexity. Lower AIC values indicate a better
balance between model fit and parsimony. It's useful for comparing different 
models fitted to the same data.
*   **`Number of Fisher Scoring iterations: 4`**: This indicates the number 
of iterations the algorithm took to converge to the maximum likelihood 
estimates.

### 5. Additional Considerations for this type of model:

*   **Overdispersion:** Overdispersion can be assessed by comparing the 
residual deviance to the degrees of freedom. A rule of thumb is that if the 
residual deviance is much larger than the degrees of freedom (e.g., by a 
factor of 2 or more), overdispersion might be present. In this case, 5.1291 
is not much larger than 4, so overdispersion may not be a huge concern, but 
it is still important to formally test for this. Overdispersion can also be 
assessed using the `dispersiontest()` function from the `AER` package.
*   **Frequent Zeros:** To check for frequent zeros, you can compare the 
observed number of zeros in the dataset to the number of zeros predicted by 
the model. If there are considerably more zeros observed than predicted, this
suggests zero inflation. You can also run a zero-inflated Poisson regression 
model and compare its fit to the standard Poisson model using AIC or a 
likelihood ratio test.

### 6. Caution

This explanation was generated by a Large Language Model. Critically review 
the output and consult additional statistical resources or experts to ensure 
correctness and a full understanding. Consider checking for overdispersion 
and zero inflation and evaluating the model's fit using residual plots.
