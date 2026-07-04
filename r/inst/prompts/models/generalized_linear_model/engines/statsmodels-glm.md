This output was produced by Python's `statsmodels` library
(`sm.GLM(...).fit().summary()`). Expect this exact structure, which differs
from R's `glm()` summary layout:

- **Top info block:** `Dep. Variable`, `Model`, `Model Family`,
  `Link Function`, `Method`, `Date`, `Time`, `No. Iterations`,
  `Covariance Type`, plus `Log-Likelihood`, `Deviance`, `Pearson chi2`, and
  sometimes `Pseudo R-squ.` — the family and link function are shown
  explicitly here as separate labeled fields, whereas R shows them inline
  in the `Call`.
- **Coefficients table** with columns, in this order: `coef`, `std err`,
  `z`, `P>|z|`, `[0.025`, `0.975]` — including a 95% confidence interval
  for each coefficient, which R's default `glm()` summary does NOT include.

When interpreting, map `coef`/`std err`/`z`/`P>|z|` to the same meaning as
R's `Estimate`/`Std. Error`/`z value`/`Pr(>|z|)`, and make use of the
confidence intervals uniquely available in this output. Deviance and AIC
remain the primary goodness-of-fit measures, as in R.
