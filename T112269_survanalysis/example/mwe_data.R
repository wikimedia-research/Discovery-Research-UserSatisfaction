load("T112269_survanalysis/Processed.RData")

library(dplyr)

# Ideally we would be performing survival analysis with frailty,
#   which is to say we would have random effects for users and
#   sessions. To keep it as simple as possible, we use medians.

sessions$last_checkin[is.na(sessions$last_checkin)] <- 0

checkins <- sort(unique(sessions$last_checkin))

events <- sessions %>%
  # We're only interested in page visit events:
  filter(event_action == "visitPage") %>%
  # Get the date out of the timestamp:
  mutate(`day in september` = lubridate::day(timestamp)) %>%
  # Calculate the median page visit time within each user's session:
  group_by(user_id, event_searchSessionId, `day in september`) %>%
  summarise(`median page visit time` = median(last_checkin)) %>%
  # Calculate the median for each user:
  group_by(user_id, `day in september`) %>%
  summarise(`median page visit time` = median(`median page visit time`)) %>%
  # Calculate when the next check-in would have happened:
  mutate(`next check-in` = sapply(`median page visit time`, function(checkin) {
    idx <- which(checkins > checkin)
    if (length(idx) == 0) idx <- 16 # length(checkins)
    return(checkins[min(idx)])
  })) %>%
  # Calcualte event status indicator:
  mutate(`status` = sapply(`median page visit time`, function(time) {
    if (time == 420) return(0) # right censored
    return(3) # interval censored
  }), date = lubridate::ymd(paste0("2015-9-", `day in september`))) %>%
  ungroup %>%
  select(-c(user_id, `day in september`))

readr::write_csv(events, "T112269_survanalysis/example/data.csv")
