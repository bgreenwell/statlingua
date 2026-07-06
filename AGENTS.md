# AGENTS.md for statlingo

This file provides context, architectural guidelines, and development workflows for AI agents working on the `statlingo` monorepo.

---

## 1. Project Overview & Mission
`statlingo` translates dense statistical model output—coefficients, p-values, model fit indices, and more—into clear, context-aware, natural language explanations using Large Language Models (LLMs).

It ships as **two language packages sharing one repository**:
- **R package** (`r/`) — leverages [`ellmer`](https://ellmer.tidyverse.org/) (R6-based `Chat` clients). Distributed via [r-universe](https://bgreenwell.r-universe.dev/) and GitHub.
- **Python package** (`python/`) — leverages [`chatlas`](https://posit-dev.github.io/chatlas/) (`Chat` clients).

**Core Mission:** Bridge the gap between complex statistical model output and human-readable explanations for various audiences (novice, student, researcher, manager, domain_expert) consistently across both packages.

---

## 2. Repository Layout
```
statlingo/
├── prompts/              # Canonical LLM prompt source (Single Source of Truth)
│   ├── config.yaml       # Short audience, verbosity, and style instructions
│   ├── common/           # Shared role prompt fragments
│   │   └── role_base.md  # Base agent persona prompt
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
│   ├── R/                # R package source code (explain, summarize, suggest_code, utils, print)
│   ├── inst/             # Contains inst/prompts ( wholesale-regenerated, DO NOT edit )
│   ├── man/              # Generated Rd documentation files
│   └── tests/            # Test suite (uses tinytest)
│
├── python/               # Python Package Root
│   ├── pyproject.toml    # Build config, dependencies, optional packages
│   ├── src/statlingo/    # Python package source code
│   │   ├── prompts/      # Python prompt copy ( wholesale-regenerated, DO NOT edit )
│   │   ├── explain.py    # Public explain() & suggest_code() functions
│   │   ├── model_handlers.py # Registered model summary extraction handlers
│   │   └── _prompting.py # System/user prompt builder & interpolator
│   ├── tests/            # Test suite (uses pytest)
│
├── evals/                # LLM-as-a-Judge Evaluation System
│   ├── judge_prompt.md   # System prompt for LLM judge grading explanations
│   └── cases/            # JSON files containing ground-truth statistical cases
│
├── docs-site/            # Unified Quarto Documentation Website
│   ├── _quarto.yml       # Quarto website configuration
│   └── *.qmd             # Project landing/get-started pages
│
├── scripts/              # Monorepo development scripts
│   ├── sync_prompts.py   # Synchronizes prompts/ into r/ and python/
│   ├── run_evals.py      # Runs the LLM-as-a-Judge evaluation test suite
│   └── build_docs_site.sh# Script to build the unified website
│
├── README.md             # Monorepo-wide README
└── AGENTS.md             # This file (AI instructions)
```

---

## 3. The Canonical Prompts System (`prompts/`)
The `prompts/` directory at the repo root is the **single source of truth** for all LLM prompt content:
- `prompts/config.yaml` — Keyed configurations mapping parameters to prompts (e.g. `audience.novice`, `verbosity.brief`, `style.markdown`).
- `prompts/common/role_base.md` — Base persona.
- `prompts/models/<name>/` — Context specific files:
  - `instructions.md`: Detailed guidance on interpreting specific statistical fields.
  - `role_specific.md`: Persona adjustments for a given model.
  - `engines/`: Optional engine-specific format overrides (e.g. `r-lm.md`, `statsmodels-ols.md`).
- `prompts/system_prompt_template.md` — The master template that both packages interpolate variables into using `{{placeholder}}` syntax.

### Prompt Synchronization
**Never hand-edit** the generated copies at `r/inst/prompts/` or `python/src/statlingo/prompts/`. They are wholesale-regenerated from the root `prompts/` directory by running:
```bash
python3 scripts/sync_prompts.py
```
To verify the packages are synchronized (e.g., in CI):
```bash
python3 scripts/sync_prompts.py --check
```
Always edit the canonical files under `prompts/` and run the sync script afterward.

---

## 4. Deterministic Caution Disclaimer & Code Suggestions
To ensure a consistent, reliable user experience and 100% parity across LLM providers and models:
1. **No LLM caution prompt**: The LLM is *not* prompted to write disclaimers. 
2. **Dynamic Append**: The `explain()` functions in both R and Python programmatically append a deterministic disclaimer message to the end of all generated explanations:
   > *Caution: This explanation was generated by a Large Language Model. Users should critically review the output and consult additional statistical resources or experts to ensure correctness and a full understanding.*
3. **Deterministic `suggest_code()`**: Both packages offer a `suggest_code(explanation)` helper which outputs deterministic, model-tailored R/Python diagnostic commands followed by a coding disclaimer.

---

## 5. LLM-as-a-Judge Evaluation System (`evals/`)
We grade natural language explanations programmatically against ground truth outputs using an LLM judge.
- **Judge Configuration**: Prompt is defined in `evals/judge_prompt.md`.
- **Evals Runner**: Execute from the root directory:
  ```bash
  source python/.venv/bin/activate
  python3 scripts/run_evals.py
  ```
- **CI Integration**: The evaluations run automatically in CI on pull requests/pushes via `.github/workflows/evals.yaml`.

---

## 6. R Package (`r/`)

### Tech Stack & Architecture
- **Language:** R (>= 4.1.0)
- **LLM Interface:** `ellmer` (>= 0.4.0) (used via `ellmer::interpolate_package()`).
- **Config Parsing:** `yaml` package (`yaml::read_yaml()`).
- **Testing:** `tinytest`.
- **OO System:** S3 dispatch for user-facing generics (`explain()`, `summarize()`, `suggest_code()`); R6 for `ellmer::Chat` objects.

### Development Workflow
Commands (run from `r/` directory):
```bash
# Load package interactively (for exploration)
Rscript -e 'devtools::load_all(".")'

# Run unit tests correctly
Rscript -e 'devtools::load_all("."); tinytest::run_test_dir("inst/tinytest")'

# Rebuild documentation (man/ and NAMESPACE)
Rscript -e 'devtools::document(".")'

# Full CRAN-style package check (CI gate)
Rscript -e 'devtools::check(".")'
```

---

## 7. Python Package (`python/`)

### Tech Stack & Architecture
- **Language:** Python (>= 3.8)
- **LLM Interface:** `chatlas` (>= 0.19.0).
- **Config Parsing:** `pyyaml`.
- **Testing:** `pytest`.
- **Model Support:** Extensible via decorator registry `@register_handler(FittedClassWrapper)` in `model_handlers.py`.

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

---

## 8. Unified Documentation Website (`docs-site/`)
The documentation is a unified [Quarto](https://quarto.org) website deployed to GitHub Pages. It integrates handwritten landing pages, Python docstrings via `quartodoc`, and R docs via `pkgdown`.

### Build Ordering
The R reference site must be generated *after* Quarto renders. Build workflow (from repo root):
```bash
./scripts/build_docs_site.sh
```

---

## 9. Coding Conventions & Best Practices

### Side-Effect Mitigation
`explain()` functions must **never** mutate the user's chat client.
- In R: Invoke `client$clone()` and reset the turns list.
- In Python: Invoke `copy.deepcopy(client)` and reset turns.

### Style Guides
- **R Style:** Tidyverse style guide (snake_case).
- **Python Style:** PEP 8 compliance, with type hints included on all public functions.
- **Git Commit Messages:** Follow Conventional Commits format (e.g. `feat: add suggest_code for OLS`).
