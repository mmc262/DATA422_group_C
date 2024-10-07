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
