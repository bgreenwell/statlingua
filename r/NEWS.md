# Changelog

(This changelog follows the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.)

## [0.1.0] - 2025-05-28

### Added

- Initial CRAN release.

### Changed 

- Major refactor, including new prompt layout in `inst/prompts`
- The `explain()` generic gained a default fallback method (thanks to @Grandhe-Sundhar). Closes [#3](https://github.com/bgreenwell/statlingua/pull/3).
- Revised vignette and README files.
- Changed LICENSE to GPL (>= 2).
- Removed troublesome OpenAI URL in vignette

### Miscellaneous

- Fixed redundant arg lists and calls to `match.arg()`.
- Updated `Description` field per feedback from CRAN.

## [0.1.0.9999] - 2025-XY-XY

### Changed

- Repository restructured into a monorepo: the R package now lives under
  `r/`, alongside a Python counterpart under `python/`.
- Prompt content (audience/verbosity/style/model instructions) is now
  sourced from a single canonical `prompts/` directory at the repo root,
  shared with the Python package, and synced into `inst/prompts/` via
  `scripts/sync_prompts.py`.
- Internal prompt assembly (`.assemble_sys_prompt()`) now uses
  `ellmer::interpolate_package()` against a master template
  (`inst/prompts/system_prompt_template.md`) instead of hand-rolled
  `paste0()` string assembly. `audience`/`verbosity`/`style` instruction
  strings moved from one-file-per-setting into `inst/prompts/config.yaml`.
- `ellmer` and `yaml` moved from `Suggests` to `Imports` (both are now used
  directly by package code, not just examples).

### Miscellaneous

- Added CRAN badge to README.
