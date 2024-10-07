# run previous script
source("03_analysis.R")


# add a new column for the day of the week, and hour.
diff_device_counts <- diff_device_counts %>%
  mutate(day_of_week = wday(NZST_date_time, label = TRUE),
         hour = hour(NZST_date_time),
         day = day(NZST_date_time))

# aggregate by day of the week or hour and calculate the sum of absolute changes
# change "day" for "hour" to plot by hour
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
