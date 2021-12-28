# Introduction ------------------------------------------------------------
# This script will pull out data from all the individual plate worksheets, 
# Which are tabs of Google sheets, 1 Google Sheet per month. This is a little
# convoluted, but it is a compromise between complexity running this sheet 
# and ease of use when actually doing the experiment. 

library(tidyverse)
library(googlesheets4)
library(lubridate)

gs4_deauth()

# Check to see if sheet has already been finished, then if tab has already 
# been finished

# Add some kind of file in the data folder that keeps track of when things 
# are finished?

# Function to go through the tabs in a Google sheet and pull out the relevant 
# data. Do a row for each well. Rows will be combined into a giant long table 
# the uploaded to Google Sheets.

december_id <- "12NXw2dRH6iRtq62KU3_w7R3FGQ5StdDr6pkfCuLP56Y"

test_sheet <- read_sheet("1j1lbNBOFVCyKuGLXUYDNSH0r_8Z5lV6JmFFgQOhk5Nw",
                         sheet = "2021-11-19_run_2",
                         col_names = FALSE,
                         col_types = "c")

process_worksheet <- function(input_sheet_id){
  output_df <- data.frame()
  tab_list <- sheet_properties(input_sheet_id)$name
  print(tab_list)
  for (x in seq(1:length(tab_list))){
    current_tab <- read_sheet(input_sheet_id,
                              sheet = tab_list[x],
                              col_names = FALSE,
                              col_types = 'c')
    
    # Pulling out all the metadata that's the same for each plate
    cell_date <- ymd(current_tab[1, 3])
    cell_run <- as.integer(current_tab[2, 3])
    cell_pollen_collect_start <- force_tz(ymd_hm(paste(current_tab[1, 3],
                                                       current_tab[3, 3])), 
                                          tzone = "America/Phoenix")
    cell_pollen_collect_end <- force_tz(ymd_hm(paste(current_tab[1, 3],
                                                     current_tab[4, 3])), 
                                        tzone = "America/Phoenix")
    cell_pgm_added <- force_tz(ymd_hm(paste(current_tab[1, 3],
                                            current_tab[5, 3])), 
                               tzone = "America/Phoenix")
    cell_pollen_on_scope <- force_tz(ymd_hm(paste(current_tab[1, 3],
                                                  current_tab[6, 3])), 
                                     tzone = "America/Phoenix")
    cell_exp_start <- force_tz(ymd_hm(paste(current_tab[1, 3],
                                            current_tab[7, 3])), 
                               tzone = "America/Phoenix")
    cell_exp_end <- force_tz(ymd_hm(paste(current_tab[1, 3],
                                          current_tab[8, 3])), 
                             tzone = "America/Phoenix")
    cell_lid_temp <- as.double(current_tab[10, 2])
    cell_base_temp <- as.double(current_tab[11, 2])
    cell_stage_heater <- as.character(current_tab[12, 2])
    cell_target_temp <- as.double(current_tab[10, 6])
    cell_thermocouple_position <- as.character(current_tab[11, 6])
    
    # Getting the accession ID for each well (each well will become a row)
    well_ids <- c(
      "A1", "A2", "A3", "A4", "A5", "A6",
      "B1", "B2", "B3", "B4", "B5", "B6",
      "C1", "C2", "C3", "C4", "C5", "C6",
      "D1", "D2", "D3", "D4", "D5", "D6"
    )
    well_contents <- as.character(c(
      current_tab[16, 2], current_tab[16, 3], current_tab[16, 4], current_tab[16, 5], current_tab[16, 6], current_tab[16, 7],
      current_tab[17, 2], current_tab[17, 3], current_tab[17, 4], current_tab[17, 5], current_tab[17, 6], current_tab[17, 7],
      current_tab[18, 2], current_tab[18, 3], current_tab[18, 4], current_tab[18, 5], current_tab[18, 6], current_tab[18, 7],
      current_tab[19, 2], current_tab[19, 3], current_tab[19, 4], current_tab[19, 5], current_tab[19, 6], current_tab[19, 7]
    ))
    
    for (y in seq(1, length(well_ids))){
      output_row <- data.frame(date = cell_date,
                               run = cell_run,
                               t_pollen_collect_start = cell_pollen_collect_start,
                               t_pollen_collect_end = cell_pollen_collect_end,
                               t_pgm_added = cell_pgm_added,
                               t_pollen_on_scope = cell_pollen_on_scope,
                               t_exp_start = cell_exp_start,
                               t_exp_end = cell_exp_end,
                               temp_lid = cell_lid_temp,
                               temp_base = cell_base_temp,
                               temp_stage = cell_stage_heater,
                               temp_target = cell_target_temp,
                               thermocouple_pos = cell_thermocouple_position,
                               well = well_ids[y],
                               accession = well_contents[y])
      output_df <- rbind(output_df, output_row)
    }
    
  }
  return(output_df)
}

test_output_df <- process_worksheet(december_id)




test_summary <- test_output_df %>% group_by(accession) %>% summarize(n = n())




