# generate all themes

library(tidyverse)

themes <- c("gage-cov", "gage-qstat", "gage-qtrend", "gage-solar", "gage-primary", "huc12-cov", "huc12-qquantile", "huc12-solar", "huc12-primary")

for (t in themes) {
  cat(rep("-", times = 80), "\n", sep = "")
  cat("Theme:", t, "\n\n")
  source(glue::glue("theme-{t}.R"))
}
