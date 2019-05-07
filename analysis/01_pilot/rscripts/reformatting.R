# Create new csv with two seperate columns for "rating" and "strange sentence

library(tidyverse)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd('../data')

df <- read.csv("example-trials.csv")

df <- separate(df,response,into=c("rtime","rkey"),sep=",")

df$rtime <- as.character(gsub("\\[","",df$rtime))
df$rkey <- as.character(gsub("\\]","",df$rkey))
df$rkey <- as.character(gsub("\\'","",df$rkey))

write.csv(df, file = "results_formatted.csv")

View(df)
