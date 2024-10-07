# run previous script
source("01_clean.R")

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

# clean dataset (deliverable)
clean_dataset <- sqldf("SELECT location AS territorial_authority_code,
                       location_2 AS statistical_area_level_2_code,
                       date_time AS NZST_date_time,
                       CAST(SUM(devices) AS INTEGER) AS device_count
                       FROM cleaned_data
                       GROUP BY location_2, location, date_time
                       ORDER BY territorial_authority_code, statistical_area_level_2_code") %>%
  drop_na() %>%
  mutate(people_count = 1.52623 * device_count)

# ONLY INCLUDE DAY 7AM TO 6 PM (ctrl + shift + C)
# clean_dataset$NZST_date_time <- as.POSIXct(clean_dataset$NZST_date_time, format="%Y-%m-%d %H:%M:%S", tz="UTC")
# 
# # Filter the data
# clean_dataset <- clean_dataset %>%
#   filter(format(NZST_date_time, "%H:%M:%S") >= "07:00:00" & format(NZST_date_time, "%H:%M:%S") <= "18:00:00")
