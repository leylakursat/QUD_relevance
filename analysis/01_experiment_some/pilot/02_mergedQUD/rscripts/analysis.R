library(tidyverse)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("helpers.R")
setwd('../data')
theme_set(theme_bw())
df = read.csv("results_formatted.csv", header = TRUE)

# INITIAL
#total time
times = df %>%
  select(workerid, Answer.time_in_minutes, speaker_cond) %>%
  unique()

ggplot(times, aes(x=Answer.time_in_minutes)) +
  geom_histogram()
#bot check


#EXCLUSIONS
#native language
#audio check
#accuracy in non-critical trials
#comprehension questions
#practice trials
#response  time 

#EXPERIMENTAL TRIALS
trials = df %>% 
  filter(str_detect(slide_type,"trial")) %>% 
  filter(str_detect(slide_type,"practice", negate = TRUE))

trials$logrt = log(trials$rtime)

ggplot(trials, aes(x=logrt)) +
  geom_histogram()

#CRITICAL TRIALS
target = trials %>% 
  filter(str_detect(audio,"some.wav")) %>%
  filter(str_detect(image,"13"))

ggplot(target, aes(x=rkey)) +
  geom_bar() +
  facet_wrap(~Answer.condition)

#rkey
ggplot(target, aes(x = factor(rkey))) +
  geom_bar(fill = "lightblue3")+
  facet_wrap(~Answer.condition) +
  labs(title = "Response type")

geom_bar(stat="identity",fill = "lightblue3") +
#proportion of semantic responses
#distribution of participants over number of semantic responses

#rtime
ggplot(target, aes(x=rtime))+
  geom_histogram()+
  facet_wrap(~Answer.condition)

agr = target %>%
  group_by(Answer.condition,rkey) %>%
  summarize(Median=median(rtime),Mean=mean(rtime),CILow=ci.low(rtime),CIHigh=ci.high(rtime),SD=sd(rtime),Var=var(rtime)) %>%
  ungroup() %>%
  mutate(YMin=Mean-CILow,YMax=Mean+CIHigh)

agr2 = target %>%
  group_by(workerid,rkey) %>%
  summarize(Median=median(rtime),Mean=mean(rtime),CILow=ci.low(rtime),CIHigh=ci.high(rtime),SD=sd(rtime),Var=var(rtime))

ggplot(agr, aes(x=rkey,y=Mean)) +
  geom_bar(stat="identity",fill = "lightblue3") +
  geom_errorbar(aes(ymin = YMin, ymax = YMax),width=.25) +
  geom_point(data=target, aes(y = rtime,color = as.factor(workerid)),alpha=.2) + 
  geom_point(aes(y=Median),color="orange",size=2) +
  #geom_line(data=target, aes(y = rtime, group= as.factor(workerid),color = as.factor(workerid)),alpha=.2)+
  labs(title = "Mean response time")+
  theme(plot.title = element_text(hjust =0.5),axis.text.x=element_text(angle=45,hjust=1,vjust=1)) +
  facet_wrap(~Answer.condition)
  
#exclusions
target[target$workerid == "3" & target$rtime > 2500,]$rtime
target[target$workerid == "2" & target$rtime > 2500,]$rtime

target <- target[!(target$rtime > 2000),]
