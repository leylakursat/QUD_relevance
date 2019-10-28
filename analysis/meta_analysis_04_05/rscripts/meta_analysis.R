library(tidyverse)
library(lme4)
library(languageR)
library(brms)
library(lmerTest)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd('../data/')

df <- read.csv("experiments_merged.csv")

length(unique(df$workerid))

semanticity = df %>%
  group_by(workerid,key, .drop=FALSE) %>%
  count(key) %>%
  filter(key=="Yes") %>%
  mutate(responder_type = ifelse(n>4,"semantic",ifelse(n<4,"pragmatic",ifelse(n==4,"inconsistent","NA"))))

df = df %>%
  #mutate(experiment = as.factor(experiment)) %>%
  mutate(numericKey = ifelse(key == "Yes",1,0)) %>%
  merge(semanticity[ ,c("workerid","responder_type","n")], by="workerid",all.x=TRUE) %>%
  mutate(numericKey = as.factor(numericKey)) %>%
  mutate(responder_type = as.factor(responder_type)) %>%
  mutate(ckey = as.numeric(key) - mean(as.numeric(key))) %>%
  mutate(cresponder_type = as.numeric(responder_type) - mean(as.numeric(responder_type)))

contrasts(df$experiment)
table(df$experiment)

View(df)
#response type from experiment type
m = glmer(numericKey ~ experiment + (1|workerid), data=df, family="binomial")
summary(m)






