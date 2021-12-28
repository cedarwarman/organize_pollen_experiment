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
cell_date <- ymd(test_sheet[1, 3])

test_string <- (paste(test_sheet[1, 3],
                      test_sheet[3, 3]))
Sys.timezone() 
OlsonNames()
force_tz(ymd_hm(test_string), tzone = "America/Phoenix")

ymd(cell_date)



process_worksheet <- function(input_sheet_id){
  tab_list <- sheet_properties(input_sheet_id)$name
  print(tab_list)
  for (x in seq(1:length(tab_list))){
    current_tab <- read_sheet(input_sheet_id,
                              sheet = tab_list[x],
                              col_names = FALSE,
                              col_types = 'c')
    cell_date <- ymd(current_tab[1, 3])
    cell_run <- as.integer(current_tab[2, 2])
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
    
    print(cell_lid_temp)
    print(cell_base_temp)
    print(cell_stage_heater)
    print(cell_target_temp)
    print(cell_thermocouple_position)
  }
}

process_worksheet(december_id)





