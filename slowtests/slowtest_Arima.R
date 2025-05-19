library(forecast)
library(statlingua)


context <- "
  Here's some additional context about the data used to this the model.

  ### Data set description

  The classic Box & Jenkins airline data. Monthly totals of international
  airline passengers, 1949 to 1960. A monthly time series, in thousands.
  "

# Fit model to first few years of AirPassengers data
fm <- Arima(window(AirPassengers, end = 1956 + 11 / 12), order = c(0, 1, 1),
            seasonal = list(order = c(0, 1, 1), period = 12), lambda = 0)

# Use an LLM to help explain the model's output
client <- ellmer::chat_gemini(echo = "none")
ex <- explain(fm, chat = client, context = context)

# Write explanation to file
file_conn <- file("slowtests/markdown/slowtest_Arima.md")
writeLines(ex, con = file_conn)
close(file_conn)
