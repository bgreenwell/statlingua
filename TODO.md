# TODO (monorepo-wide)

This file tracks cross-language / cross-cutting work. See also
[`r/TODO.md`](r/TODO.md) for R-specific enhancement ideas.

- [ ] **Python: revive agentic diagnostics on chatlas.** The Python
  package's previous `diagnose()`/`diagnose_agent()` (tool-calling, plot
  generation/interpretation) were deferred to
  `python/experimental/` during the `chatlas` migration. Re-implement using
  `chatlas`'s `register_tool()` mechanism, and consider bringing an
  equivalent to the R package as well.
- [ ] **Python: expand model handler coverage to match R.** The Python
  package now covers `statsmodels` OLS/Poisson GLM plus scikit-learn
  `LinearRegression`/`LogisticRegression`. Remaining gaps include
  logistic/other GLM families from `statsmodels`, mixed models, survival
  models, GAMs, etc., as equivalent Python libraries are identified (e.g.
  `lifelines` for survival analysis).
- [ ] **Shared prompt content review.** Now that `prompts/` is the single
  canonical source for both languages (synced via
  `scripts/sync_prompts.py`), periodically review model-specific
  instructions for language-neutral phrasing (some were originally written
  with R-specific function names, e.g. `lm()`, `glm()`).
- [ ] **CI: enforce prompt sync.** Ensure the `prompts-sync-check` CI job
  (see `.github/workflows/`) stays wired up so R and Python prompt copies
  never drift from `prompts/`.
