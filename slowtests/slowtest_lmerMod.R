library(lme4)
library(statlingua)


context <- "
  Here's some additional context about the data used to this the model.

  ### Data set description

  The data contain the average reaction time per day (in milliseconds) for
  subjects in a sleep deprivation study. Days 0-1 were adaptation and training
  (T1/T2), day 2 was baseline (B); sleep deprivation started after day 2. These
  data are from the study described in Belenky et al. (2003), for the most
  sleep-deprived group (3 hours time-in-bed) and for the first 10 days of the
  study, up to the recovery period. The original study analyzed speed
  (1/(reaction time)) and treated day as a categorical rather than a continuous
  predictor.

  ### Data set format

  A data frame with 180 observations on the following 3 variables:

  * Reaction - Average reaction time (ms)
  * Days - Number of days of sleep deprivation
  * Subject - Subject number on which the observation was made.
  "

# Fit a linear mixed model
fm <- lmer(Reaction ~ Days + (Days | Subject), sleepstudy)

# Use LLM to help explain model
client <- ellmer::chat_gemini(echo = "none")
ex <- explain(fm, chat = client, context = context)

# Write explanation to file
file_conn <- file("slowtests/markdown/slowtest_lmerMod.md")
writeLines(ex, con = file_conn)
close(file_conn)
