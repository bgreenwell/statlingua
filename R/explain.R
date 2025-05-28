#' Compare and Contrast Multiple Models
#'
#' @param ... Models to be compared, must be of class 'lm'.
#' @param verbose Logical indicating if detailed output should be shown (default TRUE).
#' @return A character string of the comparison if verbose is FALSE, otherwise prints summary.
#' @examples
#' # Example usage:
#' # llm_compare(model1, model2, verbose = TRUE)
#' @importFrom ellmer compare_summaries
#' @export
llm_compare <- function(..., verbose = TRUE) {
  models <- list(...)

  # Ensure at least two models
  if (length(models) < 2) {
    stop("At least two models need to be compared.")
  }
  
  # Ensure models are not NULL
  null_models <- sapply(models, is.null)
  if (any(null_models)) {
    stop(paste("Models at index", paste(which(null_models), collapse = ", "), "are NULL."))
  }
  
  # Check if models are supported
  unsupported_models <- !sapply(models, function(model) inherits(model, "lm"))
  if (any(unsupported_models)) {
    stop(paste("Model type not supported at index", paste(which(unsupported_models), collapse = ", "),
               ". Only 'lm' models are allowed."))
  }

  # Attempt comparison
  comparison_result <- tryCatch({
    model_summaries <- vapply(models, function(model) {
      summary_text <- capture.output(summary(model))
      paste(summary_text, collapse = "\n")
    }, character(1))
    
    # Check 'compare_summaries' function availability
    if (!isTRUE(requireNamespace("ellmer", quietly = TRUE)) || 
        !exists("compare_summaries", where = asNamespace("ellmer"), inherits = FALSE)) {
      stop("Ensure the 'ellmer' package and 'compare_summaries' function are available.")
    }

    ellmer::compare_summaries(model_summaries)
    
  }, error = function(e) {
    message <- paste("An error occurred during model comparison:", e$message)
    warning(message)
    if (verbose) {
      return(message)
    } else {
      return("A comparison error occurred.")
    }
  })

  if (verbose) {
    cat("Model Comparison:\n")
    print(comparison_result)
    invisible(NULL)
  } else {
    return(comparison_result)
  }
}