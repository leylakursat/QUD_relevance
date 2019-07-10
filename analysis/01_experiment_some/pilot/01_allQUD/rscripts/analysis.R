library(tidyverse)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("helpers.R")
setwd('../data')
theme_set(theme_bw())
df = read.csv("results_formatted.csv", header = TRUE)

# Exclusions based on total time, native language, audio check, comprehension check, practice trials, response time (and check bot question)

# All trials
#total time exclusion
times = df %>%
  select(workerid, Answer.time_in_minutes) %>%
  unique()

ggplot(times, aes(x=Answer.time_in_minutes)) +
  geom_histogram()

#rtime exclusion
trials = df %>% 
  filter(str_detect(slide_type,"critical_trial"))

trials$logrt = log(trials$rtime)

ggplot(trials, aes(x=logrt)) +
  geom_histogram()

summary(trials$rtime)

trials <- trials[!(trials$rtime > 5000),]

# Critical trials 
target = trials %>% 
  filter(str_detect(audio,"some.wav")) %>%
  filter(str_detect(image,"13"))

#rkey
ggplot(target, aes(x = factor(rkey))) +
  geom_bar()+
  labs(title = "Response type")

#rtime
ggplot(target, aes(x=rtime))+
  geom_histogram()+
  facet_wrap(~rkey)

agr = target %>%
  group_by(rkey) %>%
  summarize(Median=median(rtime),Mean=mean(rtime),CILow=ci.low(rtime),CIHigh=ci.high(rtime),SD=sd(rtime),Var=var(rtime)) %>%
  ungroup() %>%
  mutate(YMin=Mean-CILow,YMax=Mean+CIHigh)

ggplot(agr, aes(x=rkey,y=Mean)) +
  geom_bar(stat="identity",fill = "lightblue3") +
  geom_errorbar(aes(ymin = YMin, ymax = YMax),width=.25) +
  geom_point(data=target, aes(y = rtime,color = as.factor(workerid)),alpha=.2) + 
  geom_point(aes(y=Median),color="orange",size=2) +
  geom_line(data=target, aes(y = rtime, group= as.factor(workerid),color = as.factor(workerid)),alpha=.2)
  labs(title = "Mean response time")+
  theme(plot.title = element_text(hjust =0.5),axis.text.x=element_text(angle=45,hjust=1,vjust=1))

#exclusions
target[target$workerid == "3" & target$rtime > 2500,]$rtime
target[target$workerid == "2" & target$rtime > 2500,]$rtime

target <- target[!(target$rtime > 2000),]


