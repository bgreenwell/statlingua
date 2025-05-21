#' @noRd
#' @keywords internal
capture_output <- function(..., collapse = "\n", trim = FALSE) {
  # Taken from https://github.com/toscm/toscutil/tree/master
  x <- utils::capture.output(...)
  if (trim) {
    x <- sapply(x, trimws)
  }
  if (!(identical(collapse, FALSE))) {
    x <- paste(x, collapse = collapse)
  }
  return(x)
}


#' @noRd
#' @keywords internal
.get_system_prompt <- function(name) {
  file_name <- paste0("system_prompt_", name, ".md")
  file_path <- system.file("prompts", file_name, package = "statlingua")
  if (!nzchar(file_path)) {
    stop("System prompt for '", name, "' models not found.",
         call. = FALSE)
  }
  return(readChar(file_path, nchars = file.info(file_path)$size))
  # return(paste(readLines(filepath), collapse = "\n"))
}


#' @noRd
#' @keywords internal
.build_user_prompt <- function(model, output, context = NULL) {
  # Could use `ellmer::interpolate()`, but doesn't seem necessary
  prompt <- paste0("Explain the following ", model, " output:\n", output)
  if (!is.null(context) && nzchar(context)) {
    prompt <- paste0(
      prompt,
      "\n\n## Additional context to consider\n\n",
      context
    )
  }
  return(prompt)
}


#' @noRd
#' @keywords internal
#'
#' @param object An appropriate statistical object. For example, `object` can be
#' the output from calling [t.test()][stats::t.test] or [glm()][stats::glm].
#'
#' @param client A [Chat][ellmer::Chat] object (e.g., from calling
#' [chat_openai()][ellmer::chat_openai] or
#' [chat_google_gemini()][ellmer::chat_google_gemini)]).
#'
#' @param context Character string providing additional context, such as
#' background on the research question and information about the data.
#'
#' @param name Character string specifying the class name for reading in the
#' system prompt.
#'
#' @param model Character string specifying the type of model to be explained.
.explain_core <- function(object, client, context, name, model) {
  stopifnot(inherits(client, what = c("Chat", "R6")))
  sys_prompt <- .get_system_prompt(name)
  output <- summarize(object)  # create text summary of object
  usr_prompt <- .build_user_prompt(model, output = output, context = context)
  client$set_system_prompt(sys_prompt)
  # resp <- client$chat(usr_prompt)
  # if (isTRUE(return_client)) {
  #   list("client" = client, "response" = resp)
  # } else {
  #   resp
  # }
  client$chat(usr_prompt)
}


