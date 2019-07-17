# Create new csv with two seperate columns for "rating" and "strange sentence

library(tidyverse)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd('../data/merged')

df <- read.csv("results_merged.csv")

df <- separate(df,response,into=c("rawRT","key"),sep=",")

df$rawRT <- as.character(gsub("\\[","",df$rawRT))
df$key <- as.character(gsub("\\]","",df$key))

df$key <- as.character(gsub("\\'","",df$key))
df$key <- as.character(gsub("\\'","",df$key))
df$key <- as.character(gsub("\\ ","",df$key))

df <- separate(df,speaker_cond,into=c("age_group","qud"),sep="_")

df$age_group <- as.character(gsub("\\ ","",df$age_group))

write.csv(df, file = "results_formatted.csv")

View(df)
