# generate all themes

library(tidyverse)

themes <- c(
  "gage-cov",
  "gage-ecoflows", 
  "gage-lff", 
  "gage-primary", 
  "gage-qstat",
  "gage-qtrend", 
  "gage-solar", 
  "huc12-cov",
  "huc12-hydroalt", 
  "huc12-lff", 
  "huc12-primary",
  "huc12-qquantile", 
  "huc12-solar"
)

for (t in themes) {
  cat(rep("-", times = 80), "\n", sep = "")
  cat("Theme:", t, "\n\n")
  source(glue::glue("theme-{t}.R"))
}
