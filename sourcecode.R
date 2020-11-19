


# load package ------------------------------------------------------------

library(tidyverse)
library(tidytext)

# read data finishing location cleaning -----------------------------------

raw.data <- 
  read.csv("./Process/data_usa_states.csv", row.names = NULL) %>% tibble()

data.statesinfo <- 
  read.csv("./input/StatesInformation.csv", row.names = NULL) %>% tibble()

data.covid <- 
  read_csv("./input/StatesHistorical.csv", 
           col_types = cols(date = col_character()))

# text cleaning -----------------------------------------------------------

unclean_tweets <- raw.data$text
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
head(tweets)
tail(tweets)

# sentiment analysis ------------------------------------------------------

# tibble
tweets_df <- tibble(line = 1:length(tweets), tweets = tweets)

# one token per row
tweets_tidy <- tweets_df %>% 
  unnest_tokens(word, tweets) %>% 
  anti_join(stop_words); tweets_tidy

# bing lexicon
tweets_senti <- tweets_tidy %>% 
  inner_join(get_sentiments("bing")) %>% 
  count(index = line, sentiment) %>% 
  spread(key = sentiment, value = n, fill = 0) %>% 
  mutate(sentiment = positive - negative) %>% 
  select(-positive, -negative); tweets_senti

# inspect score
tweets_senti %>% select(sentiment) %>% table()

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

# write.csv(data.senti_covid, file = "./Process/data_senti_covid.csv")

# data.senti_covid %>% 
#   select(positiveIncrease) %>% 
#   simplify2array() %>% 
#   hist()
# 
# data.senti_covid %>% 
#   select(deathIncrease) %>% 
#   simplify2array() %>% 
#   hist()
# 
# data.senti_covid %>% 
#   group_by(date) %>% 
#   summarise(senti_mean = mean(sentiment))
# 
# data.senti_covid %>% 
#   mutate(posi_incre250 = positiveIncrease/250) %>% 
#   ggplot() +
#   geom_jitter(mapping = aes(x = posi_incre250, y = sentiment),
#               height = .05)
# 
# data.senti_covid %>% 
#   group_by(state) %>% 
#   summarise(senti = mean(sentiment)) %>% 
#   ungroup() %>% 
#   arrange(desc(senti)) %>% 
#   ggplot() +
#   geom_density(mapping = aes(x = senti))
# 
# data.senti_covid %>% 
#   group_by(date) %>% 
#   summarise(senti = mean(sentiment)) %>% 
#   ungroup() %>% 
#   arrange(desc(senti)) %>% 
#   ggplot() +
#   geom_density(mapping = aes(x = senti))
# 
# 
# data.senti_covid %>% 
#   select(state, death, recovered, sentiment, positive) %>% 
#   na.omit() %>% 
#   group_by(state) %>% 
#   summarise(senti = mean(sentiment),
#             death = sum(death),
#             recovered = sum(recovered),
#             infect = sum(positive)) %>% 
#   ungroup() %>% 
#   mutate(death_rate100 = death/recovered*100) %>% 
#   ggplot() +
#   geom_point(mapping = aes(x = log(death_rate100),
#                            y = faraway::logit(senti)))
# 
# model.glm <- glm(data = data.senti_covid %>% 
#                    select(state, death, recovered, sentiment, positive) %>% 
#                    na.omit() %>% 
#                    group_by(state) %>% 
#                    summarise(senti = mean(sentiment),
#                              death = sum(death),
#                              recovered = sum(recovered),
#                              infect = sum(positive)) %>% 
#                    ungroup() %>% 
#                    mutate(death_rate100 = death/recovered*100),
#                  formula = faraway::logit(senti) ~ log(death_rate100)); summary(model.glm)
#  plot(model.glm)
















