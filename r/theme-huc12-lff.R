# theme: huc12-lff

library(tidyverse)
library(janitor)
library(sf)

source("functions.R")


# load variables ----------------------------------------------------------

theme <- load_theme("huc12-lff")
theme$config$citations[[2]] <- list(
  text = "Whaling, A.R., Sanks, K.M., Asquith, W.H., Rodgers, Kirk D., 2023, Application of a workflow to determine the feasibility of using simulated streamflow for estimation of streamflow frequency statistics: Submitted to Journal of Hydrologic Engineering [in review].",
  url = ""
)

colnames <- read_csv(
  file.path(config::get("data_dir"), theme$id, "colnames_master.csv"),
  col_types = cols(.default = col_character())
) %>% 
  clean_names() %>% 
  filter(include == "YES") %>% 
  rename(name = new_name)

variables <- load_variables(theme)
# MANUAL: copy meta-variables.csv to themes.xlsx$variables

# variables <- read_csv(
#   file.path(config::get("data_dir"), theme$id, "huc12_SyntheticLFF_colnames_master_dataviz.csv"),
#   col_types = cols(.default = col_character())
# ) %>% 
#   clean_names() %>% 
#   mutate(include = include == "YES" & !name %in% c("fpp_long", "fpp_lat", "huc12_fpp"))
# view(variables)

# load dataset ------------------------------------------------------------

df_dataset <- read_tsv(
    file.path(config::get("data_dir"), theme$id, theme$config$data_file),
    col_types = cols(
      .default = col_double(),
      huc12_fpp = col_character(),
      huc12_updt = col_character(),
      huc_comid = col_character(),
      huc_InsufficientObs_1Day = col_character(),
      huc_InvalidLmoms_1Day = col_character(),
      huc_InsufficientObs_7Day = col_character(),
      huc_InvalidLmoms_7Day = col_character(),
      huc_InsufficientObs_30Day = col_character(),
      huc_InvalidLmoms_30Day = col_character()
    ),
    na = c("NA", "-Inf")
  ) %>% 
  mutate(id = huc12_fpp) %>%
  arrange(id) %>% 
  select(all_of(c("id", colnames$name))) %>% 
  na.omit()

stopifnot(
  all(!is.na(df_dataset$id)),
  all(!duplicated(df_dataset$id))
)
colnames %>% 
  filter(!name %in% c("fpp_long", "fpp_lat", "huc12_fpp")) %>% 
  arrange(name) %>% 
  write_csv("~/tmp/colnames.csv")

df_dataset %>% 
  pivot_longer(-c(id, fpp_long, fpp_lat, huc12_fpp)) %>% 
  filter(value > -Inf) %>% 
  group_by(name) %>% 
  summarise(min = min(value, na.rm = TRUE), max = max(value, na.rm = TRUE)) %>% 
  arrange(name) %>% 
  write_csv("~/tmp/variable_ranges.csv")

df_dataset %>% 
  pivot_longer(-c(id, fpp_long, fpp_lat, huc12_fpp)) %>% 
  filter(str_starts(name, "huc_")) %>%
  ggplot(aes(value)) +
  geom_histogram() +
  facet_wrap(~name)

out_dataset <- df_dataset %>% 
  select(id, lat = fpp_lat, lon = fpp_long, variables$df$id)

dataset <- list(
  df = df_dataset,
  out = out_dataset
)

# layer -------------------------------------------------------------------

layer_sf <- df_dataset %>% 
  select(id, huc12 = huc12_fpp, dec_lat_va = fpp_lat, dec_long_va = fpp_long) %>% 
  st_as_sf(coords = c("dec_long_va", "dec_lat_va"), crs = 4326, remove = FALSE)
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

# export ------------------------------------------------------------------

export_theme(theme, variables, dataset, layer)


# feature data ------------------------------------------------------------

df_feature <- dataset$out %>% 
  nest_by(id, .key = "values") %>% 
  ungroup() %>% 
  append_feature_properties(layer)

write_feature_json(theme, df_feature, clear = TRUE)


# variable ranges ---------------------------------------------------------

summary(out_dataset)

# => use max(pretty(values)) for domain ranges
out_dataset %>% 
  select(-id, -lat, -lon) %>%
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
