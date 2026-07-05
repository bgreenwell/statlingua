# Helper function for robust line ending grepl
grepl_robust_line_endings <- function(pattern, text) {
  pattern_lf <- gsub("\r\n", "\n", pattern, fixed = TRUE)
  text_lf <- gsub("\r\n", "\n", text, fixed = TRUE)
  grepl(pattern_lf, text_lf, fixed = TRUE)
}

# Helper function to normalize line endings for direct string comparison
normalize_line_endings <- function(s) {
  s <- gsub("\r\n", "\n", s, fixed = TRUE) # Convert CRLF to LF
  s <- gsub("\r", "\n", s, fixed = TRUE)    # Convert standalone CR to LF
  return(s)
}

# A simplified R6 mock client to simulate ellmer::Chat behavior. `explain()`
# calls `client$clone()` before use (to avoid mutating the caller's object),
# and R6's default clone() is a *shallow* copy: fields that hold an
# environment are copied by reference, not duplicated. So we stash the
# "recorded" state (what system/user prompt was last sent) in a nested
# environment field; that way calls made on a clone remain observable via
# the original `mock_client` object, without needing to override the
# reserved `clone` method (not allowed since R6 >= 2.5).
MockChat <- R6::R6Class(
  "MockChat", # Assign the class generator to a variable
  public = list(
    state = NULL,
    chat_response = "This is a mock LLM explanation from mock_client.",
    initialize = function(...) {
      self$state <- new.env(parent = emptyenv())
      self$state$last_system_prompt <- NULL
      self$state$last_user_prompt <- NULL
      invisible(self)
    },
    set_turns = function(turns) {
      invisible(self)
    },
    set_system_prompt = function(prompt) {
      self$state$last_system_prompt <- prompt
      invisible(self)
    },
    # Ensure ... is handled in chat to match usage in explain.R (client$chat(usr_prompt))
    chat = function(prompt, echo = NULL, ...) {
      self$state$last_user_prompt <- prompt
      return(self$chat_response)
    }
  ),
  active = list(
    last_system_prompt = function() self$state$last_system_prompt,
    last_user_prompt = function() self$state$last_user_prompt
  )
)

mock_client <- MockChat$new() # Instantiate the class correctly

# --- Test R/utils.R Functions ---

# Test .capture_output()
df_test <- data.frame(x = 1, y = "a")
expect_true(is.character(statlingo:::.capture_output(print(df_test))))
actual_output_cat <- statlingo:::.capture_output(cat("hello\nworld"), collapse = "\n")
expected_output_cat <- "hello\nworld"
expect_equal(normalize_line_endings(actual_output_cat), normalize_line_endings(expected_output_cat))

# Test .read_prompt_file()
expect_true(nchar(statlingo:::.read_prompt_file("common", "role_base.md")) > 0)
expect_equal(statlingo:::.read_prompt_file("nonexistent", "file.md"), "")

# Test .prompt_config()
config <- statlingo:::.prompt_config()
expect_true(is.list(config))
expect_true(all(c("audience", "verbosity", "style") %in% names(config)))
expect_true(nchar(config$audience$novice) > 0)
expect_true(nchar(config$verbosity$brief) > 0)
expect_true(nchar(config$style$markdown) > 0)

# Test .assemble_sys_prompt()
# Basic Assembly
prompt_lm_novice <-
  statlingo:::.assemble_sys_prompt(model_name = "linear_model",
                                   style = "markdown",
                                   audience = "novice",
                                   verbosity = "brief")
expect_true(is.character(prompt_lm_novice) && nchar(prompt_lm_novice) > 0)
expect_true(grepl("## Role", prompt_lm_novice))
expect_true(grepl("## Intended Audience and Verbosity", prompt_lm_novice))
expect_true(grepl("## Response Format Specification", prompt_lm_novice))
expect_true(grepl("## Instructions", prompt_lm_novice))
expect_true(grepl("## Caution", prompt_lm_novice))
expect_true(grepl_robust_line_endings(statlingo:::.read_prompt_file("common", "role_base.md"),
                  prompt_lm_novice))
expect_true(grepl_robust_line_endings(statlingo:::.read_prompt_file("models", "linear_model", "role_specific.md"),
                  prompt_lm_novice))
expect_true(grepl_robust_line_endings(config$audience$novice, prompt_lm_novice))
expect_true(grepl_robust_line_endings(config$verbosity$brief, prompt_lm_novice))
expect_true(grepl_robust_line_endings(statlingo:::.read_prompt_file("models", "linear_model", "instructions.md"),
                  prompt_lm_novice))
expect_true(grepl("## Output Format Notes", prompt_lm_novice, fixed = TRUE))
expect_true(grepl("Multiple R-squared", prompt_lm_novice, fixed = TRUE))

prompt_lm_spanish <-
  statlingo:::.assemble_sys_prompt(model_name = "linear_model",
                                   style = "markdown",
                                   audience = "novice",
                                   verbosity = "brief",
                                   language = "Spanish")
expect_true(grepl("## Response Language", prompt_lm_spanish, fixed = TRUE))
expect_true(grepl("Respond only in Spanish", prompt_lm_spanish, fixed = TRUE))
expect_false(grepl("## Response Language", prompt_lm_novice, fixed = TRUE))

# Model without role_specific.md (e.g., "default")
prompt_default_assembly <-
  statlingo:::.assemble_sys_prompt(model_name = "default", style = "markdown",
                                    audience = "researcher", verbosity = "moderate")
expect_true(grepl_robust_line_endings(statlingo:::.read_prompt_file("models", "default", "instructions.md"),
                  prompt_default_assembly))
# Assuming "default" model does not have a role_specific.md or it's empty.
# So, we check that a known phrase from a model-specific role (like for 'lm') is NOT present.
lm_specific_role_phrase <- "You are particularly skilled with **Linear Regression Models**"
expect_false(grepl(lm_specific_role_phrase, prompt_default_assembly, fixed = TRUE))

# Fallback for invalid model_name
prompt_invalid_model <-
  statlingo:::.assemble_sys_prompt(model_name = "invalid_model_xyz",
                                    style = "markdown",
                                    audience = "researcher", verbosity = "moderate")
expect_true(grepl_robust_line_endings(statlingo:::.read_prompt_file("models", "default", "instructions.md"),
                  prompt_invalid_model))

# Model without engine notes should not include an engine section
prompt_hypothesis_test <-
  statlingo:::.assemble_sys_prompt(model_name = "hypothesis_test",
                                   style = "markdown",
                                   audience = "researcher",
                                   verbosity = "moderate")
expect_false(grepl("## Output Format Notes",
                   prompt_hypothesis_test, fixed = TRUE))


# Test .build_usr_prompt()
model_desc <- "test model"
output_str <- "Test output"
context_str <- "Test context"
prompt_no_context <- statlingo:::.build_usr_prompt(model_desc, output = output_str) #
expect_true(grepl_robust_line_endings(paste0("Explain the following ",
                         model_desc, " output:\n", output_str),
                  prompt_no_context))
prompt_with_context <-
  statlingo:::.build_usr_prompt(model_desc,
                                  output = output_str, context = context_str) #
expect_true(grepl_robust_line_endings(paste0("\n\n## Additional context to consider\n\n", context_str),
                  prompt_with_context))

# --- Test R/summarize.R Methods ---

# summarize.default
expect_equal(statlingo::summarize("A simple string"), "[1] \"A simple string\"") #

# summarize.htest (e.g., from t.test)
t_test_obj <- t.test(1:5, 6:10)
expect_true(is.character(statlingo::summarize(t_test_obj))) #
expect_equal(statlingo::summarize(t_test_obj), statlingo:::.capture_output(t_test_obj)) #

# summarize.lm
lm_obj <- lm(mpg ~ wt, data = mtcars)
expect_true(is.character(statlingo::summarize(lm_obj))) #
expect_equal(statlingo::summarize(lm_obj), statlingo:::.capture_output(summary(lm_obj))) #

# --- Test R/explain.R Methods (using mock_client) ---

# explain.default (using a basic list, assuming it will print its structure)
simple_list_obj <- list(name = "TestObject", value = 123)
class(simple_list_obj) <- "UnregisteredClassForDefault" # Force default method
# The default method uses .capture_output(object)
expected_default_output_summary <- statlingo:::.capture_output(simple_list_obj) #

# Test explain.default
explanation_default <-
  statlingo::explain(simple_list_obj, client = mock_client,
                      audience = "student", verbosity = "detailed")
expect_equal(explanation_default$text, mock_client$chat_response)
expected_sys_prompt_default <-
  statlingo:::.assemble_sys_prompt(model_name = "default",
                                    audience = "student",
                                    verbosity = "detailed",
                                    style = "markdown")
expect_equal(mock_client$last_system_prompt, expected_sys_prompt_default)

# Check that it also returns the value invisibly
# expect_equal(explanation_lm_cat, mock_client$chat_response) # This might be tricky with expect_stdout, consider separate test if needed
expected_sys_prompt_lm_specific <-
  statlingo:::.assemble_sys_prompt(model_name = "linear_model",
                                   audience = "novice",
                                   verbosity = "brief",
                                   style = "markdown")
# expect_equal(mock_client$last_system_prompt, expected_sys_prompt_lm_specific)
# expect_true(grepl("LM test context", mock_client$last_user_prompt))

# Test explain.lm with default audience/verbosity
statlingo::explain(lm_obj, client = mock_client, context = "LM test default")
expected_sys_prompt_lm_defaults <-
  statlingo:::.assemble_sys_prompt(model_name = "linear_model",
                                   audience = "researcher",
                                   verbosity = "moderate",
                                   style = "markdown")
# expect_equal(mock_client$last_system_prompt, expected_sys_prompt_lm_defaults)
expect_true(grepl("LM test default", mock_client$last_user_prompt))


# Test explain.htest
t_test_obj <- t.test(1:5, 6:10) # Ensure t_test_obj is defined
explanation_htest <- statlingo::explain(t_test_obj, client = mock_client,
                                         audience = "manager",
                                         verbosity = "detailed")
expect_equal(explanation_htest$text, mock_client$chat_response)
expect_true(grepl(statlingo::summarize(t_test_obj), mock_client$last_user_prompt))
expected_sys_prompt_htest <-
  statlingo:::.assemble_sys_prompt(model_name = "hypothesis_test",
                                   audience = "manager",
                                   verbosity = "detailed",
                                   style = "markdown")
expect_equal(mock_client$last_system_prompt, expected_sys_prompt_htest)

explanation_language <- statlingo::explain(
  lm_obj,
  client = mock_client,
  language = "French"
)
expect_equal(explanation_language$text, mock_client$chat_response)
expect_true(grepl("Respond only in French",
                  mock_client$last_system_prompt, fixed = TRUE))


# Test input validation for client object
expect_error(
  statlingo::explain(lm_obj, client = "not_an_R6_client"), #
  "inherits(client, what = c(\"Chat\", \"R6\")) is not TRUE", # Error from stopifnot
  fixed = TRUE
)

# Test suggest_code
explanation_mock <- structure(
  list(
    text = "Mock explanation",
    model_type = "linear_model",
    audience = "student"
  ),
  class = "statlingo_explanation"
)

suggestions <- statlingo::suggest_code(explanation_mock)
expect_true(inherits(suggestions, "statlingo_code_suggestions"))
expect_true(any(grepl("plot(model, which = 1)", suggestions$suggestions, fixed = TRUE)))

