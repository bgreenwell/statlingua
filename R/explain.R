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
#' @param level The confidence level used to interpret the output. Default is
#' 0.95.
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
#' # Poisson regression example from ?stats::glm
#' counts <- c(18,17,15,20,10,20,25,13,12)
#' outcome <- gl(3,1,9)
#' treatment <- gl(3,3)
#' data.frame(treatment, outcome, counts) # showing data
#' glm.D93 <- glm(counts ~ outcome + treatment, family = poisson())
#'
#' # Use Google Gemini to explain the output; requires an API key; see
#' # ?ellmer::chat_gemini for details
#' chat <- ellmer::chat_gemini()
#' explain(glm.D93, chat = chat, verbose = TRUE)
#' }
#'
#'
#' @export
explain <- function(object, chat, ...) {
  UseMethod("explain")
}


#' @rdname explain
#' @export
explain.glm <- function(object, chat, level = 0.95, context = NULL,
                        echo = NULL, verbose = FALSE, ...) {
  stopifnot(inherits(chat, what = c("Chat", "R6")))
  if (is.null(context)) {
    context <- "No additional information available.\n"
  }
  path <- system.file("prompts/system_prompt_glm.txt", package = "statlingua")
  system_prompt <- readChar(path, nchars = file.info(path)$size)
  system_prompt <- ellmer::interpolate(
    prompt = system_prompt,
    level = level,
    context = context
  )
  input <-
  "
  Please explain the output from the following {{family}} GLM with {{link}}
  link.

  ## Model summary
  {{model}}
  "
  fam <- stats::family(object)
  input <- ellmer::interpolate(
    input,
    family = fam$family,
    link = fam$link,
    model = capture_output(summary(object))
  )
  if (isTRUE(verbose)) {
    message("System prompt:\n\n", system_prompt)
    message("Chatbot input:\n\n", input)
  }
  chat$set_system_prompt(system_prompt)
  chat$chat(input, echo = echo)
}
