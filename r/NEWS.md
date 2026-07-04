# statlingo 0.1.0.9000

## Changed

* Renamed the package to `statlingo`.
* Repository restructured into a monorepo: the R package now lives under
  `r/`, alongside a Python counterpart under `python/`.
* Prompt content (audience/verbosity/style/model instructions) is now
  sourced from a single canonical `prompts/` directory at the repo root,
  shared with the Python package, and synced into `inst/prompts/` via
  `scripts/sync_prompts.py`.
* Internal prompt assembly (`.assemble_sys_prompt()`) now uses
  `ellmer::interpolate_package()` against a master template
  (`inst/prompts/system_prompt_template.md`) instead of hand-rolled
  `paste0()` string assembly. `audience`/`verbosity`/`style` instruction
  strings moved from one-file-per-setting into `inst/prompts/config.yaml`.
* `ellmer` and `yaml` moved from `Suggests` to `Imports` (both are now used
  directly by package code, not just examples). `ellmer` requirement
  bumped to `>= 0.4.1`.
* Prompt-type keys (e.g. `lm`, `glm`) renamed to language-neutral, semantic
  names (e.g. `linear_model`, `generalized_linear_model`) shared with the
  Python package, and prompt content generalized to remove R-specific
  framing.
* `explain()` gained a `language` argument for requesting explanations in
  a specific language.
* Distributed via [r-universe](https://bgreenwell.r-universe.dev/) and
  GitHub going forward, not CRAN.

## Added

* New "engine-specific" prompt notes for model types with multiple
  supported fitting engines across R and Python (currently linear and
  generalized linear models), describing the exact output format of the
  library that produced the summary.

## Miscellaneous

* Added CRAN badge to README. (Later removed as part of the switch to
  r-universe/GitHub distribution.)

# statlingo 0.1.0

## Added

* Initial CRAN release (published under the name `statlingua`).

## Changed

* Major refactor, including new prompt layout in `inst/prompts`.
* The `explain()` generic gained a default fallback method (thanks to
  @Grandhe-Sundhar). Closes
  [#3](https://github.com/bgreenwell/statlingo/pull/3).
* Revised vignette and README files.
* Changed LICENSE to GPL (>= 2).
* Removed troublesome OpenAI URL in vignette.

## Miscellaneous

* Fixed redundant arg lists and calls to `match.arg()`.
* Updated `Description` field per feedback from CRAN.
