library(tidyverse)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd('../data/')
theme_set(theme_bw())

df = read.csv("results_formatted.csv", header = TRUE)
demo = read.csv("subject_info_merged.csv", header = TRUE)

length(unique(df$workerid))
length(unique(demo$workerid))
length(demo$workerid)


df = df %>%
  merge(demo[ ,c("workerid","age")], by="workerid",all.x=TRUE) %>%
  distinct(workerid, .keep_all = TRUE) %>%
  select(workerid,age,age_group,qud) %>%
  mutate(correct_group = ifelse(age_group=="age1"&age>17&age<26, "1", ifelse(age_group=="age2"&age>44,"2","0")))
  
table(df$age_group,df$qud)

length(df$workerid) #516 (216&300)
unique(length(df$workerid)) #516

to_exclude = df %>%
  filter(correct_group == 0) %>%
  select(workerid)

to_exclude

#97 and 105
