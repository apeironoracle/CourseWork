


# Load data ---------------------------------------------------------------

raw.data = read.csv("./input/covid19_tweets.csv", row.names = NULL,
                    encoding = "UTF-8")

# Location Cleaning India&US ----------------------------------------------

# India

tweets_location <- raw.data %>%
  mutate(user_location = tolower(user_location)) %>% #convert to lower case
  group_by(user_location) %>%
  summarise(n = n(), .groups = "drop_last") %>%
  arrange(desc(n))


  
# USA

tweets_location %>% filter(user_location == "us")

tweets_location %>% filter(user_location == "usa")

tweets_location %>% filter(user_location == "united states")

tweets_location %>% filter(user_location == "united state")

raw.data.usa <- raw.data %>% 
  mutate(user_location = tolower(user_location)) %>% 
  filter(user_location %in% c("usa", "united states"))

write.csv(raw.data.usa, "data_usa_indep.csv")



