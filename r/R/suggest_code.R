#' Suggest next statistical coding steps
#'
#' Suggest code snippets to run next based on a model explanation.
#'
#' @param x A `statlingo_explanation` object (returned by [explain()]).
#' @param ... Additional arguments.
#'
#' @returns An object of class `statlingo_code_suggestions`.
#' @export
#' @examples
#' \dontrun{
#' fm <- lm(dist ~ speed, data = cars)
#' client <- ellmer::chat_google_gemini()
#' ex <- explain(fm, client = client)
#' suggest_code(ex)
#' }
suggest_code <- function(x, ...) {
  UseMethod("suggest_code")
}

#' @export
suggest_code.statlingo_explanation <- function(x, ...) {
  model_type <- x$model_type
  
  suggestions <- if (model_type == "linear_model") {
    c(
      "# 1. Plot Residuals vs Fitted (Linearity & Homoscedasticity)",
      "plot(model, which = 1)",
      "",
      "# 2. Plot Normal Q-Q (Normality of residuals)",
      "plot(model, which = 2)",
      "",
      "# 3. Test for Multicollinearity (requires package 'car')",
      "if (requireNamespace(\"car\", quietly = TRUE)) {",
      "  car::vif(model)",
      "} else {",
      "  message(\"Install package 'car' to run: car::vif(model)\")",
      "}",
      "",
      "# 4. Test for Autocorrelation (requires package 'car')",
      "if (requireNamespace(\"car\", quietly = TRUE)) {",
      "  car::durbinWatsonTest(model)",
      "}",
      "",
      "# 5. Test for Heteroscedasticity (requires package 'lmtest')",
      "if (requireNamespace(\"lmtest\", quietly = TRUE)) {",
      "  lmtest::bptest(model)",
      "}"
    )
  } else if (model_type == "generalized_linear_model") {
    c(
      "# 1. Plot Residuals vs Fitted",
      "plot(model, which = 1)",
      "",
      "# 2. Check for Overdispersion (for Poisson/Binomial models)",
      "sum(residuals(model, type = \"pearson\")^2) / df.residual(model)",
      "",
      "# 3. Check deviance goodness-of-fit (pseudo R-squared)",
      "1 - (model$deviance / model$null.deviance)"
    )
  } else {
    c(
      "# Default diagnostic suggestions",
      "summary(model)",
      "plot(model)"
    )
  }
  
  res <- structure(
    list(
      suggestions = suggestions,
      model_type = model_type
    ),
    class = "statlingo_code_suggestions"
  )
  return(res)
}

#' @export
print.statlingo_code_suggestions <- function(x, ...) {
  cat("## Next Steps: Suggested Coding Diagnostics\n\n")
  cat(paste(x$suggestions, collapse = "\n"), "\n")
  invisible(x)
}
