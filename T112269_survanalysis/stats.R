# load("T112269_survanalysis/Initial.RData")

sessions %>%
  filter(event_action == "visitPage" & is.na(last_checkin)) %>%
  group_by(user_id, event_searchSessionId) %>%
  summarise(n = n()) %>%
  with(prop.table(table(n))+0.01) %>%
  barplot(col = "cornflowerblue", border = "white", main = "Quick quitters", las = 1,
          xlab = "Number of page visits lasting <10s\nfrom a single search session", ylab = "%")

sessions %>%
  filter(event_action == "visitPage" & !is.na(last_checkin)) %>%
  group_by(user_id, event_searchSessionId) %>%
  summarise(n = n()) %>%
  with(prop.table(table(n))+0.01) %>%
  barplot(col = "cornflowerblue", border = "white", las = 1, xlab = "#{t >= 10s}", ylab = "%",
          main = "Number of page visits lasting at least 10s\nfrom a single search session")

library(ggplot2)
library(ggfortify) # devtools::install_github('sinhrks/ggfortify')
library(survival)

median_page_visits <- sessions %>%
  filter(event_action == "visitPage" & !is.na(last_checkin)) %>%
  group_by(user_id, event_searchSessionId) %>%
  summarise(`median page visit time` = median(last_checkin)) %>%
  summarise(`median page visit time` = median(`median page visit time`)) %>%
  mutate(status = as.numeric(`median page visit time` != 420)) %>%
  left_join(users) %>%
  filter(device != "Spider")

top_os <- median_page_visits %>%
  group_by(os) %>%
  summarize(n = n()) %>%
  top_n(11, n) %>%
  select(os) %>%
  unlist %>%
  unname
median_page_visits$os <- ifelse(median_page_visits$os %in% top_os,
                                sub("Windows", "Win", median_page_visits$os), "Other")
median_page_visits$os_major <- sub("Win.*", "Windows", median_page_visits$os)
top_browser <- median_page_visits %>%
  group_by(browser) %>%
  summarize(n = n()) %>%
  top_n(5, n) %>%
  select(browser) %>%
  unlist %>%
  unname
median_page_visits$browser <- ifelse(median_page_visits$browser %in% top_browser,
                                     median_page_visits$browser, "Other")


# Right censoring – a data point is above a certain value but it is unknown by how much.
fit <- survfit(Surv(median_page_visits$`median page visit time`, median_page_visits$status, type = "right") ~ 1)
ggsave(plot =
         autoplot(fit, ylab = "% of users still on the page",
                  surv.size = 1,
                  surv.colour = scales::hue_pal()(2)[1],
                  conf.int.fill = scales::hue_pal()(2)[1],
                  conf.int.alpha = 0.3) +
         wmf::theme_fivethirtynine() +
         scale_x_continuous(name = "Time (s) spent on page (median across users & sessions)",
                            breaks = scales::pretty_breaks(10)) +
         geom_vline(x = 62.5, linetype = "dashed") +
         geom_text(x = 65, y = 1.0, label = "50% at 63s", hjust = 0, family = "Times", fontface = "italic"),
       filename = "T112269_survanalysis/figures/survival.png", width = 10, height = 6)

surv <- Surv(median_page_visits$`median page visit time`, median_page_visits$status, type = "right")

# Survival by operating system:
fit <- survfit(surv ~ os, data = median_page_visits)
ggsave(plot =
         autoplot(fit, ylab = "% of users still on the page", surv.size = 1, conf.int = FALSE) +
         wmf::theme_fivethirtynine() +
         scale_x_continuous(name = "Time (s) spent on page (median across users & sessions)",
                            breaks = scales::pretty_breaks(10)),
       filename = "T112269_survanalysis/figures/survival_os.png", width = 16, height = 6)

# Survival by operating system (not distinguishing by Windows version)
fit <- survfit(surv ~ os_major, data = median_page_visits)
ggsave(plot =
         autoplot(fit, ylab = "% of users still on the page", surv.size = 1, conf.int = FALSE) +
         wmf::theme_fivethirtynine() +
         scale_x_continuous(name = "Time (s) spent on page (median across users & sessions)",
                            breaks = scales::pretty_breaks(10)),
       filename = "T112269_survanalysis/figures/survival_os2.png", width = 14, height = 6)

# Survival by browser:
fit <- survfit(surv ~ browser, data = median_page_visits)
ggsave(plot =
         autoplot(fit, ylab = "% of users still on the page", surv.size = 1, conf.int = FALSE) +
         wmf::theme_fivethirtynine() +
         scale_x_continuous(name = "Time (s) spent on page (median across users & sessions)",
                            breaks = scales::pretty_breaks(10)),
       filename = "T112269_survanalysis/figures/survival_browser.png", width = 12, height = 6)
