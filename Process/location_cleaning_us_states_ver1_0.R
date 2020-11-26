

# Load data ---------------------------------------------------------------

raw.data = read.csv("./input/covid19_tweets.csv", row.names = NULL,
                    encoding = "UTF-8")

# Location Cleaning -------------------------------------------------------

worldcities <- read_csv("input/world-cities.csv",
                        col_types = cols(name = col_character(),
                                         country = col_character(),
                                         subcountry = col_character()))

us_cities <- worldcities %>%
  filter(country == "United States") %>%
  mutate(name = tolower(name), subcountry = tolower(subcountry)) %>%
  select(-country, -geonameid)

# tweets_location <- raw.data %>%
#   mutate(user_location = tolower(user_location)) %>% #convert to lower case
#   group_by(user_location) %>%
#   summarise(n = n(), .groups = "drop_last") %>%
#   arrange(desc(n))
#
# tweets_location %>%
#   filter(user_location %in% us_cities$subcountry |
#            user_location %in% us_cities$name)
#

city2state <- function(x){
  ifelse(x %in% us_cities$subcountry,
         state <- x,
         state <- us_cities %>%
           filter(name == x) %>%
           select(subcountry) %>%
           simplify2array() %>%
           as.vector())
  state <- ifelse(length(state)==1, state, NA)
  return(state)
}

trans2usstate <- function(x){
  trans <- x
  x.split <- strsplit(x, ", ") %>% 
    simplify2array() %>% 
    as.vector()
  trans <- ifelse(last(x.split)=="usa" & length(x.split)==2,
         first(x.split), trans)
  return(trans)
}

raw.data.state <- raw.data %>%
  mutate(user_location = tolower(user_location)) %>%
  mutate(user_location = sapply(user_location, trans2usstate)) %>% 
  filter(user_location %in% us_cities$subcountry |
           user_location %in% us_cities$name) %>%
  mutate(user_location = sapply(user_location, city2state)) %>%
  na.omit()

raw.data.state %>% select(user_location) %>% unique()

write.csv(raw.data.state, "./Process/data_usa_states.csv")


