# run previous script
source("02_merge.R")

# filter data to include only Wellington CBD areas
wellington_cbd_data <- sqldf("SELECT *
              FROM clean_dataset
              WHERE territorial_authority_code IN ('Pipitea-Kaiwharawhara',
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
              'Oriental Bay')") %>%
  filter(device_count > 0)

wellington_device_counts <- sqldf("
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
  FROM wellington_cbd_data
  ORDER BY territorial_authority_code, statistical_area_level_2_code, NZST_date_time")

wellington_diff_device_counts <- sqldf("
  SELECT 
    difference_from_last_hour AS total_difference,
    statistical_area_level_2_code,
    territorial_authority_code,
    NZST_date_time,
    people_count,
    previous_hour_people_count
  FROM wellington_device_counts")

# PLOT ------------------------------------------------------------------------

# add a new column for the day of the week, and hour.
wellington_diff_device_counts <- wellington_diff_device_counts %>%
  mutate(day_of_week = wday(NZST_date_time, label = TRUE),
         hour = hour(NZST_date_time),
         day = day(NZST_date_time))

# DAY--------------------------------------------------------------------------

# aggregate by day of the week or hour and calculate the sum of absolute changes
wellington_aggregated_data <- wellington_diff_device_counts %>%
  group_by(day) %>%
  summarise(total_difference = sum(abs(total_difference), na.rm = TRUE))

# plot the aggregated data
wellington_aggregated_data %>%
  ggplot(aes(x = day, y = total_difference)) +
  geom_col() +
  labs(title = "Sum of Absolute Changes by Day of the Week",
       x = "Day of the Week",
       y = "Sum of Absolute Changes")

# HOUR -------------------------------------------------------------------------

# aggregate by day of the week or hour and calculate the sum of absolute changes
wellington_aggregated_data <- wellington_diff_device_counts %>%
  group_by(hour) %>%
  summarise(total_difference = sum(abs(total_difference), na.rm = TRUE))

# plot the aggregated data
wellington_aggregated_data %>%
  ggplot(aes(x = hour, y = total_difference)) +
  geom_col() +
  labs(title = "Sum of Absolute Changes by Hour of the Day in Wellington CBD areas",
       x = "Hour of the Day",
       y = "Sum of Absolute Changes")

# DAY OF WEEK ------------------------------------------------------------------

# aggregate by day of the week or hour and calculate the sum of absolute changes
wellington_aggregated_data <- wellington_diff_device_counts %>%
  group_by(day_of_week) %>%
  summarise(total_difference = sum(abs(total_difference), na.rm = TRUE))

# plot the aggregated data
wellington_aggregated_data %>%
  ggplot(aes(x = day_of_week, y = total_difference)) +
  geom_col() +
  labs(title = "Sum of Absolute Changes by Hour of the Day in Wellington CBD areas",
       x = "Hour of the Day",
       y = "Sum of Absolute Changes")