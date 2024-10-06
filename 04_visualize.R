# run previous script
source("03_analysis.R")


# Add a new column for the day of the week
diff_device_counts <- diff_device_counts %>%
  mutate(day_of_week = wday(NZST_date_time, label = TRUE),
         hour = hour(NZST_date_time),
         day = day(NZST_date_time))

# Aggregate by day of the week and calculate the sum of absolute changes, ignoring NA values
aggregated_data <- diff_device_counts %>%
  group_by(hour) %>%
  summarise(total_difference = sum(abs(total_difference), na.rm = TRUE))

# Print the aggregated data to inspect the values
print(aggregated_data)

# Plot the aggregated data
aggregated_data %>%
  ggplot(aes(x = hour, y = total_difference)) +
  geom_col() +
  labs(title = "Sum of Absolute Changes by Day of the Week",
       x = "Day of the Week",
       y = "Sum of Absolute Changes")
