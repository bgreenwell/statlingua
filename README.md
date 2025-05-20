# statlingua

**WARNING:** This package is a work in progess! Use with caution.

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/dwyl/esta/issues)
[![R-CMD-check](https://github.com/bgreenwell/statlingua/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/bgreenwell/statlingua/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**statlingua** is an R package leveraging large language models to help convert complex statistical output into straightforward, understandable, and context-aware natural language descriptions. By feeding your statistical models and outcomes into this tool, you can effortlessly produce human-readable interpretations of coefficients, p-values, measures of model fit, and other key metrics, thereby democratizing statistical understanding for individuals with varying levels of technical expertise.

As of now, **statlingua** supports the following types of statistical models:

* Objects of class `"htest"` (e.g., R's built-in `t.test()` and `prop.test()` functions).
* Linear and generalized linear models (i.e., R's built-in `lm()` and `glm()` functions).
* Linear and generalized linear mixed-effects model from packages [nlme](https://cran.r-project.org/package=nlme) and [lme4](https://cran.r-project.org/package=lme4).
* Generalized additive models from package [mgcv](https://cran.r-project.org/package=mgcv).
* Survival regression models from package [survival](https://cran.r-project.org/package=survival).
* Proportional odds regression models from package [MASS](https://cran.r-project.org/package=MASS).
* Decision trees from package [rpart](https://cran.r-project.org/package=rpart).
* ~~ARIMA models from package [forecast](https://cran.r-project.org/package=forecast).~~

## Installation

The **statlingua** package is currently not available on CRAN, but you can install the development version from GitHub.

``` r
# Install the latest development version from GitHub:
if (!requireNamespace("remotes")) {
  install.packages("remotes")
}
remotes::install_github("bgreenwell/statlingua")
```

## TODO/wishlist

Some ideas on ways to enhance the package:

### Granular Control Over Explanation Output

Currently, the explanations are guided by pre-defined prompts offering a standardized output. To make it more versatile:

* User-Defined Detail Level: Allow users to specify the desired verbosity of the explanation, for example, through an argument like detail_level = "brief", "moderate", or "detailed". This would adjust the system prompt to ask the LLM for more concise or more elaborate interpretations.
* Target Audience Customization: Introduce an option to tailor the explanation's technical depth to different audiences (e.g., `audience = "novice"`, `"researcher"`, `"domain_expert_no_stats_bg"`). This would modify the prompt to use simpler language and analogies for novices, or more technical terms for experts.
* Selective Explanations: Enable users to request explanations for specific parts of the model output, such as focusing only on "coefficients," "model fit statistics," or "random effects" for mixed models.

This could be implemented by adding parameters to the `explain()` function which dynamically adjust the system prompts sent to the LLM.

### Interactive Explanation Mode & Follow-up Questions

The current explain() function provides a comprehensive, one-time explanation. Enhancing this with interactivity could significantly boost its utility as a learning and exploration tool:

* Conversational Analysis: After the initial explanation is generated, allow users to ask follow-up questions directly within the R console (e.g., "Can you explain the intercept in simpler terms?" or "What does the R-squared value imply here?").
* Contextual Memory: The system would need to maintain the context of the initial model output and the LLM's first explanation to answer follow-up questions coherently. This could leverage the chat history capabilities of the underlying ellmer package's chat objects.

This would transform statlingua from a static explanation generator into a more dynamic, conversational partner for statistical understanding.

### Support for Model Comparison Explanations

Users often fit multiple models and need to compare them. statlingua could be extended to assist with this:

* Comparative Analysis: Develop functionality where users can input two or more model objects (e.g., lm objects from a nested model sequence, or different models fit to the same data).
* Guided Interpretation: The LLM would be prompted to explain the key differences between the models, interpret comparison statistics (like those from anova() calls, or differences in AIC/BIC), and discuss potential reasons for preferring one model over another, based on the provided context and statistical output.

This would address a common and often complex task in statistical modeling.

### Enhanced Integration with Reporting Workflows & Diverse Output Formats

While Markdown is a good default, providing more output options and smoother integration with R's reporting ecosystem would be beneficial:

* Multiple Output Formats: Beyond the current Markdown, offer options to directly output explanations in formats such as:
  - HTML: For direct inclusion in web pages or RMarkdown HTML outputs beyond standard rendering.
  - LaTeX: For users preparing academic papers.
  - R Objects: Convert parts of the explanation (like structured summaries or key findings) into R objects like gt tables or flextable objects for more programmatic control in reports.
* Reporting Helpers: Include helper functions to simplify the embedding of statlingua explanations into RMarkdown or Quarto documents. This might involve custom knitr S3 methods for statlingua_explanation objects or dedicated functions that handle chunk options for verbosity, audience, etc.

This would make it easier for users to incorporate statlingua's insights into their documents and presentations.

### Deeper Guidance on Model Assumption Checking

The current prompts already do a good job of mentioning model assumptions and suggesting checks (as seen in files like inst/prompts/system_prompt_lm.md and inst/prompts/system_prompt_coxph.md). This could be taken a step further:

* Interpreting Diagnostic Plots/Tests: Allow users to optionally pass the output of common diagnostic functions (e.g., plots generated by plot(model_object), results from car::Anova(), performance::check_model(), or survival::cox.zph()) to the explain() function.
* Holistic Interpretation: The LLM could then be prompted to interpret these diagnostic outputs in conjunction with the main model summary. This would provide users with a more integrated understanding of whether model assumptions are met, the potential implications of any violations, and how these might affect the interpretation of the primary model results.
* Contextual Caveats: The explanation could then also include more specific caveats or recommendations based on the supplied diagnostic information.

This would empower users not just to understand their model output, but also to critically evaluate its validity.
