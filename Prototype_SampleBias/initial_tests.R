source("../config.R")

# Checks for biases against known existing data.
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
  hyp_data <- get_data("TestSearchSatisfaction_12423691", "WHERE LEFT(timestamp,8) >= 20150804")
  control_data <- get_data("Search_12057910", paste("WHERE timestamp BETWEEN", wmf::to_mediawiki(min(hyp_data$timestamp)),
                                                    "AND", wmf::to_mediawiki(max(hyp_data$timestamp))))

  #Parse the UAs for a comparison there.
  hyp_agents <- handle_uas(hyp_data, "User Satisfaction Schema")
  control_agents <- handle_uas(control_data, "Control Sample")
  final_set <- rbind(hyp_agents[hyp_agents$agent %in% control_agents$agent[1:10],],
                     control_agents[1:10,],
                     data.frame(agent = control_agents$agent[1:10][!control_agents$agent[1:10] %in% hyp_agents$agent],
                                Freq = 0,
                                percentage = 0,
                                sample = "User Satisfaction Schema",
                                stringsAsFactors = FALSE)
  )

  ggsave(plot = ggplot(final_set, aes(x = reorder(agent, percentage), y = percentage, fill = factor(sample))) +
           geom_bar(stat="identity", position = "dodge") +
           theme_fivethirtynine() + scale_x_discrete() + scale_y_continuous(labels=percent) +
           labs(title = "Browser usage, User Satisfaction schema versus control",
                x = "Browser", y = "Percentage of users", fill = "Sample") + coord_flip(),
         file = "ua_data.png")

  #Return
  return(hyp_data)
}


check_intertimes <- function(){

  hyp_data$timestamp <- to_seconds(hyp_data$timestamp, format = "%Y-%m-%d %H:%M:%S")
  sessions <- reconstruct_sessions(split(hyp_data$timestamp, hyp_data$event_searchSessionId))

  session_times <- event_time(sessions)
  session_times <- as.data.frame(table(session_times[session_times >= 0]), stringsAsFactors = FALSE)
  names(session_times) <- c("Intertime","Count")

}
