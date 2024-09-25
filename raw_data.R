# read .parquet file
install.packages("arrow")
library(arrow)

# read in raw data
sp_tele_data <- read.csv("sp_data.csv.gz")
vf_tele_data <- read_parquet("vf_data.parquet")
sa2_codes_names <- read.csv("sa2_2023.csv")
sa2_to_ta <- read.csv("sa2_ta_concord_2023.csv")
pop_estimates <- read.csv("subnational_pop_ests.csv")
urban_rural_codes <- read.csv("urban_rural_to_indicator_2023.csv")
urban_rural_to_sa2 <- read.csv("urban_rural_to_sa2_concord_2023.csv")