This output was **not** produced by a native library summary method —
scikit-learn's `LogisticRegression` has no built-in text summary at all.
It was synthesized by statlingo itself and contains only:

- The number of classes and their labels.
- The number of features.
- The fitted intercept(s) and coefficients, one set per class for
  multiclass problems, or one set for the positive class in the binary
  case (labeled by feature name if the model was fit on a pandas
  DataFrame, otherwise by position).

**Critically, this output does NOT and CANNOT include:** standard errors,
z-statistics, p-values, confidence intervals, deviance, AIC, or pseudo
R-squared. scikit-learn's `LogisticRegression` does not compute these
during fitting, and the fitted estimator does not retain the training data
needed to compute them afterward.

**Important interpretive caveat:** by default, scikit-learn's
`LogisticRegression` applies L2 regularization (a penalty that shrinks
coefficients toward zero) unless the caller explicitly disabled it. This
means coefficient magnitudes from this output are generally **not directly
comparable** to an unregularized/unpenalized fit from R's `glm()` or
Python's `statsmodels.GLM` with the same data — smaller coefficient
magnitudes here do not necessarily indicate weaker effects. Mention this
caveat when interpreting coefficient sizes, especially for a
researcher/student audience.

**Do not invent, estimate, or imply the presence of any missing
inferential statistics.** Explicitly tell the user that statistical
significance and model fit cannot be assessed from this output alone.
