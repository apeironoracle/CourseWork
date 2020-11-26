library(xml2)
library(rvest)
library(tidyverse)
url <- "https://www.bls.gov/opub/ted/2020/unemployment-rates-down-in-41-states-july-2020-to-august-2020.htm" 
page <- read_html(url) #Creates an html document from URL
table <- html_table(page, fill = TRUE) #Parses tables into data frames
table <- table[[1]]

head(table)
tail(table)
table %>% na.omit() %>% 
  write.csv(., file = "./input/unemployed.csv")
