# variables from all themes

library(tidyverse)
library(jsonlite)
library(glue)
library(xml2)
library(sf)

config <- config::get()

themes <- list.dirs(path = config$data_dir, recursive = FALSE) %>% basename()


# gage-cov ----------------------------------------------------------------

xml_gage_cov <- read_xml(file.path(config$data_dir, "gage-cov", "Summary of basin characteristics for NHD v.2 catchments in the southeastern U.S., 1950-2010 at USGS streamflow-gaging stations.xml"))
xml_gage_cov_attrs <- xml_find_all(xml_gage_cov, './eainfo/detailed/attr')

vars_gage_cov <- tibble(
  i = 1:length(xml_gage_cov_attrs)
) %>% 
  mutate(
    el = map(i, ~ xml_gage_cov_attrs[.]),
    attrlabl = map_chr(el, ~ xml_text(xml_child(., "attrlabl"))),
    attrdef = map_chr(el, ~ xml_text(xml_child(., "attrdef"))),
    rdommin = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommin"))),
    rdommax = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommax"))),
    attrunit = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/attrunit"))),
  ) %>% 
  mutate_at(vars(rdommin, rdommax), parse_number) %>% 
  select(
    variable = attrlabl,
    description = attrdef,
    unit = attrunit
  ) %>% 
  mutate(
    theme = "gage-cov"
  )

df_gage_cov <- read_csv(file.path(config$data_dir, "gage-cov", "all_gage_covariates.csv"), col_types = cols(
  .default = col_double(),
  site_no = col_character(),
  huc12 = col_character(),
  aquifers = col_character(),
  cat_aquifers = col_character(),
  bedperm = col_character(),
  ecol3 = col_character(),
  cat_ecol3 = col_character(),
  hlr = col_character(),
  physio = col_character(),
  cat_physio = col_character(),
  soller = col_character(),
  cat_soller = col_character(),
  statsgo = col_character()
))
df_gage_cov

# id: comid, site_no, huc12
# geo: dec_lat_va, dec_long_va
# time: decade (some variables)

# gage-qstat -------------------------------------------------------------

xml_gage_qstat <- read_xml(file.path(config$data_dir, "gage-qstat", "all_gage_flow_stats.xml"))
xml_gage_qstat_attrs <- xml_find_all(xml_gage_qstat, './eainfo/detailed[1]/attr')

vars_gage_qstat <- tibble(
  i = 1:length(xml_gage_qstat_attrs)
) %>% 
  mutate(
    el = map(i, ~ xml_gage_qstat_attrs[.]),
    attrlabl = map_chr(el, ~ xml_text(xml_child(., "attrlabl"))),
    attrdef = map_chr(el, ~ xml_text(xml_child(., "attrdef"))),
    rdommin = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommin"))),
    rdommax = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommax"))),
    attrunit = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/attrunit"))),
  ) %>% 
  mutate_at(vars(rdommin, rdommax), parse_number) %>% 
  select(
    variable = attrlabl,
    description = attrdef,
    unit = attrunit
  ) %>% 
  mutate(
    theme = "gage-qstat"
  )

df_gage_qstat <- read_csv(file.path(config$data_dir, "gage-qstat", "all_gage_flow_stats.csv"), col_types = cols(
  .default = col_double(),
  site_no = col_character(),
  huc12 = col_character()
)) %>% 
  arrange(site_no, decade)

# id: comid, site_no, huc12
# geo: dec_lat_va, dec_long_va
# time: decade (all variables)


# gage-qtrend -------------------------------------------------------------

xml_gage_qtrend <- read_xml(file.path(config$data_dir, "gage-qtrend", "Metadata for Trend analysis for sites used in RESTORE Streamflow alterations assessments.xml"))
xml_find_all(xml_gage_qtrend, './eainfo/detailed')
xml_gage_qtrend_attrs_mk <- xml_find_all(xml_gage_qtrend, './eainfo/detailed[1]/attr')
xml_gage_qtrend_attrs_qk <- xml_find_all(xml_gage_qtrend, './eainfo/detailed[2]/attr')
xml_gage_qtrend_attrs <- c(xml_gage_qtrend_attrs_mk, xml_gage_qtrend_attrs_qk)

vars_gage_qtrend <- tibble(
  test = c(rep("MK", length(xml_gage_qtrend_attrs_mk)), rep("QK", length(xml_gage_qtrend_attrs_qk))),
  i = 1:length(xml_gage_qtrend_attrs)
) %>% 
  mutate(
    el = map(i, ~ xml_gage_qtrend_attrs[[.]]),
    attrlabl = map_chr(el, ~ xml_text(xml_child(., "attrlabl"))),
    attrdef = map_chr(el, ~ xml_text(xml_child(., "attrdef"))),
    rdommin = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommin"))),
    rdommax = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommax"))),
    attrunit = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/attrunit"))),
  ) %>% 
  mutate_at(vars(rdommin, rdommax), parse_number) %>% 
  select(
    test,
    variable = attrlabl,
    description = attrdef,
    unit = attrunit
  ) %>% 
  mutate(
    theme = "gage-qtrend"
  )

# id: site_no
# subset: quantile (MK only, all variables)
# subset: rank (QK only, all variables)
# time: season, decade (MK & QK, all variables)

# season: 
#  MK = Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec, Spring, Summer, Fall, Winter
#  QK = All, Spring, Summer, Fall, Winter
# quantile:
#  MK = Q00, Q10, Q20, ..., Q80, Q90, Q100
# rank:
#  QK = 1, 2, 3, ..., # days in season



# gage-qts ----------------------------------------------------------

xml_gage_qts <- read_xml(file.path(config$data_dir, "gage-qts", "metadata_copula.xml"))
xml_gage_qts_attrs <- xml_find_all(xml_gage_qts, './eainfo/detailed[3]/attr')

vars_gage_qts <- tibble(
  i = 1:length(xml_gage_qts_attrs)
) %>% 
  mutate(
    el = map(i, ~ xml_gage_qts_attrs[.]),
    attrlabl = map_chr(el, ~ xml_text(xml_child(., "attrlabl"))),
    attrdef = map_chr(el, ~ xml_text(xml_child(., "attrdef"))),
    rdommin = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommin"))),
    rdommax = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommax"))),
    attrunit = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/attrunit"))),
  ) %>% 
  mutate_at(vars(rdommin, rdommax), parse_number) %>% 
  select(
    variable = attrlabl,
    description = attrdef,
    unit = attrunit
  ) %>% 
  mutate(
    theme = "gage-qts"
  )

df_gage_qts <- read_csv(file.path(config$data_dir, "gage-qts", "dv_output.csv"), col_types = cols(
  .default = col_double(),
  date = col_date(format = ""),
  target = col_character(),
  basin = col_character()
))

df_gage_qts %>%
  filter(target == df_gage_qts$target[[1]]) %>% 
  gather(var, value, -date, -target, -basin) %>% 
  ggplot(aes(date, value)) +
  geom_line() +
  facet_wrap(vars(var))

# id: target, basin
# time: date (all variables)


# gage-solar --------------------------------------------------------------

xml_gage_solar <- read_xml(file.path(config$data_dir, "gage-solar", "Solar radiation for NHD, v.2 catchments in the southeastern U.S., 1950-2010 at USGS streamflow-gaging stations.xml"))
xml_find_all(xml_gage_solar, './eainfo/detailed')
xml_gage_solar_attrs <- xml_find_all(xml_gage_solar, './eainfo/detailed[1]/attr')

vars_gage_solar <- tibble(
  i = 1:length(xml_gage_solar_attrs)
) %>% 
  mutate(
    el = map(i, ~ xml_gage_solar_attrs[.]),
    attrlabl = map_chr(el, ~ xml_text(xml_child(., "attrlabl"))),
    attrdef = map_chr(el, ~ xml_text(xml_child(., "attrdef"))),
    rdommin = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommin"))),
    rdommax = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommax"))),
    attrunit = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/attrunit"))),
  ) %>% 
  mutate_at(vars(rdommin, rdommax), parse_number) %>% 
  select(
    variable = attrlabl,
    description = attrdef,
    unit = attrunit
  ) %>% 
  mutate(
    theme = "gage-solar"
  )

df_gage_solar <- read_csv(file.path(config$data_dir, "gage-solar", "all_gage_solar.csv"), col_types = cols(
  .default = col_double(),
  site_no = col_character(),
  huc12 = col_character()
)) %>% 
  arrange(site_no, decade)

# id: comid, site_no, huc12
# geo: dec_lat_va, dec_long_va
# time: none (decade is not actuall used)

df_gage_solar %>% 
  select(site_no, decade, dni_ann) %>% 
  group_by(site_no) %>% 
  summarise(
    min = min(dni_ann),
    max = max(dni_ann),
    range = diff(range(dni_ann))
  ) %>% 
  filter(range > 0)
# none of the sites have annual values varying by decade

# huc12-cov ----------------------------------------------------------------

xml_huc12_cov <- read_xml(file.path(config$data_dir, "huc12-cov", "Summary of basin characteristics for NHD, v.2 catchments in the southeastern U.S., 1950-2010 at 12-digit hydrologic unit code (HUC12) pour points.xml"))
xml_find_all(xml_huc12_cov, './eainfo/detailed')
xml_huc12_cov_attrs <- xml_find_all(xml_huc12_cov, './eainfo/detailed/attr')

vars_huc12_cov <- tibble(
  i = 1:length(xml_huc12_cov_attrs)
) %>% 
  mutate(
    el = map(i, ~ xml_huc12_cov_attrs[.]),
    attrlabl = map_chr(el, ~ xml_text(xml_child(., "attrlabl"))),
    attrdef = map_chr(el, ~ xml_text(xml_child(., "attrdef"))),
    rdommin = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommin"))),
    rdommax = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommax"))),
    attrunit = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/attrunit"))),
  ) %>% 
  mutate_at(vars(rdommin, rdommax), parse_number) %>% 
  select(
    variable = attrlabl,
    description = attrdef,
    unit = attrunit
  ) %>% 
  mutate(
    theme = "huc12-cov"
  )

df_huc12_cov <- read_csv(file.path(config$data_dir, "huc12-cov", "all_huc12_covariates.csv"), col_types = cols(
  .default = col_double(),
  huc12 = col_character(),
  aquifers = col_character(),
  cat_aquifers = col_character(),
  bedperm = col_character(),
  ecol3 = col_character(),
  cat_ecol3 = col_character(),
  hlr = col_character(),
  physio = col_character(),
  cat_physio = col_character(),
  soller = col_character(),
  cat_soller = col_character(),
  statsgo = col_character()
))
df_huc12_cov

# id: comid, huc12
# geo: dec_lat_va, dec_long_va
# time: decade (some variables)


# huc12-qquantile ---------------------------------------------------------

xml_huc12_qquantile <- read_xml(file.path(config$data_dir, "huc12-qquantile", "meta_data_huc12_fdc_final.xml"))
xml_find_all(xml_huc12_qquantile, './eainfo/detailed')
xml_huc12_qquantile_attrs <- xml_find_all(xml_huc12_qquantile, './eainfo/detailed[1]/attr')

vars_huc12_qquantile <- tibble(
  i = 1:length(xml_huc12_qquantile_attrs)
) %>% 
  mutate(
    el = map(i, ~ xml_huc12_qquantile_attrs[.]),
    attrlabl = map_chr(el, ~ xml_text(xml_child(., "attrlabl"))),
    attrdef = map_chr(el, ~ xml_text(xml_child(., "attrdef"))),
    rdommin = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommin"))),
    rdommax = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommax"))),
    attrunit = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/attrunit"))),
  ) %>% 
  mutate_at(vars(rdommin, rdommax), parse_number) %>% 
  select(
    variable = attrlabl,
    description = attrdef,
    unit = attrunit
  ) %>% 
  mutate(
    theme = "huc12-qquantile"
  )

df_huc12_qquantile <- read_csv(file.path(config$data_dir, "huc12-qquantile", "fdc_predictions_huc12s.csv"), col_types = cols(
  comid = col_double(),
  huc12 = col_character(),
  decade = col_double(),
  dec_long_va = col_double(),
  dec_lat_va = col_double(),
  quantile = col_character(),
  p0.0015 = col_double(),
  p0.0250 = col_double(),
  p0.1600 = col_double(),
  p0.5000 = col_double(),
  p0.8400 = col_double(),
  p0.9750 = col_double(),
  p0.9985 = col_double(),
  mu = col_double()
))
df_huc12_qquantile

setdiff(sort(vars_huc12_qquantile$variable), sort(names(df_huc12_qquantile)))
setdiff(sort(names(df_huc12_qquantile)), sort(vars_huc12_qquantile$variable))

# id: comid, huc12
# geo: dec_lat_va, dec_long_va
# subset: quantile (f0.03, f0.5, f5, ..., f95, f99.5, f99.97)
# time: decade (all variables)


# huc12-solar --------------------------------------------------------------

xml_huc12_solar <- read_xml(file.path(config$data_dir, "huc12-solar", "Solar radiation for HND, v.2 catchments in the southeastern U.S., 1950-2010 at 12-digit hydrologic unit code (HUC12) pour points.xml"))
xml_find_all(xml_huc12_solar, './eainfo/detailed')
xml_huc12_solar_attrs <- xml_find_all(xml_huc12_solar, './eainfo/detailed[1]/attr')

vars_huc12_solar <- tibble(
  i = 1:length(xml_huc12_solar_attrs)
) %>% 
  mutate(
    el = map(i, ~ xml_huc12_solar_attrs[.]),
    attrlabl = map_chr(el, ~ xml_text(xml_child(., "attrlabl"))),
    attrdef = map_chr(el, ~ xml_text(xml_child(., "attrdef"))),
    rdommin = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommin"))),
    rdommax = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommax"))),
    attrunit = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/attrunit"))),
  ) %>% 
  mutate_at(vars(rdommin, rdommax), parse_number) %>% 
  select(
    variable = attrlabl,
    description = attrdef,
    unit = attrunit
  ) %>% 
  mutate(
    theme = "huc12-solar"
  )

df_huc12_solar <- read_csv(file.path(config$data_dir, "huc12-solar", "all_huc12_solar.csv"), col_types = cols(
  .default = col_double(),
  huc12 = col_character()
)) %>% 
  arrange(huc12, decade)
df_huc12_solar

# id: comid, huc12 (note that 16 huc12s have 2 comids)
# geo: dec_lat_va, dec_long_va
# time: none

df_huc12_solar %>% 
  select(comid, huc12, decade, dni_ann) %>% 
  group_by(comid, huc12) %>% 
  summarise(
    min = min(dni_ann),
    max = max(dni_ann),
    range = diff(range(dni_ann))
  ) %>% 
  filter(range > 0)


# merge -------------------------------------------------------------------

all_vars <- bind_rows(
  vars_gage_cov,
  vars_gage_qstat,
  vars_gage_qtrend,
  vars_gage_qts,
  vars_gage_solar,
  vars_huc12_cov,
  vars_huc12_qquantile,
  vars_huc12_solar
)

