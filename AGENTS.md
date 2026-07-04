# AGENTS.md for statlingo

This file provides context, architectural guidelines, and development workflows for AI agents working on the `statlingo` monorepo.

---

## 1. Project Overview & Mission
`statlingo` translates dense statistical model output—coefficients, p-values, model fit indices, and more—into clear, context-aware, natural language explanations using Large Language Models (LLMs).

It ships as **two language packages sharing one repository**:
- **R package** (`r/`) — leverages [`ellmer`](https://ellmer.tidyverse.org/) (R6-based `Chat` clients). Distributed via [r-universe](https://bgreenwell.r-universe.dev/) and GitHub (historically published as `statlingua` on CRAN, but not resubmitted under the new name).
- **Python package** (`python/`) — leverages [`chatlas`](https://posit-dev.github.io/chatlas/) (`Chat` clients).

**Core Mission:** Bridge the gap between complex statistical model output and human-readable explanations for various audiences (novice, student, researcher, manager, domain_expert) consistently across both packages.

---

## 2. Repository Layout
```
statlingo/
├── prompts/              # Canonical LLM prompt source (Single Source of Truth)
│   ├── config.yaml       # Short audience, verbosity, and style instructions
│   ├── common/           # Shared role/caution prompt fragments
│   │   ├── role_base.md  # Base agent persona prompt
│   │   └── caution.md    # Safety guidelines (do not invent information)
│   ├── models/           # Per-model instructions & role specific prompts
│   │   ├── arima_time_series/
│   │   ├── linear_model/
│   │   ├── generalized_linear_model/
│   │   └── default/      # Fallback model instructions
│   └── system_prompt_template.md # Master layout template
│
├── r/                    # R Package Root
│   ├── DESCRIPTION       # Package metadata & dependencies
│   ├── NAMESPACE         # Exported functions
│   ├── R/                # R package source code (explain, summarize, utils, print)
│   ├── inst/             # Contains inst/prompts ( wholesale-regenerated, DO NOT edit )
│   ├── man/              # Generated Rd documentation files
│   ├── tests/            # Test suite (uses tinytest)
│   └── TODO.md           # R-specific tasks
│
├── python/               # Python Package Root
│   ├── pyproject.toml    # Build config, dependencies, optional packages
│   ├── src/statlingo/    # Python package source code
│   │   ├── prompts/      # Python prompt copy ( wholesale-regenerated, DO NOT edit )
│   │   ├── explain.py    # Public explain() function
│   │   ├── diagnostic.py # Agentic diagnostic functions (diagnose, diagnose_agent)
│   │   ├── model_handlers.py # Registered model summary extraction handlers
│   │   └── _prompting.py # System/user prompt builder & interpolator
│   ├── tests/            # Test suite (uses pytest)
│   └── experimental/     # Visual examples & scripts for Chatlas-based agents
│
├── docs-site/            # Unified Quarto Documentation Website
│   ├── _quarto.yml       # Quarto website configuration
│   └── *.qmd             # Project landing/get-started pages
│
├── scripts/              # Monorepo development scripts
│   ├── sync_prompts.py   # Synchronizes prompts/ into r/ and python/
│   └── build_docs_site.sh# Script to build the unified website
│
├── README.md             # Monorepo-wide README
├── TODO.md               # Monorepo-wide TODO list
└── AGENTS.md             # This file (AI instructions)
```

---

## 3. The Canonical Prompts System (`prompts/`)
The `prompts/` directory at the repo root is the **single source of truth** for all LLM prompt content:
- `prompts/config.yaml` — Keyed configurations mapping parameters to prompts (e.g. `audience.novice`, `verbosity.brief`, `style.markdown`).
- `prompts/common/` — Base persona (`role_base.md`) and safety/precision constraints (`caution.md`).
- `prompts/models/<name>/` — Context specific files:
  - `instructions.md`: Detailed guidance on interpreting specific statistical fields.
  - `role_specific.md`: Persona adjustments for a given model.
  - `engines/`: Optional engine-specific format overrides (e.g. `r-lm.md`, `statsmodels-ols.md`).
- `prompts/system_prompt_template.md` — The master template that both packages interpolate variables into using `{{placeholder}}` syntax.

### Prompt Synchronization
**Never hand-edit** the generated copies at `r/inst/prompts/` or `python/src/statlingo/prompts/`. They are wholesale-regenerated from the root `prompts/` directory by running:
```bash
# From the repo root:
python3 scripts/sync_prompts.py
```
To verify the packages are synchronized (e.g., in CI):
```bash
python3 scripts/sync_prompts.py --check
```
Always edit the canonical files under `prompts/` and run the sync script afterward.

---

## 4. R Package (`r/`)

### Tech Stack
- **Language:** R (>= 4.1.0)
- **LLM Interface:** `ellmer` (>= 0.4.0), imported in `DESCRIPTION` (used directly via `ellmer::interpolate_package()` for prompt assembly).
- **Config Parsing:** `yaml` package (`yaml::read_yaml()`).
- **Testing:** `tinytest`.
- **Documentation:** `roxygen2`.
- **OO System:** S3 dispatch for user-facing generics (`explain()`, `summarize()`); R6 for `ellmer::Chat` objects.

### Architecture & Key Files
- [explain.R](file:///Users/greenwbm/Dropbox/devel/statlingo/r/R/explain.R): S3 generic `explain()` and per-model methods (e.g., `explain.lm`, `explain.glm`, `explain.htest`).
- [summarize.R](file:///Users/greenwbm/Dropbox/devel/statlingo/r/R/summarize.R): S3 generic `summarize()` to transform R model objects into plain text output for the LLM.
- [utils.R](file:///Users/greenwbm/Dropbox/devel/statlingo/r/R/utils.R): Internal orchestration. Contains `.explain_core()`, `.assemble_sys_prompt()` (reads config and model templates, performs `ellmer::interpolate_package()`), and `.remove_fences()` to clean markdown code blocks from responses.

### Development Workflow
Ensure R dev tools are installed:
```R
# Install dependencies
install.packages(c("devtools", "usethis", "tinytest", "roxygen2", "ellmer", "yaml"))
```
Commands (run from `r/` directory):
```bash
# Load package interactively (for exploration)
Rscript -e 'devtools::load_all(".")'

# Run unit tests correctly (devtools loads the package, then tinytest executes)
Rscript -e 'devtools::load_all("."); tinytest::run_test_dir("inst/tinytest")'

# Rebuild documentation (man/ and NAMESPACE)
Rscript -e 'devtools::document(".")'

# Full CRAN-style package check (CI gate)
Rscript -e 'devtools::check(".")'
```

### Mocking LLM Responses in R Tests
Because `explain()` clones the client to avoid mutating user objects, and R6's default `clone()` is shallow, `MockChat` stores recorded state (e.g., system/user prompts) inside a nested environment (`self$state`). This keeps recorded parameters observable on the original test instance. **Always** mock LLM calls in unit tests.

### Adding Support for a New Model (R)
1. Add `prompts/models/<class>/{instructions.md,role_specific.md}` to the canonical directory.
2. Run `python3 scripts/sync_prompts.py` to update generated directories.
3. Implement `summarize.<class>` in [summarize.R](file:///Users/greenwbm/Dropbox/devel/statlingo/r/R/summarize.R).
4. Implement `explain.<class>` in [explain.R](file:///Users/greenwbm/Dropbox/devel/statlingo/r/R/explain.R), calling `.explain_core(..., name = "<class>", model = "<description>")`.

---

## 5. Python Package (`python/`)

### Tech Stack
- **Language:** Python (>= 3.8)
- **LLM Interface:** `chatlas` (>= 0.19.0).
- **Config Parsing:** `pyyaml`.
- **Testing:** `pytest`.
- **Model Support:** `statsmodels` (default), `scikit-learn` (optional extra). Extensible via a decorator-based handler registry pattern.

### Architecture & Key Files
- [explain.py](file:///Users/greenwbm/Dropbox/devel/statlingo/python/src/statlingo/explain.py): Public `explain()` function.
- [diagnostic.py](file:///Users/greenwbm/Dropbox/devel/statlingo/python/src/statlingo/diagnostic.py): Public `diagnose()` and `diagnose_agent()` functions for model diagnostics.
- [model_handlers.py](file:///Users/greenwbm/Dropbox/devel/statlingo/python/src/statlingo/model_handlers.py): Handler registry mapping model classes to custom extractor functions returning `(model_name, engine, summary_text)`.
  > [!IMPORTANT]
  > `statsmodels.OLS(...).fit()` and `.GLM(...).fit()` return `RegressionResultsWrapper` and `GLMResultsWrapper` objects. These wrappers do **not** subclass or `isinstance()`-match the raw results classes (`OLSResults` / `GLMResults`). Handlers must be registered against the wrapper classes returned to the caller.
- [_prompting.py](file:///Users/greenwbm/Dropbox/devel/statlingo/python/src/statlingo/_prompting.py): Prompt construction (mirrors R package prompt assembly). Loads `config.yaml`, interpolates placeholders, and strips code fences.

### Development Workflow
Uses `uv` for environment management. From the `python/` directory:
```bash
# Create local virtualenv
uv venv
source .venv/bin/activate

# Install package in editable mode with test dependencies
uv pip install -e . pytest scikit-learn

# Run unit tests
python3 -m pytest tests/
```

### Mocking LLM Responses in Python Tests
Because Python's functions deep-copy the client (`copy.deepcopy(client)`) to prevent side effects, unit tests utilize `MockChat`. `MockChat` implements a custom `__deepcopy__` method that keeps the `recorder` dictionary and `registered_tools` list as shared references, ensuring recorded calls and tools remain observable on the original test instance.

### Adding Support for a New Model (Python)
1. Add `prompts/models/<name>/{instructions.md,role_specific.md}` to the canonical prompts directory and run the sync script.
2. Register a handler function in [model_handlers.py](file:///Users/greenwbm/Dropbox/devel/statlingo/python/src/statlingo/model_handlers.py) using `@register_handler(FittedClassWrapper)`. Be sure to inspect the exact class type returned by the estimator's fit call.
3. Import the fitted wrapper class conditionally in a `try...except ImportError:` block to keep dependencies optional.

---

## 6. Unified Documentation Website (`docs-site/`)

The documentation is a unified [Quarto](https://quarto.org) website deployed to GitHub Pages. It integrates:
1. Handwritten landing and get-started pages (`.qmd` files in `docs-site/`).
2. Python API documentation generated dynamically from python docstrings using [`quartodoc`](https://machow.github.io/quartodoc/).
3. R package documentation generated via [`pkgdown`](https://pkgdown.r-lib.org/) from the R source.

### Crucial Build Ordering
Quarto's renderer clears the output directory (`docs-site/_site/`) before building. Therefore, the R reference site must be generated *after* Quarto renders. The correct build workflow is:
```bash
# Execute from the repo root
./scripts/build_docs_site.sh
```

### Dependency Pinning
`quartodoc` is incompatible with `griffe >= 1.0` due to API changes in numpy docstring parsing. The environment **must** pin `griffe<1.0` to prevent build failures.

---

## 7. Experimental Features & Examples (`python/experimental/`)
The `python/experimental/` directory contains scripts showcasing the revived agentic model diagnostics:
- [example_diagnose.py](file:///Users/greenwbm/Dropbox/devel/statlingo/python/experimental/example_diagnose.py) demonstrates OLS diagnostics using `diagnose()`.
- [example_agent.py](file:///Users/greenwbm/Dropbox/devel/statlingo/python/experimental/example_agent.py) demonstrates fully automated visual residual plot generation and interpretation using `diagnose_agent()` with `ChatGoogle` and native `chatlas` tool calling.

---

## 8. Coding Conventions & Best Practices

### Side-Effect Mitigation
`explain()` functions must **never** mutate the user's chat client.
- In R: Invoke `client$clone()` and reset the turns list.
- In Python: Invoke `copy.deepcopy(client)` and reset turns.

### Style Guides
- **R Style:** Tidyverse style guide (snake_case for functions and variables).
- **Python Style:** PEP 8 compliance, with type hints included on all public functions.

### Git Conventions
- **Commit Messages:** Follow Conventional Commits format (e.g. `feat: add support for arima models`, `fix: correct markdown fence parsing`).
- **Granularity:** Keep commits atomic, cohesive, and focused.
