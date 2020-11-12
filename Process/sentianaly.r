# sentiment analysis whereby simple model


# data reading and cleaning -----------------------------------------------

library(tidyverse)
library(tidytext)

raw.data = read.csv("tweets1.csv",row.names = NULL, encoding = "UTF-8")
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















