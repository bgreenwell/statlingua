This output was produced by R's `glm()` function and its `summary()`
method. Expect this exact structure:

- **Call:** the R expression used to fit the model, including the `family`
  argument.
- **Deviance Residuals:** a five-number summary (Min, 1Q, Median, 3Q, Max).
- **Coefficients table** with columns, in this order: `Estimate`,
  `Std. Error`, `z value`, `Pr(>|z|)` (for most families) — one row per
  term (Intercept first). Note this uses a `z value`/Wald test, not the
  `t value` seen in `lm()`'s summary, except for the Gaussian/quasi
  families where `t value` is used instead.
- A note on the **dispersion parameter** assumed for the family.
- **Null deviance** and **Residual deviance**, each with their degrees of
  freedom.
- **AIC**.
- **Number of Fisher Scoring iterations**.

There is no R-squared or F-statistic (those are specific to `lm()`); model
fit here is assessed via deviance and AIC instead.
