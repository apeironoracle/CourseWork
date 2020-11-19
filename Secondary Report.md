# Secondary Report

## Question

### Further Refinement

Our broad question is how the COVID-19 condition impacts the people’s attitude. Since it is impossible to get a complete and precise record of people’s attitude in the past, we consider the tweets as an accessible reflection of people’s attitude. About the COVID-19, there are many dimensions to evaluate and one of them is the number of local infections and deaths. To be more specific, we only focus on the US, so our refined question is-what is the relationship in the US between the sentiment of tweets and corresponding local number of the inflections and deaths.

### Applicability

Tweets are the real reflection of the user’s mood and sentiment. In addition, Twitter is popular in the US regardless of the region and the age of the users. However, tweets may not completely reflect people’s sentiment, especially the extremely negative attitudes. Besides, tweet texts only reflect people who use the Internet and the Twitter, some hobos and patients in ICU cannot express themselves via Twitter. Therefore, when we apply the tweet text to analyze the sentiment of people, some biases of attitude appear and then we may not draw the significant results. Nevertheless, considering the feasibility and limited record of previous sentiment, it's still worthwhile to explore the relationship between the sentiment extracted from the tweets and the number of the inflections and deaths.

## Data Set

### Description and Criticism

Our dataset includes tweets, sentiment and regional cases.

**Tweets**: It’s collected with a hashtag of `#covid19` from July 25 to August 30 in 2020, including tweet texts, the location and the time that tweets were published. The dataset contains almost 190,000 lines. Due to the uneven sample size in different countries, in order to avoid too small sample size in some countries, we only select samples from the United States and then match them with the number of covid19 cases according to the states in the ‘Regional cases’ dataset. 

The limitations are shown as below. 

+ The time span is short. If the COVID-19 continues to be stable (steadily severe or increasing), changes of people’s sentiment may not be remarkable and the underlying model can be no relationship.
+ The dataset is collected with a hashtag `#covid19`. Users might not tag it when they make complaints, especially in the extreme emotion. Those who tend to tag may want to publish news or comments, which might cause the sentiment we analyses biased.
+ The texts of the tweets are not completely recorded. Some of the tweets are followed with apostrophe and don’t contain all the massage, which might cause some deviations from the original tweets, inducing the incorrectness of the outcome of our sentiment analysis.

**Sentiment**: A relatively small size of tweets are pulled from Twitter and manually tagged with “Negative”, “Extremely Negative”, “Positive”, “Extremely Positive” and “Neutral”. It is treated as a test dataset, to validate and assess the sentiment analysis method we use.

**Regional cases**: It collects information from 50 US states, the District of Columbia, and 5 other US territories and provides the testing data of positive and negative results, pending tests, as well as total hospitalizations, deaths and recovered. We combine this dataset with the “Tweets” to analyze whether the death rate, number of the confirmed cases, rate of the deaths and recovered, etc. are associated with the users’ moods.

### Pre-Process: 

**Text Cleaning**: 

**Location Cleaning**: Since the location information in the data set holds no fixed format and is messy and there are even some typo in the location information, it is necessary to do the text cleaning. 

**Sentiment Analysis**: We achieve the sentiment analysis whereby the 'bing' lexicon. The main idea is to evaluate the sentiment (score) of each word, based on the lexicon, and consider the sum as the sentiment of the whole text. Then we omit the tweets with equal amount of positive and negative words, and then label the tweets with more positive words as positive (notated by 1) and with more negative words as negative (notated by 0). 



