# theme: huc12-hydroalt

library(tidyverse)
library(sf)

source("functions.R")

theme <- load_theme("huc12-hydroalt")

variables <- load_variables(theme)
# MANUAL: copy meta-variables.csv to themes.xlsx$variables

# load dataset ------------------------------------------------------------

df_dataset <- load_dataset(theme, col_types = cols(
  .default = col_double(),
  huc12 = col_character(),
  ecochange = col_character()
), na = "NA") %>% 
  rename(id = huc12, exceedance_probs = exceedence_probs) %>%
  arrange(id, exceedance_probs) %>% 
  distinct()

out_dataset <- df_dataset %>% 
  select(id, variables$df$id)

dataset <- list(
  df = df_dataset,
  out = out_dataset
)

stopifnot(
  dataset$out %>% 
    count(id, exceedance_probs) %>% 
    filter(n > 1) %>% 
    nrow() == 0
)

# layer -------------------------------------------------------------------

layer_sf <- st_read(
  file.path(config::get("data_dir"), "sciencebase", theme$id, "hydrologic_alteration_pourpoints", "hydrologic_alteration_pourpoints.shp")
) %>%
  st_transform("EPSG:4326") %>% 
  rename(id = HUC_12)
stopifnot(all(!duplicated(layer_sf$id)))

layer <- list(
  df = st_drop_geometry(layer_sf),
  sf = layer_sf
)

layer_sf %>% 
  ggplot() +
  geom_sf()

stopifnot(all(layer_sf$id %in% df_dataset$id))
stopifnot(all(df_dataset$id %in% layer_sf$id))

df_dataset %>% 
  filter(!id %in% layer_sf$id) %>% 
  pull(id) %>% 
  unique()

# export ------------------------------------------------------------------

export_theme(theme, variables, dataset, layer)


# feature data ------------------------------------------------------------

df_feature <- dataset$out %>% 
  nest_by(id, .key = "values") %>% 
  ungroup() %>% 
  mutate(
    values = map(values, function (x) {
      x %>% 
        arrange(exceedance_probs)
    })
  ) %>% 
  append_feature_properties(layer)

write_feature_json(theme, df_feature, clear = TRUE)


# variable ranges ---------------------------------------------------------

summary(out_dataset)

# => use max(pretty(values)) for domain ranges
out_dataset %>% 
  # select(-id, -decade, -lat, -lon) %>% 
  select_if(is.numeric) %>% 
  pivot_longer(everything(), "var", "value") %>% 
  mutate(var = ordered(var, levels = variables$df$id)) %>% 
  group_by(var) %>% 
  summarise(
    min = min(pretty(value)),
    max = max(pretty(value))
  ) %>% 
  # write_csv("~/vars.csv")
  print(n = Inf)

# pretty log breaks
out_dataset %>% 
  # select(-id, -decade, -lat, -lon) %>% 
  select_if(is.numeric) %>% 
  pivot_longer(everything(), "var", "value") %>% 
  mutate(var = ordered(var, levels = variables$df$id)) %>% 
  filter(value > 0) %>%  # POSITIVE NON-ZERO VALUES ONLY
  group_by(var) %>% 
  summarise(
    min_log = min(scales::log_breaks()(value)),
    max_log = max(scales::log_breaks()(value))
  ) %>% 
  # write_csv("~/vars.csv")
  print(n = Inf)


# categorical variables ---------------------------------------------------

out_dataset %>% 
  select(-id) %>% 
  select_if(is_character) %>% 
  gather(var, value) %>% 
  distinct() %>% 
  filter(!is.na(value)) %>% 
  arrange(var, value) %>% 
  group_by(var) %>% 
  summarise(
    values = str_c(value, collapse = ",")
  )