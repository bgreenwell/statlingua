# statlingua <img src="man/figures/logo.png" align="right" height="120" alt="statlingua logo" />
[![CRAN status](https://www.r-pkg.org/badges/version/ebm)](https://CRAN.R-project.org/package=ebm)
[![R-CMD-check](https://github.com/bgreenwell/statlingua/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/bgreenwell/statlingua/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/bgreenwell/statlingua/issues)

The **statlingua** R package is designed to help bridge the gap between complex statistical outputs and clear, human-readable explanations. By leveraging the power of Large Language Models (LLMs), **statlingua** helps you effortlessly translate the dense jargon of statistical models—coefficients, p-values, model fit indices, and more—into straightforward, context-aware natural language.

Whether you're a student grappling with new statistical concepts, a researcher needing to communicate findings to a broader audience, or a data scientist looking to quickly draft reports, **statlingua** makes your statistical journey smoother and more accessible.

### Why **statlingua**?

Statistical models are powerful, but their outputs can be intimidating. **statlingua** empowers you to:

* **Democratize Understanding:** Make complex analyses accessible to individuals with varying levels of statistical expertise.
* **Enhance Learning & Education:** Students can gain a deeper intuition for model outputs, connecting theory to practical application. Use it as an interactive learning aid to demystify statistical concepts.
* **Foster Interdisciplinary Collaboration:** Researchers from diverse fields can more easily interpret and discuss analytical results, leading to richer insights.
* **Streamline Reporting & Consulting:** Quickly generate initial drafts of interpretations for reports and presentations, saving time and ensuring clarity for clients or stakeholders.
* **Drive Data-Informed Decisions:** Business professionals can better grasp statistical findings, enabling more confident data-driven decision-making without needing to become statistical experts themselves.
* **Accelerate Prototyping & Exploration:** Rapidly understand model summaries during iterative data exploration, allowing for faster assessment and refinement of analyses.

By providing clear and contextualized explanations, **statlingua** helps you focus on the *implications* of your findings rather than getting bogged down in technical minutiae.

### Supported Models

As of now, **statlingua** explicitly supports a variety of common statistical models in R, including:

* Objects of class `"htest"` (e.g., from `t.test()`, `prop.test()`).
* Linear models (`lm()`) and Generalized Linear Models (`glm()`).
* Linear and Generalized Linear Mixed-Effects Models from packages [nlme](https://cran.r-project.org/package=nlme) (`lme()`) and [lme4](https://cran.r-project.org/package=lme4) (`lmer()`, `glmer()`).
* Generalized Additive Models (`gam()` from package [mgcv](https://cran.r-project.org/package=mgcv)).
* Survival Regression Models (`survreg()`, `coxph()` from package [survival](https://cran.r-project.org/package=survival)).
* Proportional Odds Logistic Regression (`polr()` from package [MASS](https://cran.r-project.org/package=MASS)).
* Decision Trees (`rpart()` from package [rpart](https://cran.r-project.org/package=rpart)).
* ...and more, with a robust default method for other model types!

### Installation

**statlingua** is not yet on CRAN, but you can install the development version from GitHub:

```r
if (!requireNamespace("remotes")) {
  install.packages("remotes")
}
remotes::install_github("bgreenwell/statlingua")
```

You'll also need to install the [ellmer](https://cran.r-project.org/package=ellmer) package, which you can obtain from CRAN:

```r
install.packages("ellmer")  # >= 0.2.0
```

### API Key Setup & [ellmer](https://cran.r-project.org/package=ellmer) Dependency

**statlingua** doesn't directly handle API keys or LLM communication. It acts as a sophisticated prompt engineering toolkit that prepares inputs and then passes them to [ellmer](https://cran.r-project.org/package=ellmer). The [ellmer](https://cran.r-project.org/package=ellmer) package is responsible for interfacing with various LLM providers (e.g., OpenAI, Google AI Studio, Anthropic). 

Please refer to the [ellmer](https://cran.r-project.org/package=ellmer) package documentation for detailed instructions on:

  * Setting up API keys (usually as environment variables like `OPENAI_API_KEY`, `GEMINI_API_KEY`, etc.).
  * Specifying different LLM models and providers.
  * Other configuration and model parameter options.

Once [ellmer](https://cran.r-project.org/package=ellmer) is installed and has access to an LLM provider, **statlingua** will seamlessly leverage that connection.

### Quick Example: Explaining a Linear Model

```r
# Ensure you have an appropriate API key set up first!
# Sys.setenv(GEMINI_API_KEY = "<YOUR_API_KEY_HERE>") 

library(statlingua)

# Fit a polynomial regression model
fm_cars <- lm(dist ~ poly(speed, degree = 2), data = cars)
summary(fm_cars)

# Define some context (highly recommended!)
cars_context <- "
This model analyzes the 'cars' dataset from the 1920s. Variables include:
  * 'dist' - The distance (in feet) taken to stop.
  * 'speed' - The speed of the car (in mph).
We want to understand how speed affects stopping distance in the model.
"

# Establish connection to an LLM provider (in this case, Google Gemini)
client <- ellmer::chat_google_gemini(echo = "none")  # defaults to gemini-2.0-flash

# Get an explanation
explain(
  fm_cars,                 # model for LLM to interpret/explain
  client = client,         # connection to LLM provider
  context = cars_context,  # additional context for LLM to consider
  audience = "student",    # target audience
  verbosity = "detailed",  # level of detail
  style = "markdown"       # output style
)

# Ask a follow-up question
client$chat(
  "How can I construct confidence intervals for each coefficient in the model?"
)
```

For more examples, including output, see the [introductory vignette](https://bgreenwell.github.io/statlingua/articles/statlingua.html).

### Extending **statlingua** to Support New Models

One of **statlingua**'s core strengths is its extensibility. You can add or customize support for new statistical model types by crafting specific prompt components. The system prompt sent to the LLM is dynamically assembled from several markdown files located in the `inst/prompts/` directory of the package.

The main function `explain()` uses S3 dispatch. When `explain(my_model_object, ...)` is called, R looks for a method like `explain.class_of_my_model_object()`. If not found, `explain.default()` is used.

#### Prompt Directory Structure

The prompts are organized as follows within `inst/prompts/`:

  * `common/`: Contains base prompts applicable to all models.
      * `role_base.md`: Defines the fundamental role of the LLM.
      * `caution.md`: A general cautionary note appended to explanations.
  * `audience/`: Markdown files for different target audiences (e.g., `novice.md`, `researcher.md`). The filename (e.g., "novice") matches the `audience` argument in `explain()`.
  * `verbosity/`: Markdown files for different verbosity levels (e.g., `brief.md`, `detailed.md`). The filename matches the `verbosity` argument.
  * `style/`: Markdown files defining the output format (e.g., `markdown.md`, `json.md`). The filename matches the `style` argument.
  * `models/<model_class_name>/`: Directory for model-specific prompts. `<model_class_name>` should correspond to the R class of the statistical object (e.g., "lm", "glm", "htest").
      * `instructions.md`: The primary instructions for explaining this specific model type. This tells the LLM what to look for in the model output, how to interpret it, and what assumptions to discuss.
      * `role_specific.md` (Optional): Additional role details specific to this model type, augmenting `common/role_base.md`.

#### Example: Adding Support for `vglm` from the `VGAM` package

Let's imagine you want to add dedicated support for `vglm` (Vector Generalized Linear Models) objects from the [VGAM](https://cran.r-project.org/package=VGAM) package.

1.  **Create New Prompt Files:**
    You would create a new directory `inst/prompts/models/vglm/`. Inside this directory, you'd add:

      * `inst/prompts/models/vglm/instructions.md`: This file will contain the detailed instructions for the LLM on how to interpret `vglm` objects. You'd detail what aspects of `summary(vglm_object)` are important, how to discuss coefficients (potentially for multiple linear predictors), link functions, model fit statistics specific to `vglm`, and relevant assumptions.
        ```markdown
        You are explaining a **Vector Generalized Linear Model (VGLM)** (from `VGAM::vglm()`).

        **Core Concepts & Purpose:**
        VGLMs are highly flexible, extending GLMs to handle multiple linear predictors and a wider array of distributions and link functions, including multivariate responses.
        Identify the **Family** (e.g., multinomial, cumulative) and **Link functions**.

        **Interpretation:**
        * **Coefficients:** Explain for each linear predictor. Pay attention to link functions (e.g., log odds, log relative risk). Clearly state reference categories.
        * **Model Fit:** Discuss deviance, AIC, etc.
        * **Assumptions:** Mention relevant assumptions.
        ```
    
      * `inst/prompts/models/vglm/role_specific.md` (Optional): If `vglm` models require the LLM to adopt a slightly more specialized persona.
        
        You have particular expertise in Vector Generalized Linear Models (VGLMs), understanding their diverse applications for complex response types.
        

2.  **Implement the S3 Method:**
    Add an S3 method for `explain.vglm` in an R script (e.g., `R/explain_vglm.R`):

    ```r
    #' Explain a vglm object
    #'
    #' @inheritParams explain
    #' @param object A \code{vglm} object.
    #' @export
    explain.vglm <- function(
        object,
        client,
        context = NULL,
        audience = c("novice", "student", "researcher", "manager", "domain_expert"),
        verbosity = c("moderate", "brief", "detailed"),
        style = c("markdown", "html", "json", "text", "latex"),
        ...
      ) {
      audience <- match.arg(audience)
      verbosity <- match.arg(verbosity)
      style <- match.arg(style)

      # Use the internal .explain_core helper if it suits,
      # or implement custom logic if vglm needs special handling.
      # .explain_core handles system prompt assembly, user prompt building,
      # and calling the LLM via the client.
      # 'name' should match the directory name in inst/prompts/models/
      # 'model_description' is what's shown to the user in the prompt.
      .explain_core(
        object = object,
        client = client,
        context = context,
        audience = audience,
        verbosity = verbosity,
        style = style,
        name = "vglm", # This tells .assemble_sys_prompt to look in inst/prompts/models/vglm/
        model_description = "Vector Generalized Linear Model (VGLM) from VGAM"
      )
    }
    ```

    The `summarize.vglm` method might also need to be implemented in `R/summarize.R` if `summary(object)` for `vglm` needs special capture or formatting for the LLM. If `utils::capture.output(summary(object))` is sufficient, `summarize.default` might work initially.

3.  **Add to `NAMESPACE` and Document:**

      * Ensure the new method is exported in your `NAMESPACE` file (usually handled by `roxygen2`): `S3method(explain, vglm)`
      * Add `roxygen2` documentation blocks for `explain.vglm`.

4.  **Testing:**
    Thoroughly test with various `vglm` examples. You might need to iterate on your `instructions.md` and `role_specific.md` to refine the LLM's explanations.

By following this pattern, **statlingua** can be systematically extended to cover a vast array of statistical models in R\!

### Contributing

Contributions are welcome\! Please see the [GitHub issues](https://www.google.com/url?sa=E&source=gmail&q=https://github.com/bgreenwell/statlingua/issues) for areas where you can help.

### License

**statlingua** is available under the GNU General Public License v3.0 (GNU GPLv3). See the `LICENSE.md` file for more details.
