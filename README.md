# statlingua <img src="man/figures/logo.png" align="right" height="120" alt="" />

**WARNING:** This package is a work in progress! Use with caution.

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/dwyl/esta/issues)
[![R-CMD-check](https://github.com/bgreenwell/statlingua/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/bgreenwell/statlingua/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**statlingua** is an R package leveraging large language models (LLMs) to help convert complex statistical output into straightforward, understandable, and context-aware natural language descriptions. By feeding your statistical models and outcomes into this tool, you can effortlessly produce human-readable interpretations of coefficients, p-values, measures of model fit, and other key metrics. This capability aims to democratize statistical understanding for individuals with varying levels of technical expertise, making complex analyses more accessible to a broader audience.

### Usefulness Across Scenarios

The ability to translate dense statistical jargon into plain language has wide-ranging applications:

*   **Education and Learning:** Students new to statistics can use **statlingua** to better understand the output of models they are learning, bridging the gap between theoretical knowledge and practical application. It can serve as an interactive learning aid, helping to demystify complex concepts.
*   **Interdisciplinary Research:** Researchers who are not statistical experts can more easily interpret the results of analyses conducted by collaborators or through software packages, fostering better communication and deeper insights within teams.
*   **Consulting and Reporting:** Statisticians and data analysts can use **statlingua** to generate initial drafts of interpretations for reports and presentations, saving time and ensuring clarity for clients or stakeholders who may not have a strong statistical background.
*   **Data-Driven Decision Making in Business:** Business professionals can gain a clearer understanding of statistical findings, enabling them to make more informed, data-driven decisions without needing to become experts in statistical methodology.
*   **Rapid Prototyping and Exploration:** When exploring data and iterating through models, **statlingua** can provide quick, understandable summaries, allowing for faster assessment of model suitability and direction for further analysis.

By providing clear and contextualized explanations, **statlingua** empowers users to focus on the implications of their findings rather than getting bogged down in the technical details.

As of now, **statlingua** explicitly supports the following types of statistical models:

* Objects of class `"htest"` (e.g., R's built-in `t.test()` and `prop.test()` functions).
* Linear and generalized linear models (i.e., R's built-in `lm()` and `glm()` functions).
* Linear and generalized linear mixed-effects model from packages [nlme](https://cran.r-project.org/package=nlme) and [lme4](https://cran.r-project.org/package=lme4).
* Generalized additive models from package [mgcv](https://cran.r-project.org/package=mgcv).
* Survival regression models from package [survival](https://cran.r-project.org/package=survival).
* Proportional odds regression models from package [MASS](https://cran.r-project.org/package=MASS).
* Decision trees from package [rpart](https://cran.r-project.org/package=rpart).

For currently unsupported models, a useful default method is available that will attempt to provide a reasonable explanation of the provided statistical output/R object.

## Installation

The **statlingua** package is currently not available on CRAN, but you can install the development version from GitHub.

``` r
# Install the latest development version from GitHub:
if (!requireNamespace("remotes")) {
  install.packages("remotes")
}
remotes::install_github("bgreenwell/statlingua")
```

## API Key Setup

**statlingua** relies on the [ellmer](https://github.com/bgreenwell/ellmer) package to interface with various large language models (LLMs). Consequently, **statlingua** itself does not directly handle API keys. Instead, you need to configure [ellmer](https://github.com/tidyverse/ellmer) with the appropriate API key for the LLM provider you intend to use (e.g., OpenAI, Google AI Studio, Anthropic).

Please refer to the [ellmer](https://github.com/tidyverse/ellmer) package documentation for detailed instructions on:

*   Setting up API keys as environment variables (recommended).
*   Specifying different models and providers.
*   Other [ellmer](https://github.com/tidyverse/ellmer) configuration options.

Typically, you will set an environment variable like `OPENAI_API_KEY` for OpenAI models. Once [ellmer](https://github.com/tidyverse/ellmer) is correctly configured and able to access an LLM, **statlingua** will automatically leverage that connection.

## Extending statlingua to Support New Models

One of the key strengths of **statlingua** is its extensibility. If you want to add support for a new type of statistical model, you primarily need to create a new system prompt tailored to that model's output and characteristics. The package uses S3 methods for the main `explain()` function, dispatching to specific methods based on the class of the input model object.

### Understanding the Prompt Structure

The explanatory power of **statlingua** comes from carefully crafted system prompts that guide the LLM. These prompts are stored as Markdown files in the `inst/prompts/` directory of the package. For example, `inst/prompts/system_prompt_lm.md` contains the prompt for `lm` objects.

A typical system prompt generally includes:

1.  **Role Definition:** Instructs the LLM to act as an expert statistician.
2.  **Task Description:** Explains that the LLM needs to interpret statistical output and explain it in understandable terms.
3.  **Output Structure Guidance:** Specifies how the explanation should be formatted (e.g., using Markdown, sections for different parts of the model).
4.  **Key Areas to Cover:** Lists the essential components of the model output to address (e.g., coefficients, standard errors, p-values, goodness-of-fit measures, model assumptions).
5.  **Contextualization Instructions:** Asks the LLM to relate the findings to the (optional) user-provided problem description or context.
6.  **Tone and Audience:** Specifies the desired tone (e.g., helpful, slightly formal) and target audience (e.g., someone with basic statistical knowledge but not an expert).
7.  **Placeholders:** Uses placeholders like `{{PROBLEM_DESCRIPTION}}` and `{{MODEL_OUTPUT}}` which **statlingua** will replace with the actual problem description (if provided) and the model's summary output before sending the prompt to the LLM.

### Example: Adding Support for `vglm` from the `VGAM` package

Let's imagine you want to add support for `vglm` (Vector Generalized Linear Models) objects from the [VGAM](https://cran.r-project.org/package=VGAM) package. Here's a conceptual outline:

1.  **Create a New Prompt File:**
    You would start by creating a new file, say `inst/prompts/system_prompt_vglm.md`.

2.  **Draft the System Prompt for `vglm`:**
    This prompt would be similar in structure to others but would emphasize aspects specific to `vglm` objects. For example, `vglm` models can handle multiple linear predictors and a wider variety of distributions and link functions. The prompt would need to guide the LLM to:
    *   Identify the type of `vglm` (e.g., multinomial logistic regression, proportional odds model, etc.).
    *   Explain the interpretation of coefficients for each linear predictor, considering the specific link functions and family.
    *   Discuss any relevant model diagnostics or fit statistics particular to `vglm`.
    *   Mention assumptions specific to the fitted `vglm` model.

    A snippet of `inst/prompts/system_prompt_vglm.md` might look like:

    ```markdown
    You are an expert statistician tasked with explaining the output of a Vector Generalized Linear Model (VGLM) from the R package VGAM. The user will provide a problem description (optional) and the summary output of a `vglm` object. Your goal is to provide a clear, concise, and context-aware explanation of the model's results in Markdown format.

    Problem context:
    {{PROBLEM_DESCRIPTION}}

    Model output:
    
    {{MODEL_OUTPUT}}
    

    Please structure your explanation as follows:

    ## VGLM Model Overview
    - Briefly describe the type of VGLM fitted (e.g., multinomial regression, cumulative logit model).
    - Mention the response variable and its nature.
    - List the predictor variables.

    ## Interpretation of Coefficients
    - For each linear predictor/equation, explain the meaning of the coefficients.
    - Pay attention to the link functions and how they affect interpretation (e.g., log odds, log relative risk).
    - Clearly state the reference category for categorical predictors if applicable.

    ## Model Fit and Diagnostics
    - Discuss any provided statistics for model fit (e.g., deviance, AIC).
    - Mention any important assumptions for this type of VGLM and if the output provides information to assess them.

    ## Conclusion
    - Summarize the main findings in simple terms.
    - If a problem description was provided, relate the findings back to that context.

    Keep the tone helpful and aim for an audience with some statistical background but not necessarily experts in VGLMs.
    ```

3.  **Implement the S3 Method:**
    You would then add an S3 method for `explain.vglm` in an R script (e.g., `R/explain_vglm.R`):

    ```r
    #' Explain a vglm object
    #'
    #' @export
    explain.vglm <- function(x, problem_description = NULL, ...) {
      # Capture the model summary
      model_summary <- utils::capture.output(summary(x))
      model_output <- paste(model_summary, collapse = "\n")

      # Construct the prompt using the generic function
      # This assumes get_prompt_text() can find "system_prompt_vglm.md"
      # and ellmer is configured.
      res <- ellmer::prompt(
        prompt = get_prompt_text(
          system_prompt_name = "system_prompt_vglm.md",  # Or whatever you named it
          values = list(
            "{{PROBLEM_DESCRIPTION}}" = ifelse(
              test = is.null(problem_description),
              yes = "The user did not provide a problem description.",
              no = problem_description
            ),
            "{{MODEL_OUTPUT}}" = model_output
          )
        ),
        # Pass other arguments to ellmer::prompt() as needed
        # (e.g., model, provider, temperature)
        ...
      )
      
      # Return as a statlingua_explanation object
      structure(
        list(
          explanation = res,  # Assuming 'res' is the text from the LLM
          original_object = x,
          problem_description = problem_description
        ),
        class = c("statlingua_explanation", "list")
      )
    }
    ```
    You would also need to ensure `get_prompt_text()` (an internal helper function in **statlingua**) can locate your new prompt file, or you might read the prompt file directly in your method. The `explain.default` method provides a good template for how to structure these S3 methods.

4.  **Add to `NAMESPACE` and Document:**
    *   Export the new method: `S3method(explain, vglm)`
    *   Add documentation (e.g., using `roxygen2` comments).

5.  **Testing:**
    Thoroughly test the new method with various `vglm` examples to ensure the LLM provides sensible and accurate explanations based on your prompt. You might need to iterate on the prompt design to achieve the desired output quality.

By following this pattern, **statlingua** can be systematically extended to cover a wide array of statistical models in R, making it a versatile tool for statistical interpretation.
