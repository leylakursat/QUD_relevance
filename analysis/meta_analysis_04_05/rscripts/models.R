library(tidyverse)
library(lme4)
library(languageR)
library(brms)
library(lmerTest)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd('../data/')

exp1 <- read.csv("experiment4_critical.csv")
exp2 <- read.csv("experiment5_critical.csv")

#exp1 is with summa, exp2 is with some
df = exp1
#df = exp2

# 1.JUDGEMENTS - Mixed effects logistic regression predicting response type with random by-participant intercepts, from fixed effects of QUD
df = df %>%
  mutate(numericKey = ifelse(key == "Yes",1,0)) %>%
  mutate(numericKey = as.factor(numericKey)) %>%
  mutate(ckey = as.numeric(key) - mean(as.numeric(key)))

m = glmer(numericKey ~ Answer.condition + (1|workerid), data=df, family="binomial")
summary(m)

# 2.RESPONSE TIME - Mixed effects linear regression model with random by-participant intercepts predicting log-transformed response time from fixed effects of QUD, response type and their interaction
m2=lmer(logRT ~ Answer.condition*ckey + (1|workerid), data=df)
summary(m2)

# Helmert coding 
df$Answer.condition = as.factor(df$Answer.condition)
df$qud.Helm <- df$Answer.condition

contrasts(df$qud.Helm)<-cbind("all.vs.any"=c(-.5,.5,0), "all.vs.rest"=c(-(1/3),-(1/3),(2/3)))

m8 = lmer(logRT ~ qud.Helm + (1|workerid), data=df)
summary(m8)

# 3.RESPONDER TYPE - Mixed effects linear regression model with random by-participant intercepts predicting log-transformed response time from fixed effects of QUD, response type, responder type and their interaction
responder = df %>%
  group_by(workerid,key, .drop=FALSE) %>%
  count(key) %>%
  filter(key=="No") %>%
  mutate(responder_type = ifelse(n>4,"pragmatic",ifelse(n<4,"semantic",ifelse(n==4,"inconsistent","NA"))))

df_cresponder = df %>%
  merge(responder[ ,c("workerid","responder_type","n")], by="workerid",all.x=TRUE) %>%
  filter(responder_type != "inconsistent") %>%
  mutate(responder_type = as.factor(responder_type)) %>%
  mutate(cresponder_type = as.numeric(responder_type) - mean(as.numeric(responder_type)), ckey = as.numeric(key) - mean(as.numeric(key)))

#contrasts(df_cresponder$key)
#contrasts(df_cresponder$Answer.condition)
#contrasts(df_cresponder$responder_type)
#table(df_cresponder$responder_type)
#table(df_cresponder$key)

m3 = lmer(logRT ~ Answer.condition*cresponder_type*ckey + (1+ckey|workerid), data=df_cresponder)
summary(m3)

m4 = lmer(logRT ~ cresponder_type*ckey + (1+ckey|workerid), data=df_cresponder)
summary(m4)

anova(m3,m5) #to see if Answer condition adds anything

m5 = lmer(logRT ~ Answer.condition*ckey + Answer.condition*cresponder_type + Answer.condition + cresponder_type:ckey + (1+ckey|workerid), data=df_cresponder)
summary(m5)

#model to focus on (keep the main effect of answer.condition)
m10 = lmer(logRT ~ Answer.condition*ckey + Answer.condition + cresponder_type + cresponder_type:ckey + (1+ckey|workerid), data=df_cresponder)
summary(m10)

anova(m5,m10)

m11 = lmer(logRT ~ ckey + Answer.condition + cresponder_type + cresponder_type:ckey + (1+ckey|workerid), data=df_cresponder)
summary(m11)

#used model selection to determine best model

anova(m11,m10) #getting rid of answer.condition*key interaction -> significant

m12 = lmer(logRT ~ Answer.condition:ckey + ckey + cresponder_type + cresponder_type:ckey + (1+ckey|workerid), data=df_cresponder)
summary(m12)
 
anova(m10,m12) #removing main effect of answer.cond doesn't change

m6 = lmer(logRT ~ Answer.condition + cresponder_type + ckey + Answer.condition:cresponder_type + Answer.condition:ckey + cresponder_type:ckey + (1+ckey|workerid), data=df_cresponder)
summary(m5)

# 4.PRAGMATICITY - ?????
m7 = lmer(logRT ~ Answer.condition*n*ckey + (1|workerid), data=df_pragmaticity)
summary(m7)

#only for all and any
allany = df_cresponder %>%
  filter(Answer.condition != "no_QUD") %>%
  mutate(cresponder_type = as.numeric(responder_type) - mean(as.numeric(responder_type)), ckey = as.numeric(key) - mean(as.numeric(key)), cAnswer.condition = as.numeric(Answer.condition) - mean(as.numeric(Answer.condition))) %>%
  droplevels()

m9=lmer(logRT ~ Answer.condition + (1|workerid), data=allany)
summary(m9)

