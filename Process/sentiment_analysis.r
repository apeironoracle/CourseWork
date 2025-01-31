# sentiment analysis whereby simple model



# data reading ------------------------------------------------------------

library(tidyverse)
library(tidytext)

# # target data
# raw.data = read.csv("input/covid19_tweets.csv", row.names = NULL,
#                     encoding = "UTF-8")

# programming partial data
# raw.data = read.csv("Process/tweets1.csv", row.names = NULL,
#                     encoding = "UTF-8") %>% tibble()

# test --------------------------------------------------------------------

# test data
raw.data <- read_csv("input/Corona_NLP_train.csv",
                     skip_empty_rows = TRUE)
# raw.data %>% head()
# raw.data %>% tail()

senti_trans <- raw.data %>%
  select(Sentiment) %>%
  unique() %>%
  mutate(Score = c(NA,1,0,0,1))

data.test <- raw.data %>%
  inner_join(senti_trans, by = "Sentiment") %>%
  select(OriginalTweet, Score) %>%
  na.omit() %>% 
  mutate(index = 1:nrow(.)); data.test

unclean_tweets <- data.test$OriginalTweet

# text cleaning -----------------------------------------------------------

# unclean_tweets <- raw.data$text

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
tweets_df <- tibble(line = 1:length(tweets), 
                    tweets = tweets)

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

# inspect bigram lexicon
tweets_df %>%
  unnest_tokens(bigram, tweets,
                token = "ngrams", n = 2)
# negation word
negation_words <- c("no", "not", "never", "without")
# bigram score
tweets_bigram <- tweets_df %>%
  unnest_tokens(bigram, tweets,
                token = "ngrams", n = 2) %>%
  separate(bigram, c("word1", "word2"), sep = " ") %>%
  filter(word1 %in% negation_words) %>%
  inner_join(get_sentiments("bing"),
             by = c(word2 = "word")) %>%
  count(line, sentiment) %>%
  spread(key=sentiment, value=n, fill = 0) %>%
  mutate(bigram_score = 2*(negative - positive)) %>%
  select(line, bigram_score)

tweets_bigram %>% select(bigram_score) %>% table()

tweets_senti %>%
  left_join(y = tweets_bigram,
            by = c("index"="line")) %>%
  replace_na(list(bigram_score = 0)) %>%
  mutate(sentiment = sentiment+bigram_score) %>%
  select(-bigram_score)

# dichotomy
tweets_senti <- tweets_senti %>%
  filter(sentiment != 0) %>%
  mutate(sentiment = as.numeric(sentiment>0))

# inspect dichotomy
tweets_senti %>% select(sentiment) %>% table()


# test(cont.) --------------------------------------------------------------------

# error rate
tweets_senti %>%
  inner_join(data.test %>%
               select(-OriginalTweet)) %>%
  select(-index) %>%
  summarise(error_rate = mean(sentiment != Score))

compa <- tweets_senti %>%
  inner_join(data.test %>%
               select(-OriginalTweet),
             by = c("index")) %>%
  select(-index)

# confusion function
table(outcome = compa$sentiment,
      reality = compa$Score)














