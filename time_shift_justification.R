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

