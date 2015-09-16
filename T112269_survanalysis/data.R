source("T112269_survanalysis/utils.R")

hyp_data <- get_data("TestSearchSatisfaction2_13223897")

hyp_data$user_id <- paste(hyp_data$clientIp, hyp_data$userAgent, sep = '~') %>%
  factor %>% as.numeric %>% factor

hyp_data <- hyp_data[order(hyp_data$user_id, hyp_data$event_searchSessionId, hyp_data$timestamp, hyp_data$event_pageId), ]

hyp_data_ua <- uaparser::parse_agents(hyp_data$userAgent)
hyp_data_ua$browser_major <- paste(hyp_data_ua$browser, hyp_data_ua$browser_major)

# save(list = c('hyp_data', 'hyp_data_ua'), file = 'Initial.RData')
## Locally:
# load("T112269_survanalysis/Initial.RData")
hyp_data$timestamp %<>% as.POSIXct() # required for date returned by wmf::from_mediawiki()

hyp_data <- cbind(hyp_data, parse_wiki(hyp_data$wiki))

hyp_data <- cbind(hyp_data[, c('user_id', 'timestamp',
                               'event_action', 'event_checkin',
                               'event_logId', 'event_pageId', 'event_searchSessionId',
                               'wiki', 'webHost', 'project', 'language')],
                  hyp_data_ua[, c('device', 'os', 'browser', 'browser_major')])

hyp_data$wiki <- paste(ifelse(is.na(hyp_data$language), "", paste0(hyp_data$language, " ")),
                       hyp_data$project, sep = "") %>% factor

library(magrittr)
library(tidyr)
library(dplyr)

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

save(list = c('hyp_data', 'users', 'sessions'), file = 'T112269_survanalysis/Processed.RData')

rm(list = ls())
