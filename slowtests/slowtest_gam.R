library(mgcv)
library(statlingua)


context <- "
  Here's some additional context about the data used to this the model.

  ### Data set description

  Daily air quality measurements in New York, May to September 1973. The data
  were obtained from the New York State Department of Conservation (ozone data)
  and the National Weather Service (meteorological data).

  ### Data set format

  A data frame with 153 observations on the following 6 variables:

  *	Ozone	- Ozone (ppb)
  *	Solar.R	- Solar R (lang)
  *	Wind - Wind speed (mph)
  *	Temp - Temperature (degrees F)
  * Month - Month of year (1--12)
  * Day - Day of month (1--31)
  "

# Fit a simple GAM
fm <- gam(Ozone^(1/3) ~ s(Solar.R) + s(Wind, Temp), data = airquality)

# Use LLM to help explain model
client <- ellmer::chat_gemini(echo = "none")
ex <- explain(fm, chat = client, context = context)

# Write explanation to file
file_conn <- file("slowtests/markdown/slowtest_gam.md")
writeLines(ex, con = file_conn)
close(file_conn)
