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

