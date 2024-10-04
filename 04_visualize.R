# run previous script
source("03_analysis.R")


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

