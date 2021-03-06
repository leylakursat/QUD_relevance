library(tidyverse)
library("wesanderson")
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("helpers.R")
setwd('../data/')
theme_set(theme_bw())
df = read.csv("results_formatted.csv", header = TRUE)
demo = read.csv("merged_subject_information.csv", header = TRUE)

length(unique(df$workerid)) #84 participants missing from age1

key_col = wes_palette("Moonrise3") 
cond_col = wes_palette("Royal2")
hist_col = wes_palette("Moonrise3")[1]
age_col = wes_palette("GrandBudapest1")

#add column for lag response time
df$logRT = log(df$rawRT)

df = df %>%
  merge(demo[ ,c("workerid","age")], by="workerid",all.x=TRUE)

#######################################################################
#EXCLUSIONS
#age group -- 2 people excluded
age_exclude = c("97","105")
df = df[!(df$workerid %in% age_exclude),]

#native language -- 3 people exluded (#76,#123,#515)
lang = demo %>%
  select(workerid, language) %>%
  unique() %>%
  filter(str_detect(language,regex("english", ignore_case=TRUE),negate=TRUE)) %>%
  filter(str_detect(language,regex("united states", ignore_case=TRUE),negate=TRUE))
  
lang

lang_exclude = c("76","123","515")
df = df[!(df$workerid %in% lang_exclude),]

#practice trials -- 25 people excluded 
practice = df %>% 
  filter(str_detect(slide_type,"practice_trial")) %>%
  mutate(WrongAnswer = ((audio=="none.wav" & image=="13" & key=="Yes")|(audio=="all.wav" & image=="13" & key=="No")|(audio=="all.wav" & image=="0" & key=="Yes")| (audio=="none.wav" & image=="0" & key=="No"))) %>% 
  group_by(workerid) %>% 
  count(WrongAnswer) %>% 
  filter(WrongAnswer == TRUE & n>2)

table(practice$n)

df = df[!(df$workerid %in% practice$workerid),]

#audio check -- 1 person exluded (#348)
audio_fail = df[df$slide_type=="audio_check" & df$key !="Four",]

audio_fail = df %>%
  filter(str_detect(slide_type,"audio_check")) %>%
  mutate(WrongAudio = (ifelse(key != "Four",0,1))) %>%
  count(workerid, WrongAudio) %>%
  filter(n>1)

table(audio_fail$workerid,audio_fail$n)

df = df[!(df$workerid %in% audio_fail$workerid),]

#comprehension questions -- 0 people excluded
comp1_fail = df[df$slide_type=="comprehension_check_1" & ((df$qud=="allQUD" & df$key!="Empty") | (df$qud=="anyQUD" & df$key!="Jam")),]
comp2_fail = df[df$slide_type=="comprehension_check_2" & ((df$qud=="allQUD" & df$key!="Empty") | (df$qud=="anyQUD" & df$key!="Jam")),]

table(comp1_fail$workerid)
table(comp2_fail$workerid)

df = df[!(df$workerid %in% comp2_fail$workerid),]

#accuracy<85 in non-critical trials -- 27 peope exluded
yes_list = c("summa2","summa5","summa8","summa11",
             "all13",
             "none0",
             "zero0","two2","five5","eight8","eleven11","thirteen13")

accuracy = df %>% 
  filter(str_detect(slide_type,"trial")) %>% 
  filter(str_detect(slide_type,"practice", negate = TRUE)) %>%
  mutate(concat = str_c(str_sub(audio,1,end=-5),image)) %>%
  filter(str_detect(concat,"summa13", negate = TRUE)) %>%
  mutate(rightAnswer = ifelse(concat %in% yes_list,"Yes","No")) %>%
  mutate(gaveRightAnswer = ifelse(key==rightAnswer,"1","0")) #%>%

acc = ggplot(accuracy,aes(x=key, fill=factor(gaveRightAnswer)))+
  geom_bar()+
  labs(title="Accuracy in all trials")#+
  facet_wrap(~workerid)

acc

#to make sure there are equal number of yes&no's
table(accuracy$rightAnswer)

table(accuracy$gaveRightAnswer)

#ggsave(acc, file="../graphs/subject_accuracy.pdf",width=25,height=25)

acc_prop = accuracy %>%
  group_by(workerid,slide_type) %>%
  summarise(proportion=mean(as.numeric(gaveRightAnswer)))

ggplot(acc_prop,aes(x=workerid, y=proportion, color=slide_type))+
  geom_point() +
  geom_hline(yintercept = .85)

low_accuracy = accuracy %>%
  group_by(workerid,gaveRightAnswer) %>%
  count(gaveRightAnswer) %>%
  mutate(accuracy=ifelse(gaveRightAnswer=="1",n*100/64,0)) %>%
  filter(gaveRightAnswer=="1") %>%
  filter(accuracy < 85)

low_accuracy

df = df[!(df$workerid %in% low_accuracy$workerid),]

#response times
#set rt to either raw response times or log response times
df$rt = df$rawRT
df$rt = df$logRT
#distribution of rt in experimental trials
trials = df %>%
  filter(str_detect(slide_type,"trial")) %>% 
  filter(str_detect(slide_type,"practice", negate = TRUE))

rt_dist = ggplot(trials, aes(x=rt,fill=key)) +
  geom_histogram(alpha=.3,position="identity") + #fill= hist_col,
  scale_x_continuous(breaks=seq(0,10000,400),limits=c(0,10000)) +
  facet_wrap(~qud)
            # xlab("log transformed response time") #+
            # facet_wrap(~workerid, scale="free")
            
rt_dist

#ggsave(rt_dist, file="../graphs/subject_rt_distributions.pdf",width=25,height=25)

tail(sort(trials$logRT),10)

slow_workers = trials %>% 
  mutate(slowResponse = logRT>20) %>%
  group_by(workerid) %>%
  count(slowResponse) %>%
  filter((slowResponse == TRUE)&(n>5))
slow_workers

#remove workers - if logRT>20 in more than 5 trials
df = df[!(df$workerid %in% slow_workers$workerid),]

#remove trials - if logRT>20 - TOTAL: 5 trials excluded (after fast_worker exclusion)
slow_trials = trials[trials$logRT>20,]
nrow(slow_trials)
df = df[!(df$logRT>20),]
trials = df %>%
  filter(str_detect(slide_type,"trial")) %>% 
  filter(str_detect(slide_type,"practice", negate = TRUE))

#Response time distribution -for non-critical trials
non_critical = trials %>%
  mutate(concat = str_c(str_sub(audio,1,end=-5),image)) %>%
  filter(str_detect(concat,"some13", negate = TRUE)) %>%
  filter(rawRT > 1000) %>%
  group_by(audio,image,key) %>%
  summarize(Median=median(rt),Mean=mean(rt),CILow=ci.low(rt),CIHigh=ci.high(rt),SD=sd(rt),Var=var(rt),count=n()) %>%
  ungroup() %>%
  mutate(YMin=Mean-CILow,YMax=Mean+CIHigh)

dodge = position_dodge(.9)

non_critical_rt = ggplot(non_critical,aes(x=image, y=Mean ,fill=key))+
  geom_bar(stat = "identity", position=dodge) +
  scale_fill_manual(values=key_col) +
  geom_errorbar(aes(ymin = YMin, ymax = YMax),width=.25,position=dodge) +
  ylab("mean rawRT") +
  geom_text(aes(label=count, y = 5),position=position_dodge(width=1),vjust=0,size=3) +
  #scale_y_continuous(limits=c(0,10000)) +
  facet_wrap(~audio, scales="free_x")

non_critical_rt

##########################################################################################
#CRITICAL TRIALS
critical = df %>% 
  filter(str_detect(slide_type,"trial")) %>% 
  filter(str_detect(slide_type,"practice", negate = TRUE))  %>%
  filter(str_detect(audio,"summa.wav")) %>%
  filter(str_detect(image,"13")) %>%
  droplevels()

length(unique(critical$workerid)) #458 (58 people excluded)
nrow(critical) #3663 (458*8=4664) one trial exluded 

#response type (change speaker_cond with qud)
rtype = critical %>%
  mutate(semantic = ifelse(key=="Yes",1,0)) %>%
  group_by(qud) %>%
  summarise(Proportion=mean(semantic),CILow=ci.low(semantic),CIHigh=ci.high(semantic)) %>%
  ungroup() %>%
  mutate(YMin=Proportion-CILow,YMax=Proportion+CIHigh)

#proportion of semantic responses
ggplot(rtype, aes(x = qud, y=Proportion)) +
  geom_bar(stat="identity", fill = cond_col[4]) +
  geom_errorbar(aes(ymin=YMin, ymax=YMax, width=.25)) +
  ylab("Proportion of semantic responses") #+
  mutate(Answer.condition = fct_relevel(Answer.condition,"no_QUD","any_QUD"))

#trial1 vs trial2
rtype = critical %>%
  mutate(semantic = ifelse(key=="Yes",1,0)) %>%
  group_by(speaker_cond,slide_type) %>%
  summarise(Proportion=mean(semantic),CILow=ci.low(semantic),CIHigh=ci.high(semantic)) %>%
  ungroup() %>%
  mutate(YMin=Proportion-CILow,YMax=Proportion+CIHigh) %>%
  mutate(slide_type_rename = ifelse(slide_type=="trial_1","first_32", ifelse(slide_type=="trial_2", "last_32", slide_type)))

ggplot(rtype, aes(x=speaker_cond, y=Proportion,fill=speaker_cond)) +
  geom_bar(stat="identity") +
  scale_fill_manual(values=cond_col) +
  geom_errorbar(aes(ymin=YMin, ymax=YMax, width=.25)) +
  ylab("Proportion of semantic responses") +
  facet_wrap(~slide_type_rename)

#age buckets
rtype = critical %>%
  mutate(semantic = ifelse(key=="Yes",1,0)) %>%
  left_join(demo,by = c("workerid")) %>%
  group_by(qud,age_group) %>%
  summarise(Proportion=mean(semantic),CILow=ci.low(semantic),CIHigh=ci.high(semantic),count=n()) %>%
  ungroup() %>%
  mutate(YMin=Proportion-CILow,YMax=Proportion+CIHigh) #%>%
  mutate(speaker_cond = fct_relevel(Answer.condition,"no_QUD","any_QUD"))

age_judgement = ggplot(rtype, aes(x = qud, y=Proportion, fill=qud)) +
  geom_bar(stat="identity") +
  scale_fill_manual(values = cond_col) +
  geom_errorbar(aes(ymin=YMin, ymax=YMax, width=.25)) +
  ylab("Proportion of semantic responses")+
  facet_wrap(~age_group) +
  #geom_text(aes(label=count),nudge_x=0.2)
  geom_text(aes(label=count, y = 0),position=position_dodge(width=1),vjust=0,size=3) #+
  mutate(Answer.condition = fct_relevel(qud,"no_QUD","any_QUD"))

age_judgement

#ggsave(age_judgement, file="../graphs/age_judgement.pdf")

#distribution of participants over number of semantic responses
d = critical %>%
  group_by(workerid,key,.drop=FALSE) %>%
  count() %>% 
  filter(key=="Yes") %>%
  merge(critical[ ,c("workerid","qud")], by="workerid",all.x=TRUE) %>%
  #filter(Answer.condition=="no_QUD") %>%
  unique()

table(d$qud,d$n)

ggplot(d, aes(x=n,fill=qud)) +
  scale_fill_manual(values = cond_col) +
  geom_histogram(position="dodge") +
  xlab("Number of semantic responses") +
  scale_x_continuous(breaks=c(0:8))+
  labs(fill = "QUD") #+
  facet_wrap(~key)
  
#response time
critical$rt = critical$logRT
critical$rt = critical$rawRT

ggplot(critical, aes(x=rt)) +
  geom_histogram(fill = hist_col) 

agr = critical %>%
  group_by(qud,key) %>%
  summarize(Median=median(rt),Mean=mean(rt),CILow=ci.low(rt),CIHigh=ci.high(rt),SD=sd(rt),Var=var(rt),count=n()) %>%
  ungroup() %>%
  mutate(YMin=Mean-CILow,YMax=Mean+CIHigh)

dodge = position_dodge(.9)

#yes/no rt means with qud
mean_rt = ggplot(agr, aes(fill=key,x=qud,y=Mean)) +
  geom_bar(stat="identity",position=dodge) +
  scale_fill_manual(values = key_col) +
  geom_errorbar(aes(ymin = YMin, ymax = YMax),width=.25,position=dodge) +
  ylab("mean rawRT")+
  #geom_point(data=agr2, aes(color = as.factor(workerid)),alpha=.2) +
  #geom_line(data=critical, aes(y = rt, group= as.factor(workerid),color = as.factor(workerid)),alpha=.2)+
  geom_text(aes(label=count, y = 5),position=position_dodge(width=1),vjust=0,size=3)
mean_rt

#ggsave(mean_rt, file="../graphs/mean_rt.pdf")

#yes/no rt means with responder type & qud
responder = critical %>%
  group_by(workerid,key, .drop=FALSE) %>%
  count(key) %>%
  filter(key=="Yes") %>%
  mutate(responder_type = ifelse(n>4,"semantic",ifelse(n<4,"pragmatic",ifelse(n==4,"inconsistent","NA"))))

table(responder$n)

agr2 = critical %>%
  merge(responder[ ,c("workerid","responder_type")], by="workerid",all.x=TRUE) %>%
  #merge(demo[ ,c("workerid","age")], by="workerid",all.x=TRUE) %>%
  #mutate(age_bucket = ifelse(age<=25,"0-25",ifelse(age>25,"25+",NA))) %>%
  group_by(qud,key,responder_type,age_group) %>%
  #group_by(qud,key,age_group) %>% 
  summarize(Median=median(rt),Mean=mean(rt),CILow=ci.low(rt),CIHigh=ci.high(rt),SD=sd(rt),Var=var(rt),count=n()) %>%
  ungroup() %>%
  mutate(YMin=Mean-CILow,YMax=Mean+CIHigh)

mean_responder_rt = ggplot(agr2, aes(fill=key,x=qud,y=Mean)) +
  geom_bar(stat="identity",position=dodge) +
  scale_fill_manual(values = key_col) +
  geom_errorbar(aes(ymin = YMin, ymax = YMax),width=.25,position=dodge) +
  facet_grid(age_group~responder_type)+
  #facet_wrap(~responder_type)+
  #facet_wrap(~age_bucket) +
  geom_text(aes(label=count, y = 5),position=position_dodge(width=1),vjust=0,size=3)

mean_responder_rt

#ggsave(mean_responder_rt, file="../graphs/mean_responder_rt.pdf")

#yes/no rt means with responder semanticity and QUD (remove)
semanticity = critical %>%
  modify_if(is.integer, as.factor) %>%
  group_by(workerid) %>%
  summarize(Median=median(rt),Mean=mean(rt),CILow=ci.low(rt),CIHigh=ci.high(rt),SD=sd(rt),Var=var(rt),count=n()) %>%
  ungroup() %>%
  mutate(YMin=Mean-CILow,YMax=Mean+CIHigh) %>%
  merge(responder[ ,c("workerid","n")], by="workerid",all.x=TRUE) %>%
  merge(critical[ ,c("workerid","qud")], by="workerid",all.x=TRUE)

mean_semanticity_rt = ggplot(semanticity, aes(x=n, y=Mean, color=factor(qud))) +
  geom_point(alpha=.2) +
  scale_color_manual(values=age_col) +
  scale_x_continuous(breaks=c(0:8)) +
  xlab("Number of semantic responses")+
  ylab("Mean rawRT")
mean_semanticity_rt

#ggsave(mean_semanticity_rt, file="../graphs/mean_semanticity_rt.pdf")

#yes/no rt means with age
agr3 = critical %>%
  group_by(qud,key,age_group) %>%
  summarize(Median=median(rt),Mean=mean(rt),CILow=ci.low(rt),CIHigh=ci.high(rt),SD=sd(rt),Var=var(rt),count=n()) %>%
  ungroup() %>%
  mutate(YMin=Mean-CILow,YMax=Mean+CIHigh)

mean_age_rt = ggplot(agr3, aes(fill=key,x=qud,y=Mean)) +
  geom_bar(stat="identity",position=dodge) +
  scale_fill_manual(values = key_col) +
  geom_errorbar(aes(ymin = YMin, ymax = YMax),width=.25,position=dodge) +
  theme(plot.title = element_text(hjust =0.5),axis.text.x=element_text(angle=45,hjust=1,vjust=1))+
  facet_wrap(~age_group) +
  geom_text(aes(label=count, y = 5),position=position_dodge(width=1),vjust=0,size=3)

mean_age_rt

#ggsave(mean_age_rt, file="../graphs/mean_age_rt.pdf")

#age groups
times = trials %>%
  group_by(workerid) %>%
  mutate(meanRT=mean(rawRT)) %>%
  left_join(demo,by = c("workerid")) %>%
  select(workerid,meanRT,age,age_group) %>%
  unique()

ggplot(times, aes(x=age, y=meanRT)) +
  geom_point(color=age_col[2])+
  geom_smooth(method="lm",color=age_col[4])

length(unique(times$workerid))

#ANALYSIS##########################################################################
library(tidyverse)
library(lme4)
library(languageR)
library(brms)

# 1) Mixed effects logistic regression predicting response type with random by-participant intercepts, from fixed effects of QUD
# prediction: main effect of QUD such that there are more pragmatic responses for all-QUD compared to any-QUD and no-QUD
m = glmer(key ~ Answer.condition + (1|workerid), data=critical, family="binomial")
summary(m)

#BRMS key should be 0 and 1, than center!
critical = critical %>%
  mutate(numericKey = ifelse(key == "Yes",1,0))

m2 = brm(key ~ Answer.condition + (1|workerid), save_all_pars=TRUE, data=critical, iter=1000, family="binomial")
summary(m2)


#######
age_critical = critical %>%
  left_join(demo,by = c("workerid")) %>%
  mutate(age_bucket = ifelse(age<=25,0,ifelse(age>25,1,NA))) %>%
  mutate(cagebucket=age_bucket-mean(age_bucket),cage=age-mean(age))

contrasts(age_critical$Answer.condition) = cbind("all.vs.no"=c(1,0,0),"any.vs.no"=c(0,1,0))

mage = glmer(key ~ Answer.condition*cagebucket + (1|workerid), data=age_critical, family="binomial")
summary(mage)

table(age_critical$age_bucket)

mage = glmer(key ~ Answer.condition*cage + (1|workerid), data=age_critical, family="binomial")
summary(mage)

##????#####
m = glmer(key ~ Answer.condition, family=binomial(link='logit',data=critical))

# 2) Mixed effects linear regression model with random by-participant intercepts predicting log-transformed response time from fixed effects of QUD, response type and their interaction
# prediction: interaction of QUD and response such that the more relevant the alternative, the faster the pragmatic responses become and the slower the semantic responses become

# add REML=F for p value
#m.all=lmer(logRT ~ Answer.condition + key + Answer.condition*key + (1|workerid), data=critical)

m.all=lmer(logRT ~ Answer.condition*key + (1|workerid), data=critical)
summary(m.all)

#############################################################################

m.qud=lmer(logRT ~ Answer.condition + (1|workerid), data=critical)
summary(m.qud)

m.key=lmer(logRT ~ key + (1|workerid), data=critical)
summary(m.key)
