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
.read_prompt_part <- function(..., package = "statlingua") {
  # Construct path like "prompts/common/role_base.md"
  # The components passed in '...' are joined by file.path separator
  relative_path <- do.call(file.path, as.list(c("prompts", ...)))
  
  file_path <- system.file(relative_path, package = package) # No lib.loc needed usually
  
  if (nzchar(file_path) && file.exists(file_path)) {
    # Check if file is not empty before reading
    file_size <- file.info(file_path)$size
    if (file_size > 0) {
      return(readChar(file_path, nchars = file_size))
    } else {
      # warning(paste0("Prompt file is empty: ", relative_path)) # Optional warning
      return("") # Return empty string for empty file
    }
  } else {
    # warning(paste0("Prompt file not found: ", relative_path)) # Optional warning
    return("") # Return an empty string if file doesn't exist
  }
}

#' @noRd
#' @keywords internal
.assemble_system_prompt <- function(model_name, audience = "researcher", verbosity = "moderate", package = "statlingua") {
  # Default to "default" model if specific model instructions are not found
  model_instructions_path_test <- system.file(do.call(file.path, as.list(c("prompts", "models", model_name, "instructions.md"))), package = package)
  actual_model_name <- if (nzchar(model_instructions_path_test) && file.exists(model_instructions_path_test)) model_name else "default"

  role_base_text <- .read_prompt_part("common", "role_base.md", package = package)
  model_role_specific_text <- .read_prompt_part("models", actual_model_name, "role_specific.md", package = package)

  role_section <- paste0(
    "## Role

",
    trimws(role_base_text),
    if (nzchar(model_role_specific_text)) paste0("

", trimws(model_role_specific_text)) else ""
  )

  audience_text <- .read_prompt_part("audience", paste0(audience, ".md"), package = package)
  verbosity_text <- .read_prompt_part("verbosity", paste0(verbosity, ".md"), package = package)
  
  # Check if audience or verbosity files were empty/not found, and provide defaults if so.
  if (!nzchar(audience_text)) {
    warning(paste0("Audience file for '", audience, "' not found or empty. Using default content."))
    audience_text <- "Assume the user has a good understanding of statistical concepts." # Default or fallback
  }
  if (!nzchar(verbosity_text)) {
    warning(paste0("Verbosity file for '", verbosity, "' not found or empty. Using default content."))
    verbosity_text <- "Provide a moderate level of detail." # Default or fallback
  }

  audience_verbosity_section <- paste0(
    "## Intended Audience and Verbosity

",
    "### Target Audience: ", tools::toTitleCase(audience), "
", trimws(audience_text), "

",
    "### Level of Detail (Verbosity): ", tools::toTitleCase(verbosity), "
", trimws(verbosity_text)
  )

  response_format_text <- .read_prompt_part("common", "response_format.md", package = package)
  response_format_section <- paste0("## Response Format

", trimws(response_format_text))
  
  instructions_text <- .read_prompt_part("models", actual_model_name, "instructions.md", package = package)
  instructions_section <- paste0("## Instructions

", trimws(instructions_text))

  caution_text <- .read_prompt_part("common", "caution.md", package = package)
  caution_section <- paste0("## Caution

", trimws(caution_text))

  # Assemble the full prompt, ensuring sections are separated by two newlines
  # and sections with potentially missing content are handled.
  full_prompt <- paste(
    role_section,
    audience_verbosity_section,
    response_format_section,
    instructions_section,
    caution_section,
    sep = "


" # Use three newlines for better separation between major sections
  )
  
  return(trimws(full_prompt))
}

#' @noRd
#' @keywords internal
# .get_system_prompt <- function(name) {
#   file_name <- paste0("system_prompt_", name, ".md")
#   file_path <- system.file("prompts", file_name, package = "statlingua")
#   if (!nzchar(file_path)) {
#     stop("System prompt for '", name, "' models not found.",
#          call. = FALSE)
#   }
#   return(readChar(file_path, nchars = file.info(file_path)$size))
#   # return(paste(readLines(filepath), collapse = "\n"))
# }


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
#' system prompt (used as `model_name` for `.assemble_system_prompt`).
#'
#' @param model Character string specifying the type of model to be explained (used in user prompt).
#' @param audience Character string specifying the target audience for the explanation.
#' @param verbosity Character string specifying the desired level of detail.
.explain_core <- function(object, client, context, name, model, concatenate, audience = "researcher", verbosity = "moderate") {
  stopifnot(inherits(client, what = c("Chat", "R6")))
  # sys_prompt <- .get_system_prompt(name) # Old way
  sys_prompt <- .assemble_system_prompt(model_name = name, audience = audience, verbosity = verbosity)
  output <- summarize(object)  # create text summary of object
  usr_prompt <- .build_user_prompt(model, output = output, context = context)
  client$set_system_prompt(sys_prompt)
  ex <- client$chat(usr_prompt)
  if (isTRUE(concatenate)) {
    cat(ex)
    return(invisible(ex))
  } else {
    return(ex)
  }
}


