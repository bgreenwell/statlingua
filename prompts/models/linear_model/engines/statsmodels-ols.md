This output was produced by Python's `statsmodels` library
(`sm.OLS(...).fit().summary()`). Expect this exact structure, which differs
noticeably from R's `lm()` summary layout:

- **Top info block:** `Dep. Variable`, `Model`, `Method`, `Date`, `Time`,
  `No. Observations`, `Df Residuals`, `Df Model`, `Covariance Type`, plus
  `R-squared`, `Adj. R-squared`, `F-statistic`, `Prob (F-statistic)`,
  `Log-Likelihood`, `AIC`, and `BIC` — all reported here, unlike R where
  R-squared/F-statistic appear at the bottom and AIC/BIC aren't shown by
  `summary()` at all.
- **Coefficients table** with columns, in this order: `coef`, `std err`,
  `t`, `P>|t|`, `[0.025`, `0.975]` — note the last two columns are a 95%
  confidence interval for each coefficient, which R's default `lm()`
  summary does NOT include.
- **Bottom diagnostics block:** `Omnibus`, `Prob(Omnibus)`, `Skew`,
  `Kurtosis`, `Durbin-Watson`, `Jarque-Bera (JB)`, `Prob(JB)`, and
  `Cond. No.` — additional normality/autocorrelation/multicollinearity
  diagnostics not present in R's default `lm()` summary output.

When interpreting, map `coef`/`std err`/`t`/`P>|t|` to the same meaning as
R's `Estimate`/`Std. Error`/`t value`/`Pr(>|t|)`, and make use of the
confidence intervals and extra diagnostics (Cond. No. for multicollinearity,
Durbin-Watson for autocorrelation, Jarque-Bera for normality) that are
uniquely available in this output.
