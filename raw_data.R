# read .parquet file
install.packages("arrow")
install.packages("sqldf")

library(arrow)
library(sqldf)
library(tidyverse)

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
sp_tele_data <- sp_tele_data %>% mutate(clean_date = as.POSIXct(ts, format="%Y-%m-%dT%H:%M:%SZ")) %>%
  mutate(data_from = "sp")

# clean columns and variable names
sa2_codes_names <- rownames_to_column(sa2_codes_names)
sa2_codes_names <- rename(sa2_codes_names, area_code = rowname, location = Classification.report)
sp_tele_data <- rename(sp_tele_data, dt = ts, area = sa2, devices = cnt)
sa2_to_ta <- rename(sa2_to_ta, area_code = Concordance.report, location_2 = X.3)
urban_rural_codes <- rename(urban_rural_codes, area_code = Concordance.report)
urban_rural_to_sa2 <- rename(urban_rural_to_sa2, area_code = Concordance.report, location_3 = X.3)

# combine telecommunications data from spark and vodafone
combined_tele_data <- rbind(sp_tele_data, vf_tele_data)

# combine location data
combined_location_data <- sqldf("SELECT scn.area_code, scn.location, stt.location_2
                                FROM sa2_codes_names scn
                                JOIN sa2_to_ta stt ON scn.area_code == stt.area_code")

# put clean data into new df
cleaned_data <- sqldf("SELECT ctd.clean_date AS date_time, ctd.devices, ctd.area, cld.location, cld.location_2, ctd.data_from
                      FROM combined_tele_data ctd
                      JOIN combined_location_data cld ON ctd.area == cld.area_code") %>%
  mutate(date_time = as.POSIXct(date_time, origin="1970-01-01", tz="UTC")) %>%
  mutate(date_time = format(date_time, format = "%Y-%m-%d %H:%M:%S"))


