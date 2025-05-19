library(rpart)
library(statlingua)


context <- "
  Here's some additional context about the data used to this the model.

  ### Data set description

  The kyphosis data frame has 81 rows and 4 columns representing data on
  children who have had corrective spinal surgery.

  ### Data set format

  The data contain the following columns:

  * Kyphosis - a factor with levels absent present indicating if a kyphosis (a
    type of deformation) was present after the operation.
  * Age - age in months.
  * Number - the number of vertebrae involved.
  * Start - the number of the first (topmost) vertebra operated on.
  "

# Fit a time transform model using current age
fm <- rpart(Kyphosis ~ Age + Number + Start, data = kyphosis)

# Use an LLM to help explain the model's output
client <- ellmer::chat_gemini(echo = "none")
ex <- explain(fm, chat = client, context = context)

# Write explanation to file
file_conn <- file("slowtests/markdown/slowtest_rpart.md")
writeLines(ex, con = file_conn)
close(file_conn)
