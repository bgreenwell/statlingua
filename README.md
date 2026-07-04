# statlingo

[![R-CMD-check](https://github.com/bgreenwell/statlingo/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/bgreenwell/statlingo/actions/workflows/R-CMD-check.yaml)
[![Python tests](https://github.com/bgreenwell/statlingo/actions/workflows/python-tests.yaml/badge.svg)](https://github.com/bgreenwell/statlingo/actions/workflows/python-tests.yaml)
[![Docs site](https://github.com/bgreenwell/statlingo/actions/workflows/docs-site.yaml/badge.svg)](https://bgreenwell.github.io/statlingo/)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: GPL v2+](https://img.shields.io/badge/license-GPL%20(%3E%3D%202)-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/bgreenwell/statlingo/issues)

**statlingo** translates the dense output of statistical models—coefficients,
p-values, model fit indices, and more—into clear, context-aware, natural
language explanations using Large Language Models (LLMs).

This is a monorepo containing two packages that share a common design and a
single canonical set of LLM prompts:

| Package | Language | LLM interface | Location |
|---|---|---|---|
| `statlingo` | R (formerly published on CRAN as `statlingua`) | [`ellmer`](https://ellmer.tidyverse.org/) | [`r/`](r) |
| `statlingo` | Python | [`chatlas`](https://posit-dev.github.io/chatlas/) | [`python/`](python) |

See each package's own README for installation and usage instructions:
[`r/README.md`](r/README.md) and [`python/README.md`](python/README.md).

## Repository layout

```
r/           R package (DESCRIPTION, R/, man/, tests/, vignettes/, ...)
python/      Python package (pyproject.toml, src/statlingo/, tests/)
prompts/     Canonical LLM prompt source, shared by both packages
scripts/     Dev tooling (e.g. scripts/sync_prompts.py)
```

`prompts/` is the single source of truth for prompt content (audience,
verbosity, output style, and per-model instructions). Both packages ship a
generated copy of it (`r/inst/prompts/`, `python/src/statlingo/prompts/`);
run `python3 scripts/sync_prompts.py` after editing anything under `prompts/`
to regenerate them.

## Contributing

Contributions are welcome! Please open an issue or pull request on GitHub.
See `AGENTS.md` for repository conventions and development workflows.

## License

This project is licensed under the GNU General Public License v3.0 (GNU GPLv3).
