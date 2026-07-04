#' Explain statistical output
#'
#' Use an LLM to explain the output from various statistical objects using
#' straightforward, understandable, and context-aware natural language
#' descriptions.
#'
#' @param object An appropriate statistical object. For example, `object` can be
#' the output from calling [t.test()][stats::t.test] or [glm()][stats::glm].
#'
#' @param client A [Chat][ellmer::Chat] object (e.g., from calling
#' [chat_openai()][ellmer::chat_openai] or
#' [chat_gemini()][ellmer::chat_gemini)]).
#'
#' @param context Optional character string providing additional context, such
#' as background on the research question and information about the data.
#'
#' @param audience Character string indicating the target audience:
#' * `"novice"` - Assumes the user has a limited statistics background
#' (default).
#' * `"student"` - Assumes the user is learning statistics.
#' * `"researcher"` - Assumes the user has a strong statistical background and
#' is familiar with common methodologies.
#' * `"manager"` - Assumes the user needs high-level insights for
#' decision-making.
#' * `"domain_expert"` - Assumes the user is an expert in their own field but
#' not necessarily in statistics.
#'
#' @param verbosity Character string indicating the desired verbosity:
#' * `"moderate"` - Offers a balanced explanation (default).
#' * `"brief"` - Offers a high-level summary.
#' * `"detailed"` - Offers a comprehensive interpretation.
#'
#' @param style Character string indicating the desired output style:
#'   * `"markdown"` (default) - Output formatted as plain Markdown.
#'   * `"html"` - Output formatted as an HTML fragment.
#'   * `"json"` - Output structured as a JSON string parseable into an R list.
#'   * `"text"` - Output as plain text.
#'   * `"latex"` - Output as a LaTeX fragment.
#'
#' @param language Character string specifying the language the explanation
#'   should be written in (e.g. `"Spanish"`, `"French"`,
#'   `"Mandarin Chinese"`). If `NULL` (the default), no language
#'   constraint is added and the LLM will typically respond in the same
#'   language as the input/context or its default language.
#'
#' @param ... Additional optional arguments. (Currently ignored.)
#'
#' @returns An object of class `"statlingo_explanation"`. Essentially a list
#' with the following components:
#' * `text` - Character string representation of the LLM's response.
#' * `model_type` - Character string giving the internal prompt model type
#' (e.g., `"linear_model"` or `"cox_proportional_hazards"`).
#' * `audience` - Character string specifying the level or intended audience for
#' the explanations.
#' * `verbosity` - Character string specifying the level of verbosity or level
#' of detail of the provided explanation.
#'
#' @examples
#' \dontrun{
#' # Polynomial regression
#' fm1 <- lm(dist ~ poly(speed, degree = 2), data = cars)
#' context <- "
#' The data give the speed of cars (mph) and the distances taken to stop (ft).
#' Note that the data were recorded in the 1920s!
#' "
#' # Use Google Gemini to explain the output; requires an API key; see
#' # ?ellmer::chat_google_gemini for details
#' client <- ellmer::chat_google_gemini(echo = "none")
#' ex <- explain(fm1, client = client, context = context)
#' explain(fm1, client = client, context = context, language = "Spanish")
#'
#' # Poisson regression example using the bike sharing data from ISLR2
#' Bikeshare <- ISLR2::Bikeshare
#'
#' # Fit a Poisson regression model to the bike sharing data set
#' fm2 <- glm(bikers ~ mnth + hr + workingday + temp + weathersit,
#'            data = Bikeshare, family = poisson)
#'
#' # Additional context for the LLM to consider when explaining the model's
#' # output
#' context <- "
#' The data contain the hourly and daily count of rental bikes between years
#' 2011 and 2012 in Capital bikeshare system, along with weather and seasonal
#' information. The variables in the model include:
#'
#' * bikers - Total number of bikers.
#' * mnth - Month of the year, coded as a factor.
#' * hr - Hour of the day, coded as a factor from 0 to 23.
#' * workingday - Is it a work day? Yes=1, No=0.
#' * temp - Normalized temperature in Celsius. The values are derived via
#'   (t-t_min)/(t_max-t_min), t_min=-8, t_max=+39.
#' * weathersit - Weather, coded as a factor.
#' "
#'
#' # Use Google Gemini to explain the output; requires an API key; see
#' # ?ellmer::chat_google_gemini for details
#' client <- ellmer::chat_google_gemini(echo = "none")
#' explain(fm2, client = client, context = context, audience = "student",
#'         verbosity = "brief", style = "text")
#' }
#'
#'
#' @export
explain <- function(
    object,
    client,
    context = NULL,
    audience = c("novice", "student", "researcher", "manager",
                 "domain_expert"),
    verbosity = c("moderate", "brief", "detailed"),
    style = c("markdown", "html", "json", "text", "latex"),
    language = NULL,
    ...
  ) {
  audience <- match.arg(audience)
  verbosity <- match.arg(verbosity)
  style <- match.arg(style)
  UseMethod("explain")
}


#' @rdname explain
#' @export
explain.default <- function(
    object,
    client,
    context = NULL,
    audience = "novice",
    verbosity = "moderate",
    style = "markdown",
    language = NULL,
    ...
  ) {
  stopifnot(inherits(client, what = c("Chat", "R6")))
  sys_prompt <- .assemble_sys_prompt(model_name = "default",
                                     audience = audience, verbosity = verbosity,
                                     style = style, language = language)
  output <- .capture_output(object)
  usr_prompt <- .build_usr_prompt("R object", output = output,
                                   context = context)
  
  # Clone the client to avoid side effects on the user's object
  client_clone <- client$clone()
  client_clone$set_turns(list())
  client_clone$set_system_prompt(sys_prompt)
  
  ex <- client_clone$chat(usr_prompt, echo = "none")
  
  ex <- .remove_fences(ex)
  output <- structure(
    list(
      text = ex,
      # Potentially add other metadata here if useful later
      model_type = "default",
      audience = audience,
      verbosity = verbosity,
      style = style
    ),
    class = c("statlingo_explanation", "character")
  )
  return(output)
}


# Methods for package stats ----------------------------------------------------

#' @rdname explain
#' @export
explain.htest <- function(
    object,
    client,
    context = NULL,
    audience = "novice",
    verbosity = "moderate",
    style = "markdown",
    language = NULL,
    ...
  ) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    style = style,
    language = language,
    name = "hypothesis_test",
    model = object$method
  )
}


#' @rdname explain
#' @export
explain.lm <- function(
    object,
    client,
    context = NULL,
    audience = "novice",
    verbosity = "moderate",
    style = "markdown",
    language = NULL,
    ...
  ) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    style = style,
    language = language,
    name = "linear_model",
    model = "linear regression model"
  )
}


#' @rdname explain
#' @export
explain.glm <- function(
    object,
    client,
    context = NULL,
    audience = "novice",
    verbosity = "moderate",
    style = "markdown",
    language = NULL,
    ...
  ) {
  .family <- stats::family(object)$family
  .link <- stats::family(object)$link
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    style = style,
    language = language,
    name = "generalized_linear_model",
    model = paste(.family, "generalized linear model with", .link, "link")
  )
}


# Methods for package MASS -----------------------------------------------------

#' @rdname explain
#' @export
explain.polr <- function(
    object,
    client,
    context = NULL,
    audience = "novice",
    verbosity = "moderate",
    style = "markdown",
    language = NULL,
    ...
  ) {
  .method <- object$method
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    style = style,
    language = language,
    name = "proportional_odds_logistic_regression",
    model = paste("proportional odds", .method, "regression model")
  )
}


# Methods for package nlme -----------------------------------------------------

#' @rdname explain
#' @export
explain.lme <- function(
    object,
    client,
    context = NULL,
    audience = "novice",
    verbosity = "moderate",
    style = "markdown",
    language = NULL,
    ...
  ) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    style = style,
    language = language,
    name = "linear_mixed_model_nlme",
    model = "linear mixed-effects model"
  )
}


# Methods for package lme4 -----------------------------------------------------

#' @rdname explain
#' @export
explain.lmerMod <- function(
    object,
    client,
    context = NULL,
    audience = "novice",
    verbosity = "moderate",
    style = "markdown",
    language = NULL,
    ...
  ) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    style = style,
    language = language,
    name = "linear_mixed_model_lme4",
    model = "linear mixed-effects model"
  )
}


#' @rdname explain
#' @export
explain.glmerMod <- function(
    object,
    client,
    context = NULL,
    audience = "novice",
    verbosity = "moderate",
    style = "markdown",
    language = NULL,
    ...
  ) {
  .family <- stats::family(object)$family
  .link <- stats::family(object)$link
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    style = style,
    language = language,
    name = "generalized_linear_mixed_model",
    model = paste(.family, "generalized linear mixed-effects model with",
                  .link, "link")
  )
}


# Methods for package mgcv -----------------------------------------------------

#' @rdname explain
#' @export
explain.gam <- function(
    object,
    client,
    context = NULL,
    audience = "novice",
    verbosity = "moderate",
    style = "markdown",
    language = NULL,
    ...
  ) {
  .family <- stats::family(object)$family
  .link <- stats::family(object)$link
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    style = style,
    language = language,
    name = "generalized_additive_model",
    model = paste(.family, "generalized additive model with", .link, "link")
  )
}


# Methods for package survival--------------------------------------------------

#' @rdname explain
#' @export
explain.survreg <- function(
    object,
    client,
    context = NULL,
    audience = "novice",
    verbosity = "moderate",
    style = "markdown",
    language = NULL,
    ...
  ) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    style = style,
    language = language,
    name = "survival_regression",
    model = "parametric survival regression model"
  )
}


#' @rdname explain
#' @export
explain.coxph <- function(
    object,
    client,
    context = NULL,
    audience = "novice",
    verbosity = "moderate",
    style = "markdown",
    language = NULL,
    ...
  ) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    style = style,
    language = language,
    name = "cox_proportional_hazards",
    model = "Cox proportional hazards regression model"
  )
}


# Methods for package rpart ----------------------------------------------------

#' @rdname explain
#' @export
explain.rpart <- function(
    object,
    client,
    context = NULL,
    audience = "novice",
    verbosity = "moderate",
    style = "markdown",
    language = NULL,
    ...
  ) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    style = style,
    language = language,
    name = "recursive_partitioning_tree",
    model = "recursive partitioning tree model"
  )
}
