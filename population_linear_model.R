# clean data 
device_data <- read.csv("device_populaion_counts.csv") %>%
  drop_na() %>%
  mutate(Population = as.numeric(gsub(",", "", Population))) %>%
  mutate(Devices = as.numeric(Devices))

# fit linear model to predict population using device count
model <- lm(Population ~ Devices, data = device_data)

# plot data with regression line
ggplot2::ggplot(device_data, aes(x = Devices, y = Population)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  labs(title = "Population vs Devices",
       x = "Devices",
       y = "Population") +
  lims(x = c(0, 300000), y = c(0, 500000))

# summary of linear model
summary(model)