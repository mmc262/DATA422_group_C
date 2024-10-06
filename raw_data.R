# read .parquet file
install.packages("arrow")
install.packages("sqldf")
install.packages("tidyverse")

library(arrow)
library(sqldf)
library(tidyverse)
library(lubridate)

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

# combine telecommunications data from spark and vodafone
combined_tele_data <- rbind(sp_tele_data, vf_tele_data)

# combine location data
combined_location_data <- sqldf("SELECT scn.area_code, scn.location, stt.location_2
                                FROM sa2_codes_names scn
                                JOIN sa2_to_ta stt ON scn.area_code == stt.area_code")

# put clean data into new df
cleaned_data <- sqldf("SELECT ctd.clean_date AS date_time, ctd.devices, ctd.area, cld.location, cld.location_2, ctd.data_from
                      FROM combined_tele_data ctd
                      JOIN combined_location_data cld ON ctd.area == cld.area_code")

# Ensure date_time is in the correct format
cleaned_data <- cleaned_data %>%
  mutate(date_time = as.POSIXct(date_time, format="%Y-%m-%d %H:%M:%S", tz="UTC")) %>%
  mutate(date_time = format(date_time, format = "%Y-%m-%d %H:%M:%S"))

# Device count by territory on June 11th, 2024.
# Date_time chosen as no public holiday, Not a friday or weekend
# and most people asleep at 3am
devices_by_ter <- sqldf("SELECT CAST(SUM(devices) AS INTEGER), location, location_2
                FROM cleaned_data
                WHERE date_time = '2024-06-12 04:00:00'
                GROUP BY location")

# Device count by city on June 11th, 2024.
# Date_time chosen as no public holiday, Not a friday or weekend
# and most people asleep at 3am
devices_by_city <- sqldf("SELECT CAST(SUM(devices) AS INTEGER) AS device_count, location_2
                FROM cleaned_data
                WHERE date_time = '2024-06-12 04:00:00'
                GROUP BY location_2")

# clean dataset (deliverable)
clean_dataset <- sqldf("SELECT location AS territorial_authority_code,
                       location_2 AS statistical_area_level_2_code,
                       date_time AS NZST_date_time,
                       CAST(SUM(devices) AS INTEGER) AS people_count
                       FROM cleaned_data
                       GROUP BY location_2, location, date_time
                       ORDER BY territorial_authority_code, statistical_area_level_2_code") %>%
  drop_na()

# export clean data set
write.csv(clean_dataset, file = "clean_dataset.csv", row.names = FALSE)

# get device counts and difference in device counts from last hour
device_counts <- sqldf("
  SELECT people_count,
    LAG(people_count, 1) 
    OVER(PARTITION BY territorial_authority_code, statistical_area_level_2_code 
    ORDER BY NZST_date_time) AS previous_hour_people_count,
    people_count - LAG(people_count, 1) 
    OVER(PARTITION BY territorial_authority_code, statistical_area_level_2_code 
    ORDER BY NZST_date_time) AS difference_from_last_hour,
    territorial_authority_code,
    statistical_area_level_2_code,
    NZST_date_time
  FROM clean_dataset
  ORDER BY territorial_authority_code, statistical_area_level_2_code, NZST_date_time")

diff_device_counts <- sqldf("
  SELECT 
    difference_from_last_hour AS total_difference,
    statistical_area_level_2_code,
    territorial_authority_code,
    NZST_date_time,
    people_count,
    previous_hour_people_count
  FROM device_counts")


# Perform the SQL query without filtering by territorial_authority_code
test <- sqldf("SELECT *
              FROM diff_device_counts
              ORDER BY NZST_date_time")

# Add a new column for the day of the week
test <- test %>%
  mutate(day_of_week = wday(NZST_date_time, label = TRUE))

# Aggregate by day of the week and calculate the sum of absolute changes, ignoring NA values
aggregated_data <- test %>%
  group_by(day_of_week) %>%
  summarise(total_difference = sum(abs(total_difference), na.rm = TRUE))

# Print the aggregated data to inspect the values
print(aggregated_data)

# Plot the aggregated data
aggregated_data %>%
  ggplot(aes(x = day_of_week, y = total_difference)) +
  geom_col() +
  labs(title = "Sum of Absolute Changes by Day of the Week",
       x = "Day of the Week",
       y = "Sum of Absolute Changes")



