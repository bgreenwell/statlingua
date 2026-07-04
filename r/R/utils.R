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
.read_prompt_file <- function(...) {
  # Construct path like "prompts/common/role_base.md"; the components passed
  # in '...' are joined by file.path separator.
  relative_path <- do.call(file.path, as.list(c("prompts", ...)))
  file_path <- system.file(relative_path, package = "statlingo")
  if (nzchar(file_path) && file.exists(file_path)) {
    file_size <- file.info(file_path)$size
    if (file_size > 0) {
      return(readChar(file_path, nchars = file_size))
    }
  }
  ""  # Empty string if the file doesn't exist or is empty
}

#' @noRd
#' @keywords internal
#'
#' Read and cache `inst/prompts/config.yaml`, which holds the short
#' audience/verbosity/style instruction strings shared by both the R and
#' Python packages. Cached in the package namespace since the file never
#' changes at runtime.
.prompt_config <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) {
      config_path <- system.file("prompts", "config.yaml",
                                  package = "statlingo")
      cache <<- yaml::read_yaml(config_path)
    }
    cache
  }
})

#' @noRd
#' @keywords internal
#'
#' Read engine-specific prompt notes for a model when available.
.read_engine_notes <- function(model_name, engine = "r") {
  engine_file_map <- list(
    r = c(
      linear_model = "r-lm",
      generalized_linear_model = "r-glm"
    )
  )

  engine_files <- engine_file_map[[engine]]
  if (is.null(engine_files)) {
    return("")
  }

  if (!(model_name %in% names(engine_files))) {
    return("")
  }

  engine_file <- unname(engine_files[[model_name]])
  if (is.null(engine_file) || !nzchar(engine_file)) {
    return("")
  }

  .read_prompt_file(
    "models", model_name, "engines", paste0(engine_file, ".md")
  )
}

#' @noRd
#' @keywords internal
#'
#' Assemble the full system prompt for a given model type, audience,
#' verbosity, and output style. Short instruction strings (audience,
#' verbosity, style) come from `inst/prompts/config.yaml`; longer,
#' model-specific instructions come from `inst/prompts/models/<name>/`.
#' The pieces are interpolated into `inst/prompts/system_prompt_template.md`
#' via [ellmer::interpolate_package()].
.assemble_sys_prompt <- function(model_name, audience, verbosity, style) {
  # Fall back to the "default" model instructions if this model has none
  has_model_instructions <- nzchar(system.file(
    "prompts", "models", model_name, "instructions.md",
    package = "statlingo"
  ))
  if (!has_model_instructions) {
    model_name <- "default"
  }

  config <- .prompt_config()

  role_instruction <- trimws(paste(
    trimws(.read_prompt_file("common", "role_base.md")),
    trimws(.read_prompt_file("models", model_name, "role_specific.md")),
    sep = "\n\n"
  ))

  model_instructions <-
    trimws(.read_prompt_file("models", model_name, "instructions.md"))
  engine_notes <- trimws(.read_engine_notes(model_name, engine = "r"))
  engine_section <- if (nzchar(engine_notes)) {
    paste0("## Output Format Notes\n\n", engine_notes, "\n")
  } else {
    ""
  }

  ellmer::interpolate_package(
    package = "statlingo",
    path = "system_prompt_template.md",
    role_instruction = role_instruction,
    audience_title = tools::toTitleCase(audience),
    audience_instruction = config$audience[[audience]],
    verbosity_title = tools::toTitleCase(verbosity),
    verbosity_instruction = config$verbosity[[verbosity]],
    style_title = tools::toTitleCase(style),
    style_instruction = config$style[[style]],
    model_instructions = model_instructions,
    engine_section = engine_section,
    caution_instruction = trimws(.read_prompt_file("common", "caution.md"))
  )
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
#' @param name Character string specifying the internal prompt model key used
#' as `model_name` for `.assemble_sys_prompt`.
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
  
  # Clone the client to avoid side effects on the user's object
  client_clone <- client$clone()
  client_clone$set_turns(list())
  client_clone$set_system_prompt(sys_prompt)
  
  ex <- client_clone$chat(usr_prompt, echo = "none")
  
  ex <- .remove_fences(ex)
  output <- structure(
    list(
      text = ex,
      # Potentially add other metadata here if useful later
      model_type = name, # 'name' argument from .explain_core
      audience = audience,
      verbosity = verbosity
    ),
    class = c("statlingo_explanation", "character")
  )
  return(output)
}
