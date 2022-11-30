# theme: gage-qtrend

library(tidyverse)
library(glue)

source("functions.R")

theme <- load_theme("gage-qtrend")

variables <- load_variables(theme)
# MANUAL: copy meta-variables.csv to themes.xlsx$variables


# layer -------------------------------------------------------------------

df_layer <- readxl::read_xlsx(
  file.path(config::get("data_dir"), theme$id, "Longitude and latitude of sites used in RESTORE Streamflow alteration assessments.xlsx"),
  sheet = 1
) %>% 
  mutate(
    id = site_no,
    huc12 = sprintf("%012.0f", HUC_12)
  ) %>% 
  select(id, site_no, huc12, dec_long_va = Longitude, dec_lat_va = Latitude)

layer <- df_layer %>% 
  create_layer()

ggplot(layer$sf) +
  geom_sf()

# load quantile kendall test ----------------------------------------------

read_qk <- function(decade, season) {
  cat(glue("read_qk({decade},{season})"), "\n")
  if (season == "Annual") {
    filename <- glue("{decade}_QK_Results.xls")
  } else {
    filename <- glue("{season}_QK_{decade}_Results.xls")
  }
  filepath <- file.path(config::get("data_dir"), theme$id, "_versions", "v1.0", "Trend analysis results", "Quantile-Kendall results", decade, filename)
  
  sheets <- readxl::excel_sheets(filepath)
  
  map_df(sheets, function(sheet) {
    readxl::read_xls(filepath, sheet = sheet, na = "NaN", skip = 1, col_names = c(
      "quantile", "slopeLog", "slopePct", "pValue", "pValueAdj", "tau", "rho1", "rho2", "freq", "z"
      )
    ) %>%
      mutate(
        quantile = as.integer(quantile),
        gage = !!sheet
      )
  }) %>% 
    select(gage, everything())
}

# all results
df_qk_raw <- crossing(
  decade = seq(1950, 2000, by = 10),
  season = c("Annual", "Spring", "Summer", "Fall", "Winter")
) %>% 
  mutate(
    data = map2(decade, season, ~ read_qk(decade = .x, season = .y))
  ) %>% 
  unnest(data)

# only min, median, max quantiles
df_qk_all <- df_qk_raw %>% 
  group_by(season) %>% 
  mutate(
    quantile = case_when(
      quantile == min(quantile) ~ "min",
      quantile == floor(median(quantile)) ~ "median",
      quantile == max(quantile) ~ "max",
      TRUE ~ NA_character_
    )
  ) %>% 
  ungroup() %>% 
  mutate(season = tolower(season)) %>% 
  filter(!is.na(quantile)) %>% 
  mutate(
    signif = pValueAdj < 0.05
  ) %>% 
  select(id = gage, decade, season, quantile, signif, slopepct = slopePct) 

df_qk_signif <- df_qk_all %>% 
  mutate(
    slopepct = if_else(signif, slopepct, NA_real_),
    signif = TRUE
  )

df_qk <- bind_rows(
  df_qk_all %>% 
    mutate(signif = FALSE),
  df_qk_signif
) %>% 
  pivot_longer(c(slopepct), "var", "value") %>% 
  unite("var", c(season, quantile, var)) %>% 
  mutate(var = str_c("qk_", var)) %>% 
  pivot_wider(names_from = var, values_from = value) %>% 
  arrange(id, decade, signif)

qk_vars <- crossing(
  test = "qk",
  season = c("Spring", "Summer", "Fall", "Winter", "Annual"),
  quantile = c("Min", "Median", "Max"),
  var = c("slopepct")
) %>%
  mutate(
    var = tolower(str_c(test, season, quantile, var, sep = "_")),
    label = glue("{season} {quantile} Streamflow - QK Trend Slope"),
    description = glue("Estimated Sen slope (%/yr) of {season} {quantile} streamflow based on Quantile-Kendall test")
  ) %>% 
  left_join(
    df_qk %>% 
      filter(signif) %>% 
      pivot_longer(c(-decade, -id), "var", "value") %>% 
      group_by(var) %>% 
      summarise(
        min = min(value, na.rm = TRUE),
        q01 = quantile(value, prob = 0.01, na.rm = TRUE),
        median = quantile(value, prob = 0.5, na.rm = TRUE),
        q99 = quantile(value, prob = 0.99, na.rm = TRUE),
        max = max(value, na.rm = TRUE)
      ),
    by = "var"
  ) %>% 
  mutate(
    quantile = ordered(quantile, levels = c("Min", "Median", "Max")),
    season = ordered(season, levels = c("Annual", "Spring", "Summer", "Fall", "Winter"))
  ) %>% 
  arrange(season, quantile)


# load mann kendall test ---------------------------------------------------

read_mk <- function(decade, season) {
  cat(glue("read_mk({decade},{season})"), "\n")
  
  filename <- glue("{season}Ave_{decade}.xlsx")
  filepath <- file.path(config::get("data_dir"), theme$id, "Trend analysis results_v1.1", glue("Result Output {decade}"), filename)
  readxl::read_xlsx(filepath, sheet = 1, na = "NaN", skip = 1, col_names = c("Row", "Site", "Tau", "Tau.p", "SensSlope", "Z", "Z.p")) %>% 
    select(-Row)
}

# mann-kendall
df_mk_raw <- crossing(
  decade = seq(1950, 2000, by = 10),
  season = c(
    month.abb,
    c("Spring", "Summer", "Winter", "Fall"),
    glue("Q{sprintf('%02d', 10*(0:10))}")
  )
) %>% 
  mutate(
    data = map2(decade, season, read_mk)
  ) %>% 
  unnest(data)

df_mk_all <- df_mk_raw %>% 
  mutate(
    signif = Tau.p < 0.05
  ) %>% 
  select(
    id = Site, decade, season, signif, slope = SensSlope
  )

df_mk_signif <- df_mk_all %>% 
  mutate(
    slope = if_else(signif, slope, NA_real_),
    signif = TRUE
  )

df_mk <- bind_rows(
  df_mk_all %>% 
    mutate(signif = FALSE),
  df_mk_signif
) %>% 
  pivot_longer(c(slope), "var", "value") %>% 
  mutate(season = tolower(season)) %>% 
  unite("var", c(season, var)) %>%
  mutate(var = str_c("mk_", var)) %>% 
  pivot_wider(names_from = var, values_from = value) %>% 
  arrange(id, decade, signif)

mk_vars <- crossing(
  test = "mk",
  season = c(
    month.abb,
    c("Spring", "Summer", "Fall", "Winter"),
    glue("Q{sprintf('%02d', 10*(0:10))}")
  ),
  var = c("slope")
) %>%
  mutate(
    var = tolower(str_c(test, season, var, sep = "_")),
    label = glue("{season} Streamflow - MK Trend Slope"),
    description = glue("Estimated Sen slope (m3/s/yr) of {season} streamflow based on Mann-Kendall test")
  ) %>% 
  left_join(
    df_mk %>% 
      filter(signif) %>% 
      pivot_longer(c(-decade, -id), "var", "value") %>% 
      group_by(var) %>% 
      summarise(
        min = min(value, na.rm = TRUE),
        q01 = quantile(value, prob = 0.01, na.rm = TRUE),
        median = quantile(value, prob = 0.5, na.rm = TRUE),
        q99 = quantile(value, prob = 0.99, na.rm = TRUE),
        max = max(value, na.rm = TRUE)
      ),
    by = "var"
  ) %>% 
  mutate(
    season = ordered(season, levels = c(
      month.abb,
      c("Spring", "Summer", "Fall", "Winter"),
      glue("Q{sprintf('%02d', 10*(0:10))}")
    ))
  ) %>% 
  arrange(season)

# merge -------------------------------------------------------------------

setdiff(df_mk$id, df_qk$id)
setdiff(df_qk$id, df_mk$id)

df_dataset <- full_join(
  df_mk, df_qk,
  by = c("id", "decade", "signif")
)

stopifnot(all(df_layer$id %in% unique(df_dataset$id)))
stopifnot(all(unique(df_dataset$id) %in% df_layer$id))

out_dataset <- df_dataset %>% 
  left_join(
    df_layer %>% 
      select(id, lat = dec_lat_va, lon = dec_long_va),
    by = "id"
  ) %>% 
  select(id, lat, lon, decade, signif, variables$df$id) %>% 
  arrange(id, decade, signif)

dataset <- list(
  df = df_dataset,
  out = out_dataset,
  qk = df_qk_raw,
  mk = df_mk_raw
)

stopifnot(
  dataset$out %>% 
    mutate(id_decade_signif = str_c(id, decade, signif, sep = "-")) %>% 
    filter(duplicated(id_decade_signif)) %>% 
    nrow() == 0
)

# export ------------------------------------------------------------------

export_theme(theme, variables, dataset, layer)

# feature data ------------------------------------------------------------

df_feature <- dataset$out %>% 
  select(-lat, -lon) %>% 
  nest(values = -id) %>% 
  mutate(
    values = map2(id, values, function (i, v) {
      v %>% 
        arrange(decade, signif) %>% 
        mutate(
          qk_annual_slopepct = map2(decade, signif, function (d, s) {
            if (!s) {
              x <- df_qk_raw %>% 
                filter(
                  gage == i,
                  season == "Annual",
                  decade == d
                ) %>% 
                arrange(quantile) %>% 
                pull(slopePct)  
            } else {
              x <- df_qk_raw %>% 
                filter(
                  gage == i,
                  season == "Annual",
                  decade == d
                ) %>% 
                arrange(quantile) %>% 
                mutate(slopePct = if_else(pValueAdj < 0.05, slopePct, NA_real_)) %>% 
                pull(slopePct)  
            }
            x
          })
        )
    })
  ) %>% 
  append_feature_properties(layer)

write_feature_json(theme, df_feature)


# variable ranges ---------------------------------------------------------

summary(out_dataset)

# => use max(pretty(values)) for domain ranges
out_dataset %>% 
  filter(signif) %>% 
  select(-id, -decade, -lat, -lon, -signif) %>% 
  select_if(is.numeric) %>% 
  pivot_longer(everything(), "var", "value") %>% 
  mutate(var = ordered(var, levels = variables$df$id)) %>% 
  group_by(var) %>% 
  filter(
    value >= quantile(value, probs = 0.05, na.rm = TRUE),
    value <= quantile(value, probs = 0.95, na.rm = TRUE)
  ) %>% 
  summarise(
    min = min(pretty(value)),
    max = max(pretty(value)),
    min = if_else(abs(min) > max, min, -max),
    max = if_else(abs(min) > max, -min, max)
  ) %>% 
  # write_csv("~/vars.csv")
  print(n = Inf)
