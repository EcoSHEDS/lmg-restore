# generate themes.json config file

library(tidyverse)
library(jsonlite)
library(readxl)

config <- config::get()

themes <- read_xlsx("xlsx/themes.xlsx", sheet = "themes") %>% 
  filter(!skip) %>% 
  mutate(
    citations = map2(citation_text, citation_url, ~ list(list(text = .x, url = .y)))
  ) %>% 
  select(group, id, name, description, citations)

gage_themes <- themes %>% 
  filter(group == "gage") %>% 
  select(-group) %>% 
  mutate(
    title = str_c("Gages > ", name)
  )

gage_themes$citations[[1]] <- gage_themes %>% 
  filter(id %in% c("gage-cov", "gage-qstat", "gage-lff", "gage-qtrend")) %>% 
  pull(citations) %>% 
  map(~ .[[1]])

huc12_themes <- themes %>% 
  filter(group == "huc12") %>% 
  select(-group) %>% 
  mutate(
    title = str_c("HUC12 Basins > ", name)
  )

huc12_themes$citations[[1]] <- huc12_themes %>% 
  filter(id %in% c("huc12-cov", "huc12-qquantile")) %>% 
  pull(citations) %>% 
  map(~ .[[1]])

list(
  list(
    id = "gage",
    name = "Streamflow Gages",
    children = gage_themes
  ),
  list(
    id = "huc12",
    name = "HUC12 Basins",
    children = huc12_themes
  )
) %>% 
  # toJSON(auto_unbox = TRUE, pretty = TRUE)
  write_json("../src/assets/themes.json", auto_unbox = TRUE, pretty = TRUE)
