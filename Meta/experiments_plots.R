rm(list = ls())
library(LSAfun)
library(dplyr)
library(rstatix)
library(ggplot2)
library(lmerTest)
library(ggpattern)
library(ggsignif)

# Set working dir
this.dir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(this.dir)

# LOAD SPACE
load("../semantic_spaces/baroni.rda") # baroni 	 English cbow space, 400 dimensions (not downloaded yet)

# models
models <- c("Llama2-7b", "Llama2-7b-chat","Llama2-70b", "Llama2-70b-chat")

# experiments
experiments <- c("02_ClozeTask_within_this", "05_ClozeTask_within_see", "06_ClozeTask_within_want")

# read experiments data
df <- c()
for (model in models) {
  print(model)
  files_to_read = list.files(
    path = paste0("./", model, "/"),        # directory to search within
    pattern = "cleaned_completions.csv", # regex pattern, some explanation below
    recursive = TRUE,          # search subdirectories
    full.names = TRUE          # return the full path
  )
  print(files_to_read)
  dfs <- lapply(files_to_read, read.csv)
  
  for (i in seq(1,3)) {
    dfs[[i]]$Experiment <- experiments[i]
  }
  # merge all dfs in one
  temp <- bind_rows(dfs)
  temp$Model <- model
  df <- rbind(df, temp)
}

# Noun and Answer as character
df$Item <- as.character(df$Item)
df$Answer <- as.character(df$Answer)

# for comparison I use only the words that are in EVERY space
df <- df[df$Answer %in% rownames(baroni),]
df <- df[df$Item %in% rownames(baroni),]
df <- droplevels(df)

# ADD COS SIMILIARITY SCORES TO DATAFRAME
# baroni 	 English cbow space, 400 dimensions (not downloaded yet)
cos_sim <- function(w1, w2){
  return(Cosine(w1, w2, tvectors = baroni))
}
df <- cbind(df, Cos.Sim.baroni = mapply(cos_sim, df$Item, df$Answer))

# factors
df$Polarity <- as.factor(df$Polarity)
df$Experiment <- as.factor(df$Experiment)
df$Model <- as.factor(df$Model)

# aggregate by experiment x subject x polarity
df.item <- df %>%
  group_by(Experiment, Model, Item, Polarity) %>%
  get_summary_stats(Cos.Sim.baroni, type = "mean_sd")

# plot
names(df.item)[names(df.item) == "mean"] <- "mean.sim"
se <- function(x) sqrt(var(x)/length(x))
to.plot <- group_by(df.item, Experiment, Model, Polarity) %>%
  summarise(
    count = n(),
    mean = mean(mean.sim, na.rm = TRUE),
    sd = sd(mean.sim, na.rm = TRUE),
    se = se(mean.sim)
  )

# read human data
to.plot.humans <- read.csv("../Humans/human_experiment_plot_data.csv")
to.plot.humans$Model <- "Humans"

# experiments
to.plot$Experiment <- recode_factor(to.plot$Experiment,
                                    "02_ClozeTask_within_this"  = "3\n this", 
                                   "05_ClozeTask_within_see" = "6\n see",
                                   "06_ClozeTask_within_want" = "7\n want")

# merge
to.plot <- rbind(to.plot, data.frame(to.plot.humans))

# factors
to.plot$Polarity <- as.factor(to.plot$Polarity)
to.plot$Experiment <- as.factor(to.plot$Experiment)
to.plot$Model <- as.factor(to.plot$Model)
to.plot$Model <- ordered(to.plot$Model, levels =  c("Llama2-7b", "Llama2-7b-chat", "Llama2-70b", "Llama2-70b-chat", "Humans"))

jpeg("overall_plot_meta.jpeg", width = 800, height = 800)
ggplot(to.plot, aes(x=Model, y=mean, width=.35)) + 
  ylab("Mean Similarity X-Y") +
  geom_bar_pattern(aes(pattern=Polarity), position="dodge", stat="identity", fill="white", colour="black", pattern_key_scale_factor=.5) +
  geom_signif(stat="identity",
              data=data.frame(Experiment = rep(c("3\n this", "6\n see", "7\n want"), each=5),
                              x=rep(c(0.875, 1.875, 2.875, 3.875, 4.875), 3),
                              xend=rep(c(1.125, 2.125, 3.125, 4.125, 5.125), 3),
                              y=rep(c(.55), 15),
                              annotation=c("**", " *** ", "   n.s.   ", "   ***  ", " n.s. ",
                                           "n.s.", " *** ", " * ", "**", "***",
                                           "n.s.", "* ", " n.s. ", " * ", "***"),
                              tip_length=0,
                              manual=T),
  aes(x=x,xend=xend, y=y, yend=y, annotation=annotation, textsize = 5)) +
  geom_errorbar(aes(pattern=Polarity, ymin=mean-se, ymax=mean+se), width=.2,
                position=position_dodge(.35)) +
  ylim(0,.6) +
  facet_wrap(~Experiment, dir = "v") +
  theme_bw() +
  theme(text = element_text(size = 20))
dev.off()