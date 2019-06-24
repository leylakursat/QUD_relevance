# Create new csv with two seperate columns for "rating" and "strange sentence

library(tidyverse)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd('../data')

df <- read.csv("results_merged.csv")

df <- separate(df,response,into=c("rawRT","key"),sep=",")

df$rawRT <- as.character(gsub("\\[","",df$rawRT))
df$key <- as.character(gsub("\\]","",df$key))
df$key <- as.character(gsub("\\'","",df$key))
df$key <- as.character(gsub("\\'","",df$key))
df$key <- as.character(gsub("\\ ","",df$key))

write.csv(df, file = "results_formatted.csv")

View(df)
