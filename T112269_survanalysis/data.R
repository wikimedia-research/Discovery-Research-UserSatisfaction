# source("../config.R")
## Options
options(scipen = 500)

## Dependencies
# install.packages("devtools")
library(wmf) # devtools::install_github("ironholds/wmf")
library(ineq) # install.packages("ineq")
library(uaparser) # devtools::install_github("ua-parser/uap-r")
library(magrittr)
library(ggplot2)
library(ggthemes) # install.packages('ggthemes', dependencies = TRUE)
library(scales)
library(reconstructr) # devtools::install_github("ironholds/reconstructr")
library(RMySQL)

# Simple data reader and scrubber
get_data <- function(table, ...){
  mysql_read <- function(query, database){
    con <- dbConnect(drv = RMySQL::MySQL(),
                     host = "analytics-store.eqiad.wmnet",
                     dbname = database,
                     default.file = "/etc/mysql/conf.d/research-client.cnf")
    to_fetch <- dbSendQuery(con, query)
    data <- fetch(to_fetch, -1)
    dbClearResult(dbListResults(con)[[1]])
    dbDisconnect(con)
    return(data)
  }
  data <- mysql_read(paste("SELECT * FROM", table, ...), "log")
  data$timestamp <- lubridate::ymd_hms(data$timestamp)
  return(data)
}

hyp_data <- get_data("TestSearchSatisfaction2_13223897")
# hyp_data$timestamp %<>% as.POSIXct() # required for date returned by wmf::from_mediawiki()

hyp_data$user_id <- paste(hyp_data$clientIp, hyp_data$userAgent, sep = '~') %>%
  factor %>% as.numeric %>% factor

hyp_data <- hyp_data[order(hyp_data$user_id, hyp_data$event_searchSessionId, hyp_data$timestamp, hyp_data$event_pageId), ]

hyp_data_ua <- uaparser::parse_agents(hyp_data$userAgent)
hyp_data_ua$browser_major <- paste(hyp_data_ua$browser, hyp_data_ua$browser_major)
hyp_data <- cbind(hyp_data[, c('user_id', 'timestamp', 'wiki', 'webHost', 'event_action', 'event_checkin',
                               'event_logId', 'event_pageId', 'event_searchSessionId')],
                  hyp_data_ua[, c('device', 'os', 'browser', 'browser_major')])

users <- hyp_data %>%
  select(c(user_id, device, os, browser, browser_major)) %>%
  distinct()

sessions <- hyp_data %>%
  group_by(user_id, event_searchSessionId) %>%
  filter(all(c('searchResultPage', 'visitPage', 'checkin') %in% event_action)) %>%
  group_by(user_id, event_searchSessionId, event_pageId) %>%
  mutate(last_checkin = max(event_checkin, na.rm = TRUE)) %>%
  select(-event_checkin) %>%
  filter(event_action != "checkin")

# save(list = c('hyp_data'), file = 'Initial.RData')

## Locally:
# load("T112269_survanalysis/Initial.RData")

library(magrittr)
library(tidyr)
library(dplyr)

save(list = c('hyp_data', 'users', 'sessions'), file = 'T112269_survanalysis/Initial.RData')
