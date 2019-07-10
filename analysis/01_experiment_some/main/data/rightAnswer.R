library(tidyverse)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("helpers.R")
setwd('../data')
theme_set(theme_bw())
df = read.csv("results_formatted.csv", header = TRUE)

yes_list = c("some2","some5","some8","some11",
             "all13",
             "none0",
             "zero0","two2","five5","eight8","eleven11","thirteen13")

low_accuracy = df %>% 
  filter(str_detect(slide_type,"trial")) %>% 
  filter(str_detect(slide_type,"practice", negate = TRUE)) %>% 
  mutate(concat = str_c(str_sub(audio,1,end=-5),image)) %>%
  filter(str_detect(concat,"some13", negate = TRUE)) %>%
  mutate(rightAnswer = ifelse(concat %in% yes_list,"Yes","No")) %>%
  mutate(gaveRightAnswer = ifelse(key==rightAnswer,"1","0")) %>%
  group_by(workerid,gaveRightAnswer) %>%
  count(gaveRightAnswer) %>%
  mutate(accuracy=ifelse(gaveRightAnswer=="1",n*100/64,0)) %>%
  filter(gaveRightAnswer=="1") %>%
  filter(accuracy < 85)






left_join
answers = xtabs(~workerid +gaveRightAnswer, df2)
df3 = prop.table(answers, margin=1)*100

View(df3)save



df4 = filter(df3, workerid=="1")
  



  







