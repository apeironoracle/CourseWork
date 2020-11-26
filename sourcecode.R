


# load package ------------------------------------------------------------

library(tidyverse)
library(tidytext)

# read data finishing location cleaning -----------------------------------
rm(list = ls())

raw.data <- 
  read.csv("./Process/data_usa_states_v2.csv", row.names = NULL) %>% tibble()

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
  tweets_df <- tibble(line = raw.data$X, tweets = tweets)
  
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
  inner_join(tweets_senti, by = c("X" = "index"))

# add other predictors ----------------------------------------------------

# state information
data.statesinfo <- 
  read.csv("./input/StatesInformation.csv", row.names = NULL) %>% tibble()

# covid history state-level
data.covid <- 
  read_csv("./input/StatesHistorical.csv", 
           col_types = cols(date = col_character()))

# covid history us-level
data.covid.us <- 
  read_csv("./input/US_historical.csv",
           col_types = cols(date = col_character(),
                            dateChecked = col_character())); data.covid.us

# mask information
data.mask <- read_csv("./input/mask.csv")

data.mask %>% 
  select(-"Type of Requirement") %>% 
  rename(state = "State.", 
         mask = "Masks Required?", 
         date = "Requirement Date") %>% 
  mutate(state = state %>% 
           str_extract(pattern = "(?<=\\[).*(?=\\])")) %>% 
  mutate(mask = mask %>% 
           str_extract("\\w*") %>% 
           str_to_lower() %>% 
           str_replace_all("masks", "entire") %>% 
           factor(levels = c("no", "parts", "entire"),
                  labels = c("n", "p", "f"))) %>% 
  mutate(date = date %>% as.Date("%m/%d/%Y"))

# unemployed rate
data.unemploy <- read_csv("./input/unemployed.csv") %>% select(-1)

library(zoo)
lct <- Sys.getlocale("LC_TIME"); Sys.setlocale("LC_TIME", "C");rm(lct)

data.unemploy %>% 
  rename(state = State) %>% 
  gather(-state, key = "date", value = "rate") %>% 
  mutate(date = date %>% 
           str_remove_all(" ") %>% 
           as.yearmon("%b%Y") %>% 
           format("%Y-%m")) %>% 
  mutate(rate = rate %>% str_remove_all("\\%")) %>% 
  mutate(rate = as.numeric(rate))

# lock down
data.lockdown <- read_csv("./input/countryLockdowndates.csv")

data.lockdown %>% 
  select(-Reference) %>% 
  rename(type = Type,
         state = Province,
         date = Date,
         country = `Country/Region`) %>% 
  filter(country == "US") %>% 
  select(-country) %>% 
  mutate(date = date %>% as.Date("%d/%m/%Y"),
         type = factor(type, 
                       levels = c("None", "Full"), 
                       labels = c("n", "f"))) 


# aggregate

data_whole <- data.senti %>% #select(user_location, date) %>% 
  mutate(date = date %>% 
           str_sub(start = 1L, end = 10L)) %>% 
  inner_join(y = data.mask %>% 
               select(-"Type of Requirement") %>% 
               rename(state = "State.", 
                      mask = "Masks Required?", 
                      date = "Requirement Date") %>% 
               mutate(state = state %>% 
                        str_extract(pattern = "(?<=\\[).*(?=\\])")) %>% 
               mutate(mask = mask %>% 
                        str_extract("\\w*") %>% 
                        str_to_lower() %>% 
                        str_replace_all("masks", "entire") %>% 
                        factor(levels = c("no", "parts", "entire"),
                               labels = c("n", "p", "f"))) %>% 
               mutate(date = date %>% as.Date("%m/%d/%Y")) %>% 
               rename(date.m = date),
             by = c("user_location"="state")) %>% #select(mask) %>% table
  mutate(mask = ifelse( na.fill(date > date.m, TRUE) , mask, 1)) %>% 
  mutate(mask = factor(mask, levels = c("1", "2", "3"),
                       labels = c("n", "p", "f"))) %>% #select(mask) %>% table
  select(-date.m) %>% 
  inner_join(y = data.lockdown %>% 
               select(-Reference) %>% 
               rename(type = Type,
                      state = Province,
                      date = Date,
                      country = `Country/Region`) %>% 
               filter(country == "US") %>% 
               select(-country) %>% 
               mutate(date = date %>% as.Date("%d/%m/%Y"),
                      type = factor(type, 
                                    levels = c("None", "Full"), 
                                    labels = c("n", "f"))) %>% 
               rename(date.l = date,
                      lock = type),
             by = c("user_location"="state")) %>% #transmute(date>date.l) %>% table
  select(-date.l) %>% 
  mutate(date.ym = date %>% 
           as.Date("%Y-%m-%d") %>% 
           format("%Y-%m")) %>% 
  inner_join(y = data.unemploy %>% 
               rename(state = State) %>% 
               gather(-state, key = "date", value = "rate") %>% 
               mutate(date = date %>% 
                        str_remove_all(" ") %>% 
                        as.yearmon("%b%Y") %>% 
                        format("%Y-%m")) %>% 
               mutate(rate = rate %>% str_remove_all("\\%")) %>% 
               mutate(rate = as.numeric(rate)) %>% 
               rename(unemploy_rate = rate), 
             by = c("user_location"="state",
                    "date.ym"="date")) %>% 
  select(-date.ym) %>% 
  inner_join(y = data.statesinfo %>% 
               select(state, name) %>% 
               rename(state.abbr = state),
             by = c("user_location"="name")) %>% 
  inner_join(y = data.covid %>% 
               mutate(date = as.Date(date, "%Y%m%d") %>% as.character),
             by = c("date"="date",
                    "state.abbr"="state")) %>% #select(user_name) %>% unique()
  distinct(user_name, .keep_all = TRUE) #%>% select(user_name) %>% unique()

#write.csv(data_whole %>% rename(index = X), "./Process/data_whole.csv")
#read_csv("./Process/data_whole.csv")

data_whole %>% 
  select(sentiment, user_location, positive, positiveIncrease,
         death, deathIncrease, recovered,mask, lock, unemploy_rate)








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

# Model 1

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

# Model 2, group by state

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

# Model 3, group by date


