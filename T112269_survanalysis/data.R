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
  data$timestamp <- wmf::from_mediawiki(data$timestamp)
  return(data)
}

hyp_data <- get_data("TestSearchSatisfaction2_13223897")

hyp_data$user_id <- paste(hyp_data$clientIp, hyp_data$userAgent, sep = '~') %>%
  factor %>% as.numeric %>% factor

hyp_data <- hyp_data[order(hyp_data$user_id, hyp_data$timestamp), ]

unnecessary_checkins <- duplicated(hyp_data[, c('user_id', 'event_action', 'event_pageId')], fromLast = TRUE)
# ^ need to verify that this is robust
hyp_data <- hyp_data[!unnecessary_checkins, ]

hyp_data_ua <- uaparser::parse_agents(hyp_data$userAgent)
hyp_data_ua <- hyp_data_ua[!unnecessary_checkins, ]

# save(list = c('hyp_data', 'hyp_data_ua'), file = 'Initial.RData')
# load("T112269_survanalysis/Initial.RData")
