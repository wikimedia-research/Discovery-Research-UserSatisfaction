## Options
options(scipen = 500)

## Dependencies
library(magrittr)
# install.packages("devtools")
library(wmf) # devtools::install_github("ironholds/wmf")
# library(reconstructr) # devtools::install_github("ironholds/reconstructr")
# library(ineq) # install.packages("ineq")
library(RMySQL)
library(uaparser) # devtools::install_github("ua-parser/uap-r")

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
  data$timestamp <- lubridate::ymd_hms(data$timestamp)
  return(data)
}

library(rvest)
prefixes <- html("https://en.wikipedia.org/wiki/List_of_Wikipedias#Detailed_list") %>%
  html_nodes(".wikitable") %>%
  { .[[3]] } %>%
  html_table()

parse_wiki <- function(x) { # x <- hyp_data$wiki
  language <- sub("(.*)wik.*", "\\1", x)
  project <- sub(".*wik(.*)", "wik\\1", x)
  lang_should_be_proj <- language %in% c("commons", "wikidata", "foundation", "mediawiki", "incubator", "meta", "simple", "sources", "species", "testwikidata", "office", "outreach", "donate", "be_x_old", "beta")
  project[lang_should_be_proj] <- paste(language[lang_should_be_proj], project[lang_should_be_proj])
  project[project == "wiki"] <- "Wikipedia"
  project %<>% sub("commons wiki", "Commons", .)
  project %<>% sub("donate wiki", "Donation Site", .)
  project %<>% sub("incubator wiki", "Wikimedia Incubator", .)
  project %<>% sub("mediawiki wiki", "MediaWiki", .)
  project %<>% sub("species wiki", "Wikispecies", .)
  project %<>% sub("sources wiki", "Wikisource", .)
  project %<>% sub("simple wiki", "Simple Wikipedia", .)
  project %<>% sub("wikidata wiki", "Wikidata", .)
  project %<>% sub("testwikidata wiki", "Wikidata Test", .)
  project %<>% sub("foundation wiki", "Wikimedia Foundation", .)
  project %<>% sub("beta wikiversity", "Wikiversity (Beta)", .)
  project %<>% sub("wikibooks", "Wikibooks", .)
  project %<>% sub("wikiquote", "Wikiquote", .)
  project %<>% sub("wikisource", "Wikisource", .)
  project %<>% sub("wikiversity", "Wikiversity", .)
  project %<>% sub("wikivoyage", "Wikivoyage", .)
  project %<>% sub("wiktionary", "Wiktionary", .)
  project %<>% sub("wikinews", "Wikinews", .)
  project %<>% sub("simple wiktionary", "Simple Wiktionary", .)
  project %<>% sub("meta wiki", "Meta", .)
  project %<>% sub("wikimedia", "Wikimedia Wiki", .)
  project %<>% factor
  language[lang_should_be_proj] <- NA
  y <- data.frame(Wiki = language, project = project)
  y %<>% dplyr::left_join(prefixes[, c('Wiki', 'Language')], by = "Wiki") %>%
    dplyr::rename(language = Language) %>% dplyr::mutate(language = factor(language))
  return(dplyr::select(y, -Wiki))
}
