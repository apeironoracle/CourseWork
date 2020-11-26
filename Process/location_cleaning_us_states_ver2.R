# Input: the raw tweets data
# Output: the data set including tweets with tidy location info.
# Purpose: clean the messy location info.

# Load data ---------------------------------------------------------------

raw.data = read.csv("./input/covid19_tweets.csv", row.names = NULL,
                    encoding = "UTF-8") %>% tibble()

# Inspect the data

tweets_location <- raw.data %>%
  filter(user_location != "") %>% 
  mutate(user_location = user_location %>% 
           trimws() %>% str_remove_all("\\.")) %>% 
  group_by(user_location) %>%
  summarise(n = n(), .groups = "drop_last") %>%
  arrange(desc(n))

tweets_location %>% 
  filter(str_detect(user_location %>% tolower(), "new york"))

tweets_location %>% 
  filter(str_detect(user_location %>% tolower(), "washington"))

tweets_location %>% 
  filter(str_detect(user_location, "WA$"))

tweets_location %>% 
  filter(str_detect(user_location %>% tolower(), "chicago"))

tweets_location %>% 
  filter(str_detect(user_location %>% tolower(), "illinois"))

tweets_location %>% 
  filter(str_detect(user_location, "IL$"))

tweets_location %>% 
  filter(str_detect(user_location %>% tolower(), "madison"))

tweets_location %>% 
  filter(str_detect(user_location %>% tolower(), "wisconsin"))

tweets_location %>% 
  filter(str_detect(user_location, "WI$"))

# Load reference

data.state.info <- read_csv("input/StatesInformation.csv")

data.state.infom <- data.state.info %>% 
  select(state, name) %>% 
  rename(abbr = state, state = name)


# Operation ---------------------------------------------------------------

# data.test <- raw.data[1:2000,] %>% tibble() %>% 
#   filter(user_location != "") %>% 
#   select(user_location)

tweets_location %>% 
  filter(str_detect(user_location, "usa$"))

tweets_location %>% 
  filter(str_detect(user_location, ",USA$"))

trans.state <- function(x){
  trans <- x
  x.split <- str_split(x, ",") %>% unlist() %>% trimws()
  trans <- ifelse(last(x.split) == "USA",
                  nth(x.split, -2L), last(x.split))
  trans <- ifelse(trans %in% data.state.infom$state, trans, 
                  ifelse(trans %in% data.state.infom$abbr,
                         data.state.infom %>% 
                           filter(abbr == trans) %>% 
                           select(state) %>% 
                           simplify2array() %>% 
                           as.character(), NA))
  return(as.character(trans))
}

# trans.state("Illinois, USA")
# trans.state("Seattle, WA")
# trans.state("Washington, D.C.")

# data.test %>% 
#   mutate(user_location = map_chr(user_location, trans.state)) %>% 
#   na.omit()

data.usa_state <- raw.data %>%
  mutate(user_location = map_chr(user_location, trans.state)) %>% 
  na.omit

write.csv(data.usa_state, "./Process/data_usa_states_v2.csv")