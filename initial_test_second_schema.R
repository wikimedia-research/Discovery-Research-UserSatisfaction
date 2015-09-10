source("config.R")

check_biases <- function(){

  #Simple data reader and scrubber
  get_data <- function(table, ...){
    data <- wmf::mysql_read(paste("SELECT * FROM", table, ...), "log")
    data$timestamp <- wmf::from_mediawiki(data$timestamp)
    return(data)
  }

  #Parse agents and identify mobile/desktop/common patterns
  handle_uas <- function(dataset, name){

    #Deduplicate
    user_agents <- dataset$userAgent[!duplicated(dataset[,c("clientIp","userAgent")])]
    ua_data <- uaparser::parse_agents(user_agents)
    browsers <- paste(ua_data$browser, ua_data$browser_major)

    results <- paste(ua_data$browser, ua_data$browser_major) %>%
      table %>%
      as.data.frame(stringsAsFactors = FALSE)

    results$percentage <- results$Freq/sum(results$Freq)
    results <- results[order(results$percentage, decreasing = TRUE),]
    names(results)[1] <- "agent"
    results$sample <- name
    return(results)
  }

  # Read in hypothesis data and control data and compare.
  hyp_data <- get_data("TestSearchSatisfaction2_13223897")
  control_data <- get_data("Search_12057910", paste("WHERE timestamp BETWEEN", wmf::to_mediawiki(min(hyp_data$timestamp)),
                                                    "AND", wmf::to_mediawiki(max(hyp_data$timestamp))))

  #Parse the UAs for a comparison there.
  hyp_agents <- handle_uas(hyp_data, "User Satisfaction Schema")
  control_agents <- handle_uas(control_data, "Control Sample")
  final_set <- rbind(hyp_agents[hyp_agents$agent %in% control_agents$agent[1:10],],
                     control_agents[1:10,])

  ggsave(plot = ggplot(final_set, aes(x = reorder(agent, percentage), y = percentage, fill = factor(sample))) +
           geom_bar(stat="identity", position = "dodge") +
           theme_fivethirtynine() + scale_x_discrete() + scale_y_continuous(labels=percent) +
           labs(title = "Browser usage, second User Satisfaction schema versus control",
                x = "Browser", y = "Percentage of users", fill = "Sample") + coord_flip(),
         file = "second_ua_data.png")

  #Return
  return(hyp_data)
}

checkins_and_reconstruction <- function(hyp_data){

  ggsave(plot = ggplot(hyp_data[!is.na(hyp_data$event_checkin),], aes(x = event_checkin)) +
           geom_density(fill="#00BFC4") + theme_fivethirtyeight() +
           labs(title = "Browser checkin density in the second user satisfaction schema"),
         file = "second_checkin_density.png")

  # Session reconstruction attempt
  hyp_data$timestamp <- to_seconds(x = hyp_data$timestamp, format = "null") # Format isn't necessary
  session_dataset <- hyp_data[hyp_data$event_action %in% c("searchResultPage","visitPage"),]
  events_by_user <- split(session_dataset$timestamp, paste0(session_dataset$clientIp, session_dataset$userAgent))
  results <- generate_intertimes(events_by_user)
  ggsave(plot = ggplot(as.data.frame(results), aes(results)) + geom_density(fill="#00BFC4") +
           theme_fivethirtynine() +
           labs(title = "Intertimes between events, user ID",
                x = "Intertime (seconds)",
                y = "Density"),
         file = "per_user_intertime_density.png")
  ggsave(plot = ggplot(as.data.frame(results), aes(results)) + geom_density(fill="#00BFC4") +
           theme_fivethirtynine() +
           labs(title = "Intertimes between events, user ID",
                x = "Intertime (seconds)",
                y = "Density") +
           scale_x_log10(),
         file = "per_user_intertime_density_log.png")

  events_by_session <- split(session_dataset$timestamp, session_dataset$event_searchSessionId)
  results <- generate_intertimes(events_by_user)
  ggsave(plot = ggplot(as.data.frame(results), aes(results)) + geom_density(fill="#00BFC4") +
           theme_fivethirtynine() +
           labs(title = "Intertimes between events, session ID",
                x = "Intertime (seconds)",
                y = "Density"),
         file = "per_session_intertime_density.png")
  ggsave(plot = ggplot(as.data.frame(results), aes(results)) + geom_density(fill="#00BFC4") +
           theme_fivethirtynine() + labs(title = "Intertimes between events, session ID",
                                          x = "Intertime (seconds)",
                                          y = "Density") +
           scale_x_log10(),
         file = "per_session_intertime_density_log.png")
}
