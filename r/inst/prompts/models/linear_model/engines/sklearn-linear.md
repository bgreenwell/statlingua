This output was **not** produced by a native library summary method —
scikit-learn's `LinearRegression` has no built-in text summary at all.
It was synthesized by statlingo itself and contains only:

- The number of features.
- The fitted intercept.
- The fitted coefficients, one per feature (labeled by feature name if the
  model was fit on a pandas DataFrame, otherwise by position).

**Critically, this output does NOT and CANNOT include:** standard errors,
t/z-statistics, p-values, confidence intervals, R-squared, or any other
inferential or goodness-of-fit statistic. scikit-learn's `LinearRegression`
does not compute these during fitting, and the fitted estimator does not
retain the training data needed to compute them afterward.

**Do not invent, estimate, or imply the presence of any of these missing
values.** Explicitly tell the user that statistical significance and model
fit cannot be assessed from this output alone, and that they would need to
either use a library that computes these (e.g. `statsmodels`) or supply
them separately (e.g. via cross-validation) if that information is needed.
