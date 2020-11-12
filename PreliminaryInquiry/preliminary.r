# Preliminary Inquiry Source Code

library(tidyverse)

# Load data ---------------------------------------------------------------

## import state condition data
data.state <- read_csv("./PreliminaryInquiry/dataset/States - current.csv")
names(data.state)

## import hospital data
data.hospital <- read_csv("./PreliminaryInquiry/dataset/Hospital Capacity by State.CSV")
names(data.hospital)
data.hospital <- select(data.hospital, c(1,2,3,10))

## exclude variable artificially
data.death <- data.state %>% select(state, death, recovered)

## combine dataset
data.comb.death <- left_join(
  x = data.death,
  y = data.hospital,
  by = c("state" = "State"),
  copy = FALSE
) %>% na.omit() %>% select(-state)

### %>% column_to_rownames(var = "state")

## rename
names(data.comb.death) <- c("death", "recover", "Total_Hosp", "Total_ICU", "Adult_Pop")
sapply(data.comb.death, sum)

# OLS ---------------------------------------------------------------------

model.ols <- lm(data = data.comb.death %>% select(-recover),
                formula = death~.)
summary(model.ols)

cor(data.comb.death)
car::vif(model.ols)

plot(model.ols, which = 1)




























