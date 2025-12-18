# Strategic Improvements for `statlingua`

Based on a review of the codebase (v0.1.0) and the capabilities of `ellmer` (0.4.0), the following architectural changes are recommended to improve maintainability, performance, and output quality.

## 1. Modernize Prompt Architecture

**Goal:** Simplify the R code and centralization of prompt logic by leveraging `ellmer`'s built-in templating features.

### Current State
- **Mechanism:** `R/utils.R` contains custom logic (`.assemble_sys_prompt`, `.read_prompt`) to manually read files from `inst/prompts/` and paste them together.
- **Drawback:** The structure of the system prompt (e.g., that "Role" comes before "Audience") is hardcoded in R. Reordering requires code changes. File handling is verbose.

### Recommendation: `ellmer::interpolate_package`
Adopt the standard `ellmer` pattern for package-based prompts.

1.  **Create a Master Template:**
    Create `inst/prompts/system_prompt.md` using Mustache/Jinja-style placeholders:
    ```markdown
    {{role_instruction}}

    # Context
    {{audience_instruction}}
    {{verbosity_instruction}}

    # Model Context
    {{model_specific_instruction}}

    # Output Requirements
    {{style_instruction}}
    {{caution_instruction}}
    ```

2.  **Refactor `R/explain.R`:**
    Replace the custom assembly code with a single call:
    ```r
    sys_prompt <- ellmer::interpolate_package(
      package = "statlingua",
      path = "prompts/system_prompt.md",
      role_instruction = ...,
      audience_instruction = ...
    )
    ```

## 2. Consolidate Configuration

**Goal:** Reduce file clutter and improve developer experience (DX).

### Current State
- **Mechanism:** "One file per setting".
    - `inst/prompts/audience/novice.md`
    - `inst/prompts/audience/expert.md`
    - `inst/prompts/verbosity/brief.md`
    - ...
- **Drawback:** dozens of tiny files containing single sentences. Hard to compare settings or make bulk edits.

### Recommendation: YAML Configuration
Move stable, short definitions into a single `inst/prompts/config.yaml`.

```yaml
audience:
  novice: "Assume the user has a limited statistics background..."
  expert: "Assume the user is a domain expert..."
verbosity:
  brief: "Be concise and to the point."
  detailed: "Provide comprehensive details."
```

**Implementation:**
- Add `yaml` to `Imports`.
- Read this file once at runtime (or on package load) and look up the string based on the user's `audience` argument.
- Keep `models/` as separate directories/files, as those instructions are lengthy and complex.

## 3. Leverage Structured Data (`broom`)

**Goal:** Reduce LLM hallucinations and improve precision.

### Current State
- **Mechanism:** `summarize()` calls `capture.output(summary(object))`.
- **Drawback:** The LLM receives a "wall of text" (whitespace-formatted table). It must visually parse columns, which is error-prone for tokens.

### Recommendation: Structured Context
Integrate `broom` (and `broom.mixed` for `lme4`/`nlme`) to generate JSON-ready data.

1.  **Update `summarize()`:**
    Instead of returning just text, return a structured representation (or a hybrid).
    ```r
    summarize.lm <- function(object, ...) {
      # Get coefficients as a clean dataframe
      tidy_stats <- broom::tidy(object)
      glance_stats <- broom::glance(object)
      
      # Convert to JSON or a strict Markdown table
      json_stats <- jsonlite::toJSON(list(coefficients = tidy_stats, metrics = glance_stats), auto_unbox = TRUE)
      
      return(json_stats)
    }
    ```
2.  **Benefit:** The LLM receives `{"p.value": 0.004}` explicitly, rather than parsing `0.004 **` from a string.

## 4. Performance & Caching

**Goal:** Save API costs and reduce latency.

### Recommendation: Memoise
LLM calls are expensive. Users often re-run `explain()` with the same parameters.
- Add `memoise` to `Imports`.
- Wrap the internal `.explain_core` function with `memoise::memoise()`.
- Use a cache key based on `hash(object, prompt_args)`.

## 5. Streaming Support

**Goal:** Improve perceived latency for interactive users.

### Recommendation
While `explain()` currently returns a static object, `ellmer` supports streaming.
- **Advanced:** Allow `explain(..., stream = TRUE)` which returns an `ellmer` stream object immediately, allowing the explanation to type out in the console in real-time.
