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
.get_system_prompt <- function(model_name) {
  file_name <- paste0("system_prompt_", model_name, ".md")
  file_path <- system.file("prompts", file_name, package = "statlingua")
  if (!nzchar(file_path)) {
    stop("System prompt for '", model_name, "' models not found.",
         call. = FALSE)
  }
  return(readChar(file_path, nchars = file.info(file_path)$size))
  # return(paste(readLines(filepath), collapse = "\n"))
}


#' @noRd
#' @keywords internal
.build_user_prompt <- function(model_type, model_summary, context = NULL) {
  # Could use `ellmer::interpolate()`, but doesn't seem necessary
  prompt <- paste0(
    "Explain the output from the following ",
    model_type,
    " model: \n\n",
    model_summary
  )
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
.explain_core <- function(object, client, context, model_name, model_type) {
  stopifnot(inherits(client, what = c("Chat", "R6")))
  sys_prompt <- .get_system_prompt(model_name)  # read system prompt
  model_summary <- summarize(object)  # create text summary of object
  usr_prompt <- .build_user_prompt(model_type,
                                   model_summary = model_summary,
                                   context = context)  # build user prompt
  # if (isTRUE(verbose)) {
  #   message("System prompt:\n\n", sys_prompt)
  #   message("Client input:\n\n", usr_prompt)
  # }
  # FIXME: Return "Chat" object so user can ask follow-up questions?
  chat$set_system_prompt(sys_prompt)
  chat$chat(usr_prompt)
}


