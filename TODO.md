### TODO

- [ ] **Enhanced Model Support & Granularity:**
    - [ ] Systematically add support for more popular statistical modeling packages (e.g., `brms`, `rstanarm`, `tidymodels` workflows, specific time series models, `glmmTMB`).
    - [ ] Allow users to request explanations for specific *parts* of the summary output (e.g., "explain just the random effects table," "explain the ANOVA table for fixed effects," "explain these specific coefficients").

- [ ] **Custom Prompt Template Management:**
    - [ ] Allow users to supply their own complete prompt templates or modify existing ones without altering the package installation (e.g., via an argument like `prompt_template_dir` or functions to export/view/load modified default prompts).

- [ ] **Output Validation & Structuring for Programmatic Use:**
    - [ ] Implement more robust validation that the LLM's output *is* valid JSON when `style = "json"` is used.
    - [ ] Define a more structured and predictable JSON schema for each model type to make the JSON output more reliable for programmatic extraction of information.
    - [ ] Consider an option to return the explanation as a structured R list directly, not just a JSON string.

- [ ] **Integration with Reporting Workflows:**
    - [ ] Provide helper functions or examples for easily integrating `statlingua` explanations into R Markdown, Quarto, or other reporting tools.
    - [ ] Ensure `style = "latex"` and `style = "html"` fragments are clean and directly usable.
    - [ ] Explore creating helper functions like `to_quarto_block()` or `to_rmd_chunk()` to wrap explanations appropriately.
