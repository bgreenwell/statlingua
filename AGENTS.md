# AGENTS.md for statlingua

This file provides context and instructions for AI agents working on the `statlingua` R package.

## Project Overview
`statlingua` is an R package designed to interpret and explain the output of statistical models (e.g., `lm`, `glm`, `htest`) using Large Language Models (LLMs). It leverages the `ellmer` package to interface with LLM providers.

**Core Mission:** Bridge the gap between complex statistical R output and human-readable explanations for various audiences (novice, student, researcher, etc.).

## Tech Stack
- **Language:** R (>= 4.1.0)
- **LLM Interface:** `ellmer` (>= 0.4.0) (R6-based chat clients)
- **Testing:** `tinytest`
- **Documentation:** `roxygen2`
- **OO System:** S3 (for user-facing generics like `explain`), R6 (internal use and `ellmer` objects).

## File Structure & Architecture
- **`R/explain.R`**: Contains the main `explain()` S3 generic and methods. This is the primary user interface.
- **`R/summarize.R`**: Contains the `summarize()` S3 generic. This function converts R model objects into a text representation suitable for LLM consumption.
- **`R/utils.R`**: Internal helpers, including `.explain_core` (the orchestration logic) and prompt loading functions.
- **`inst/prompts/`**: The "Prompt Engineering" database.
    - `models/<model_class>/`: Specific instructions and roles for different model types.
    - `audience/`: Personas for the output (e.g., `novice.md`).
    - `verbosity/`: Instructions for length/detail.
    - `style/`: Instructions for output format (markdown, html, etc.).
- **`inst/tinytest/`**: Unit tests.

## Development Workflow

### 1. Setup
The project is a standard R package.
```r
# Install dev dependencies
Rscript -e 'install.packages(c("devtools", "tinytest", "roxygen2", "ellmer"))'
```

### 2. Running Tests
The project uses `tinytest`.
- **Run all tests:**
  ```bash
  Rscript -e 'tinytest::build_install_test()' # Robust check
  # OR for quick dev cycle:
  Rscript -e 'tinytest::run_test_dir("inst/tinytest")'
  ```
- **Test File:** `inst/tinytest/test_statlingua.R`
- **Mocks:** The tests use a `MockChat` R6 class to simulate `ellmer` behavior without making real API calls. **Always** use mocking for new tests unless explicitly testing integration.

### 3. Documentation
- Edit R scripts with `#'` roxygen comments.
- Update documentation using:
  ```bash
  Rscript -e 'devtools::document()'
  ```
- This updates `NAMESPACE` and `man/*.Rd` files.

### 4. Adding Support for New Models
To add support for a new statistical class (e.g., `brmsfit`):
1.  **Create `inst/prompts/models/brmsfit/`**: Add `instructions.md` and `role_specific.md`.
2.  **Implement `summarize.brmsfit`** in `R/summarize.R`: Return a clean text summary of the object.
3.  **Implement `explain.brmsfit`** in `R/explain.R`: Call `.explain_core`.

## Coding Conventions
- **Style:** Tidyverse style (snake_case for functions/variables).
- **Side Effects:** Functions should generally be pure. `explain()` interacts with an LLM but should **not** mutate the user's `client` object. Always `clone()` the client before use.
- **Output:** `explain()` returns a `statlingua_explanation` object (list with class attribute).

## Git Practices
- **Commits:** Use conventional commit messages (e.g., `feat: add support for glm`, `fix: update prompt loading logic`).
- **Granularity:** Keep commits atomic and focused.
