ReadMe
================

- [Purpose Of This Project](#purpose-of-this-project)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
- [Scripts](#scripts)
  - [Main Scripts](#main-scripts)
    - [*00_load.R*](#load.r)
    - [*01_clean.R*](#clean.r)
    - [*02_merge.R*](#merge.r)
    - [*03_analysis.R*](#analysis.r)
    - [*04_visualize.R*](#visualize.r)
  - [Additional Scripts](#additional-scripts)
    - [*export_data.set.R*](#export_data.set.r)
    - [*population_linear_model.R*](#population_linear_model.r)
    - [*required_packages.R*](#required_packages.r)
    - [*time_shift_justification.R*](#time_shift_justification.r)
    - [*auckland_cbd.R*](#auckland_cbd.r)
    - [*christchurch_cbd.R*](#christchurch_cbd.r)
    - [*wellington_cbd.R*](#wellington_cbd.r)
    - [*total_cbd.R*](#total_cbd.r)
- [Datasets](#datasets)
  - [*sp_data*](#sp_data)
  - [*vf_data*](#vf_data)
  - [*sa2_2023*](#sa2_2023)
  - [*sa2_ta_concord_2023*](#sa2_ta_concord_2023)
  - [*subnational_pop_ests*](#subnational_pop_ests)
  - [*urban_rural_to_indicator_2023*](#urban_rural_to_indicator_2023)
  - [*urban_rural_to_sa2_concord_2023*](#urban_rural_to_sa2_concord_2023)

# Purpose Of This Project

In this project, we will assist Fulton Hogan by helping them choose the
best time to schedule of roadworks in the Central Business Districts
(CBDs) of Auckland, Christchurch, and Wellington. We will do this by
determining the benefits of planning these roadworks during school
holidays, the best time of day to plan the roadworks, and by considering
any geographical differences between the cities. We aim to find out
which time of day provides the safest , least disruptive , and most cost
effective window for roadworks, and whether school holidays provide the
same benefits. We will also provide Fulton Hogan with a cleaned dataset,
so their data scientists can conduct any further investigations in the
future.

# Getting Started

Before running any scripts in this project, the following packages need
to be installed:

## Prerequisites

Required packages to run all scripts, found in the required_packages.R
script.

- Arrow<br>*Used to read .parquet files.*

  ``` sh
  install.packages("arrow")
  ```

- Sqldf<br>*Use SQL statements to combine and filter data.*

  ``` sh
  install.packages("sqldf")
  ```

- Tidyverse<br>*Used for piping and plotting.*

  ``` sh
  install.packages("tidyverse")
  ```

# Scripts

The following scripts are broken into two sections, main scripts, and
additional scripts.<br> The main scripts consist of the data processing
pipeline, starting from loading the raw data to plotting the clean
dataset. <br> The additional scripts are for running the main scripts on
specific cities, and some additional information used in the methods
PDF.

## Main Scripts

These scripts make up the five main steps used in this project, starting
from loading the raw data to plotting the clean dataset.

### *00_load.R*

<details>
<summary>
Loads the required libraries, which should be install via the
required_packages.R script. It also reads in all the data which is
required to answer the questions posed by the stakeholders.
</summary>

``` sh
# load libraries
library(arrow)
library(sqldf)
library(tidyverse)
library(lubridate)

# read in raw data
sp_tele_data <- read.csv("sp_data.csv.gz")
vf_tele_data <- read_parquet("vf_data.parquet")
sa2_codes_names <- read.csv("sa2_2023.csv")
sa2_to_ta <- read.csv("sa2_ta_concord_2023.csv")
pop_estimates <- read.csv("subnational_pop_ests.csv")
urban_rural_codes <- read.csv("urban_rural_to_indicator_2023.csv")
urban_rural_to_sa2 <- read.csv("urban_rural_to_sa2_concord_2023.csv")
```

</details>

### *01_clean.R*

<details>
<summary>
Cleans the Spark and Vodafone telecommunications data by renaming
variables so they are matching for both data sets, and for easier
interpretation. The date & time data is also reformatted so both data
sets are compatible for merging.
</summary>

``` sh
# run previous script
source("00_load.R")

# clean date time data
vf_tele_data <- vf_tele_data %>% mutate(clean_date = as.POSIXct(dt, format="%Y-%m-%dT%H:%M:%SZ", tz="UTC") + 12 * 3600,
                                        clean_date = format(clean_date, "%Y-%m-%d %H:%M:%S"),
                                        data_from = "vf") %>%
  distinct()

sp_tele_data <- sp_tele_data %>%
  # Perform the mutation
  mutate(clean_date = as.POSIXct(ts, format="%Y-%m-%dT%H:%M:%SZ", tz="UTC") + 12 * 3600,
         clean_date = format(clean_date, "%Y-%m-%d %H:%M:%S"),
         data_from = "sp") %>%
  distinct()



# clean columns and variable names
sa2_codes_names <- rownames_to_column(sa2_codes_names)
sa2_codes_names <- rename(sa2_codes_names, area_code = rowname, location = Classification.report)
sp_tele_data <- rename(sp_tele_data, dt = ts, area = sa2, devices = cnt)
sa2_to_ta <- rename(sa2_to_ta, area_code = Concordance.report, location_2 = X.3)
urban_rural_codes <- rename(urban_rural_codes, area_code = Concordance.report)
urban_rural_to_sa2 <- rename(urban_rural_to_sa2, area_code = Concordance.report, location_3 = X.3)
```

</details>

### *02_merge.R*

<details>
<summary>
Combines the telecommunications data and the location data, which is
further combined into one large dataset called cleaned_data. The
required variables are then renamed for use in the clean_dataset, which
is outputted to be returned in the deliverables, and used for all
further analysis.
</summary>

``` sh
# run previous script
source("01_clean.R")

# combine telecommunications data from spark and vodafone
combined_tele_data <- rbind(sp_tele_data, vf_tele_data)

# combine location data
combined_location_data <- sqldf("SELECT scn.area_code, scn.location, stt.location_2
                                FROM sa2_codes_names scn
                                JOIN sa2_to_ta stt ON scn.area_code == stt.area_code")

# put clean data into new df
cleaned_data <- sqldf("SELECT ctd.clean_date AS date_time, ctd.devices, ctd.area, cld.location, cld.location_2, ctd.data_from
                      FROM combined_tele_data ctd
                      JOIN combined_location_data cld ON ctd.area == cld.area_code")

# Ensure date_time is in the correct format
cleaned_data <- cleaned_data %>%
  mutate(date_time = as.POSIXct(date_time, format="%Y-%m-%d %H:%M:%S", tz="UTC")) %>%
  mutate(date_time = format(date_time, format = "%Y-%m-%d %H:%M:%S"))

# clean dataset (deliverable)
clean_dataset <- sqldf("SELECT location AS territorial_authority_code,
                       location_2 AS statistical_area_level_2_code,
                       date_time AS NZST_date_time,
                       CAST(SUM(devices) AS INTEGER) AS device_count
                       FROM cleaned_data
                       GROUP BY location_2, location, date_time
                       ORDER BY territorial_authority_code, statistical_area_level_2_code") %>%
  drop_na() %>%
  mutate(people_count = 1.819 * device_count)

# ONLY INCLUDE DAY 7AM TO 6 PM (ctrl + shift + C)
# clean_dataset$NZST_date_time <- as.POSIXct(clean_dataset$NZST_date_time, format="%Y-%m-%d %H:%M:%S", tz="UTC")
# 
# # Filter the data
# clean_dataset <- clean_dataset %>%
#   filter(format(NZST_date_time, "%H:%M:%S") >= "07:00:00" & format(NZST_date_time, "%H:%M:%S") <= "18:00:00")
```

</details>

### *03_analysis.R*

<details>
<summary>
Creates a new variable, which is the current count of people in the area
minus the amount of people in the area in the previous hour. This gives
the difference in people between hours, which models the amount of
people travelling between areas.
</summary>

``` sh
# run previous script
source("02_merge.R")

# get device counts and difference in device counts from last hour
diff_device_counts <- sqldf("
  SELECT people_count,
    LAG(people_count, 1) 
    OVER(PARTITION BY territorial_authority_code, statistical_area_level_2_code 
    ORDER BY NZST_date_time) AS previous_hour_people_count,
    people_count - LAG(people_count, 1) 
    OVER(PARTITION BY territorial_authority_code, statistical_area_level_2_code 
    ORDER BY NZST_date_time) AS total_difference,
    territorial_authority_code,
    statistical_area_level_2_code,
    NZST_date_time
  FROM clean_dataset
  ORDER BY territorial_authority_code, statistical_area_level_2_code, NZST_date_time")
```

</details>

### *04_visualize.R*

<details>
<summary>
Adds a new variable to aggregate the data by either day or hour. The
data is then plotted to see absolute change in people by day or hour.
</summary>

``` sh
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
```

</details>

## Additional Scripts

Scripts that are not used in the main pipeline.

### *export_data.set.R*

<details>
<summary>
Exports the clean data set to be returned in the deliverables.
</summary>

``` sh
# run previous script
source("02_merge.R")

# export clean data set
write.csv(clean_dataset, file = "clean_dataset.csv", row.names = FALSE)
```

</details>

### *population_linear_model.R*

<details>
<summary>
Gives the function used to model the number of people based on device
count.
</summary>

``` sh
# get population estimates
population_estimates <- sqldf("SELECT *
              FROM pop_estimates
              WHERE Age = 'Total people, age'
              AND AREA_POPES_SUB_006 >= 100100
              AND AREA_POPES_SUB_006 != 'NZTA'
              AND AREA_POPES_SUB_006 != 99900")

# tidy data
sa2_codes_names <- rownames_to_column(sa2_codes_names) %>%
  rename(area_name = Classification.report)

# match population estimates with names
population_estimates_names <- sqldf("SELECT obs_value AS population, rowname AS area_code, area_name AS name
                FROM test t
                JOIN sa2_codes_names sa2 ON t.AREA_POPES_SUB_006 = sa2.rowname")

# get device counts at 5AM on Teusday, 11th of June
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
```

</details>

### *required_packages.R*

<details>
<summary>
Contains the code used to install the required packages.
</summary>

``` sh
install.packages("arrow")
install.packages("sqldf")
install.packages("tidyverse")
```

</details>

### *time_shift_justification.R*

<details>
<summary>
Shows the reasons for why time is shifted forward by 12 hours in the
Spark telecommunications data.<br> Further explained in the methods PDF.
</summary>

``` sh
# read the data
sp_tele_data <- read.csv("sp_data.csv.gz")
vf_tele_data <- read_parquet("vf_data.parquet")

# shifting time forwards 12 hours ----------------------------------------------------------

# select the first 40 rows from each data frame
sp_head <- sp_tele_data %>% slice(1:40) %>%
  rename(devices = cnt, area = sa2, dt = ts)

vf_head <- vf_tele_data %>% slice(1:40)


# convert the dt column to character in both data frames
sp_head <- sp_head %>% mutate(dt = as.character(dt), area = as.numeric(area))
vf_head <- vf_head %>% mutate(dt = as.character(dt), area = as.numeric(area))

# combine the data frames with row numbers to maintain the original order
sp_head <- sp_head %>% mutate(row_order = row_number(), source = "SP")
vf_head <- vf_head %>% mutate(row_order = row_number(), source = "VF")

# combine the data frames
combined_data <- bind_rows(sp_head, vf_head)

# plot the dual bar chart with a smooth line
ggplot(combined_data, aes(x = factor(row_order), y = devices, fill = source)) +
  geom_bar(stat = "identity", position = "dodge") +
  geom_smooth(aes(group = source, color = source), method = "loess", se = FALSE) +
  labs(title = "Device Counts Comparison for Each Row",
       x = "Row Order",
       y = "Device Counts",
       fill = "Source",
       color = "Source") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))



# removing the first 12 hours ---------------------------------------------------------------

# select the first 40 rows from each data frame
sp_head <- sp_tele_data %>% slice(13:52) %>%
  rename(devices = cnt, area = sa2, dt = ts)

vf_head <- vf_tele_data %>% slice(1:40)


# convert the dt column to character in both data frames
sp_head <- sp_head %>% mutate(dt = as.character(dt), area = as.numeric(area))
vf_head <- vf_head %>% mutate(dt = as.character(dt), area = as.numeric(area))

# combine the data frames with row numbers to maintain the original order
sp_head <- sp_head %>% mutate(row_order = row_number(), source = "SP")
vf_head <- vf_head %>% mutate(row_order = row_number(), source = "VF")

# combine the data frames
combined_data <- bind_rows(sp_head, vf_head)

# plot the dual bar chart with a smooth line
ggplot(combined_data, aes(x = factor(row_order), y = devices, fill = source)) +
  geom_bar(stat = "identity", position = "dodge") +
  geom_smooth(aes(group = source, color = source), method = "loess", se = FALSE) +
  labs(title = "Device Counts Comparison for Each Row",
       x = "Row Order",
       y = "Device Counts",
       fill = "Source",
       color = "Source") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))
```

</details>

### *auckland_cbd.R*

<details>
<summary>
Runs all the main scripts, but only on areas within the Auckland CBD.
</summary>

``` sh
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
```

</details>

### *christchurch_cbd.R*

<details>
<summary>
Runs all the main scripts, but only on areas within the Christchurch
CBD.
</summary>

``` sh
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
```

</details>

### *wellington_cbd.R*

<details>
<summary>
Runs all the main scripts, but only on areas within the Wellington CBD.
</summary>

``` sh
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
```

</details>

### *total_cbd.R*

<details>
<summary>
Runs all the main scripts, but only on within CBD areas (Auckland,
Christchurch, and Wellington).
</summary>

``` sh
# run previous script
source("02_merge.R")

# filter data to include only CBD areas
total_cbd_data <- sqldf("SELECT *
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
              'Symonds Street West',
              'Pipitea-Kaiwharawhara',
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
              'Oriental Bay',
              'Christchurch Central-West',
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

cbd_device_counts <- sqldf("
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
  FROM total_cbd_data
  ORDER BY territorial_authority_code, statistical_area_level_2_code, NZST_date_time")

cbd_diff_device_counts <- sqldf("
  SELECT 
    difference_from_last_hour AS total_difference,
    statistical_area_level_2_code,
    territorial_authority_code,
    NZST_date_time,
    people_count,
    previous_hour_people_count
  FROM cbd_device_counts")

# PLOT ------------------------------------------------------------------------

# Add a new column for the day of the week
cbd_diff_device_counts <- cbd_diff_device_counts %>%
  mutate(day_of_week = wday(NZST_date_time, label = TRUE))

# Aggregate by day of the week and calculate the sum of absolute changes
cbd_aggregated_data <- cbd_diff_device_counts %>%
  group_by(day_of_week) %>%
  summarise(total_difference = sum(abs(total_difference), na.rm = TRUE))

# Plot the aggregated data
cbd_aggregated_data %>%
  ggplot(aes(x = day_of_week, y = total_difference)) +
  geom_col() +
  labs(title = "Sum of Absolute Changes by Day of the Week In CBD Areas",
       x = "Day of the Week",
       y = "Sum of Absolute Changes")
```

</details>

# Datasets

A brief description of each dataset used, and a dropdown containing the
variable names, and first 20 rows for each dataset.

### *sp_data*

<details>
<summary>
Telecommunications data from Spark.
</summary>

``` r
sp_tele_data <- read.csv("sp_data.csv.gz")
head(sp_tele_data, 20)
```

    ##                      ts    sa2       cnt
    ## 1  2024-06-02T12:00:00Z 100100  792.8768
    ## 2  2024-06-02T13:00:00Z 100100  741.5510
    ## 3  2024-06-02T14:00:00Z 100100 1232.5516
    ## 4  2024-06-02T15:00:00Z 100100  959.4204
    ## 5  2024-06-02T16:00:00Z 100100 1133.9700
    ## 6  2024-06-02T17:00:00Z 100100  662.9584
    ## 7  2024-06-02T18:00:00Z 100100  484.9348
    ## 8  2024-06-02T19:00:00Z 100100  969.6630
    ## 9  2024-06-02T20:00:00Z 100100  837.4511
    ## 10 2024-06-02T21:00:00Z 100100  886.7831
    ## 11 2024-06-02T22:00:00Z 100100  551.8284
    ## 12 2024-06-02T23:00:00Z 100100 1077.4268
    ## 13 2024-06-03T00:00:00Z 100100 1115.3426
    ## 14 2024-06-03T01:00:00Z 100100 1350.2643
    ## 15 2024-06-03T02:00:00Z 100100 1681.5510
    ## 16 2024-06-03T03:00:00Z 100100 1840.4862
    ## 17 2024-06-03T04:00:00Z 100100 1555.3753
    ## 18 2024-06-03T05:00:00Z 100100 2512.6743
    ## 19 2024-06-03T06:00:00Z 100100 1202.1971
    ## 20 2024-06-03T07:00:00Z 100100 2009.2764

</details>

### *vf_data*

<details>
<summary>
Telecommunications data from Vodafone.
</summary>

``` r
vf_tele_data <- read_parquet("vf_data.parquet")
head(vf_tele_data ,20)
```

    ## # A tibble: 20 × 3
    ##    dt                  area   devices
    ##    <dttm>              <chr>    <dbl>
    ##  1 2024-06-03 00:00:00 100100    340.
    ##  2 2024-06-03 01:00:00 100100    318.
    ##  3 2024-06-03 02:00:00 100100    528.
    ##  4 2024-06-03 03:00:00 100100    411.
    ##  5 2024-06-03 04:00:00 100100    486.
    ##  6 2024-06-03 05:00:00 100100    284.
    ##  7 2024-06-03 06:00:00 100100    208.
    ##  8 2024-06-03 07:00:00 100100    416.
    ##  9 2024-06-03 08:00:00 100100    359.
    ## 10 2024-06-03 09:00:00 100100    380.
    ## 11 2024-06-03 10:00:00 100100    236.
    ## 12 2024-06-03 11:00:00 100100    462.
    ## 13 2024-06-03 12:00:00 100100    478.
    ## 14 2024-06-03 13:00:00 100100    579.
    ## 15 2024-06-03 14:00:00 100100    721.
    ## 16 2024-06-03 15:00:00 100100    789.
    ## 17 2024-06-03 16:00:00 100100    667.
    ## 18 2024-06-03 17:00:00 100100   1077.
    ## 19 2024-06-03 18:00:00 100100    515.
    ## 20 2024-06-03 19:00:00 100100    861.

</details>

### *sa2_2023*

<details>
<summary>
SA2 codes and names.
</summary>

``` r
sa2_codes_names <- read.csv("sa2_2023.csv")
head(sa2_codes_names ,20)
```

    ##                               Classification.report  X
    ## Statistical Area 2 2023                             NA
    ## Valid from                              01-Jan-2023 NA
    ## Valid to                Current (as at 20-May-2024) NA
    ## Lifecycle status                           Released NA
    ## Audience                                        OSS NA
    ## Code                                     Descriptor NA
    ## 100100                                   North Cape NA
    ## 100200                             Rangaunu Harbour NA
    ## 100301                    Inlets Far North District NA
    ## 100400                           Karikari Peninsula NA
    ## 100500                                     Tangonge NA
    ## 100600                                      Ahipara NA
    ## 100700                                 Kaitaia East NA
    ## 100800                                 Kaitaia West NA
    ## 100900                                    Rangitihi NA
    ## 101000                               Oruru-Parapara NA
    ## 101101                                Doubtless Bay NA
    ## 101200                             Herekino-Takahue NA
    ## 101300                                        Peria NA
    ## 101400                              Taemaro-Oruaiti NA

</details>

### *sa2_ta_concord_2023*

<details>
<summary>
Concordance for SA2 to Territorial Authorities (TA).
</summary>

``` r
sa2_to_ta <- read.csv("sa2_ta_concord_2023.csv")
head(sa2_to_ta ,20)
```

    ##                                       Concordance.report
    ## 1  Statistical Area 2 2023 to Territorial Authority 2023
    ## 2                                             Valid from
    ## 3                                               Valid to
    ## 4                                       Lifecycle status
    ## 5                              Statistical Area 2 2023 2
    ## 6                                         SA22023 V1.0.0
    ## 7                                                 100100
    ## 8                                                 100200
    ## 9                                                 100301
    ## 10                                                100400
    ## 11                                                100500
    ## 12                                                100600
    ## 13                                                100700
    ## 14                                                100800
    ## 15                                                100900
    ## 16                                                101000
    ## 17                                                101101
    ## 18                                                101200
    ## 19                                                101300
    ## 20                                                101400
    ##                            X             X.1                        X.2
    ## 1                                                                      
    ## 2                   1-Jan-23                                           
    ## 3                   1-Jan-24                                           
    ## 4                   Released                                           
    ## 5                                            Territorial Authority 2023
    ## 6                                                         TA2023 V1.0.0
    ## 7                 North Cape Many To One Map                          1
    ## 8           Rangaunu Harbour Many To One Map                          1
    ## 9  Inlets Far North District Many To One Map                          1
    ## 10        Karikari Peninsula Many To One Map                          1
    ## 11                  Tangonge Many To One Map                          1
    ## 12                   Ahipara Many To One Map                          1
    ## 13              Kaitaia East Many To One Map                          1
    ## 14              Kaitaia West Many To One Map                          1
    ## 15                 Rangitihi Many To One Map                          1
    ## 16            Oruru-Parapara Many To One Map                          1
    ## 17             Doubtless Bay Many To One Map                          1
    ## 18          Herekino-Takahue Many To One Map                          1
    ## 19                     Peria Many To One Map                          1
    ## 20           Taemaro-Oruaiti Many To One Map                          1
    ##                   X.3
    ## 1                    
    ## 2                    
    ## 3                    
    ## 4                    
    ## 5                    
    ## 6                    
    ## 7  Far North District
    ## 8  Far North District
    ## 9  Far North District
    ## 10 Far North District
    ## 11 Far North District
    ## 12 Far North District
    ## 13 Far North District
    ## 14 Far North District
    ## 15 Far North District
    ## 16 Far North District
    ## 17 Far North District
    ## 18 Far North District
    ## 19 Far North District
    ## 20 Far North District

</details>

### *subnational_pop_ests*

<details>
<summary>
A file with population estimates with demographic breakdown.
</summary>

``` r
pop_estimates <- read.csv("subnational_pop_ests.csv")
head(pop_estimates ,20)
```

    ##    STRUCTURE               STRUCTURE_ID
    ## 1   DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 2   DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 3   DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 4   DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 5   DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 6   DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 7   DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 8   DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 9   DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 10  DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 11  DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 12  DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 13  DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 14  DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 15  DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 16  DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 17  DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 18  DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 19  DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ## 20  DATAFLOW STATSNZ:POPES_SUB_006(1.0)
    ##                                                                                        STRUCTURE_NAME
    ## 1  Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 2  Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 3  Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 4  Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 5  Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 6  Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 7  Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 8  Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 9  Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 10 Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 11 Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 12 Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 13 Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 14 Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 15 Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 16 Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 17 Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 18 Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 19 Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ## 20 Subnational population estimates (TA, SA2), by age and sex, at 30 June 1996-2023 (2023 boundaries)
    ##    ACTION YEAR_POPES_SUB_006 Year.at.30.June SEX_POPES_SUB_006
    ## 1       I               2023            2023              SEX3
    ## 2       I               2023            2023              SEX3
    ## 3       I               2023            2023              SEX3
    ## 4       I               2023            2023              SEX3
    ## 5       I               2023            2023              SEX3
    ## 6       I               2023            2023              SEX3
    ## 7       I               2023            2023              SEX3
    ## 8       I               2023            2023              SEX3
    ## 9       I               2023            2023              SEX3
    ## 10      I               2023            2023              SEX3
    ## 11      I               2023            2023              SEX3
    ## 12      I               2023            2023              SEX3
    ## 13      I               2023            2023              SEX3
    ## 14      I               2023            2023              SEX3
    ## 15      I               2023            2023              SEX3
    ## 16      I               2023            2023              SEX3
    ## 17      I               2023            2023              SEX3
    ## 18      I               2023            2023              SEX3
    ## 19      I               2023            2023              SEX3
    ## 20      I               2023            2023              SEX3
    ##                  Sex AGE_POPES_SUB_006        Age AREA_POPES_SUB_006 Area
    ## 1  Total people, sex           AGE0014 0-14 Years              00100   NA
    ## 2  Total people, sex           AGE0014 0-14 Years              00200   NA
    ## 3  Total people, sex           AGE0014 0-14 Years              00300   NA
    ## 4  Total people, sex           AGE0014 0-14 Years              01100   NA
    ## 5  Total people, sex           AGE0014 0-14 Years              01200   NA
    ## 6  Total people, sex           AGE0014 0-14 Years              01300   NA
    ## 7  Total people, sex           AGE0014 0-14 Years              01500   NA
    ## 8  Total people, sex           AGE0014 0-14 Years              01600   NA
    ## 9  Total people, sex           AGE0014 0-14 Years              01700   NA
    ## 10 Total people, sex           AGE0014 0-14 Years              01800   NA
    ## 11 Total people, sex           AGE0014 0-14 Years              01900   NA
    ## 12 Total people, sex           AGE0014 0-14 Years              02000   NA
    ## 13 Total people, sex           AGE0014 0-14 Years              02100   NA
    ## 14 Total people, sex           AGE0014 0-14 Years              02200   NA
    ## 15 Total people, sex           AGE0014 0-14 Years              02300   NA
    ## 16 Total people, sex           AGE0014 0-14 Years              02400   NA
    ## 17 Total people, sex           AGE0014 0-14 Years              02500   NA
    ## 18 Total people, sex           AGE0014 0-14 Years              02600   NA
    ## 19 Total people, sex           AGE0014 0-14 Years              02700   NA
    ## 20 Total people, sex           AGE0014 0-14 Years              02800   NA
    ##    OBS_VALUE Observation.value
    ## 1      15000                NA
    ## 2      19900                NA
    ## 3       5100                NA
    ## 4       4600                NA
    ## 5       4000                NA
    ## 6      19900                NA
    ## 7       7200                NA
    ## 8      38100                NA
    ## 9      12100                NA
    ## 10      2250                NA
    ## 11      5800                NA
    ## 12      2000                NA
    ## 13      7800                NA
    ## 14     10400                NA
    ## 15     31100                NA
    ## 16     16800                NA
    ## 17      8300                NA
    ## 18      1710                NA
    ## 19      2300                NA
    ## 20     11600                NA

</details>

### *urban_rural_to_indicator_2023*

<details>
<summary>
Concordance between urban/rural codes and their type.
</summary>

``` r
urban_rural_codes <- read.csv("urban_rural_to_indicator_2023.csv")
head(urban_rural_codes ,20)
```

    ##                           Concordance.report                              X
    ## 1  Urban Rural 2023 to Urban Rural Indicator                               
    ## 2                                 Valid from                       1-Jan-23
    ## 3                                   Valid to                       1-Jan-24
    ## 4                           Lifecycle status                       Released
    ## 5                         Urban Rural 2023 2                               
    ## 6                              UR2023 V1.0.0                               
    ## 7                                       1001                        Pukenui
    ## 8                                       1002                      Kaimaumau
    ## 9                                       1003                  Tokerau Beach
    ## 10                                      1004                       Karikari
    ## 11                                      1005                         Awanui
    ## 12                                      1006                        Ahipara
    ## 13                                      1007                        Kaitaia
    ## 14                                      1008                          Taipa
    ## 15                                      1009                      Cable Bay
    ## 16                                      1010                  Coopers Beach
    ## 17                                      1011                           Hihi
    ## 18                                      1012                       Mangonui
    ## 19                                      1013 Other rural Far North District
    ## 20                                      1014                      Whangaroa
    ##                X.1                   X.2              X.3
    ## 1                                                        
    ## 2                                                        
    ## 3                                                        
    ## 4                                                        
    ## 5                  Urban Rural Indicator                 
    ## 6                         IUR2018 V1.0.0                 
    ## 7  Many To One Map                    21 Rural settlement
    ## 8  Many To One Map                    21 Rural settlement
    ## 9  Many To One Map                    21 Rural settlement
    ## 10 Many To One Map                    21 Rural settlement
    ## 11 Many To One Map                    21 Rural settlement
    ## 12 Many To One Map                    14 Small urban area
    ## 13 Many To One Map                    14 Small urban area
    ## 14 Many To One Map                    21 Rural settlement
    ## 15 Many To One Map                    21 Rural settlement
    ## 16 Many To One Map                    21 Rural settlement
    ## 17 Many To One Map                    21 Rural settlement
    ## 18 Many To One Map                    21 Rural settlement
    ## 19 Many To One Map                    22      Rural other
    ## 20 Many To One Map                    21 Rural settlement

</details>

### *urban_rural_to_sa2_concord_2023*

<details>
<summary>
Concordance between urban/rural and SA2 codes.
</summary>

``` r
urban_rural_to_sa2 <- read.csv("urban_rural_to_sa2_concord_2023.csv")
head(urban_rural_to_sa2 ,20)
```

    ##                             Concordance.report                         X
    ## 1  Statistical Area 2 2023 to Urban Rural 2023                          
    ## 2                                   Valid from                  1-Jan-23
    ## 3                                     Valid to                  1-Jan-24
    ## 4                             Lifecycle status                  Released
    ## 5                    Statistical Area 2 2023 2                          
    ## 6                               SA22023 V1.0.0                          
    ## 7                                       100100                North Cape
    ## 8                                       100100                North Cape
    ## 9                                       100200          Rangaunu Harbour
    ## 10                                      100200          Rangaunu Harbour
    ## 11                                      100200          Rangaunu Harbour
    ## 12                                      100301 Inlets Far North District
    ## 13                                      100400        Karikari Peninsula
    ## 14                                      100400        Karikari Peninsula
    ## 15                                      100400        Karikari Peninsula
    ## 16                                      100500                  Tangonge
    ## 17                                      100600                   Ahipara
    ## 18                                      100700              Kaitaia East
    ## 19                                      100800              Kaitaia West
    ## 20                                      100900                 Rangitihi
    ##                 X.1              X.2                            X.3
    ## 1                                                                  
    ## 2                                                                  
    ## 3                                                                  
    ## 4                                                                  
    ## 5                   Urban Rural 2023                               
    ## 6                      UR2023 V1.0.0                               
    ## 7  Many To Many Map             1001                        Pukenui
    ## 8  Many To Many Map             1013 Other rural Far North District
    ## 9  Many To Many Map             1005                         Awanui
    ## 10 Many To Many Map             1013 Other rural Far North District
    ## 11 Many To Many Map             1002                      Kaimaumau
    ## 12       Simple Map             1015      Inlets Far North District
    ## 13 Many To Many Map             1003                  Tokerau Beach
    ## 14 Many To Many Map             1013 Other rural Far North District
    ## 15 Many To Many Map             1004                       Karikari
    ## 16 Many To Many Map             1013 Other rural Far North District
    ## 17       Simple Map             1006                        Ahipara
    ## 18  Many To One Map             1007                        Kaitaia
    ## 19  Many To One Map             1007                        Kaitaia
    ## 20 Many To Many Map             1013 Other rural Far North District

</details>
