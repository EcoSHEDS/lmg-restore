library(tidyverse)
library(sf)
library(USAboundaries)

sf_states <- us_states(resolution = "low", states = c("TX", "AR", "OK", "MO", "IL", "KY", "TN", "AL", "MS", "GA", "TN", "FL", "SC", "LA", "NC"))

sf_states %>% 
  ggplot() +
  geom_sf()

filename <- "../public/gis/states.geojson"
if (file.exists(filename)) {
  unlink(filename)
}
sf_states %>% 
  select(label = state_name, code = state_abbr) %>% 
  write_sf(filename, driver = "GeoJSON", layer_options = c("COORDINATE_PRECISION=6", "ID_GENERATE=YES"))
