events <- readr::read_csv("T112269_survanalysis/example/data.csv")
#> head(events)
#   median page visit time next check-in status       date
# 1                    240           300      3 2015-09-04
# 2                     20            30      3 2015-09-03
# 3                     90           120      3 2015-09-09
# 4                    420           420      0 2015-09-09
# 5                     10            20      3 2015-09-09
# 6                    140           150      3 2015-09-09

# 0 indicates the event (closing the page) is right-censored --
#   That is, we know the session ended above 420s, but it is unknown by how much.
# 3 indicates the event occured somewhere in the interval, but we don't know when.

library(survival)

surv <- Surv(time = events$`median page visit time`,
             time2 = events$`next check-in`,
             event = events$status,
             type = "interval")

fit <- survfit(surv ~ 1)

plot(fit) # Kaplan-Meier estimated survival curve

quantile(fit, probs = 0.50) # LD50: 88.75

## LD50 by day:
daily_ld50 <- events %>%
  dplyr::group_by(date) %>%
  dplyr::summarise(LD50 = (function(data) {
    surv <- Surv(time = data[, 1], time2 = data[, 2],
                 event = data[, 3], type = "interval")
    fit <- survfit(surv ~ 1)
    return(unname(quantile(fit, probs = 0.50)$quantile))
  })(cbind(`median page visit time`, `next check-in`, status)))

#          date  LD50
# 1  2015-09-02 30.00
# 2  2015-09-03 57.50
# 3  2015-09-04 87.50
# 4  2015-09-05 87.50
# 5  2015-09-06 87.50
# 6  2015-09-07 88.75
# 7  2015-09-08 88.75
# 8  2015-09-09 86.25
# 9  2015-09-10 87.50
# 10 2015-09-11 17.50

library(ggplot2)
ggplot(data = daily_ld50, aes(x = date, y = LD50)) +
  geom_line() + wmf::theme_fivethirtynine()
