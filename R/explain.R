# R/explain.R

# Load necessary libraries
library(ellmer)

#' Compare and Contrast Models Using LLMs
#'
#' This function compares and contrasts the outputs of two or more statistical models
#' using a specified LLM from the ellmer package.
#'
#' @param ... Models to compare. Accepts any number of compatible statistical model objects.
#' @param model_names A character vector of model names. If not provided, default names will be generated.
#' @param llm_type A character string specifying the type of LLM to use from the ellmer package. Expected values are "default_llm", "advanced_llm", etc.
#' @return A list containing the comparison results from the LLM.
#' @examples
#' model1 <- lm(mpg ~ wt + cyl, data = mtcars)
#' model2 <- lm(mpg ~ hp + qsec, data = mtcars)
#' llm_compare(model1, model2, model_names = c("Model 1", "Model 2"))
#' llm_compare(model1, llm_type = "advanced_llm")
#' @export
llm_compare <- function(..., model_names = NULL, llm_type = "default_llm") {
  # Collect models into a list
  model_list <- list(...)
  
  # Check if models are provided
  stopifnot(length(model_list) > 0)
  
  # Validate model types
  validate_models(model_list)
  
  # Generate default model names if not provided
  if (is.null(model_names)) {
    model_names <- paste("Model", seq_along(model_list))
  }
  
  # Ensure model_names and models lengths match
  if (length(model_names) != length(model_list)) {
    stop("The number of model names must match the number of models. Please ensure they match.")
  }
  
  # Extract summaries or relevant information for each model
  model_summaries <- extract_model_summaries(model_list)
  
  # Perform comparison using the specified LLM
  comparison_results <- tryCatch({
    ellmer::compare_models(
      summaries = model_summaries,
      model_names = model_names,
      llm_type = llm_type
    )
  }, error = function(e) {
    stop("Model comparison failed: ", e$message)
  })
  
  return(comparison_results)
}

# Validate models' types
validate_models <- function(models) {
  invalid_models <- sapply(models, function(model) !inherits(model, "lm"))
  if (any(invalid_models)) {
    invalid_indices <- which(invalid_models)
    stop(sprintf("Models at indices %s are not of type 'lm'. Please revise your input.", paste(invalid_indices, collapse = ", ")))
  }
}

# Extract summaries of models
extract_model_summaries <- function(models) {
  lapply(models, function(model) {
    tryCatch({
      summary(model)
    }, error = function(e) {
      stop("Failed to extract summary for a model: ", e$message)
    })
  })
}

# Ensure the ellmer package is imported
# In NAMESPACE: importFrom(ellmer, compare_models)