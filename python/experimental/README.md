# Experimental (deferred) features

This directory holds agentic, tool-calling features that predate the
`chatlas` migration and are **not** part of the public `statlingo` API:

- `diagnostic.py` — `diagnose()` / `diagnose_agent()`, which used `litellm`
  directly for tool-calling (e.g. generating and interpreting residual
  plots).
- `example_agent.py`, `example_diagnose.py` — example scripts for the above.

These were deliberately deferred (not deleted) when the package was
refactored onto `chatlas`, per the decision to focus that pass purely on
bringing `explain()`/`summarize()`-equivalent functionality to parity with
the R package. Reviving this functionality on top of `chatlas` (e.g. via
`Chat.register_tool()`) is tracked as a follow-up in `../../TODO.md`.

Nothing in this directory is installed as part of the `statlingo` package,
and it still depends on `litellm` (not currently a package dependency).
