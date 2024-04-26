rm(list = ls())
library(LSAfun)
library(dplyr)
library(rstatix)
library(ggplot2)
library(lmerTest)

# Set working dir
this.dir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(this.dir)

# Load semantic space
load("../../../../semantic_spaces/baroni.rda") # baroni 	 English cbow space, 400 dimensions (not downloaded yet)

# Read clean data
df <- read.csv("cleaned_completions.csv")

# Noun and Answer as character
df$Item <- as.character(df$Item)
df$Answer <- as.character(df$Answer)

# Check if the words are in the space
df <- df[df$Answer %in% rownames(baroni),]
df <- df[df$Item %in% rownames(baroni),]
df <- droplevels(df)

# ADD COS SIMILIARITY SCORES TO DATAFRAME
# baroni 	 English cbow space, 400 dimensions (not downloaded yet)
cos_sim <- function(w1, w2){
  return(Cosine(w1, w2, tvectors = baroni))
}
df <- cbind(df, Cos.Sim.baroni = mapply(cos_sim, df$Item, df$Answer))

# aggregate by subject and polarity
df.subj <- df %>%
  group_by(Subject, Polarity) %>%
  get_summary_stats(Cos.Sim.baroni, type = "mean_sd")

# factors
df$Polarity <- as.factor(df$Polarity)
df$Subject <- as.factor(df$Subject)
df$Item <- as.factor(df$Item)

# plot
names(df.subj)[names(df.subj) == "mean"] <- "mean.sim"
se <- function(x) sqrt(var(x)/length(x))
to.plot <- group_by(df.subj, Polarity) %>%
  summarise(
    count = n(),
    mean = mean(mean.sim, na.rm = TRUE),
    sd = sd(mean.sim, na.rm = TRUE),
    se = se(mean.sim)
  )

ggplot(to.plot, aes(x=Polarity, y=mean, fill=Polarity)) + 
  theme(text = element_text(size = 20)) +
  ylab("Mean Similarity X-Y") +
  geom_bar(position=position_dodge(), stat="identity") +
  geom_errorbar(aes(ymin=mean-se, ymax=mean+se), width=.2,
                position=position_dodge(.9))


######## 4. LMEM ########
# main effect of Polarity
m <- lmer(Cos.Sim.baroni ~ Polarity +
            (1 + Polarity|Item), data = df, REML = FALSE)
summary(m)