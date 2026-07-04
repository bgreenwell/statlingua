This output was produced by R's `lm()` function and its `summary()` method.
Expect this exact structure:

- **Call:** the R expression used to fit the model.
- **Residuals:** a five-number summary (Min, 1Q, Median, 3Q, Max) of the
  residuals.
- **Coefficients table** with columns, in this order: `Estimate`,
  `Std. Error`, `t value`, `Pr(>|t|)` — one row per term (Intercept first).
  A trailing `Signif. codes` line explains the significance stars
  (`***`, `**`, `*`, `.`).
- **Residual standard error** with its degrees of freedom.
- **Multiple R-squared** and **Adjusted R-squared**.
- **F-statistic** with its degrees of freedom and overall p-value.

There are no confidence intervals shown by default (only point estimates,
standard errors, and hypothesis tests).
