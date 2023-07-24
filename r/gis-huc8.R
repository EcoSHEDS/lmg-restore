library(tidyverse)
library(sf)
library(glue)

huc12_primary <- read_rds("rds/huc12-primary.rds")
huc2s <- unique(str_sub(huc12_primary$layer$df$huc12, 1, 2))
huc4s <- unique(str_sub(huc12_primary$layer$df$huc12, 1, 4))

sf_huc4 <- map_df(huc2s, \(x) st_read(dsn = file.path(config::get("data_dir"), "..", "gis", "wbd", glue("WBD_{x}_HU2_GDB"), glue("WBD_{x}_HU2_GDB.gdb")), layer = "WBDHU4")) %>% 
  filter(
    huc4 %in% huc4s
  )

sf_huc4 %>%
  st_simplify(dTolerance = 100) %>% 
  ggplot() + 
  geom_sf()

sf_huc8 <- map_df(huc2s, \(x) st_read(dsn = file.path(config::get("data_dir"), "..", "gis", "wbd", glue("WBD_{x}_HU2_GDB"), glue("WBD_{x}_HU2_GDB.gdb")), layer = "WBDHU8")) %>% 
  filter(
    str_sub(huc8, 1, 4) %in% huc4s
  )

sf_huc4 %>%
  st_simplify(dTolerance = 100) %>%
  ggplot() + 
  geom_sf()


filename <- "../public/gis/huc8.geojson"
if (file.exists(filename)) {
  unlink(filename)
}
sf_huc8 %>% 
  st_simplify(dTolerance = 100) %>%
  mutate(
    label = glue("HUC8 {huc8} - {name}"), 
    code = huc8
  ) %>% 
  write_sf(filename, driver = "GeoJSON", layer_options = c("COORDINATE_PRECISION=6", "ID_GENERATE=YES"))

filename <- "../public/gis/huc4.geojson"
if (file.exists(filename)) {
  unlink(filename)
}
sf_huc4 %>% 
  st_simplify(dTolerance = 100) %>%
  mutate(
    label = glue("HUC4 {huc4} - {name}"), 
    code = huc4
  ) %>% 
  write_sf(filename, driver = "GeoJSON", layer_options = c("COORDINATE_PRECISION=6", "ID_GENERATE=YES"))

