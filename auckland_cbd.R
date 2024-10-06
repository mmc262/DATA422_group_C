# run previous script
source("02_merge.R")

# filter data to include only Auckland CBD areas
auckland_cbd_data <- sqldf("SELECT *
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
              'Symonds Street West')")

auckland_device_counts <- sqldf("
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
  FROM auckland_cbd_data
  ORDER BY territorial_authority_code, statistical_area_level_2_code, NZST_date_time")

auckland_diff_device_counts <- sqldf("
  SELECT 
    difference_from_last_hour AS total_difference,
    statistical_area_level_2_code,
    territorial_authority_code,
    NZST_date_time,
    people_count,
    previous_hour_people_count
  FROM auckland_device_counts")

# PLOT ------------------------------------------------------------------------

# Add a new column for the day of the week
auckland_diff_device_counts <- auckland_diff_device_counts %>%
  mutate(day_of_week = wday(NZST_date_time, label = TRUE))

# Aggregate by day of the week and calculate the sum of absolute changes
auckland_aggregated_data <- auckland_diff_device_counts %>%
  group_by(day_of_week) %>%
  summarise(total_difference = sum(abs(total_difference), na.rm = TRUE))

# Plot the aggregated data
auckland_aggregated_data %>%
  ggplot(aes(x = day_of_week, y = total_difference)) +
  geom_col() +
  labs(title = "Sum of Absolute Changes by Day of the Week In Auckland CBD Areas",
       x = "Day of the Week",
       y = "Sum of Absolute Changes")