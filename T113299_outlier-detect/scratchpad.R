# load("T112269_survanalysis/Processed.RData")

library(magrittr)
import::from(dplyr, keep_where = filter, select, arrange, group_by, summarize, mutate, rename)

library(ggplot2) # devtools::install_github("hadley/ggplot2")
library(ggfortify) # devtools::install_github('sinhrks/ggfortify')
library(ggthemes) # install.packages('ggthemes', dependencies = TRUE)
library(scales)

top_seshs <- sessions %>%
  group_by(event_searchSessionId) %>%
  summarize(n = n()) %>%
  dplyr::top_n(20, n) # %>% select(event_searchSessionId) %>% unlist %>% unname

top_seshs_2 <- sessions %>%
  keep_where(!is.na(last_checkin)) %>%
  group_by(event_searchSessionId) %>%
  summarize(n = n()) %>%
  dplyr::top_n(20, n) # %>% select(event_searchSessionId) %>% unlist %>% unname

p1 <- sessions %>%
  keep_where(event_searchSessionId %in% top_seshs$event_searchSessionId &
               event_action == "visitPage" &
               !is.na(last_checkin)) %>%
  mutate(last_checkin = last_checkin/60) %>%
  ggplot(data = ., aes(y = last_checkin, x = event_searchSessionId)) +
  geom_boxplot(outlier.colour = scales::hue_pal()(1), outlier.size = 3) +
  geom_point(size = 1) +
  scale_y_continuous(name = "last check-in", labels = unit_format("min")) +
  scale_x_discrete(name = "page visits in a session", labels = top_seshs$n) +
  ggtitle("Page visit times for top 20 sessions with the most page visits") +
  wmf::theme_fivethirtynine()

p2 <- sessions %>%
  keep_where(event_searchSessionId %in% top_seshs_2$event_searchSessionId &
               event_action == "visitPage" &
               !is.na(last_checkin)) %>%
  mutate(last_checkin = last_checkin/60) %>%
  ggplot(data = ., aes(y = last_checkin, x = event_searchSessionId)) +
  geom_boxplot(outlier.colour = scales::hue_pal()(1), outlier.size = 3) +
  geom_point(size = 1) +
  scale_y_continuous(name = "last check-in", labels = unit_format("min")) +
  scale_x_discrete(name = "page visits in a session", labels = top_seshs_2$n) +
  ggtitle("Times for top 20 seshs w/ the most ≥10s page visits") +
  wmf::theme_fivethirtynine()

library(gridExtra)
# ggsave <- ggplot2::ggsave; body(ggsave) <- body(ggplot2::ggsave)[-2]

p <- gridExtra::arrangeGrob(p1, p2, nrow = 1)
ggsave("T113299_outlier-detect/top20seshs.png", p, width = 21, height = 7)
