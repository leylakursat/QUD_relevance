library(tidyverse)
library(lme4)
library(languageR)
library(brms)
library(lmerTest)

theme_set(theme_bw())

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd('../data/')
source('../rscripts/helpers.R')

#cbPalette <- c("#000000", "#009E73", "#e79f00", "#9ad0f3", "#0072B2", "#D55E00","#CC79A7", "#F0E442")
cbPalette <- c("#000000", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

#with no QUD
#exp1 <- read.csv("experiment4_critical.csv")
#exp2 <- read.csv("experiment5_critical.csv")

#without no QUD
exp1 <- read.csv("experiment6_critical.csv") %>%
  #select(-X.1,-X) %>%
  rename(quantifier=audio) %>%
  mutate(quantifier=fct_recode(quantifier,"some of"="summa.wav")) %>%
  mutate(new_rt=rt-868)

exp2 <- read.csv("experiment7_critical.csv") %>%
  #select(-X.1,-X) %>%
  rename(quantifier=audio) %>%
  mutate(quantifier=fct_recode(quantifier,"some"="some.wav"),workerid = workerid + 800) %>% # add number of participants in exp1 to exp2 so they're unique
  mutate(new_rt=rt-735)

##########################################################################
#exp1 is with summa, exp2 is with some
#df = exp1
#df = exp2

df = bind_rows(exp1,exp2) %>%
  droplevels() %>%
  mutate(quantifier = as.factor(as.character(quantifier))) %>%
  mutate(logNRT = log(new_rt)) 

# 1.JUDGEMENTS - Mixed effects logistic regression predicting response type with random by-participant intercepts, from fixed effects of QUD
df = df %>%
  mutate(qud=fct_recode(Answer.condition,"any-QUD"="any_QUD","all-QUD"="all_QUD")) %>%
  mutate(qud=fct_relevel(qud,"any-QUD")) %>%
  mutate(numericKey = ifelse(key == "Yes",1,0)) %>%
  mutate(numericKey = as.factor(numericKey)) %>%
  mutate(ckey = as.numeric(key) - mean(as.numeric(key))) %>%
  mutate(response = as.factor(ifelse(key == "Yes","literal","pragmatic")),cqud=as.numeric(qud)-mean(as.numeric(qud)),cquantifier=as.numeric(quantifier)-mean(as.numeric(quantifier)))

m = glmer(response ~ cqud*cquantifier + (1|workerid), data=df, family="binomial")
summary(m)

m.simple = glmer(response ~ quantifier*qud - qud + (1|workerid), data=df, family="binomial")
summary(m.simple) # simple effects show that the interaction in the model above is due to the qud effect being bigger for the "some" than the "some of" condition

# separately for the two quantifiers (for CogSci paper)
df_some = df %>%
  filter(quantifier == "some") %>%
  droplevels()

m.some = glmer(response ~ cqud + (1|workerid), data=df_some, family="binomial")
summary(m.some)

df_summa = df %>%
  filter(quantifier == "some of") %>%
  droplevels()

m.summa = glmer(response ~ cqud + (1|workerid), data=df_summa, family="binomial")
summary(m.summa)

# re-plot judgments
df$PragmaticResponse = ifelse(df$response == "pragmatic", 1, 0)

toplot = df %>%
  mutate(quantifier=fct_recode(quantifier,"Exp. 1: some of"="some of","Exp. 2: some"="some")) %>%
  group_by(qud,quantifier) %>%
  summarise(Mean=mean(PragmaticResponse),CILow=ci.low(PragmaticResponse),CIHigh=ci.high(PragmaticResponse)) %>%
  ungroup() %>%
  mutate(YMin=Mean-CILow,YMax=Mean+CIHigh) 

#reorder quantifier levels
toplot$quantifier_re <- factor(toplot$quantifier, levels = c("Exp. 1: some of","Exp. 2: some"))

ggplot(toplot, aes(x=qud,y=Mean,fill=qud)) +
  geom_bar(stat="identity") +
  scale_fill_manual(values=cbPalette[2:3]) +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25) +
  xlab("QUD") +
  ylab("Proportion of pragmatic responses") +
  facet_wrap(~quantifier_re) +
  theme(axis.text.x=element_text(angle=15,hjust=1,vjust=1)) +
  guides(fill=FALSE)
ggsave("../graphs/fig1.png",width=3,height=2.7)

###plot proportion of participants and number of pragmatic answers
pragmaticity = df %>%
  group_by(workerid,response,.drop=FALSE) %>%
  summarize(numPragmatic = n()) %>%
  filter(response=="pragmatic") %>%
  merge(df[ ,c("workerid","qud","quantifier")], by="workerid",all.x=TRUE) %>%
  unique() %>%
  mutate(quantifier=fct_recode(quantifier,"Exp. 1: some of"="some of","Exp. 2: some"="some")) %>%
  group_by(quantifier,numPragmatic,qud) %>%
  #group_by(quantifier,numPragmatic) %>%
  tally() %>%
  group_by(qud,quantifier) %>%
  #group_by(quantifier)%>%
  mutate(total=sum(n)) %>%
  mutate(proportion=n/total)

pragmaticity$quantifier_re <- factor(pragmaticity$quantifier, levels = c("Exp. 1: some of","Exp. 2: some"))

ggplot(pragmaticity, aes(x=numPragmatic, y=proportion, fill=qud)) +
  geom_bar(stat="identity", position = position_dodge(.6), width = 0.6) +
  scale_fill_manual(values=cbPalette[2:3]) +
  xlab("Number of pragmatic responses") +
  ylab("Proportion of participants ") +
  labs(fill="QUD") +
  scale_x_continuous(breaks=c(0:8)) +
  theme(axis.text.y=element_text(size=10), axis.title=element_text(size=12), axis.text.x=element_text(size=10), legend.position = "bottom") +
  facet_wrap(~quantifier_re, nrow = 2) +
  ylim(0,0.6)

ggsave("../graphs/fig4.png",width=5,height=5)

# 2.RESPONSE TIME - Mixed effects linear regression model with random by-participant intercepts predicting log-transformed response time from fixed effects of QUD, response type and their interaction

# this analysis needs to be done separately for the two quantifiers because the stims differ in length
d.some = df %>%
  filter(quantifier == "some") %>%
  droplevels() %>%
  mutate(ckey = as.numeric(key) - mean(as.numeric(key))) %>%
  mutate(cqud=as.numeric(qud)-mean(as.numeric(qud)),cresponse=as.numeric(response)-mean(as.numeric(response)))

m.some=lmer(logRT ~ cqud*cresponse + (1|workerid), data=d.some,REML=F)
summary(m.some)

d.summa = df %>%
  filter(quantifier == "some of") %>%
  droplevels() %>%
  mutate(ckey = as.numeric(key) - mean(as.numeric(key))) %>%
  mutate(cqud=as.numeric(qud)-mean(as.numeric(qud)),cresponse=as.numeric(response)-mean(as.numeric(response)))

m.summa=lmer(logRT ~ cqud*cresponse + (1|workerid), data=d.summa,REML=F)
summary(m.summa)

#### if we do it together with new response times
d.tog = df %>%
  filter(new_rt>0) %>%
  mutate(ckey = as.numeric(key) - mean(as.numeric(key))) %>%
  mutate(cquantifier=as.numeric(quantifier)-mean(as.numeric(quantifier))) %>%
  mutate(cresponse=as.numeric(response)-mean(as.numeric(response))) %>%
  mutate(cqud=as.numeric(qud)-mean(as.numeric(qud)))

m.tog=lmer(logNRT ~ cquantifier*cresponse + (1|workerid), data=d.tog,REML=F)
summary(m.tog)

####
# Helmert coding (not necessary when there are only two conditions)
# df$Answer.condition = as.factor(df$Answer.condition)
# df$qud.Helm <- df$Answer.condition
# 
# contrasts(df$qud.Helm)<-cbind("all.vs.any"=c(-.5,.5,0), "all.vs.rest"=c(-(1/3),-(1/3),(2/3)))
# 
# m8 = lmer(logRT ~ qud.Helm + (1|workerid), data=df)
# summary(m8)

# 3.RESPONDER TYPE - Mixed effects linear regression model with random by-participant intercepts predicting log-transformed response time from fixed effects of QUD, response type, responder type and their interaction
responder = df %>%
  group_by(workerid,key, .drop=FALSE) %>%
  count(key) %>%
  filter(key=="No") %>%
  mutate(responder_type = ifelse(n>4,"pragmatic",ifelse(n<4,"literal",ifelse(n==4,"inconsistent","NA"))))

responder$quantifier = ifelse(responder$workerid < 800, "summa","some")

prop.table(table(responder$quantifier,responder$responder_type),mar=c(1))

df_cresponder = df %>%
  merge(responder[ ,c("workerid","responder_type","n")], by="workerid",all.x=TRUE) %>%
  filter(responder_type != "inconsistent") %>%
  filter(new_rt>0) %>%
  mutate(responder_type = relevel(as.factor(responder_type),"literal"))

df_cresponder.tog = d.tog %>%
  merge(responder[ ,c("workerid","responder_type","n")], by="workerid",all.x=TRUE) %>%
  filter(responder_type != "inconsistent") %>%
  filter(new_rt>0) %>%
  mutate(responder_type = relevel(as.factor(responder_type),"literal"))

df_full = df_cresponder %>%
  mutate(cqud=as.numeric(qud)-mean(as.numeric(qud)),cresponse=as.numeric(response)-mean(as.numeric(response)),cresponder_type = as.numeric(responder_type) - mean(as.numeric(responder_type)))

df_full.tog = df_cresponder.tog %>%
  mutate(cqud=as.numeric(qud)-mean(as.numeric(qud)),cresponse=as.numeric(response)-mean(as.numeric(response)),cresponder_type = as.numeric(responder_type) - mean(as.numeric(responder_type)))

# model reported in ELM abstract
m.full=lmer(logRT ~ cquantifier*cqud*cresponse*cresponder_type + (1|workerid), data=df_full,REML=F)
summary(m.full)

# full model with new RT
m.full_rt=lmer(logNRT ~ cquantifier*cqud*cresponse*cresponder_type + (1|workerid), data=df_full.tog,REML=F)
summary(m.full)

# simple with new rt
m.some.simple.quant=lmer(logRT ~ responder_type*response*qud*quantifier - quantifier + (1|workerid), data=df_full.tog,REML=F)
summary(m.some.simple.quant)

# to run the full models separately:
d.some = df_cresponder %>%
  filter(quantifier == "some") %>%
  droplevels() %>%
  mutate(cqud=as.numeric(qud)-mean(as.numeric(qud)),cresponse=as.numeric(response)-mean(as.numeric(response)),cresponder_type = as.numeric(responder_type) - mean(as.numeric(responder_type)))

m.some=lmer(logRT ~ cqud*cresponse*cresponder_type + (1|workerid), data=d.some,REML=F)
summary(m.some)

# effect of lit-to-prag for diff respondertypes
m.some.simple.rt=lmer(logRT ~ responder_type*qud*response - response + (1|workerid), data=d.some,REML=F)
summary(m.some.simple.rt)

# effect of lit-to-prag for diff quds
m.some.simple.q=lmer(logRT ~ qud*responder_type*response - response + (1|workerid), data=d.some,REML=F)
summary(m.some.simple.q)


d.summa = df_cresponder %>%
  filter(quantifier == "some of") %>%
  droplevels() %>%
  mutate(cqud=as.numeric(qud)-mean(as.numeric(qud)),cresponse=as.numeric(response)-mean(as.numeric(response)),cresponder_type = as.numeric(responder_type) - mean(as.numeric(responder_type)))

m.summa=lmer(logRT ~ cqud*cresponse*cresponder_type + (1|workerid), data=d.summa,REML=F)
summary(m.summa)

m.summa=lmer(logRT ~ qud*response*responder_type + (1|workerid), data=d.summa,REML=F)
summary(m.summa)

# effect of lit-to-prag for diff respondertypes
m.summa.simple=lmer(logRT ~ responder_type*qud*response - response + (1|workerid), data=d.summa,REML=F)
summary(m.summa.simple)

# effect of lit-to-prag for diff quds
m.summa.simple=lmer(logRT ~ qud*responder_type*response - response + (1|workerid), data=d.summa,REML=F)
summary(m.summa.simple)

# plot response times
toplot = df_cresponder %>%
  mutate(quantifier=fct_recode(quantifier,"Exp. 1: some of"="some of","Exp. 2: some"="some")) %>%
  group_by(qud,quantifier,responder_type,response) %>%
  summarise(Mean=mean(rt),CILow=ci.low(rt),CIHigh=ci.high(rt)) %>%
  ungroup() %>%
  mutate(YMin=Mean-CILow,YMax=Mean+CIHigh) %>%
  mutate(responder=fct_recode(responder_type,"literal responders"="literal","pragmatic responders"="pragmatic"))
dodge = position_dodge(.9)

toplot$quantifier_re <- factor(toplot$quantifier, levels = c("Exp. 1: some of","Exp. 2: some"))

ggplot(toplot, aes(x=qud,y=Mean,alpha=response,fill=qud)) +
  geom_bar(stat="identity",position=dodge) +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position=dodge) +
  scale_fill_manual(values=cbPalette[2:3],guide='none') +
  scale_alpha_discrete(range=c(0.4, 1), name="Response") +
  xlab("QUD") +
  ylab("Mean response time (ms)") +
  facet_wrap(~quantifier_re+responder,nrow=2) +
  theme(axis.text.x=element_text(angle=15,hjust=1,vjust=1),legend.position="bottom",plot.margin=unit(c(0,0,0,0),"pt"),legend.margin=margin(-10,0,0,0))

ggsave("../graphs/fig2.png",width=4.3,height=4.5)
# ggsave("../graphs/fig2.png",width=6.5,height=6.5)
ggsave("../../../papers/cogsci2020/plots/responsetimes.pdf",width=4.3,height=4.5)

#plot response count and response times 
pragmaticity = df %>%
  group_by(workerid,response, .drop =FALSE) %>%
  summarize(numPragmatic = n()) %>%
  filter(response=="pragmatic")

toplot = df %>%
  merge(pragmaticity[ ,c("workerid","numPragmatic")], by="workerid",all.x=TRUE) %>%
  group_by(numPragmatic) %>%
  summarise(Mean = mean(rt), CILow=ci.low(rt),CIHigh=ci.high(rt))%>%
  ungroup() %>%
  mutate(YMin=Mean-CILow,YMax=Mean+CIHigh) 

#reorder quantifier levels
toplot$quantifier_re <- factor(toplot$quantifier, levels = c("some of","some"))

ggplot(toplot, aes(x=numPragmatic, y=Mean)) +
  geom_bar(fill="gray80",color="black",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.2,position=dodge) +
  xlab("Number of pragmatic responses") +
  ylab("Mean response time (ms)") +
  scale_x_continuous(breaks=c(0:8)) +
  ylim(0,2100) +
  #facet_grid(~quantifier_re) +
  theme(axis.text.x=element_text(hjust=1,vjust=1))
  
ggsave("../graphs/fig3.png",width=4,height=3)
