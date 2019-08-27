# Create new csv with two seperate columns for "rating" and "strange sentence

library(tidyverse)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd('../data/')

df <- read.csv("merged_trials.csv")

df <- separate(df,response,into=c("rawRT","key"),sep=",")

df$rawRT <- as.character(gsub("\\[","",df$rawRT))
df$key <- as.character(gsub("\\]","",df$key))

df$key <- as.character(gsub("\\'","",df$key))
df$key <- as.character(gsub("\\'","",df$key))
df$key <- as.character(gsub("\\ ","",df$key))

df <- separate(df,Answer.condition,into=c("age_group","qud"),sep="-")

df$age_group <- as.character(gsub("\\ ","",df$age_group))

write.csv(df, file = "trials_formatted.csv")

View(df)
