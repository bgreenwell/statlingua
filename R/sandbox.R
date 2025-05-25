#' Explain differences between two statistical models
#'
#' @param object An initial statistical object.
#' @param object2 A second statistical object to compare against the first.
#' @param client A \code{\link[ellmer:Chat]{Chat}} object.
#' @param context Optional character string providing additional context.
#' @param concatenate Logical indicating whether to return an unformatted
#'   character string (\code{FALSE}) or to concatenate the results (\code{TRUE}).
#' @param ... Additional arguments.
#' @export
compare <- function(object, object2, client, context = NULL, concatenate = FALSE, ...) {
  UseMethod("compare")
}

#' @rdname compare
#' @export
compare.default <- function(object, object2, client, context = NULL, concatenate = FALSE, ...) {
  stopifnot(inherits(client, what = c("Chat", "R6")))
  sys_prompt <- .get_system_prompt("compare") # New system prompt

  output1 <- summarize(object)
  output2 <- summarize(object2)

  model_name1 <- class(object)[1] # Or a more descriptive name
  model_name2 <- class(object2)[1]

  usr_prompt <- paste0(
    "Please compare and contrast the following two statistical model outputs.\n\n",
    "## Model 1 (", model_name1, "):\n", output1, "\n\n",
    "## Model 2 (", model_name2, "):\n", output2, "\n\n",
    "Focus on key differences in coefficients (if applicable), model fit statistics (e.g., AIC, BIC, R-squared), ",
    "and overall model significance. Discuss potential reasons for preferring one model over the other, ",
    "especially in light of the provided context (if any)."
  )

  if (!is.null(context) && nzchar(context)) {
    usr_prompt <- paste0(
      usr_prompt,
      "\n\n## Additional context to consider for this comparison:\n\n",
      context
    )
  }

  client$set_system_prompt(sys_prompt)
  ex <- client$chat(usr_prompt)

  if (isTRUE(concatenate)) {
    cat(ex)
    return(invisible(ex))
  } else {
    return(ex)
  }
}

# Need to create inst/prompts/system_prompt_comparison.md
# This prompt would guide the LLM on how to structure the comparison,
# what metrics to focus on (e.g., AIC, BIC, likelihood ratio tests if applicable),
# and how to discuss model preference.


#' Suggest appropriate statistical models based on data and research question
#' @export
suggest <- function(data, response, predictors, client, context, concatenate = TRUE, ...) {
  # Basic data summary
  if (!response %in% names(data)) stop("Outcome variable not in data.")
  outcome_type <- class(data[[response]])
  num_obs <- nrow(data)
  num_preds <- length(predictors)

  data_summary <- paste0(
    "Data summary for model suggestion:\n",
    "- Outcome variable: '", response, "' (type: ", outcome_type, ")\n",
    "- Predictor variables: ", paste(predictors, collapse = ", "), "\n",
    "- Number of observations: ", num_obs, "\n",
    "- Number of predictors: ", num_preds
  )

  sys_prompt_suggest <- .get_system_prompt("suggest") # New prompt

  usr_prompt_suggest <- paste0(
    "I need help choosing a statistical model. Here is information about my data and research:\n\n",
    data_summary, "\n\n",
    "Research Question/Goal:\n", context, "\n\n",
    "Based on this, what statistical model(s) would be appropriate to consider? ",
    "Please explain your suggestions in simple terms, including why they might be suitable and any key assumptions."
  )

  client$set_system_prompt(sys_prompt_suggest)
  suggestion <- client$chat(usr_prompt_suggest)

  if (isTRUE(concatenate)) {
    cat(suggestion)
    return(invisible(suggestion))
  } else {
    return(suggestion)
  }
}
# Needs inst/prompts/system_prompt_model_suggestion.md
