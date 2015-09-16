# load("T112269_survanalysis/Processed.RData")

library(ggplot2)
library(ggfortify) # devtools::install_github('sinhrks/ggfortify')
library(ggthemes) # install.packages('ggthemes', dependencies = TRUE)
library(scales)

## Some simple EDA:
sessions %>%
  filter(event_action == "visitPage" & is.na(last_checkin)) %>%
  group_by(user_id, event_searchSessionId) %>%
  summarise(n = n()) %>%
  ggplot(data = ., aes(x = n)) +
  geom_histogram() +
  wmf::theme_fivethirtynine() +
  scale_x_continuous(name = "Number of page visits lasting <10s from a single search session")
sessions %>%
  filter(event_action == "visitPage" & !is.na(last_checkin)) %>%
  group_by(user_id, event_searchSessionId) %>%
  summarise(n = n()) %>%
  ggplot(data = ., aes(x = n)) +
  geom_histogram() +
  wmf::theme_fivethirtynine() +
  scale_x_continuous(name = "Number of page visits lasting at least 10s from a single search session")

## Let's aggregate across sessions and users.
# So: first we take the median page visit time in each session for each user
#     then we take the median of those, so each user has only 1 row of data.

median_page_visits <- sessions %>%
  filter(event_action == "visitPage" & !is.na(last_checkin)) %>%
  group_by(user_id, event_searchSessionId, wiki, project, language) %>%
  summarise(`median page visit time` = median(last_checkin)) %>%
  group_by(user_id, wiki, project, language) %>%
  summarise(`median page visit time` = median(`median page visit time`)) %>%
  mutate(status = as.numeric(`median page visit time` != 420)) %>% # 7,624
  left_join(users) # 7,624
  # filter(device != "Spider") # 7,624

median_page_visits$language %<>% as.character
median_page_visits$project %<>% as.character
median_page_visits$wiki %<>% as.character

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
top_project <- median_page_visits %>%
  group_by(project) %>%
  summarize(n = n()) %>%
  top_n(5, n) %>%
  select(project) %>%
  unlist %>%
  unname
median_page_visits$project <- ifelse(median_page_visits$project %in% top_project,
                                     median_page_visits$project, "Other")
top_language <- median_page_visits %>%
  group_by(language) %>%
  summarize(n = n()) %>%
  top_n(5, n) %>%
  select(language) %>%
  unlist %>%
  unname
median_page_visits$language <- ifelse(median_page_visits$language %in% top_language,
                                      median_page_visits$language, "Other")
top_wiki <- median_page_visits %>%
  group_by(wiki) %>%
  summarize(n = n()) %>%
  top_n(5, n) %>%
  select(wiki) %>%
  unlist %>%
  unname
median_page_visits$wiki <- ifelse(median_page_visits$wiki %in% top_wiki,
                                  median_page_visits$wiki, "Other")
rm(top_os, top_browser, top_project, top_language, top_wiki)

library(survival)

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
         geom_vline(x = 60, linetype = "dashed") +
         geom_text(x = 65, y = 1.0, label = "50% at 60s", hjust = 0, family = "Times", fontface = "italic"),
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

# Survival by language:
fit <- survfit(surv ~ language, data = median_page_visits)
ggsave(plot =
         autoplot(fit, ylab = "% of users still on the page", surv.size = 1, conf.int = FALSE) +
         wmf::theme_fivethirtynine() +
         scale_x_continuous(name = "Time (s) spent on page (median across users & sessions)",
                            breaks = scales::pretty_breaks(10)),
       filename = "T112269_survanalysis/figures/survival_lang.png", width = 16, height = 6)

# Survival by project:
fit <- survfit(surv ~ project, data = median_page_visits)
ggsave(plot =
         autoplot(fit, ylab = "% of users still on the page", surv.size = 1, conf.int = FALSE) +
         wmf::theme_fivethirtynine() +
         scale_x_continuous(name = "Time (s) spent on page (median across users & sessions)",
                            breaks = scales::pretty_breaks(10)),
       filename = "T112269_survanalysis/figures/survival_proj.png", width = 16, height = 6)

# Survival by wiki:
fit <- survfit(surv ~ wiki, data = median_page_visits)
ggsave(plot =
         autoplot(fit, ylab = "% of users still on the page", surv.size = 1, conf.int = FALSE) +
         wmf::theme_fivethirtynine() +
         scale_x_continuous(name = "Time (s) spent on page (median across users & sessions)",
                            breaks = scales::pretty_breaks(10)),
       filename = "T112269_survanalysis/figures/survival_wiki.png", width = 16, height = 6)

rm(fit, surv)
