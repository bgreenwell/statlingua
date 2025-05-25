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
#' @param Verbosity Character string indicating the desired verbosity:
#' * `"moderate"` - Offers a balanced explanation (default).
#' * `"brief"` - Offers a high-level summary.
#' * `"detailed"` - Offers a comprehensive interpretation.
#'
#' @param concatenate Logical indicating whether to return an unformatted
#' character string (`FALSE`) or to concatenate the results into formatted
#' output (`TRUE`) using [cat()][base::cat]. Default is `FALSE`.
#'
#' @param ... Additional optional arguments. (Currently ignored.)
#'
#' @returns Either a character string providing the LLM explanation
#' (`concatenate = FALSE`) or nothing (i.e., invisible `NULL`).
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
#'
#' # Poisson regression example from ?stats::glm
#' counts <- c(18,17,15,20,10,20,25,13,12)
#' outcome <- gl(3,1,9)
#' treatment <- gl(3,3)
#' data.frame(treatment, outcome, counts) # showing data
#' fm2 <- glm(counts ~ outcome + treatment, family = poisson())
#'
#' # Use Google Gemini to explain the output; requires an API key; see
#' # ?ellmer::chat_google_gemini for details
#' client <- ellmer::chat_google_gemini()
#' explain(fm2, client = client, audience = "student", verbosity = "detailed")
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
    concatenate = FALSE,
    ...
  ) {
  audience <- match.arg(audience)
  verbosity <- match.arg(verbosity)
  UseMethod("explain")
}


#' @rdname explain
#' @export
explain.default <- function(
    object,
    client,
    context = NULL,
    audience = c("novice", "student", "researcher", "manager",
                 "domain_expert"),
    verbosity = c("moderate", "brief", "detailed"),
    concatenate = FALSE,
    ...
) {
  stopifnot(inherits(client, what = c("Chat", "R6")))
  sys_prompt <- .assemble_sys_prompt(model_name = "default",
                                     audience = audience, verbosity = verbosity)
  output <- .capture_output(object)
  usr_prompt <- .build_usr_prompt("R object", output = output,
                                   context = context)
  client$set_system_prompt(sys_prompt)
  ex <- client$chat(usr_prompt)
  if (isTRUE(concatenate)) {
    cat(ex)
    return(invisible(ex))
  } else {
    return(ex)
  }
}


# Methods for package stats ----------------------------------------------------

#' @rdname explain
#' @export
explain.htest <- function(
    object,
    client,
    context = NULL,
    audience = c("novice", "student", "researcher", "manager",
                 "domain_expert"),
    verbosity = c("moderate", "brief", "detailed"),
    concatenate = FALSE,
    ...
) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    name = "htest",
    model = object$method,
    concatenate = concatenate
  )
}


#' @rdname explain
#' @export
explain.lm <- function(
    object,
    client,
    context = NULL,
    audience = c("novice", "student", "researcher", "manager",
                 "domain_expert"),
    verbosity = c("moderate", "brief", "detailed"),
    concatenate = FALSE,
    ...
) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    name = "lm",
    model = "linear regression model",
    concatenate = concatenate
  )
}


#' @rdname explain
#' @export
explain.glm <- function(
    object,
    client,
    context = NULL,
    audience = c("novice", "student", "researcher", "manager",
                 "domain_expert"),
    verbosity = c("moderate", "brief", "detailed"),
    concatenate = FALSE,
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
    name = "glm",
    model = paste(.family, "generalized linear model with", .link, "link"),
    concatenate = concatenate
  )
}


# Methods for package MASS -----------------------------------------------------

#' @rdname explain
#' @export
explain.polr <- function(
    object,
    client,
    context = NULL,
    audience = c("novice", "student", "researcher", "manager",
                 "domain_expert"),
    verbosity = c("moderate", "brief", "detailed"),
    concatenate = FALSE,
    ...
) {
  .method <- object$method
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    name = "polr",
    model = paste("proportional odds", .method, "regression model"),
    concatenate = concatenate
  )
}


# Methods for package nlme -----------------------------------------------------

#' @rdname explain
#' @export
explain.lme <- function(
    object,
    client,
    context = NULL,
    audience = c("novice", "student", "researcher", "manager",
                 "domain_expert"),
    verbosity = c("moderate", "brief", "detailed"),
    concatenate = FALSE,
    ...
) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    name = "lme",
    model = "linear mixed-effects model",
    concatenate = concatenate
  )
}


# Methods for package lme4 -----------------------------------------------------

#' @rdname explain
#' @export
explain.lmerMod <- function(
    object,
    client,
    context = NULL,
    audience = c("novice", "student", "researcher", "manager",
                 "domain_expert"),
    verbosity = c("moderate", "brief", "detailed"),
    concatenate = FALSE,
    ...
) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    name = "lmerMod",
    model = "linear mixed-effects model",
    concatenate = concatenate
  )
}


#' @rdname explain
#' @export
explain.glmerMod <- function(
    object,
    client,
    context = NULL,
    audience = c("novice", "student", "researcher", "manager",
                 "domain_expert"),
    verbosity = c("moderate", "brief", "detailed"),
    concatenate = FALSE,
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
    name = "glmerMod",
    model = paste(.family, "generalized linear mixed-effects model with",
                       .link, "link"),
    concatenate = concatenate
  )
}


# Methods for package mgcv -----------------------------------------------------

#' @rdname explain
#' @export
explain.gam <- function(
    object,
    client,
    context = NULL,
    audience = c("novice", "student", "researcher", "manager",
                 "domain_expert"),
    verbosity = c("moderate", "brief", "detailed"),
    concatenate = FALSE,
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
    name = "gam",
    model = paste(.family, "generalized additive model with", .link, "link"),
    concatenate = concatenate
  )
}


# Methods for package survival--------------------------------------------------

#' @rdname explain
#' @export
explain.survreg <- function(
    object,
    client,
    context = NULL,
    audience = c("novice", "student", "researcher", "manager",
                 "domain_expert"),
    verbosity = c("moderate", "brief", "detailed"),
    concatenate = FALSE,
    ...
) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    name = "survreg",
    model = "parametric survival regression model",
    concatenate = concatenate
  )
}


#' @rdname explain
#' @export
explain.coxph <- function(
    object,
    client,
    context = NULL,
    audience = c("novice", "student", "researcher", "manager",
                 "domain_expert"),
    verbosity = c("moderate", "brief", "detailed"),
    concatenate = FALSE,
    ...
) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    name = "coxph",
    model = "Cox proportional hazards regression model",
    concatenate = concatenate
  )
}


# Methods for package rpart ----------------------------------------------------

#' @rdname explain
#' @export
explain.rpart <- function(
    object,
    client,
    context = NULL,
    audience = c("novice", "student", "researcher", "manager",
                 "domain_expert"),
    verbosity = c("moderate", "brief", "detailed"),
    concatenate = FALSE,
    ...
) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    audience = audience,
    verbosity = verbosity,
    name = "rpart",
    model = "recursive partitioning tree model",
    concatenate = concatenate
  )
}
