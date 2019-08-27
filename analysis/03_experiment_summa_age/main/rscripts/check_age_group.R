library(tidyverse)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd('../data/')
theme_set(theme_bw())

df = read.csv("results_formatted.csv", header = TRUE)
demo = read.csv("merged_subject_information.csv", header = TRUE)

df = df %>%
  merge(demo[ ,c("workerid","age")], by="workerid",all.x=TRUE) %>%
  distinct(workerid, .keep_all = TRUE) %>%
  select(workerid,age,age_group) %>%
  mutate(correct_group = ifelse(age_group=="age1"&age>17&age<26, "1", ifelse(age_group=="age2"&age>44,"2","0"))) #%>%
  filter(age_group == "age1")

length(df$workerid) #516 (216&300)
unique(length(df$workerid)) #516

to_exclude = df %>%
  filter(correct_group == 0) %>%
  select(workerid)

#97 and 105
