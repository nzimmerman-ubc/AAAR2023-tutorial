# Set directory containing the files (Dash and RAMP files must be in the same location)
setwd("C:/Users/davi_/Sync/iREACH/Students/Davi/- Data for Naomi to play/PLUME 11-17 Sep") # this is user specified, example: C:/Users/davi_/Downloads/PhD/Dissertation/PLUME_Data_Dashboard/WCPC and FMPS Exports/to R

library(dplyr)
library(openair)
library(lubridate)

# Get a list of all Dashboard files in the specified directory
Dashboard_list <- list.files(pattern = "^Sensor_Transcript_")

# Loop through the list of files and load each as a dataframe file with the same name
for(file in Dashboard_list) {
  # Read in the file name
  file_name = gsub("\\.csv$", "", file) # change ".xlsx" to ".csv" if appropriate
  
  # Create an auxiliary data frame
  aux_dataframe = read.csv(file)
  colnames(aux_dataframe)[1] = "date"
  new_names = c("date", "NO2_PLUME", "UFP_PLUME", "O3_PLUME",	"CO_PLUME",	"CO2_PLUME", "NO_PLUME", "WS_PLUME", "WD_PLUME", "WV_PLUME")
  colnames(aux_dataframe) = c(new_names)
  aux_dataframe$CO_PLUME = aux_dataframe$CO_PLUME*1000 # convert to ppm (PLUME) to ppb (RAMP)
  Particle_Volume = (4/3)*pi*(0.1)^3 # assuming 0.1 um particles
  aux_dataframe$UFP_PLUME = aux_dataframe$UFP_PLUME*Particle_Volume*0.1 # assuming density = 0.1
  aux_dataframe$date <- as.POSIXct(aux_dataframe$date)
  
  # Set up timeAverage
  first_date <- aux_dataframe$date[1]
  day <- day(first_date)
  date_begin = "2023-09-"
  date_begin = paste0(date_begin, day)
  start_date = paste(date_begin, "00:00:00")
  print(start_date)
  
  aux_dataframe = timeAverage(aux_dataframe, avg.time = "15 min", start.date = start_date)
  
  # Create a data frame with the same name as of the file
  assign(file_name, aux_dataframe)
  
  # Remove auxiliary data frame
  rm(aux_dataframe)
}

# Get a list of all RAMP files in the specified directory
RAMP_list <- list.files(pattern = "^RAMP_")

# Loop through the list of files and load each as a dataframe file with the same name
for(file in RAMP_list) {
  # Read in the file name
  file_name = gsub("\\.txt$", "", file) # change ".xlsx" to ".csv" if appropriate
  
  # Create an auxiliary data frame
  aux_dataframe = read.table(file, header=FALSE, sep=",")
  
  aux_dataframe = aux_dataframe %>% select(c('V2', 'V4', 'V6', 'V8', 'V10', 'V12', 'V14', 'V16', 'V18'))
  new_names = c("date", "CO_RAMP", "NO_RAMP", "NO2_RAMP", "O3_RAMP","CO2_RAMP", "T_RAMP", "RH_RAMP", "PM_RAMP")
  colnames(aux_dataframe) = c(new_names)
  aux_dataframe$date <- as.POSIXct(strptime(aux_dataframe$date, format = "%m/%d/%y %H:%M:%S"))
  
  # Set up timeAverage
  first_date <- aux_dataframe$date[1]
  print(first_date)
  day <- day(first_date)
  date_begin = "2023-09-"
  date_begin = paste0(date_begin, day)
  start_date = paste(date_begin, "00:00:00")
  print(start_date)

  aux_dataframe = timeAverage(aux_dataframe, avg.time = "15 min", start.date = start_date)

  # Create a data frame with the same name as of the file
  assign(file_name, aux_dataframe)
  
  # Remove auxiliary data frame
  rm(aux_dataframe)
}

# Find dataframes in the R Global Environment based on their name
# Create an empty list to store filenames without ".csv" OR ".txt"
RAMP_names <- vector("character", length(RAMP_list))

# Iterate over the list and remove ".txt" extension
for (i in seq_along(RAMP_list)) {
  RAMP_names[i] <- sub("_1086.txt$", "", RAMP_list[i])
}

# Create an empty list to store filenames without ".csv"
Dash_names <- vector("character", length(Dashboard_list))

# Iterate over the list and remove ".csv" extension
for (i in seq_along(Dashboard_list)) {
  Dash_names[i] <- sub("_UPDATED.csv$", "", Dashboard_list[i])
}

# Get the unique dates from the dataframe names
RAMP_dates <- unique(sub("RAMP_", "", RAMP_names))
Dash_dates <- unique(sub("Sensor_Transcript_", "", Dash_names))

# Find the dates that are common to both dataframes
common_dates <- intersect(RAMP_dates, Dash_dates)


# Get the column names from the existing dataframe
dat_ref_column_names <- names(Sensor_Transcript_2023_09_13_UPDATED)
dat_column_names <- names(RAMP_2023_09_13_1086)

# Create a blank dataframe with the same column names
dat_ref_15min <- data.frame(matrix(nrow = 0, ncol = length(dat_ref_column_names)))
dat_15min <- data.frame(matrix(nrow = 0, ncol = length(dat_column_names)))

# Set the column names of the blank dataframe
colnames(dat_ref_15min) <- dat_ref_column_names
colnames(dat_15min) <- dat_column_names

# Merge dataframes by rows
for (date in common_dates) {
    # Data
    dat_15min <- rbind(dat_15min, get(paste0("RAMP_", date, "_1086")))
    dat_ref_15min <- rbind(dat_ref_15min, get(paste0("Sensor_Transcript_", date, "_UPDATED")))
}

# Tibble the data
tbl_15min <- as_tibble(dat_15min)
tbl_ref_15min <- as_tibble(dat_ref_15min)
combined_15min = inner_join(tbl_15min, tbl_ref_15min)


# Convert the tibble to a dataframe (if needed)
my_dataframe <- as.data.frame(combined_15min)

# Export the tibble as a .csv file using write_csv()
write_csv(my_dataframe)