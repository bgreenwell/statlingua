library(survival)
library(statlingua)


context <- "
  Here's some additional context about the data used to this the model.

  ### Data set description

  Survival in patients with advanced lung cancer from the North Central Cancer
  Treatment Group. Performance scores rate how well the patient can perform
  usual daily activities.

  ### Data set format

  A data frame with 228 observations on the following 10 variables:

  * inst - Institution code
  * time - Survival time in days
  * status - censoring status 1=censored, 2=dead
  * age -	Age in years
  * sex -	Male=1 Female=2
  * ph.ecog -	ECOG performance score as rated by the physician. 0=asymptomatic, 1= symptomatic but completely ambulatory, 2= in bed <50% of the day, 3= in bed > 50% of the day but not bedbound, 4 = bedbound
  * ph.karno - Karnofsky performance score (bad=0-good=100) rated by physician
  * pat.karno -	Karnofsky performance score as rated by patient
  * meal.cal - Calories consumed at meals
  * wt.loss -	Weight loss in last six months (pounds)
  "

# Fit a time transform model using current age
fm <- coxph(Surv(time, status) ~ ph.ecog + tt(age), data = lung,
            tt = function(x, t, ...) pspline(x + t/365.25))
(summary(fm))
# Call:
#   coxph(formula = Surv(time, status) ~ ph.ecog + tt(age), data = lung,
#         tt = function(x, t, ...) pspline(x + t/365.25))
#
# n= 227, number of events= 164
# (1 observation deleted due to missingness)
#
# coef    se(coef) se2      Chisq DF   p
# ph.ecog         0.45284 0.117827 0.117362 14.77 1.00 0.00012
# tt(age), linear 0.01116 0.009296 0.009296  1.44 1.00 0.23000
# tt(age), nonlin                            2.70 3.08 0.45000
#
# exp(coef) exp(-coef) lower .95 upper .95
# ph.ecog                1.573     0.6358    1.2484     1.981
# ps(x + t/365.25)3      1.275     0.7845    0.2777     5.850
# ps(x + t/365.25)4      1.628     0.6141    0.1342    19.761
# ps(x + t/365.25)5      2.181     0.4585    0.1160    41.015
# ps(x + t/365.25)6      2.762     0.3620    0.1389    54.929
# ps(x + t/365.25)7      2.935     0.3408    0.1571    54.812
# ps(x + t/365.25)8      2.843     0.3517    0.1571    51.472
# ps(x + t/365.25)9      2.502     0.3997    0.1382    45.310
# ps(x + t/365.25)10     2.529     0.3955    0.1390    45.998
# ps(x + t/365.25)11     3.111     0.3214    0.1699    56.961
# ps(x + t/365.25)12     3.610     0.2770    0.1930    67.545
# ps(x + t/365.25)13     5.487     0.1822    0.2503   120.280
# ps(x + t/365.25)14     8.903     0.1123    0.2364   335.341
#
# Iterations: 4 outer, 10 Newton-Raphson
# Theta= 0.7960256
# Degrees of freedom for terms= 1.0 4.1
# Concordance= 0.612  (se = 0.027 )
# Likelihood ratio test= 22.46  on 5.07 df,   p=5e-04

# Use an LLM to help explain the model's output
client <- ellmer::chat_gemini(echo = "none")
ex <- explain(fm, chat = client, context = context)

# Write explanation to file
file_conn <- file("slowtests/markdown/slowtest_coxph.md")
writeLines(ex, con = file_conn)
close(file_conn)
