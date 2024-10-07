# run previous script
source("03_analysis.R")


# add a new column for the day of the week, and hour.
diff_device_counts <- diff_device_counts %>%
  mutate(day_of_week = wday(NZST_date_time, label = TRUE),
         hour = hour(NZST_date_time),
         day = day(NZST_date_time))

# DAY--------------------------------------------------------------------------

# aggregate by day of the week or hour and calculate the sum of absolute changes
aggregated_data <- diff_device_counts %>%
  group_by(day) %>%
  summarise(total_difference = sum(abs(total_difference), na.rm = TRUE))

# plot the aggregated data
aggregated_data %>%
  ggplot(aes(x = day, y = total_difference)) +
  geom_col() +
  labs(title = "Sum of Absolute Changes by Day of the Week",
       x = "Day of the Week",
       y = "Sum of Absolute Changes")

# HOUR -------------------------------------------------------------------------

# aggregate by day of the week or hour and calculate the sum of absolute changes
aggregated_data <- diff_device_counts %>%
  group_by(hour) %>%
  summarise(total_difference = sum(abs(total_difference), na.rm = TRUE))

# plot the aggregated data
aggregated_data %>%
  ggplot(aes(x = hour, y = total_difference)) +
  geom_col() +
  labs(title = "Sum of Absolute Changes by Hour of the Day",
       x = "Hour of the Day",
       y = "Sum of Absolute Changes")