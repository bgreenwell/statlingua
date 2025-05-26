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
.assemble_sys_prompt <- function(model_name, audience, verbosity, style) {

  # Default to "default" model if specific model instructions are not found
  args <- as.list(c("prompts", "models", model_name, "instructions.md"))
  file_path <-  system.file(do.call(file.path, args = args),
                            package = "statlingua")
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

  # response_format_text <- .read_prompt("common", "response_format.md")
  # response_format_section <- paste0("## Response Format\n\n",
  #                                   trimws(response_format_text))

  # Dynamically load response format based on 'style'
  # This replaces the static loading of: .read_prompt("common", "response_format.md")
  response_format_text <- .read_prompt("style", paste0(style, ".md"))
  if (!nzchar(response_format_text)) {
    warning("Response format file for style '", style, "' not found or empty. ",
            "Using default Markdown format instructions if available, ",
            "or minimal formatting.")
    # Fallback to markdown if specific style file not found, or provide a very
    # basic default
    response_format_text <- .read_prompt("style", "markdown.md")
    if(!nzchar(response_format_text)) { # If markdown.md also fails
      response_format_text <- "Format your response clearly."  # absolute fallback
    }
  }
  response_format_section <- paste0("## Response Format Specification (Style: ",
                                    tools::toTitleCase(style), ")\n\n",
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

# In R/utils.R

#' Remove surrounding language fences from LLM output
#'
#' This function checks for and removes common Markdown-style language
#' fences (e.g., ```json ... ``` or ``` ... ```) that LLMs might add
#' around their output. It also trims leading/trailing whitespace from
#' the core content.
#'
#' @param text_string The raw text string from the LLM.
#' @return The text string with fences removed, or the original string
#'   if no fences were detected.
#' @noRd
#' @keywords internal
.remove_fences <- function(text_string) {
  if (is.null(text_string) || !nzchar(text_string)) {
    return(text_string)
  }

  # Regex to detect and capture content within fences:
  # - Starts with 3 or more backticks (```)
  # - Optionally followed by a language identifier (e.g., html, json, markdown, r, R, etc.)
  #   (non-capturing group for common identifiers, or any word characters)
  # - Optionally followed by whitespace and a newline
  # - Captures the content (non-greedy)
  # - Ends with an optional newline and the same number of backticks as opened with
  #   (though most common is just 3 backticks for closing)

  # More robust pattern to handle various language identifiers and optional newlines
  # This pattern specifically looks for ``` followed by an optional language specifier
  # and then the content, ending with ```.
  # It handles cases like:
  # ```json\n{...}\n```
  # ```html\n<p>...</p>\n```
  # ```\nSome text\n```
  # ```Some text```

  # Pattern 1: Matches fences with optional language identifiers (e.g., ```json, ```html)
  # It looks for balanced backticks if possible, but most LLMs just use ``` to close.
  # ^(?:`{3,})(?:[a-zA-Z0-9_-]+)?\s*\n?([\s\S]*?)\n?\s*```$
  # Let's simplify and make it robust for typical LLM fence outputs.
  # Most LLMs use ``` or ```language. They don't usually vary the number of backticks for closing.

  # Updated regex:
  # ^                 - start of the string
  # `{3,}            - three or more backticks
  # ([a-zA-Z0-9_-]*)? - optional language identifier (captured as group 1, but we discard)
  # \s*\n?            - optional whitespace and an optional newline
  # ([\s\S]*?)       - the actual content (captured as group 2, non-greedy)
  # \n?\s* - optional newline and optional whitespace before closing
  # `{3,}            - three or more backticks to close
  # $                 - end of the string

  # We'll try a multi-stage regex approach for robustness
  # Stage 1: Match ```language ... ```
  pattern_lang <- "^`{3,}([a-zA-Z0-9_-]+)?\\s*\\n?([\\s\\S]*?)\\n?\\s*`{3,}$"
  if (grepl(pattern_lang, text_string, perl = TRUE)) {
    # Extract the content (second captured group from the refined pattern)
    cleaned_string <- sub(pattern_lang, "\\2", text_string, perl = TRUE)
    return(trimws(cleaned_string))
  }

  # Stage 2: If no language identifier, match simple ``` ... ```
  # This is often what happens if the LLM is just denoting a block of text.
  pattern_simple <- "^`{3,}\\s*\\n?([\\s\\S]*?)\\n?\\s*`{3,}$"
  if (grepl(pattern_simple, text_string, perl = TRUE)) {
    cleaned_string <- sub(pattern_simple, "\\1", text_string, perl = TRUE)
    return(trimws(cleaned_string))
  }

  return(text_string) # Return original if no wrapping fences found
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
.explain_core <- function(object, client, context, name, model,
                          audience = "novice", verbosity = "moderate",
                          style = "markdown") {
  stopifnot(inherits(client, what = c("Chat", "R6")))
  sys_prompt <- .assemble_sys_prompt(name, audience = audience,
                                     verbosity = verbosity, style = style)
  output <- summarize(object)  # create text summary of object
  usr_prompt <- .build_usr_prompt(model, output = output, context = context)
  client$set_system_prompt(sys_prompt)
  ex <- client$chat(usr_prompt)
  ex <- .remove_fences(ex)
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
