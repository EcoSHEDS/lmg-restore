# theme: gage-ecoflows

library(tidyverse)
library(janitor)
library(glue)
library(sf)

source("functions.R")

id <- "gage-ecoflows"
base_theme <- list(
  id = id,
  path = file.path("../data/", id),
  config = readxl::read_xlsx("xlsx/themes.xlsx", sheet = "themes") %>% 
    filter(id == !!id) %>% 
    mutate(
      citations = map2(citation_text, citation_url, ~ list(text = .x, url = .y))
    ) %>% 
    as.list()
)

# theme <- load_theme("gage-ecoflows")

# variables <- load_variables(theme)
# MANUAL: copy meta-variables.csv to themes.xlsx$variables

ecoflows_load_variables <- function (theme_id) {
  df <- readxl::read_xlsx("xlsx/themes.xlsx", sheet = "variables") %>% 
    filter(theme == !!theme_id) %>% 
    select(-row_number)
  
  categories <- readxl::read_xlsx("xlsx/themes.xlsx", sheet = "categories") %>% 
    filter(theme == !!theme_id)
  
  cfg <- transform_variables(df, categories)
  
  list(
    df = df,
    config = cfg,
    meta = NULL,
    categories = categories
  )
}
ecoflows_load_variables("gage-ecoflows-obs-east")

# load datasets ------------------------------------------------------------

filenames <- c(
  "observed_streamflow_east.csv",
  "observed_streamflow_southeast.csv",
  "observed_streamflow_west.csv",
  "synthetic_streamflow_east.csv",
  "synthetic_streamflow_southeast.csv",
  "synthetic_streamflow_west.csv"
)

raw_data <- tibble(file = filenames) %>% 
  mutate(
    path = file.path(config::get("data_dir"), base_theme$id, file),
    data = map(path, function (x) {
      read_csv(x, col_types = cols(.default = col_double(), StationID = col_character(), site_no = col_character())) %>% 
        janitor::clean_names() %>% 
        rename(dec_lat_va = lat_dec, dec_long_va = long_dec, mbisq = m_bisq_score)
    }),
    region = map_chr(file, ~ str_split(str_remove(., ".csv"), "_")[[1]][3]),
    flowtype = map_chr(file, ~ str_split(str_remove(., ".csv"), "_")[[1]][1]),
    flowtype = case_when(
      flowtype == "observed" ~ "obs",
      flowtype == "synthetic" ~ "syn"
    )
  )

# variable ranges
raw_data %>% 
  select(file, data) %>% 
  unnest(data) %>% 
  select(-station_id, -site_no, -dec_lat_va, -dec_long_va) %>% 
  pivot_longer(-c(file), names_to = "variable", values_to = "value", values_drop_na = TRUE) %>% 
  group_by(file, variable) %>% 
  summarise(
    min = min(value, na.rm = TRUE),
    max = max(value, na.rm = TRUE)
  ) %>% 
  ungroup() %>% 
  write_csv("~/tmp/variable_ranges.csv")

theme_data <- raw_data %>% 
  select(flowtype, region, data) %>% 
  mutate(theme_id = glue("gage-ecoflows-{flowtype}-{region}"), .before = everything()) %>% 
  rowwise() %>% 
  mutate(
    data = list({
      data %>% 
        mutate(id = station_id)
    }),
    variables = list(ecoflows_load_variables(theme_id)),
    layer = list({
      if (flowtype == "obs") {
        x <- select(data, id, site_no, station_id, dec_lat_va, dec_long_va)
      } else {
        x <- select(data, id, station_id, dec_lat_va, dec_long_va)
      }
      
      sf_layer <- sf::st_as_sf(x, crs = 4326, coords = c("dec_long_va", "dec_lat_va"), remove = FALSE)
      
      stopifnot(all(!duplicated(sf_layer$id)))
      
      list(
        df = x,
        sf = sf_layer
      )
    }),
    theme = list({
      x <- list(
        id = theme_id,
        title = base_theme$config$name,
        description = base_theme$config$description,
        citations = base_theme$config$citations,
        layer = list(
          url = glue("{theme_id}/layer.json")
        ),
        data = list(
          url = glue("{theme_id}/data.csv"),
          group = list(by = "id")
        ),
        dimensions = list(
          decade = base_theme$config$dims_decade,
          signif = base_theme$config$dims_signif,
          exceedance = base_theme$config$dims_exceedance
        ),
        variables = variables$config
      )
    })
  ) %>% 
  print()


# export ------------------------------------------------------------------

theme_data %>% 
  mutate(
    theme_path = list({
      x <- file.path("../data", theme_id)
      if (!dir.exists(x)) {
        print(glue("creating directory: {x}"))
        dir.create(x)
      }
      x
    }),
    layer_file = list({
      filepath <- file.path(theme_path, "layer.json")
      layer$sf %>% 
        sf::st_write(
          dsn = filepath,
          driver = "GeoJSON", delete_dsn = TRUE, layer_options = "ID_FIELD=id"
        )
      filepath
    }),
    theme_file = list({
      filepath <- file.path(theme_path, "theme.json")
      jsonlite::write_json(theme, filepath, auto_unbox = TRUE, pretty = TRUE, na = "null")
      filepath
    }),
    data_file = list({
      filepath <- file.path(theme_path, "data.csv")
      write_csv(data, filepath, na = "")
      filepath
    }),
    feature_files = list({
      features_path <- file.path("../data", theme_id, "features")
      if (!dir.exists(features_path)) {
        print(glue("creating directory: {features_path}"))
        dir.create(features_path)
      }

      df <- data %>% 
        nest_by(id, .key = "values") %>% 
        ungroup() %>% 
        append_feature_properties(layer)
      for (i in 1:nrow(df)) {
        id <- df$id[[i]]
        jsonlite::write_json(
          list(
            id = id,
            properties = df[i, ]$properties[[1]],
            values = df[i, ]$values[[1]]
          ),
          path = file.path(features_path, glue::glue("{id}.json")),
          auto_unbox = TRUE,
          pretty = TRUE,
          dataframe = "rows",
          na = "null"
        )
      }
    })
  )
