source("02_merge.R")

# get population estimates
population_estimates <- sqldf("SELECT *
              FROM pop_estimates
              WHERE Age = 'Total people, age'
              AND AREA_POPES_SUB_006 >= 100100
              AND AREA_POPES_SUB_006 != 'NZTA'
              AND AREA_POPES_SUB_006 != 99900")

# match population estimates with names
population_estimates_names <- sqldf("SELECT obs_value AS population, area_code, location AS name
                FROM population_estimates t
                JOIN sa2_codes_names sa2 ON t.AREA_POPES_SUB_006 = sa2.area_code")

# get device counts at 5AM on Tuesday, 11th of June
device_count <- sqldf("SELECT *
                FROM clean_dataset
                WHERE NZST_date_time = '2024-06-11 05:00:00'")

# compare device counts to population
population_devices_comp <- sqldf("SELECT name, population, device_count
                FROM device_count dc
                JOIN population_estimates_names pen ON dc.territorial_authority_code = pen.name
                ORDER BY population DESC")

# fit linear model to predict population using device count
model <- lm(population ~ 0+device_count, data = population_devices_comp)

# plot data with regression line
ggplot(population_devices_comp, aes(x = device_count, y = population)) +
  geom_point() +
  geom_smooth(method = "lm", formula = y ~ 0 + x, se = FALSE) +
  geom_abline(intercept = 0, slope = 1, color = "red", size = 1) +
  labs(title = "Population vs Devices",
       x = "Devices",
       y = "Population")

# summary of linear model
summary(model)
