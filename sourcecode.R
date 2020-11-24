


# load package ------------------------------------------------------------

library(tidyverse)
library(tidytext)

# read data finishing location cleaning -----------------------------------
rm(list = ls())

raw.data <- 
  read.csv("./Process/data_usa_states.csv", row.names = NULL) %>% tibble()

data.statesinfo <- 
  read.csv("./input/StatesInformation.csv", row.names = NULL) %>% tibble()

data.covid <- 
  read_csv("./input/StatesHistorical.csv", 
           col_types = cols(date = col_character()))

# text cleaning -----------------------------------------------------------

text_clean <- function(unclean_tweets){
# input:    text vector
# output:   text vector
# purpose:  text cleaning
  head(unclean_tweets)
  tweet = gsub("&amp", "", unclean_tweets)
  tweet = gsub("(RT|via)((?:\\b\\W*@\\w+)+)", "", tweet)
  tweet = gsub("@\\w+", "", tweet)
  tweet = gsub("[[:punct:]]", "", tweet)
  tweet = gsub("[[:digit:]]", "", tweet)
  tweet = gsub("http\\w+", "", tweet)
  tweet = gsub("[ \t]{2,}", "", tweet)
  tweet = gsub("^\\s+|\\s+$", "", tweet) 
  head(tweet)
  clean <- function(x) {
    x %>%
      str_remove_all(" ?(f|ht)(tp)(s?)(://)(.*)[.|/](.*)") %>%
      str_replace_all("&amp;", "and") %>%
      str_remove_all("[[:punct:]]") %>%
      str_remove_all("^RT:? ") %>%
      str_remove_all("@[[:alnum:]]+") %>%
      str_remove_all("#[[:alnum:]]+") %>%
      str_replace_all("\\\n", " ") %>%
      str_to_lower() %>%
      str_trim("both")
  }
  tweets <- tweet %>% clean
  return(tweets)
}

tweets <- text_clean(raw.data$text)

head(tweets)
tail(tweets)


# sentiment analysis ------------------------------------------------------

senti_analysis <- function(tweets){
# input:    text vector
# output:   tibble with line index and SA score
# purpose:  calculate sentiment analysis score with bing lexicon
  tweets_df <- tibble(line = 1:length(tweets), tweets = tweets)
  
  # one token per row
  tweets_tidy <- tweets_df %>% 
    unnest_tokens(word, tweets) %>% 
    anti_join(stop_words, by = "word"); tweets_tidy
  
  # bing lexicon
  tweets_senti <- tweets_tidy %>% 
    inner_join(get_sentiments("bing"), by = "word") %>% 
    count(index = line, sentiment) %>% 
    spread(key = sentiment, value = n, fill = 0) %>% 
    mutate(sentiment = positive - negative) %>% 
    select(-positive, -negative); tweets_senti
  
  # inspect score
  tweets_senti %>% select(sentiment) %>% table()
  return(tweets_senti)
}

tweets_senti <- senti_analysis(tweets)

# dichotomy
tweets_senti <- tweets_senti %>%
  filter(sentiment != 0) %>%
  mutate(sentiment = as.numeric(sentiment>0))

# inspect dichotomy
tweets_senti %>% select(sentiment) %>% table()


# combine data sets -------------------------------------------------------

data.senti <- raw.data %>% 
  inner_join(tweets_senti, by = c("X"="index"))

data.senti_covid <- data.senti %>% 
  inner_join(y = data.statesinfo %>% 
               select(state, name) %>% 
               mutate(name = tolower(name)),
             by = c("user_location"="name")) %>% 
  mutate(date = date %>% 
           (function(x) str_sub(x, start = 1L, end = 10L))) %>% 
  inner_join(data.covid %>% 
               mutate(date = date %>% 
                        (function(x) str_c(str_sub(x, start = 1L, end = 4L),
                                           str_sub(x, start = 5L, end = 6L),
                                           str_sub(x, start = -2L, end = -1L),
                                           sep = "-", collapse = NULL))),
             by = c("date"="date", "state"="state"))

# # export the data
# write.csv(data.senti_covid, file = "./Process/data_senti_covid.csv")


data.senti_covid %>% 
  ggplot() +
  geom_jitter(mapping = aes(x = log(deathIncrease), 
                            y = sentiment),
              height = .1)

data.senti_covid %>%
  mutate(sentiment = factor(sentiment, 
                            levels = c(0, 1),
                            labels = c("Neg", "Pos"))) %>% 
  ggplot() +
  aes(fill = sentiment) +
  geom_boxplot(mapping = aes(x = sentiment,
                             y = log(positive)),
               data = ~ .x %>% mutate(tag = "Infect_log")) +
  geom_boxplot(mapping = aes(x = sentiment,
                             y = log(death)),
               data = ~ .x %>% mutate(tag = "Death_log")) +
  geom_boxplot(mapping = aes(x = sentiment,
                             y = log(deathIncrease)),
               data = ~ .x %>% mutate(tag = "Death_Incre_log")) +
  geom_boxplot(mapping = aes(x = sentiment,
                             y = log(positiveIncrease)),
               data = ~ .x %>% mutate(tag = "Infect_Incre_log")) +
  geom_boxplot(mapping = aes(x = sentiment,
                             y = log(death/recovered)),
               data = ~ .x %>% 
                 filter(!is.na(recovered)) %>% 
                 mutate(tag = "Death_Rate_log")) +
  coord_flip() +
  facet_wrap(~tag, scales = "free_x", ncol = 2) +
  labs(y = "value", title = "Box Plot") +
  guides(fill = FALSE) +
  theme(plot.title = element_text(hjust = .5))

glm(data = data.senti_covid %>% 
      filter(deathIncrease > 0) %>% 
      mutate(death_incre_log = log(deathIncrease)),
    formula = sentiment ~ death_incre_log,
    family = binomial()) %>% summary

glm(data = data.senti_covid %>% 
      filter(positiveIncrease > 0) %>% 
      mutate(infect_incre_log = log(positiveIncrease)),
    formula = sentiment ~ infect_incre_log,
    family = binomial()) %>% summary

glm(data = data.senti_covid %>% 
      filter(positive > 0) %>% 
      mutate(infect_log = log(positive)),
    formula = sentiment ~ infect_log,
    family = binomial()) %>% summary

model.glm.death_rate <- glm(data = data.senti_covid %>% 
                              filter(!is.na(recovered)) %>% 
                              mutate(death_ratio_log = log(death/recovered)),
                            formula = sentiment ~ death_ratio_log,
                            family = binomial())
summary(model.glm.death_rate)

pscl::pR2(model.glm.death_rate)

data.senti_covid %>% 
  filter(!is.na(recovered)) %>% 
  group_by(state) %>% 
  summarise(death_rate_mean_log = log(mean(death/recovered)),
            sentiment_mean_logit = faraway::logit(mean(sentiment))) %>% 
  ggplot(aes(x = death_rate_mean_log,
             y = sentiment_mean_logit)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE,
              lty = "dashed") +
  labs(x = "logit mean of death rate",
       y = "logit mean of sentiment", 
       title = "Scatter Plot with OLS") +
  theme(plot.title = element_text(hjust = .5))

model.lm.death_rate.states <- data.senti_covid %>% 
  filter(!is.na(recovered)) %>% 
  group_by(state) %>% 
  summarise(death_rate_mean_log = log(mean(death/recovered)),
            sentiment_mean_logit = faraway::logit(mean(sentiment))) %>% 
  ungroup() %>% 
  filter(sentiment_mean_logit != 0) %>% 
  lm(formula = sentiment_mean_logit ~ death_rate_mean_log)

summary(model.lm.death_rate.states)

par(mfrow = c(2,2))
plot(model.lm.death_rate.states)


