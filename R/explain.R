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
#' @param ... Additional optional arguments. (Currently ignored.)
#'
#' @returns Either a character string providing the LLM explanation
#' (`return_client = FALSE`) or a list containing the LLM client and response
#' (`return_client = TRUE`).
#'
#' @examples
#' \dontrun{
#' # Polynomial regression
#' cars_lm <- lm(dist ~ poly(speed, degree = 2), data = cars)
#' context <- "
#' The data give the speed of cars (mph) and the distances taken to stop (ft).
#' Note that the data were recorded in the 1920s.
#' "
#' # Use Google Gemini to explain the output; requires an API key; see
#' # ?ellmer::chat_google_gemini for details
#' client <- ellmer::chat_google_gemini(echo = "none")
#' ex <- explain(cars_lm, client = client, context = context)
#'
#' # Poisson regression example from ?stats::glm
#' counts <- c(18,17,15,20,10,20,25,13,12)
#' outcome <- gl(3,1,9)
#' treatment <- gl(3,3)
#' data.frame(treatment, outcome, counts) # showing data
#' D93_glm <- glm(counts ~ outcome + treatment, family = poisson())
#'
#' # Use Google Gemini to explain the output; requires an API key; see
#' # ?ellmer::chat_google_gemini for details
#' client <- ellmer::chat_google_gemini()
#' explain(D93_glm, client = client)
#' }
#'
#'
#' @export
explain <- function(object, client, context = NULL, ...) {
  UseMethod("explain")
}


#' @rdname explain
#' @export
explain.default <- function(object, client, context = NULL, ...) {
  stopifnot(inherits(client, what = c("Chat", "R6")))
  sys_prompt <- .get_system_prompt("default")
  output <- capture_output(object)
  usr_prompt <- .build_user_prompt("R object", output = output,
                                   context = context)
  client$set_system_prompt(sys_prompt)
  client$chat(usr_prompt)
}


# Methods for package stats ----------------------------------------------------

#' @rdname explain
#' @export
explain.htest <- function(object, client, context = NULL, ...) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    name = "htest",
    model = object$method
  )
}


#' @rdname explain
#' @export
explain.lm <- function(object, client, context = NULL, ...) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    name = "lm",
    model = "linear regression model"
  )
}


#' @rdname explain
#' @export
explain.glm <- function(object, client, context = NULL, ...) {
  .family <- stats::family(object)$family
  .link <- stats::family(object)$link
  .explain_core(
    object = object,
    client = client,
    context = context,
    name = "glm",
    model = paste(.family, "generalized linear model with", .link, "link")
  )
}


# Methods for package MASS -----------------------------------------------------

#' @rdname explain
#' @export
explain.polr <- function(object, client, context = NULL, ...) {
  .method <- object$method
  .explain_core(
    object = object,
    client = client,
    context = context,
    name = "polr",
    model = paste("proportional odds", .method, "regression model")
  )
}


# Methods for package nlme -----------------------------------------------------

#' @rdname explain
#' @export
explain.lme <- function(object, client, context = NULL, ...) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    name = "lme",
    model = "linear mixed-effects model"
  )
}


# Methods for package lme4 -----------------------------------------------------

#' @rdname explain
#' @export
explain.lmerMod <- function(object, client, context = NULL, ...) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    name = "lmerMod",
    model = "linear mixed-effects model"
  )
}


#' @rdname explain
#' @export
explain.glmerMod <- function(object, client, context = NULL, ...) {
  .family <- stats::family(object)$family
  .link <- stats::family(object)$link
  .explain_core(
    object = object,
    client = client,
    context = context,
    name = "glmerMod",
    model = paste(.family, "generalized linear mixed-effects model with",
                       .link, "link")
  )
}


# Methods for package mgcv -----------------------------------------------------

#' @rdname explain
#' @export
explain.gam <- function(object, client, context = NULL, ...) {
  .family <- stats::family(object)$family
  .link <- stats::family(object)$link
  .explain_core(
    object = object,
    client = client,
    context = context,
    name = "gam",
    model = paste(.family, "generalized additive model with", .link, "link")
  )
}


# Methods for package survival--------------------------------------------------

#' @rdname explain
#' @export
explain.survreg <- function(object, client, context = NULL, ...) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    name = "survreg",
    model = "parametric survival regression model"
  )
}


#' @rdname explain
#' @export
explain.coxph <- function(object, client, context = NULL, ...) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    name = "coxph",
    model = "Cox proportional hazards regression model"
  )
}


# Methods for package rpart ----------------------------------------------------

#' @rdname explain
#' @export
explain.rpart <- function(object, client, context = NULL, ...) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    name = "rpart",
    model = "recursive partitioning tree model"
  )
}
