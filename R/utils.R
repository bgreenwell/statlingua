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
  filename <- paste0("system_prompt_", model_class, ".md")
  filepath <- system.file("prompts", filename, package = "statlingua")
  if (!nzchar(filepath)) {
    stop("System prompt for class '", name, "' not found.", call. = FALSE)
  }
  # sys_prompt <- readChar(path, nchars = file.info(path)$size)
  return(paste(readLines(filepath), collapse = "\n"))
}
