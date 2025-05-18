#' Explain statistical output
#'
#' Use an LLM to explain the output from various statistical objects using
#' straightforward, understandable, and context-aware natural language
#' descriptions.
#'
#' @param object An appropriate statistical object. For example, `object` can be
#' the output from calling [t.test()][stats::t.test] or [glm()][stats::glm].
#'
#' @param chat A [Chat][ellmer::Chat] object (e.g., from calling
#' [chat_openai()][ellmer::chat_openai] or
#' [chat_gemini()][ellmer::chat_gemini)]).
#'
#' @param context Optional character string providing additional context, such
#' as background on the experiment and information about the data.
#'
#' @param echo Logical specifying whether to emit the response to stdout as it's
#' received. If `NULL` (the default), then the value of `echo` set when the
#' `chat` object was created will be used. See the `$chat()` method described in
#' [Chat][ellmer::Chat].
#'
#' @param verbose Logical indicating whether to print the system  prompt and
#' chatbot input, which can be useful for debugging. Default is `FALSE`.
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
#' # ?ellmer::chat_gemini for details
#' chat <- ellmer::chat_gemini()
#' explain(cars_lm, chat = chat, context = context)
#'
#' # Poisson regression example from ?stats::glm
#' counts <- c(18,17,15,20,10,20,25,13,12)
#' outcome <- gl(3,1,9)
#' treatment <- gl(3,3)
#' data.frame(treatment, outcome, counts) # showing data
#' D93_glm <- glm(counts ~ outcome + treatment, family = poisson())
#'
#' # Use Google Gemini to explain the output; requires an API key; see
#' # ?ellmer::chat_gemini for details
#' chat <- ellmer::chat_gemini()
#' explain(D93_glm, chat = chat, verbose = TRUE)
#' }
#'
#'
#' @export
explain <- function(object, chat, ...) {
  UseMethod("explain")
}


#' @rdname explain
#' @export
explain.htest <- function(object, chat, context = NULL, echo = NULL,
                          verbose = FALSE, ...) {
  stopifnot(inherits(chat, what = c("Chat", "R6")))
  if (is.null(context)) {
    context <- "No additional information available.\n"
  }
  path <- system.file("prompts/system_prompt_htest.md", package = "statlingua")
  sys_prompt <- readChar(path, nchars = file.info(path)$size)
  usr_prompt <-
  "
  Explain the output from the following {{method}}:

  {{object}}

  ## Additional context

  {{context}}
  "
  usr_prompt <- ellmer::interpolate(
    usr_prompt,
    method = object$method,
    object = capture_output(object),
    context = context
  )
  if (isTRUE(verbose)) {
    message("System prompt:\n\n", sys_prompt)
    message("Chatbot input:\n\n", usr_prompt)
  }
  chat$set_system_prompt(sys_prompt)
  chat$chat(usr_prompt, echo = echo)
}



#' @rdname explain
#' @export
explain.lm <- function(object, chat, context = NULL, echo = NULL,
                       verbose = FALSE, ...) {
  stopifnot(inherits(chat, what = c("Chat", "R6")))
  if (is.null(context)) {
    context <- "No additional information available.\n"
  }
  path <- system.file("prompts/system_prompt_glm.md", package = "statlingua")
  sys_prompt <- readChar(path, nchars = file.info(path)$size)
  usr_prompt <-
    "
  Explain the output from the following linear regression model.

  ## Model summary

  {{model}}

  ## Additional context

  {{context}}
  "
  usr_prompt <- ellmer::interpolate(
    usr_prompt,
    model = capture_output(summary(object)),
    context = context
  )
  if (isTRUE(verbose)) {
    message("System prompt:\n\n", sys_prompt)
    message("Chatbot input:\n\n", usr_prompt)
  }
  chat$set_system_prompt(sys_prompt)
  chat$chat(usr_prompt, echo = echo)
}


#' @rdname explain
#' @export
explain.glm <- function(object, chat, context = NULL, echo = NULL,
                        verbose = FALSE, ...) {
  stopifnot(inherits(chat, what = c("Chat", "R6")))
  if (is.null(context)) {
    context <- "No additional information available.\n"
  }
  path <- system.file("prompts/system_prompt_glm.md", package = "statlingua")
  sys_prompt <- readChar(path, nchars = file.info(path)$size)
  usr_prompt <-
  "
  Explain the output from the following {{family}} generalized linear model with
  a {{link}} link function.

  ## Model summary

  {{model}}

  ## Additional context

  {{context}}
  "
  fam <- stats::family(object)
  usr_prompt <- ellmer::interpolate(
    usr_prompt,
    family = fam$family,
    link = fam$link,
    model = capture_output(summary(object)),
    context = context
  )
  if (isTRUE(verbose)) {
    message("System prompt:\n\n", sys_prompt)
    message("Chatbot input:\n\n", usr_prompt)
  }
  chat$set_system_prompt(sys_prompt)
  chat$chat(usr_prompt, echo = echo)
}


#' @rdname explain
#' @export
explain.polr <- function(object, chat, context = NULL, echo = NULL,
                        verbose = FALSE, ...) {
  stopifnot(inherits(chat, what = c("Chat", "R6")))
  if (is.null(context)) {
    context <- "No additional information available.\n"
  }
  path <- system.file("prompts/system_prompt_polr.md", package = "statlingua")
  sys_prompt <- readChar(path, nchars = file.info(path)$size)
  usr_prompt <-
    "
  Explain the output from the following proportional odds {{method}} regression
  model.

  ## Model summary

  {{model}}

  ## Additional context

  {{context}}
  "
  usr_prompt <- ellmer::interpolate(
    usr_prompt,
    method = object$method,
    model = capture_output(summary(object)),
    context = context
  )
  if (isTRUE(verbose)) {
    message("System prompt:\n\n", sys_prompt)
    message("Chatbot input:\n\n", usr_prompt)
  }
  chat$set_system_prompt(sys_prompt)
  chat$chat(usr_prompt, echo = echo)
}


#' @rdname explain
#' @export
explain.lme <- function(object, chat, context = NULL, echo = NULL,
                        verbose = FALSE, ...) {
  stopifnot(inherits(chat, what = c("Chat", "R6")))
  if (is.null(context)) {
    context <- "No additional information available.\n"
  }
  # Potentially more specific/robust way to get family and link if applicable
  # For lme, family is typically gaussian
  model_family <- "Gaussian (assumed for lme)"
  model_link <- "identity (assumed for lme)"

  # Calling `summary.lme()` can be quite verbose, so let's break it up manually
  # into different components:
  #
  # * Fixed effects - summary(object)$tTable
  # * Random effects - summary(object)$coef$random
  # * Variance components - summary(object)$modelStruct$reStruct
  # * Correlation structure (if any) - summary(object)$modelStruct$corStruct
  model_summary <- capture_output(summary(object))
  fixed_effects <- capture_output(stats::anova(object, type = "marginal"))
  # fixed_effects <- capture_output(summary(object)$tTable)
  random_effects_summary <- capture_output(nlme::VarCorr(object))

  # Read system prompt
  path <- system.file("prompts/system_prompt_lme.md", package = "statlingua")
  if (!file.exists(path)) {
    stop("System prompt file not found: system_prompt_lme.md")
  }
  sys_prompt <- readChar(path, nchars = file.info(path)$size)

  # Construct user prompt
  usr_prompt <-
  "
  Explain the output from the following Linear Mixed-Effects Model (from nlme package).

  ## Model Family and Link Function
  Family: {{family}}
  Link: {{link}}

  ## Model Summary
  {{model_summary}}


  ## Fixed Effects (Type III ANOVA or equivalent if summary doesn't provide p-values directly)
  {{fixed_effects}}


  ## Random Effects (Variance Components)
  {{random_effects_summary}}


  ## Additional context
  {{context}}
  "
  usr_prompt <- ellmer::interpolate(
    usr_prompt,
    family = model_family,
    link = model_link,
    model_summary = model_summary,
    fixed_effects = fixed_effects,
    random_effects_summary = random_effects_summary,
    context = context
  )

  if (isTRUE(verbose)) {
    message("System prompt:\n\n", sys_prompt)
    message("Chatbot input:\n\n", usr_prompt)
  }
  chat$set_system_prompt(sys_prompt)
  chat$chat(usr_prompt, echo = echo)
}


#' @rdname explain
#' @export
explain.lmerMod <- function(object, chat, context = NULL, echo = NULL,
                            verbose = FALSE, ...) {
  stopifnot(inherits(chat, what = c("Chat", "R6")))
  if (is.null(context)) {
    context <- "No additional information available.\n"
  }

  # FIXME: lme4 typically assumes Gaussian family for lmerMod, but make this
  # more robust
  model_family <- "Gaussian"
  model_link <- "identity"

  model_summary <- capture_output(summary(object))
  fixed_effects <- capture_output(print(stats::coef(summary(object))))
  random_effects_summary <- capture_output(print(lme4::VarCorr(object)))
  # ANOVA for fixed effects (using lmerTest if available for p-values)
  anova_summary <- if (requireNamespace("lmerTest", quietly = TRUE)) {
    capture_output(print(stats::anova(object)))
  } else {
    paste(
      "ANOVA p-values for fixed effects require them'lmerTest' package.",
      "Consider installing and loading it for more detailed output on fixed",
      "effects significance."
    )
  }

  # Read system prompt
  path <- system.file("prompts/system_prompt_lmerMod.md", package = "statlingua")
  if (!file.exists(path)) {
    stop("System prompt file not found: system_prompt_lmerMod.md")
  }
  sys_prompt <- readChar(path, nchars = file.info(path)$size)

  # Construct user prompt
  usr_prompt <-
  "
  Explain the output from the following Linear Mixed-Effects Model (from lme4 package).

  ## Model Family and Link Function
  Family: {{family}}
  Link: {{link}}

  ## Model Summary
  {{model_summary}}


  ## Fixed Effects Coefficients
  {{fixed_effects}}


  ## ANOVA for Fixed Effects (Type III with Satterthwaite's method if lmerTest is used)
  {{anova_summary}}


  ## Random Effects (Variance Components)
  {{random_effects_summary}}


  ## Additional context
  {{context}}
  "
  usr_prompt <- ellmer::interpolate(
    usr_prompt,
    family = model_family,
    link = model_link,
    model_summary = model_summary,
    fixed_effects = fixed_effects,
    anova_summary = anova_summary,
    random_effects_summary = random_effects_summary,
    context = context
  )

  if (isTRUE(verbose)) {
    message("System prompt:\n\n", sys_prompt)
    message("Chatbot input:\n\n", usr_prompt)
  }
  chat$set_system_prompt(sys_prompt)
  chat$chat(usr_prompt, echo = echo)
}


#' @rdname explain
#' @export
explain.glmerMod <- function(object, chat, context = NULL, echo = NULL,
                             verbose = FALSE, ...) {
  stopifnot(inherits(chat, what = c("Chat", "R6")))
  if (is.null(context)) {
    context <- "No additional information available.\n"
  }

  model_family_info <- summary(object)$family
  model_link_info <- summary(object)$link

  model_summary <- capture_output(summary(object))
  fixed_effects <- capture_output(print(stats::coef(summary(object))))
  random_effects_summary <- capture_output(print(lme4::VarCorr(object)))
  # ANOVA for fixed effects (using lmerTest or car package for Type II/III tests)
  # Note: anova() for glmerMod objects is more complex than for lmerMod.
  # Likelihood Ratio Tests are common, or Wald tests from car::Anova.
  # For simplicity, we might just point to the fixed effects table for p-values.
  anova_summary <- if (requireNamespace("car", quietly = TRUE)) {
    # Using tryCatch in case of convergence issues or model complexity for car::Anova
    tryCatch({
      capture_output(car::Anova(object, type = "III")) # Or type = "II"
    }, error = function(e) {
      paste(
        "Could not compute ANOVA table for fixed effects (possibly due to",
        "model complexity or issues). Refer to fixed effects coefficients for",
        "Wald tests."
      )
    })
  } else {
    paste(
      "ANOVA table for fixed effects (e.g., Type II or III tests) often",
      "requires the 'car' package. Consider installing and loading it. Wald",
      "z-tests for individual coefficients are available in the fixed effects",
      "summary."
    )
  }

  # Read system prompt
  path <- system.file("prompts/system_prompt_glmerMod.md", package = "statlingua")
  if (!file.exists(path)) {
    stop("System prompt file not found: system_prompt_glmerMod.md")
  }
  sys_prompt <- readChar(path, nchars = file.info(path)$size)

  # Construct user prompt
  usr_prompt <-
  "
  Explain the output from the following Generalized Linear Mixed-Effects Model
  (from lme4 package).

  ## Model Family and Link Function
  Family: {{family}}
  Link: {{link}}

  ## Model Summary
  {{model_summary}}


  ## Fixed Effects Coefficients (Wald z-tests)
  {{fixed_effects}}


  ## ANOVA for Fixed Effects (e.g., Type III Wald chi-square tests if 'car' package is used)
  {{anova_summary}}


  ## Random Effects (Variance Components)
  {{random_effects_summary}}


  ## Additional context
  {{context}}
  "
  usr_prompt <- ellmer::interpolate(
    usr_prompt,
    family = model_family_info,
    link = model_link_info,
    model_summary = model_summary,
    fixed_effects = fixed_effects,
    anova_summary = anova_summary,
    random_effects_summary = random_effects_summary,
    context = context
  )

  if (isTRUE(verbose)) {
    message("System prompt:\n\n", sys_prompt)
    message("Chatbot input:\n\n", usr_prompt)
  }
  chat$set_system_prompt(sys_prompt)
  chat$chat(usr_prompt, echo = echo)
}


#' @rdname explain
#' @export
explain.gam <- function(object, chat, context = NULL, echo = NULL,
                        verbose = FALSE, ...) {
  stopifnot(inherits(chat, what = c("Chat", "R6")))
  if (is.null(context)) {
    context <- "No additional information available.\n"
  }

  model_family_info <- summary(object)$family$family
  model_link_info <- summary(object)$family$link

  # Full summary can be very long, especially with many smooth terms
  model_summary_output <- capture_output(summary(object))
  parametric_coef_summary <- capture_output(summary(object)$p.table)
  smooth_terms_summary <- capture_output(summary(object)$s.table)

  path <- system.file("prompts/system_prompt_gam.md", package = "statlingua")
  if (!file.exists(path)) {
    stop("System prompt file not found: system_prompt_gam.md")
  }
  sys_prompt <- readChar(path, nchars = file.info(path)$size)

  usr_prompt <-
  "
  Explain the output from the following Generalized Additive Model (GAM) from
  the mgcv package.

  ## Model Family and Link Function
  Family: {{family}}
  Link: {{link}}

  ## Full Model Summary (selected parts may follow)
  {{model_summary_output}}


  ## Parametric Coefficients (if any)
  {{parametric_coef_summary}}


  ## Approximate Significance of Smooth Terms
  {{smooth_terms_summary}}


  ## Additional context
  {{context}}
  "
  usr_prompt <- ellmer::interpolate(
    usr_prompt,
    family = model_family_info,
    link = model_link_info,
    model_summary_output = model_summary_output,
    parametric_coef_summary = parametric_coef_summary,
    smooth_terms_summary = smooth_terms_summary,
    context = context
  )

  if (isTRUE(verbose)) {
    message("System prompt:\n\n", sys_prompt)
    message("Chatbot input:\n\n", usr_prompt)
  }
  chat$set_system_prompt(sys_prompt)
  chat$chat(usr_prompt, echo = echo)
}


#' @rdname explain
#' @export
explain.survreg <- function(object, chat, context = NULL, echo = NULL,
                            verbose = FALSE, ...) {
  stopifnot(inherits(chat, what = c("Chat", "R6")))
  if (is.null(context)) {
    context <- "No additional information available.\n"
  }

  # Extract distribution
  # The dist is not directly in the summary object in a clean way, need from object itself
  model_distribution <- object$dist
  if (is.null(model_distribution)) { # Sometimes it might be in the call
    call_dist <- tryCatch(object$call$dist, error = function(e) NULL)
    if (!is.null(call_dist)) model_distribution <- as.character(call_dist)
    else model_distribution <- "unknown (check model call)"
  }

  model_summary_output <- capture_output(summary(object))
  # Coefficients are in summary(object)$table
  # Log-likelihood is summary(object)$loglik

  # Construct system prompt
  path <- system.file("prompts/system_prompt_survreg.md", package = "statlingua")
  if (!file.exists(path)) {
    stop("System prompt file not found: system_prompt_survreg.md")
  }
  sys_prompt <- readChar(path, nchars = file.info(path)$size)

  # Construct user prompt
  usr_prompt <-
  "
  Explain the output from the following Parametric Survival Model
  (from survival package, using survreg).

  ## Assumed Survival Time Distribution
  Distribution: {{model_distribution}}

  ## Model Summary
  {{model_summary_output}}


  ## Additional context
  {{context}}
  "
  usr_prompt <- ellmer::interpolate(
    usr_prompt,
    model_distribution = model_distribution,
    model_summary_output = model_summary_output,
    context = context
  )

  if (isTRUE(verbose)) {
    message("System prompt:\n\n", sys_prompt)
    message("Chatbot input:\n\n", usr_prompt)
  }
  chat$set_system_prompt(sys_prompt)
  chat$chat(usr_prompt, echo = echo)
}
