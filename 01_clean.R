# run previous script
source("00_load.R")

# read in raw data
sp_tele_data <- read.csv("sp_data.csv.gz")
vf_tele_data <- read_parquet("vf_data.parquet")
sa2_codes_names <- read.csv("sa2_2023.csv")
sa2_to_ta <- read.csv("sa2_ta_concord_2023.csv")
pop_estimates <- read.csv("subnational_pop_ests.csv")
urban_rural_codes <- read.csv("urban_rural_to_indicator_2023.csv")
urban_rural_to_sa2 <- read.csv("urban_rural_to_sa2_concord_2023.csv")

# clean date time data
vf_tele_data <- vf_tele_data %>% mutate(clean_date = as.POSIXct(dt, origin="1970-01-01", tz="UTC")) %>%
  mutate(data_from = "vf")
sp_tele_data <- sp_tele_data %>%
  mutate(clean_date = as.POSIXct(ts, format="%Y-%m-%dT%H:%M:%SZ", tz="UTC") + 12 * 3600,
         clean_date = format(clean_date, "%Y-%m-%d %H:%M:%S"),
         data_from = "sp")

# clean columns and variable names
sa2_codes_names <- rownames_to_column(sa2_codes_names)
sa2_codes_names <- rename(sa2_codes_names, area_code = rowname, location = Classification.report)
sp_tele_data <- rename(sp_tele_data, dt = ts, area = sa2, devices = cnt)
sa2_to_ta <- rename(sa2_to_ta, area_code = Concordance.report, location_2 = X.3)
urban_rural_codes <- rename(urban_rural_codes, area_code = Concordance.report)
urban_rural_to_sa2 <- rename(urban_rural_to_sa2, area_code = Concordance.report, location_3 = X.3)