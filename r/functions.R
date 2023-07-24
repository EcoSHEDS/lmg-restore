load_theme <- function(id) {
  theme <- list(
    id = id,
    path = file.path("../public/data/", id),
    config = readxl::read_xlsx("xlsx/themes.xlsx", sheet = "themes") %>% 
      filter(id == !!id) %>% 
      mutate(
        citations = map2(citation_text, citation_url, ~ list(text = .x, url = .y))
      ) %>% 
      as.list()
  )
  
  theme$config$meta_file_index <- as.numeric(str_split(theme$config$meta_file_index, ",")[[1]])
  
  if (!dir.exists(theme$path)) {
    cat(glue::glue("Creating theme directory: {theme$path}"), "\n")
    dir.create(theme$path)
  }
  
  
  if (!dir.exists(file.path(theme$path, "features"))) {
    cat(glue::glue("Creating theme/features directory: {file.path(theme$path, 'features')}"), "\n")
    dir.create(file.path(theme$path, "features"))
  }
  
  theme
}

parse_xml_attrs <- function (xml_attrs) {
  tibble(
    i = 1:length(xml_attrs)
  ) %>% 
    mutate(
      el = map(i, ~ xml_attrs[.]),
      attrlabl = map_chr(el, ~ xml2::xml_text(xml2::xml_child(., "attrlabl"))),
      attrdef = map_chr(el, ~ xml2::xml_text(xml2::xml_child(., "attrdef"))),
      rdommin = map_chr(el, ~ xml2::xml_text(xml2::xml_child(., "attrdomv/rdom/rdommin"))),
      rdommax = map_chr(el, ~ xml2::xml_text(xml2::xml_child(., "attrdomv/rdom/rdommax"))),
      attrunit = map_chr(el, ~ xml2::xml_text(xml2::xml_child(., "attrdomv/rdom/attrunit"))),
    ) %>% 
    mutate_at(vars(rdommin, rdommax), parse_number) %>% 
    select(
      variable = attrlabl,
      description = attrdef,
      unit = attrunit,
      value_min = rdommin,
      value_max = rdommax
    )
}

extract_meta_variables <- function(theme) {
  # to find meta_file_index
  # > xml2::xml_find_all(xml2::read_xml(meta_xml_path), './eainfo/detailed')
  meta_xml_path <- file.path(config::get("data_dir"), theme$id, theme$config$meta_file)
  meta_xml <- xml2::read_xml(meta_xml_path)
  map(theme$config$meta_file_index, function (index) {
    meta_xml_attrs <- xml2::xml_find_all(meta_xml, glue::glue('./eainfo/detailed[{index}]/attr'))
    parse_xml_attrs(meta_xml_attrs)
  }) %>% 
    bind_rows(.id = "index")
}


load_variables <- function(theme, index_names = NULL) {
  meta <- NULL
  if (!is.na(theme$config$meta_file)) {
    meta <- extract_meta_variables(theme)
    meta %>%
      write_csv(file.path(theme$path, "meta-variables.csv"))
  }
  
  df <- readxl::read_xlsx("xlsx/themes.xlsx", sheet = "variables") %>% 
    filter(theme == !!theme$id) %>% 
    select(-row_number)
  
  categories <- readxl::read_xlsx("xlsx/themes.xlsx", sheet = "categories") %>% 
    filter(theme == !!theme$id)
  
  cfg <- transform_variables(df, categories)
  
  list(
    df = df,
    config = cfg,
    meta = meta,
    categories = categories
  )
}

transform_variables <- function(df, categories) {
  cfg <- list()
  if (nrow(df) > 0) {
    cfg <- map(1:nrow(df), function (i) {
      if (df$type[i] == "cat") {
        scale <- list(
          domain = categories %>% 
            filter(variable == df$id[i]) %>% 
            select(value, label)
        )
      } else {
        scale <- list(
          domain = c(df$scale_domain_min[i], df$scale_domain_max[i]),
          transform = df$scale_transform[i]
        )
      }
      list(
        id = df$id[i],
        label = df$label[i],
        description = df$description[i],
        units = df$units[i],
        type = df$type[i],
        group = df$group[i],
        map = df$map[i],
        filter = df$filter[i],
        formats = list(
          value = df$format_value[i],
          map = df$format_map[i],
          filter = df$format_filter[i]
        ),
        scale = scale,
        default = df$map_default[i]
      )
    })
  }
  cfg
}

load_dataset <- function (theme, ...) {
  read_csv(file.path(config::get("data_dir"), theme$id, theme$config$data_file), ...)
}

create_layer <- function (df, coords = c("dec_long_va", "dec_lat_va")) {
  stopifnot(all(!duplicated(df$id)))
  
  sf_layer <- sf::st_as_sf(df, crs = 4326, coords = coords)
  
  stopifnot(all(!duplicated(sf_layer$id)))
  
  list(
    df = df,
    sf = sf_layer
  )
}


export_theme <- function (theme, variables, dataset, layer) {
  cat("saving theme data to ", glue::glue("rds/{theme$id}.rds"), "\n", sep = "")
  list(
    theme = theme,
    variables = variables,
    layer = layer,
    dataset = dataset
  ) %>% 
    saveRDS(glue::glue("rds/{theme$id}.rds"))
  
  cat("saving layer to ", file.path(theme$path, "layer.json"), "\n", sep = "")
  layer$sf %>% 
    sf::st_write(dsn = file.path(theme$path, "layer.json"), driver = "GeoJSON", delete_dsn = TRUE, layer_options = "ID_FIELD=id")
  
  cat("saving dataset to ", file.path(theme$path, "data.csv"), "\n", sep = "")
  dataset$out %>% 
    write_csv(file.path(theme$path, "data.csv"), na = "")
  
  cat("saving config to ", file.path(theme$path, "theme.json"), "\n", sep = "")
  list(
    id = theme$id,
    title = str_c(
      case_when(
        theme$config$group == "gage" ~ "Gages > ",
        theme$config$group == "huc12" ~ "HUC12 Basins > ",
        TRUE ~ ""
      ),
      theme$config$name
    ),
    description = theme$config$description,
    citations = theme$config$citations,
    layer = list(
      url = glue::glue("{theme$id}/layer.json")
    ),
    data = list(
      url = glue::glue("{theme$id}/data.csv"),
      group = list(
        by = "id"
      )
    ),
    dimensions = list(
      decade = theme$config$dims_decade,
      signif = theme$config$dims_signif,
      exceedance = theme$config$dims_exceedance
    ),
    variables = variables$config
  ) %>% 
    jsonlite::write_json(path = file.path(theme$path, "theme.json"), auto_unbox = TRUE, pretty = TRUE, na = "null")
}

write_feature_json <- function(theme, df, clear = FALSE) {
  if (clear) {
    cat(glue::glue("deleting existing files in {file.path(theme$path, 'features')}"), "\n", sep = "")
    unlink(file.path(theme$path, "features", "*.json"))
  }
  cat(glue::glue("saving feature data to {file.path(theme$path, 'features')} (n = {nrow(df)})"), "\n", sep = "")
  pb <- progress::progress_bar$new(total = nrow(df))
  for (i in 1:nrow(df)) {
    pb$tick()
    id <- df$id[[i]]
    jsonlite::write_json(
      list(
        id = id,
        properties = df[i, ]$properties[[1]],
        values = df[i, ]$values[[1]]
      ),
      path = file.path(theme$path, "features", glue::glue("{id}.json")),
      auto_unbox = TRUE,
      pretty = TRUE,
      dataframe = "rows",
      na = "null"
    )
  }
}

append_feature_properties <- function(df, layer) {
  df %>% 
    left_join(
      layer$df %>% 
        nest(properties = -id) %>% 
        mutate(
          properties = map(properties, ~ as.list(.))
        ),
      by = "id"
    ) %>% 
    select(id, properties, everything())
}
