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

# A simplified R6 mock client to simulate ellmer::Chat behavior
MockChat <- R6::R6Class(
  "MockChat", # Assign the class generator to a variable
  public = list(
    last_system_prompt = NULL,
    last_user_prompt = NULL,
    chat_response = "This is a mock LLM explanation from mock_client.",
    # Ensure client argument from explain.R is handled in initialize
    initialize = function(client, ...) {
      invisible(self)
    },
    set_system_prompt = function(prompt) {
      self$last_system_prompt <- prompt
      invisible(self)
    },
    # Ensure ... is handled in chat to match usage in explain.R (client$chat(usr_prompt))
    chat = function(prompt, ...) {
      self$last_user_prompt <- prompt
      return(self$chat_response)
    }
  )
)

mock_client <- MockChat$new() # Instantiate the class correctly

# --- Test R/utils.R Functions ---

# Test .capture_output()
df_test <- data.frame(x = 1, y = "a")
expect_true(is.character(statlingua:::.capture_output(print(df_test))))
actual_output_cat <- statlingua:::.capture_output(cat("hello\nworld"), collapse = "\n")
expected_output_cat <- "hello\nworld"
expect_equal(normalize_line_endings(actual_output_cat), normalize_line_endings(expected_output_cat))

# Test .read_prompt()
expect_true(nchar(statlingua:::.read_prompt("common", "role_base.md")) > 0)
# expect_equal(statlingua:::.read_prompt("nonexistent", "file.md"), "")
expect_warning(statlingua:::.read_prompt("nonexistent", "file.md"))

# Test .assemble_sys_prompt()
# Basic Assembly
prompt_lm_novice <-
  statlingua:::.assemble_sys_prompt(model_name = "lm", style = "markdown",
                                    audience = "novice", verbosity = "brief")
expect_true(is.character(prompt_lm_novice) && nchar(prompt_lm_novice) > 0)
expect_true(grepl("## Role", prompt_lm_novice))
expect_true(grepl("## Intended Audience and Verbosity", prompt_lm_novice))
expect_true(grepl("## Response Format", prompt_lm_novice))
expect_true(grepl("## Instructions", prompt_lm_novice))
expect_true(grepl("## Caution", prompt_lm_novice))
expect_true(grepl_robust_line_endings(statlingua:::.read_prompt("common", "role_base.md"),
                  prompt_lm_novice))
expect_true(grepl_robust_line_endings(statlingua:::.read_prompt("models", "lm", "role_specific.md"),
                  prompt_lm_novice))
expect_true(grepl_robust_line_endings(statlingua:::.read_prompt("audience", "novice.md"),
                  prompt_lm_novice))
expect_true(grepl_robust_line_endings(statlingua:::.read_prompt("verbosity", "brief.md"),
                  prompt_lm_novice))
expect_true(grepl_robust_line_endings(statlingua:::.read_prompt("models", "lm", "instructions.md"),
                  prompt_lm_novice))

# Model without role_specific.md (e.g., "default")
prompt_default_assembly <-
  statlingua:::.assemble_sys_prompt(model_name = "default", style = "markdown",
                                    audience = "researcher", verbosity = "moderate")
expect_true(grepl_robust_line_endings(statlingua:::.read_prompt("models", "default", "instructions.md"),
                  prompt_default_assembly))
# Assuming "default" model does not have a role_specific.md or it's empty.
# The current implementation of .assemble_sys_prompt adds the "## Role" header regardless,
# then the base role, and then potentially the model-specific role.
# So, we check that a known phrase from a model-specific role (like for 'lm') is NOT present.
lm_specific_role_phrase <- "You are particularly skilled with **Linear Regression Models**"
expect_false(grepl(lm_specific_role_phrase, prompt_default_assembly, fixed = TRUE))

# Fallback for invalid model_name
prompt_invalid_model <-
  statlingua:::.assemble_sys_prompt(model_name = "invalid_model_xyz",
                                    style = "markdown",
                                    audience = "researcher", verbosity = "moderate")
expect_true(grepl_robust_line_endings(statlingua:::.read_prompt("models", "default", "instructions.md"),
                  prompt_invalid_model))

# Fallback for invalid audience
expect_warning(
  prompt_invalid_audience <-
    statlingua:::.assemble_sys_prompt(model_name = "lm",
                                      audience = "invalid_audience_xyz",
                                      verbosity = "moderate",
                                      style = "markdown"),
  "Audience file for 'invalid_audience_xyz' not found or empty."
)
expect_true(grepl("Assume the user has a good understanding of statistical concepts.",
                  prompt_invalid_audience, fixed = TRUE))

# Fallback for invalid verbosity
expect_warning(
  prompt_invalid_verbosity <-
    statlingua:::.assemble_sys_prompt(model_name = "lm",
                                      audience = "researcher",
                                      verbosity = "invalid_verbosity_xyz",
                                      style = "markdown"),
  "Verbosity file for 'invalid_verbosity_xyz' not found or empty."
)
expect_true(grepl("Provide a moderate level of detail.",
                  prompt_invalid_verbosity, fixed = TRUE))


# Test .build_usr_prompt()
model_desc <- "test model"
output_str <- "Test output"
context_str <- "Test context"
prompt_no_context <- statlingua:::.build_usr_prompt(model_desc, output = output_str) #
expect_true(grepl_robust_line_endings(paste0("Explain the following ",
                         model_desc, " output:\n", output_str),
                  prompt_no_context))
prompt_with_context <-
  statlingua:::.build_usr_prompt(model_desc,
                                  output = output_str, context = context_str) #
expect_true(grepl_robust_line_endings(paste0("\n\n## Additional context to consider\n\n", context_str),
                  prompt_with_context))

# --- Test R/summarize.R Methods ---

# summarize.default
expect_equal(statlingua::summarize("A simple string"), "[1] \"A simple string\"") #

# summarize.htest (e.g., from t.test)
t_test_obj <- t.test(1:5, 6:10)
expect_true(is.character(statlingua::summarize(t_test_obj))) #
expect_equal(statlingua::summarize(t_test_obj), statlingua:::.capture_output(t_test_obj)) #

# summarize.lm
lm_obj <- lm(mpg ~ wt, data = mtcars)
expect_true(is.character(statlingua::summarize(lm_obj))) #
expect_equal(statlingua::summarize(lm_obj), statlingua:::.capture_output(summary(lm_obj))) #

# --- Test R/explain.R Methods (using mock_client) ---

# explain.default (using a basic list, assuming it will print its structure)
simple_list_obj <- list(name = "TestObject", value = 123)
class(simple_list_obj) <- "UnregisteredClassForDefault" # Force default method
# The default method uses .capture_output(object)
expected_default_output_summary <- statlingua:::.capture_output(simple_list_obj) #

# Test explain.default
explanation_default <-
  statlingua::explain(simple_list_obj, client = mock_client,
                      audience = "student", verbosity = "detailed")
expect_equal(explanation_default$text, mock_client$chat_response)
expected_sys_prompt_default <-
  statlingua:::.assemble_sys_prompt(model_name = "default",
                                    audience = "student",
                                    verbosity = "detailed",
                                    style = "markdown")
expect_equal(mock_client$last_system_prompt, expected_sys_prompt_default)

# Check that it also returns the value invisibly
# expect_equal(explanation_lm_cat, mock_client$chat_response) # This might be tricky with expect_stdout, consider separate test if needed
expected_sys_prompt_lm_specific <-
  statlingua:::.assemble_sys_prompt(model_name = "lm", audience = "novice",
                                    verbosity = "brief", style = "markdown")
# expect_equal(mock_client$last_system_prompt, expected_sys_prompt_lm_specific)
# expect_true(grepl("LM test context", mock_client$last_user_prompt))

# Test explain.lm with default audience/verbosity
statlingua::explain(lm_obj, client = mock_client, context = "LM test default")
expected_sys_prompt_lm_defaults <-
  statlingua:::.assemble_sys_prompt(model_name = "lm", audience = "researcher",
                                    verbosity = "moderate", style = "markdown")
# expect_equal(mock_client$last_system_prompt, expected_sys_prompt_lm_defaults)
expect_true(grepl("LM test default", mock_client$last_user_prompt))


# Test explain.htest
t_test_obj <- t.test(1:5, 6:10) # Ensure t_test_obj is defined
explanation_htest <- statlingua::explain(t_test_obj, client = mock_client,
                                         audience = "manager",
                                         verbosity = "detailed")
expect_equal(explanation_htest$text, mock_client$chat_response)
expect_true(grepl(statlingua::summarize(t_test_obj), mock_client$last_user_prompt))
expected_sys_prompt_htest <-
  statlingua:::.assemble_sys_prompt(model_name = "htest", audience = "manager",
                                    verbosity = "detailed", style = "markdown")
expect_equal(mock_client$last_system_prompt, expected_sys_prompt_htest)


# Test input validation for client object
expect_error(
  statlingua::explain(lm_obj, client = "not_an_R6_client"), #
  "inherits(client, what = c(\"Chat\", \"R6\")) is not TRUE", # Error from stopifnot
  fixed = TRUE
)
