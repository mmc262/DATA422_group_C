# run previous script
source("02_merge.R")

# filter data to include only Christchurch CBD areas
christchurch_cbd_data <- sqldf("SELECT *
              FROM clean_dataset
              WHERE territorial_authority_code IN ('Christchurch Central-West',
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
              'Phillipstown')")

# Get device counts for christchurch and differences between device counts each hour
christchurch_device_counts <- sqldf("
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
  FROM christchurch_cbd_data
  ORDER BY territorial_authority_code, statistical_area_level_2_code, NZST_date_time")

christchurch_diff_device_counts <- sqldf("
  SELECT 
    difference_from_last_hour AS total_difference,
    statistical_area_level_2_code,
    territorial_authority_code,
    NZST_date_time,
    people_count,
    previous_hour_people_count
  FROM christchurch_device_counts")

# PLOT ------------------------------------------------------------------------

# add a new column for the day of the week
christchurch_diff_device_counts <- christchurch_diff_device_counts %>%
  mutate(day_of_week = wday(NZST_date_time, label = TRUE))

# aggregate by day of the week and calculate the sum of absolute changes
christchurch_aggregated_data <- christchurch_diff_device_counts %>%
  group_by(day_of_week) %>%
  summarise(total_difference = sum(abs(total_difference), na.rm = TRUE))

# plot the aggregated data
christchurch_aggregated_data %>%
  ggplot(aes(x = day_of_week, y = total_difference)) +
  geom_col() +
  labs(title = "Sum of Absolute Changes by Day of the Week In Christchurch CBD Areas",
       x = "Day of the Week",
       y = "Sum of Absolute Changes")