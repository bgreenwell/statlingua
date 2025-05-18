library(survival)
library(statlingua)


context <- "
  Here's some additional context about the data used to this the model.

  ### Data set description

  Survival in a randomised trial comparing two treatments for ovarian cancer.

  ### Data set format

  * futime:	survival or censoring time
  * fustat:	censoring status
  * age:	in years
  * resid.ds:	residual disease present (1=no,2=yes)
  * rx:	treatment group
  * ecog.ps:	ECOG performance status (1 is better, see reference)
  "

# Fit an exponential model
fm <- survreg(Surv(futime, fustat) ~ ecog.ps + rx, ovarian,
              dist = "weibull", scale = 1)

# Use LLM to help explain model
client <- ellmer::chat_gemini(echo = "none")
ex <- explain(fm, chat = client, context = context)

# Write explanation to file
file_conn <- file("slowtests/markdown/slowtest_survreg.md")
writeLines(ex, con = file_conn)
close(file_conn)
