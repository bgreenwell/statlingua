#' Print LLM explanation
#'
#' Print a formatted version of an LLMs explanation using [cat()].
#'
#' @param x A [statlingo_explanation][explain] object.
#'
#' @param ... Additional optional arguments to be passed to [print.default()].
#'
#' @returns Invisibly returns the printed [statlingo_explanation][explain]
#' object.
#'
#' @export
print.statlingo_explanation <- function(x, ...) {
  cat(x$text, "\n")  # or just cat(x$text) if newlines are already in text
  invisible(x)
}
