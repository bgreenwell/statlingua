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
#' as background on the experiment and information about the data.
#'
#' @param ... Additional optional arguments. (Currently ignored.)
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
#' # ?ellmer::client_gemini for details
#' client <- ellmer::client_gemini(echo = "none")
#' explain(cars_lm, client = client, context = context)
#'
#' # Poisson regression example from ?stats::glm
#' counts <- c(18,17,15,20,10,20,25,13,12)
#' outcome <- gl(3,1,9)
#' treatment <- gl(3,3)
#' data.frame(treatment, outcome, counts) # showing data
#' D93_glm <- glm(counts ~ outcome + treatment, family = poisson())
#'
#' # Use Google Gemini to explain the output; requires an API key; see
#' # ?ellmer::client_gemini for details
#' client <- ellmer::client_gemini()
#' explain(D93_glm, client = client, verbose = TRUE)
#' }
#'
#'
#' @export
explain <- function(object, client, ...) {
  UseMethod("explain")
}


# Methods for package stats ----------------------------------------------------

#' @rdname explain
#' @export
explain.htest <- function(object, client, context = NULL, ...) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    model_name = "htest",
    model_type = object$method
  )
}


#' @rdname explain
#' @export
explain.lm <- function(object, client, context = NULL, ...) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    model_name = "lm",
    model_type = "linear model"
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
    model_name = "glm",
    model_type = paste(.family, "generalized linear model with", .link, "link")
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
    model_name = "polr",
    model_type = paste("proportional odds", .method, "regression model")
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
    model_name = "lme",
    model_type = "linear mixed-effects model"
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
    model_name = "lmerMod",
    model_type = "linear mixed-effects model"
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
    model_name = "glmerMod",
    model_type = paste(.family, "generalized linear mixed-effects model with",
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
    model_name = "gam",
    model_type = paste(.family, "generalized additive model with", .link, "link")
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
    model_name = "survreg",
    model_type = "parametric survival regression model"
  )
}


#' @rdname explain
#' @export
explain.coxph <- function(object, client, context = NULL, ...) {
  .explain_core(
    object = object,
    client = client,
    context = context,
    model_name = "coxph",
    model_type = "Cox proportional hazards regression model"
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
    model_name = "rpart",
    model_type = "recursive partitioning tree model"
  )
}


#' # Methods for package forecast -------------------------------------------------
#'
#' #' @rdname explain
#' #' @export
#' explain.Arima <- function(object, client, context = NULL, echo = NULL,
#'                           verbose = FALSE, ...) {
#'   stopifnot(inherits(client, what = c("Chat", "R6")))
#'   if (!requireNamespace("forecast", quietly = TRUE)) {
#'     stop("Package 'forecast' needed for this function to work. ",
#'          "Please install it.", call. = FALSE)
#'   }
#'   if (is.null(context)) {
#'     context <- "No additional information available.\n"
#'   }
#'
#'   model_summary_output <- capture_output(summary(object))
#'
#'   # Robustly construct ARIMA order string
#'   arima_order_vector <- forecast::arimaorder(object)
#'
#'   base_order_string <- paste0("ARIMA(",
#'                               # Handle potential NA from arimaorder if object is weird
#'                               ifelse(is.na(arima_order_vector["p"]), "?", arima_order_vector["p"]), ",",
#'                               ifelse(is.na(arima_order_vector["d"]), "?", arima_order_vector["d"]), ",",
#'                               ifelse(is.na(arima_order_vector["q"]), "?", arima_order_vector["q"]), ")")
#'
#'   seasonal_string <- ""
#'   # Check if 'm' is present, not NA, and greater than 1 for seasonal components
#'   if (!is.null(arima_order_vector["m"]) &&
#'       !is.na(arima_order_vector["m"]) && arima_order_vector["m"] > 1) {
#'     seasonal_string <- paste0("(",
#'                               ifelse(is.na(arima_order_vector["P"]), "?", arima_order_vector["P"]), ",",
#'                               ifelse(is.na(arima_order_vector["D"]), "?", arima_order_vector["D"]), ",",
#'                               ifelse(is.na(arima_order_vector["Q"]), "?", arima_order_vector["Q"]), ")[",
#'                               arima_order_vector["m"], "]")
#'   }
#'
#'   arima_order_string_for_prompt <- paste0(base_order_string, seasonal_string)
#'
#'   # Read system prompt
#'   path <- system.file("prompts/system_prompt_Arima.md", package = "statlingua")
#'   if (!file.exists(path)) {
#'     stop("System prompt file not found: system_prompt_Arima.md")
#'   }
#'   sys_prompt <- readChar(path, nchars = file.info(path)$size)
#'
#'   # Construct user prompt
#'   usr_prompt <-
#'   "
#'   Explain the output from the following ARIMA Model (Arima object from forecast package).
#'
#'   ## Identified ARIMA Order
#'   Order: {{arima_order_string}}
#'   (The model summary below will provide details on coefficients, including any
#'   drift or intercept terms.)
#'
#'   ## Model Summary (Coefficients, Fit Statistics)
#'   {{model_summary_output}}
#'
#'   ## Additional context (e.g., nature of time series, forecasting goal)
#'   {{context}}
#'   "
#'   usr_prompt <- ellmer::interpolate(
#'     usr_prompt,
#'     arima_order_string = arima_order_string_for_prompt,
#'     model_summary_output = model_summary_output,
#'     context = context
#'   )
#'
#'   if (isTRUE(verbose)) {
#'     message("System prompt:\n\n", sys_prompt)
#'     message("Chatbot input:\n\n", usr_prompt)
#'   }
#'   client$set_system_prompt(sys_prompt)
#'   client$chat(usr_prompt, echo = echo)
#' }
