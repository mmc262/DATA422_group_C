# run previous script
source("02_merge.R")

# export clean data set
write.csv(clean_dataset, file = "clean_dataset.csv", row.names = FALSE)