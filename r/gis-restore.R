library(tidyverse)
library(sf)
library(glue)

gis_dir <- "data/gis"

# pearl/pascagoula --------------------------------------------------------

sf_pascagoula <- st_read(file.path(gis_dir, "Pearl Pascagoula", "Pascagoula_w_minor_hucs.shp")) %>% 
  transmute(label = "Pascagoula Basin") %>% 
  st_make_valid()
sf_pearl <- st_read(file.path(gis_dir, "Pearl Pascagoula", "Pearl_Basin_Boundary.shp")) %>% 
  transmute(label = "Pearl Basin") %>% 
  st_zm()

sf_pearl_pascagoula <- bind_rows(sf_pascagoula, sf_pearl)

sf_pearl_pascagoula %>% 
  ggplot() +
  geom_sf()

filename <- "../public/gis/pearl_pascagoula.geojson"
if (file.exists(filename)) {
  unlink(filename)
}
sf_pearl_pascagoula %>% 
  # st_simplify(dTolerance = 100) %>%
  write_sf(filename, driver = "GeoJSON", layer_options = c("COORDINATE_PRECISION=5", "ID_GENERATE=YES"))


# mobile/tombigbee --------------------------------------------------------

sf_mobile <- st_read(file.path(gis_dir, "Alabama", "Mobile Tombigbee", "Mobile", "WBDHU4.shp")) %>% 
  mutate(label = "Mobile Basin")
sf_tombigbee <- st_read(file.path(gis_dir, "Alabama", "Mobile Tombigbee", "Tombigbee", "WBDHU4.shp")) %>% 
  mutate(label = "Tombigbee Basin")

sf_mobile_tombigbee <- bind_rows(sf_mobile, sf_tombigbee)

sf_mobile_tombigbee %>% 
  ggplot() +
  geom_sf()

filename <- "../public/gis/mobile_tombigbee.geojson"
if (file.exists(filename)) {
  unlink(filename)
}
sf_mobile_tombigbee %>% 
  st_simplify(dTolerance = 10) %>%
  write_sf(filename, driver = "GeoJSON", layer_options = c("COORDINATE_PRECISION=5", "ID_GENERATE=YES"))


# alabama SHU -------------------------------------------------------------

sf_alabama_shu <- st_read(file.path(gis_dir, "Alabama", "SHU", "SHU_SRRU_v3.shp")) %>% 
  st_transform(crs = "EPSG:4326") %>% 
  st_make_valid()

sf_alabama_shu %>% 
  st_simplify(dTolerance = 100) %>%
  ggplot() +
  geom_sf()

filename <- "../public/gis/alabama_shu.geojson"
if (file.exists(filename)) {
  unlink(filename)
}
sf_alabama_shu %>% 
  st_simplify(dTolerance = 100) %>%
  transmute(
    label = glue("AL SHU: {name}")
  ) %>% 
  write_sf(filename, driver = "GeoJSON", layer_options = c("COORDINATE_PRECISION=6", "ID_GENERATE=YES"))


# ecoflows --------------------------------------------------------

sf_ecoflows <- st_read(file.path(gis_dir, "Ecoflows", "study_area_bnd_project.shp")) %>% 
  st_transform(crs = 4326) %>% 
  transmute(label = "Ecoflows Study Area") %>% 
  st_make_valid()

sf_ecoflows %>% 
  ggplot() +
  geom_sf()

filename <- "../public/gis/ecoflows.geojson"
if (file.exists(filename)) {
  unlink(filename)
}
sf_ecoflows %>% 
  # st_simplify(dTolerance = 100) %>%
  write_sf(filename, driver = "GeoJSON", layer_options = c("COORDINATE_PRECISION=5", "ID_GENERATE=YES"))
