library(dplyr)
library(syuzhet)

# read data
covid <- read.csv(file = "input/covid19_tweets.csv", header = T, nrows = 5000, encoding = 'UTF-8')
str(covid)

# build corpus
library(tm)
corpus <- iconv(covid$text) %>% na.omit
corpus <- Corpus(VectorSource(corpus))
inspect(corpus[1:5])

# clean text
corpus <- tm_map(corpus, tolower)
inspect(corpus[1:5])

corpus <- tm_map(corpus, removePunctuation)
inspect(corpus[1:5])

corpus <- tm_map(corpus, removeNumbers)
inspect(corpus[1:5])

# sentiment analysis
tweets <- iconv(covid$text, to = "UTF-8") %>% na.omit()

head(tweets)

senti <- get_nrc_sentiment(tweets)



