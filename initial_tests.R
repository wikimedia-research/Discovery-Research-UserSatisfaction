source("config.R")

# Checks for biases against known existing data.
check_biases <- function(){

  #Simple data reader and scrubber
  get_data <- function(table){
    data <- olivr::mysql_read(paste("SELECT * FROM", table), "log")
    data$timestamp <- olivr::from_mediawiki(data$timestamp)
    return(data)
  }

  # Read in hypothesis data and control data and compare.
  hyp_data <- get_data("TestSearchSatisfaction_12423691")
  control_data <- get_data("Search_12057910")
  control_data <- control_data[as.Date(control_data$timestamp) %in% as.Date(hyp_data$timestamp),]

}
