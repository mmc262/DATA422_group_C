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
              'Oriental Bay')")

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

# Add a new column for the day of the week
wellington_diff_device_counts <- wellington_diff_device_counts %>%
  mutate(day_of_week = wday(NZST_date_time, label = TRUE))

# Aggregate by day of the week and calculate the sum of absolute changes
wellington_aggregated_data <- wellington_diff_device_counts %>%
  group_by(day_of_week) %>%
  summarise(total_difference = sum(abs(total_difference), na.rm = TRUE))

# Plot the aggregated data
wellington_aggregated_data %>%
  ggplot(aes(x = day_of_week, y = total_difference)) +
  geom_col() +
  labs(title = "Sum of Absolute Changes by Day of the Week In Wellington CBD Areas",
       x = "Day of the Week",
       y = "Sum of Absolute Changes")