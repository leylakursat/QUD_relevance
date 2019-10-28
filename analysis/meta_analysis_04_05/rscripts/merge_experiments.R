library(tidyverse)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd('../data/')

exp4 <- read.csv("experiment4_critical.csv")
exp5 <- read.csv("experiment5_critical.csv")

View(exp4)
View(exp5)

exp4$experiment<-4
exp5$experiment<-5

exp5$workerid<-2000+exp5$workerid

df <- rbind(exp4, exp5)
View(df)

write.csv(df, file = "experiments_merged.csv")





