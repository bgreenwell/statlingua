#' @noRd
#' @keywords internal
.capture_output <- function(..., collapse = "\n", trim = FALSE) {
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
.read_prompt <- function(...) {
  # Construct path like "prompts/common/role_base.md"; the components passed
  # in '...' are joined by file.path separator.
  relative_path <- do.call(file.path, as.list(c("prompts", ...)))
  file_path <- system.file(relative_path, package = "statlingua")
  if (nzchar(file_path) && file.exists(file_path)) {
    # Check if file is not empty before reading
    file_size <- file.info(file_path)$size
    if (file_size > 0) {
      return(readChar(file_path, nchars = file_size))
    } else {
      warning(paste0("Prompt file is empty: ", relative_path))
      return("") # Return empty string for empty file
    }
  } else {
    warning(paste0("Prompt file not found: ", relative_path))
    return("") # Return an empty string if file doesn't exist
  }
}

#' @noRd
#' @keywords internal
.assemble_sys_prompt <- function(model_name, audience, verbosity) {

  # Default to "default" model if specific model instructions are not found
  args <- as.list(c("prompts", "models", model_name, "instructions.md"))
  file_path <-
    system.file(do.call(file.path, args = args), package = "statlingua")
  model_name <- if (nzchar(file_path) && file.exists(file_path)) {
    model_name
  } else "default"

  # Construct role section for system prompt
  role_base_text <- .read_prompt("common", "role_base.md")
  model_role_specific_text <-
    .read_prompt("models", model_name, "role_specific.md")
  role_section <- paste0(
    "## Role\n\n",
    trimws(role_base_text),
    if (nzchar(model_role_specific_text)) {
      paste0("\n\n", trimws(model_role_specific_text))
    } else ""
  )

  audience_text <- .read_prompt("audience", paste0(audience, ".md"))
  verbosity_text <- .read_prompt("verbosity", paste0(verbosity, ".md"))

  # Check if audience or verbosity files were empty/not found, and provide
  # defaults if so.
  if (!nzchar(audience_text)) {
    warning("Audience file for '", audience, "' not found or empty. ",
            "Using default content.")
    audience_text <- paste("Assume the user has a good understanding",
                           "of statistical concepts.")  # default/fallback
  }
  if (!nzchar(verbosity_text)) {
    warning("Verbosity file for '", verbosity, "' not found or empty. ",
            "Using default content.")
    verbosity_text <- "Provide a moderate level of detail."  # default/fallback
  }

  audience_verbosity_section <- paste0(
    "## Intended Audience and Verbosity\n\n",
    "### Target Audience: ", tools::toTitleCase(audience), "\n",
    trimws(audience_text), "\n\n",
    "### Level of Detail (Verbosity): ", tools::toTitleCase(verbosity), "\n",
    trimws(verbosity_text)
  )

  response_format_text <- .read_prompt("common", "response_format.md")
  response_format_section <- paste0("## Response Format\n\n",
                                    trimws(response_format_text))

  instructions_text <- .read_prompt("models", model_name,
                                         "instructions.md")
  instructions_section <- paste0("## Instructions\n\n",
                                 trimws(instructions_text))

  caution_text <- .read_prompt("common", "caution.md")
  caution_section <- paste0("## Caution\n\n", trimws(caution_text))

  # Assemble the full prompt, ensuring sections are separated by two newlines
  # and sections with potentially missing content are handled.
  full_prompt <- paste(
    role_section,
    audience_verbosity_section,
    response_format_section,
    instructions_section,
    caution_section,
    sep = "\n\n\n"  # use three newlines for better separation between major sections
  )

  return(trimws(full_prompt))
}

#' @noRd
#' @keywords internal
.build_usr_prompt <- function(model, output, context = NULL) {
  prompt <- paste0("Explain the following ", model, " output:\n", output)
  if (!is.null(context) && nzchar(context)) {
    prompt <- paste0(
      prompt, "\n\n",
      "## Additional context to consider\n\n",
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
#' system prompt (used as `model_name` for `.assemble_sys_prompt`).
#'
#' @param model Character string specifying the type of model to be explained (used in user prompt).
#' @param audience Character string specifying the target audience for the explanation.
#' @param verbosity Character string specifying the desired level of detail.
.explain_core <- function(object, client, context, name, model, concatenate,
                          audience = "researcher", verbosity = "moderate") {
  stopifnot(inherits(client, what = c("Chat", "R6")))
  sys_prompt <- .assemble_sys_prompt(name, audience = audience, verbosity = verbosity)
  output <- summarize(object)  # create text summary of object
  usr_prompt <- .build_usr_prompt(model, output = output, context = context)
  client$set_system_prompt(sys_prompt)
  ex <- client$chat(usr_prompt)
  output <- structure(
    list(
      text = ex,
      # Potentially add other metadata here if useful later
      model_type = name, # 'name' argument from .explain_core
      audience = audience,
      verbosity = verbosity
    ),
    class = c("statlingua_explanation", "character")
  )
  return(output)
}
