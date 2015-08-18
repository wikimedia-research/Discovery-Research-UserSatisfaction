# Initial analysis of the TestSearchSatisfaction data to validate that the theory works
Mikhail Popov  
August 17, 2015  

 This analysis is meant to address the Phabricator task [T105355](https://phabricator.wikimedia.org/T105355).

## Prerequisities

This notebook uses the following packages: magrittr, tidyr, dplyr, knitr, ggplot2, ggthemes, scales, and printr.



## Data Preparation

Oliver Keyes prepared the data for analysis (read it in, cleaned up timestamps, and parsed user agents).




```r
# setwd('analysis_T105355')
load('second_ab_run_tbl-df.RData')
```

## Notes to self

### control_data

|control_data               |comment                          |
|:--------------------------|:--------------------------------|
|uuid                       |Unique user ID
|clientIp                   ||
|timestamp                  ||
|userAgent                  ||
|webHost                    ||
|wiki                       ||
|event_action               ||
|event_clickIndex           ||
|event_numberOfResults      ||
|event_platform             ||
|event_resultSetType        ||
|event_searchSessionToken   ||
|event_timeOffsetSinceStart ||
|event_timeToDisplayResults ||
|event_userSessionToken     ||

### hyp_data (hypothesis data)

|column name           | comment                      |
|:---------------------|:-----------------------------|
|uuid                  ||
|clientIp              ||
|timestamp             ||
|userAgent             ||
|webHost               ||
|wiki                  ||
|event_action          | Identifies the context in which the event was created. When the user clicks a link in the results a visitPage event is created. |
|event_depth           | Records how many clicks away from the search page the user currently is. |
|event_logId           | A unique identifier generated per event. |
|event_pageId          | A unique identifier generated per visited page. This allows a visitPage event to be correlated with a leavePage event. |
|event_searchSessionId | A unique identifier generated per search session. |
|device                     ||
|os                         ||
|os_major                   ||
|os_minor                   ||
|os_patch                   ||
|os_patch_minor             ||
|browser                    ||
|browser_major              ||
|browser_minor              ||
|browser_patch              ||
|browser_patch_minor        ||

## Bias Checking

![](notebook_files/figure-html/unnamed-chunk-4-1.png) 

Let's take a look at proportions of (known) spiders in our datasets...


Controls   Hypothesis 
---------  -----------
0.008%     0.022%     



![](notebook_files/figure-html/unnamed-chunk-7-1.png) 

![](notebook_files/figure-html/unnamed-chunk-8-1.png) 

![](notebook_files/figure-html/unnamed-chunk-9-1.png) 

## Analysis

![](notebook_files/figure-html/unnamed-chunk-10-1.png) 



16122 visits to pages from 94751 search result pages (17.015%) under [Schema:TestSearchSatisfaction](https://meta.wikimedia.org/wiki/Schema:TestSearchSatisfaction)



20682 visits to pages from 224976 search result pages (9.193%) under [Schema:Search](https://meta.wikimedia.org/wiki/Schema:Search)



2-sample test for equality of proportions (17.015% vs 9.193%): p < 0.001

95% CI for difference of proportions: (-8.1%, -7.6%)

### 

