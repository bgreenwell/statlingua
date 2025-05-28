#' @examples
#' \dontrun{
#' # Load the Bike Sharing dataset
#' bikeshare <- ISLR2::Bikeshare
#' 
#' # Fit a Poisson regression model to the bike sharing data set
#' fm <- glm(bikers ~ mnth + hr + workingday + temp + weathersit,
#'           data = bikeshare, family = poisson)
#' 
#' # Additional context to consider when explaining model output
#' context <- "
#' The data contain the hourly and daily count of rental bikes between years 2011
#' and 2012 in the Capital bikeshare system, along with weather and seasonal
#' information. The variables in the model include:
#'
#' * bikers - Total number of bikers.
#' * mnth - Month of the year, coded as a factor.
#' * hr - Hour of the day, coded as a factor from 0 to 23.
#' * workingday - Is it a work day? Yes=1, No=0.
#' * temp - Normalized temperature in Celsius. The values are derived via
#'   (t-t_min)/(t_max-t_min), t_min=-8, t_max=+39.
#' * weathersit - Weather, coded as a factor.
#' "
#' 
#' # Use Google Gemini to explain the output; requires an API key; see
#' # ?ellmer::chat_google_gemini for details
#' client <- ellmer::chat_google_gemini(echo = "none")
#' 
#' # Explain the model with the correct parameters
#' explain(fm, client = client, context = context, audience = "student",
#'         verbosity = "brief", style = "text")
#' }