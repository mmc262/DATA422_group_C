# run previous script
source("02_merge.R")

# filter data to include only CBD areas
total_cbd_data <- sqldf("SELECT *
              FROM clean_dataset
              WHERE territorial_authority_code IN ('Queen Street',
              'Quay Street-Customs Street',
              'Wynyard-Viaduct',
              'Shortland Street',
              'Victoria Park',
              'Hobson Ridge North',
              'Hobson Ridge Central',
              'Hobson Ridge South',
              'Freemans Bay',
              'Auckland-University',
              'College Hill',
              'Ponsonby East',
              'Ponsonby West',
              'Saint Marys Bay',
              'Symonds Street East',
              'Symonds Street North West',
              'Symonds Street West',
              'Pipitea-Kaiwharawhara',
              'Thorndon South',
              'Wellington Botanic Gardens',
              'Kelburn', 'Aro Valley',
              'Wellington University',
              'Wellington Central',
              'Dixon Street West',
              'Dixon Street East',
              'Vivian West',
              'Courtenay',
              'Mount Cook North',
              'Mount Cook South',
              'Vivian East',
              'Mount Cook East',
              'Mount Victoria North',
              'Mount Victoria South',
              'Oriental Bay',
              'Christchurch Central-West',
              'Christchurch Central-North',
              'Christchurch Central',
              'Christchurch Central-East',
              'Christchurch Central-South',
              'Hagley Park',
              'Lancaster Park',
              'Sydenham Central',
              'Addington West',
              'Addington North',
              'Addington East',
              'Stanmore',
              'Phillipstown')") %>%
  filter(device_count > 0)

cbd_device_counts <- sqldf("
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
  FROM total_cbd_data
  ORDER BY territorial_authority_code, statistical_area_level_2_code, NZST_date_time")

cbd_diff_device_counts <- sqldf("
  SELECT 
    difference_from_last_hour AS total_difference,
    statistical_area_level_2_code,
    territorial_authority_code,
    NZST_date_time,
    people_count,
    previous_hour_people_count
  FROM cbd_device_counts")

# PLOT ------------------------------------------------------------------------

# add a new column for the day of the week, and hour.
cbd_diff_device_counts <- cbd_diff_device_counts %>%
  mutate(day_of_week = wday(NZST_date_time, label = TRUE),
         hour = hour(NZST_date_time),
         day = day(NZST_date_time))

# DAY--------------------------------------------------------------------------

# aggregate by day of the week or hour and calculate the sum of absolute changes
cbd_aggregated_data <- cbd_diff_device_counts %>%
  group_by(day) %>%
  summarise(total_difference = sum(abs(total_difference), na.rm = TRUE))

# plot the aggregated data
cbd_aggregated_data %>%
  ggplot(aes(x = day, y = total_difference)) +
  geom_col() +
  labs(title = "Sum of Absolute Changes by Day of the Week",
       x = "Day of the Week",
       y = "Sum of Absolute Changes")

# HOUR -------------------------------------------------------------------------

# aggregate by day of the week or hour and calculate the sum of absolute changes
cbd_aggregated_data <- cbd_diff_device_counts %>%
  group_by(hour) %>%
  summarise(total_difference = sum(abs(total_difference), na.rm = TRUE))

# plot the aggregated data
cbd_aggregated_data %>%
  ggplot(aes(x = hour, y = total_difference)) +
  geom_col() +
  labs(title = "Sum of Absolute Changes by Hour of the Day in all CBD areas",
       x = "Hour of the Day",
       y = "Sum of Absolute Changes")

# DAY OF WEEK ------------------------------------------------------------------

# aggregate by day of the week or hour and calculate the sum of absolute changes
cbd_aggregated_data <- cbd_diff_device_counts %>%
  group_by(day_of_week) %>%
  summarise(total_difference = sum(abs(total_difference), na.rm = TRUE))

# plot the aggregated data
cbd_aggregated_data %>%
  ggplot(aes(x = day_of_week, y = total_difference)) +
  geom_col() +
  labs(title = "Sum of Absolute Changes by Hour of the Day in all CBD areas",
       x = "Hour of the Day",
       y = "Sum of Absolute Changes")