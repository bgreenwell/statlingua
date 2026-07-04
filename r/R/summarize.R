#' Summarize statistical output
#'
#' Generate text-based summaries of statistical output that can be embedded into
#' prompts for querying Large Language Models (LLMs). Intended primarily for
#' internal use.
#'
#' @param object An object for which a summary is desired (e.g., a
#' [glm][stats::glm] object).
#'
#' @param ... Additional optional arguments. (Currently ignored.)
#'
#' @returns A character string summarizing the statistical output.
#'
#' @seealso [summary()][base::summary].
#'
#' @examples
#' tt <- t.test(1:10, y = c(7:20))
#' summarize(tt)  # prints output as a character string
#' cat(summarize(tt))  # more useful for reading
#'
#' @export
summarize <- function(object, ...) {
  UseMethod("summarize")
}


#' @rdname summarize
#' @export
summarize.default <- function(object, ...) {
  .capture_output(object)
}


#' @rdname summarize
#' @export
summarize.htest <- function(object, ...) {
  .capture_output(object)
}


#' @rdname summarize
#' @export
summarize.lm <- function(object, ...) {
  .capture_output(summary(object))
}


#' @rdname summarize
#' @export
summarize.glm <- function(object, ...) {
  .capture_output(summary(object))
}


#' @rdname summarize
#' @export
summarize.polr <- function(object, ...) {
  .capture_output(summary(object))
}


#' @rdname summarize
#' @export
summarize.lme <- function(object, ...) {
  # FIXME: Manually break up output?
  .capture_output(summary(object))
}


#' @rdname summarize
#' @export
summarize.lmerMod <- function(object, ...) {
  # FIXME: Manually break up output?
  .capture_output(summary(object))
}


#' @rdname summarize
#' @export
summarize.glmerMod <- function(object, ...) {
  # FIXME: Manually break up output?
  .capture_output(summary(object))
}


#' @rdname summarize
#' @export
summarize.gam <- function(object, ...) {
  # .family <- family(object)$family
  # .link <- family(object)$link
  .summary <- summary(object)
  ptab <- .summary$p.table
  stab <- .summary$s.table
  paste0(
    # "## Model Family and Link Function\n",
    # "Family: ", .family, "\n",
    # "Link: ", .link, "\n\n",
    "## Full Model Summary (selected parts may follow)\n",
    .capture_output(summary(object)), "\n\n",
    "## Parametric Coefficients (if any)\n\n",
    .capture_output(ptab), "\n\n",
    "## Smooth Terms (if any)\n\n",
    .capture_output(stab), "\n\n"
  )
}


#' @rdname summarize
#' @export
summarize.survreg <- function(object, ...) {
  .dist <- object$dist
  if (is.null(.dist)) {  # sometimes it might be in the call
    call_dist <- tryCatch(object$call$dist, error = function(e) NULL)
    .dist <- if (!is.null(call_dist)) {
      as.character(call_dist)
    } else {
      "unknown (check model call)"
    }
  }
  paste0(
    "## Response Distribution\n\n",
    "Distribution: ", .dist, "\n\n",
    "## Model Summary\n",
    .capture_output(summary(object))
  )
}


#' @rdname summarize
#' @export
summarize.coxph <- function(object, ...) {
  # FIXME: Check for time-dependent covariates if possible (more advanced, but
  # good to note). For example, if `cox.zph()` was run, its output could be
  # summarized. For now, we'll stick to the basic summary.
  .capture_output(summary(object))
}


#' @rdname summarize
#' @export
summarize.rpart <- function(object, ...) {
  # Calling `summary.rpart()` prints the call, the table shown by `printcp()`,
  # the variable importance (summing to 100), and details for each node (the
  # details depending on the type of tree).
  .capture_output(summary(object))
}
