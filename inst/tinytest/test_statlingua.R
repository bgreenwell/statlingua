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

# Test capture_output()
df_test <- data.frame(x = 1, y = "a")
expect_true(is.character(statlingua:::capture_output(print(df_test))))
expect_equal(statlingua:::capture_output(cat("hello\nworld"), collapse = "\n"), "hello\nworld")

# Test .get_system_prompt() (requires package structure for system.file)
# Assuming 'default.md' and 'lm.md' prompts exist in 'inst/prompts/'
expect_true(nchar(statlingua:::.get_system_prompt("default")) > 0) #
expect_error(statlingua:::.get_system_prompt("non_existent_prompt_type")) #

# Test .build_user_prompt()
model_desc <- "test model"
output_str <- "Test output"
context_str <- "Test context"
prompt_no_context <- statlingua:::.build_user_prompt(model_desc, output = output_str) #
expect_true(grepl(paste0("Explain the following ", model_desc, " output:\n", output_str), prompt_no_context, fixed = TRUE))
prompt_with_context <- statlingua:::.build_user_prompt(model_desc, output = output_str, context = context_str) #
expect_true(grepl(paste0("\n\n## Additional context to consider\n\n", context_str), prompt_with_context, fixed = TRUE))

# --- Test R/summarize.R Methods ---

# summarize.default
expect_equal(statlingua::summarize("A simple string"), "A simple string") #

# summarize.htest (e.g., from t.test)
t_test_obj <- t.test(1:5, 6:10)
expect_true(is.character(statlingua::summarize(t_test_obj))) #
expect_equal(statlingua::summarize(t_test_obj), statlingua:::capture_output(t_test_obj)) #

# summarize.lm
lm_obj <- lm(mpg ~ wt, data = mtcars)
expect_true(is.character(statlingua::summarize(lm_obj))) #
expect_equal(statlingua::summarize(lm_obj), statlingua:::capture_output(summary(lm_obj))) #

# --- Test R/explain.R Methods (using mock_client) ---

# explain.default (using a basic list, assuming it will print its structure)
simple_list_obj <- list(name = "TestObject", value = 123)
class(simple_list_obj) <- "UnregisteredClassForDefault" # Force default method
# The default method uses capture_output(object)
expected_default_output_summary <- statlingua:::capture_output(simple_list_obj) #

# Test explain.default with concatenate = FALSE
explanation_default <- statlingua::explain(simple_list_obj, client = mock_client, concatenate = FALSE) #
expect_equal(explanation_default, mock_client$chat_response)
expect_true(grepl(expected_default_output_summary, mock_client$last_user_prompt))
expect_equal(mock_client$last_system_prompt, statlingua:::.get_system_prompt("default")) #

# Test explain.lm with concatenate = TRUE
# This will print to console due to cat()
# Assuming the corrected concatenate logic: cat(ex); invisible(ex)
expect_stdout(
  explanation_lm_cat <- statlingua::explain(lm_obj, client = mock_client, context = "LM test context", concatenate = TRUE), #
  mock_client$chat_response
)
# Check that it also returns the value invisibly
expect_equal(explanation_lm_cat, mock_client$chat_response)
expect_true(grepl("LM test context", mock_client$last_user_prompt))
expect_equal(mock_client$last_system_prompt, statlingua:::.get_system_prompt("lm")) #


# Test explain.htest
explanation_htest <- statlingua::explain(t_test_obj, client = mock_client, concatenate = FALSE) #
expect_equal(explanation_htest, mock_client$chat_response)
expect_true(grepl(statlingua::summarize(t_test_obj), mock_client$last_user_prompt)) #
expect_equal(mock_client$last_system_prompt, statlingua:::.get_system_prompt("htest")) #


# Test input validation for client object
expect_error(
  statlingua::explain(lm_obj, client = "not_an_R6_client"), #
  "inherits(client, what = c(\"Chat\", \"R6\")) is not TRUE", # Error from stopifnot
  fixed = TRUE
)
