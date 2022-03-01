# Introduction ------------------------------------------------------------
# This script will pull out data from all the individual plate worksheets, 
# Which are tabs of Google sheets, 1 Google Sheet per month. This is a little
# convoluted, but it is a compromise between complexity running this sheet 
# and ease of use when actually doing the experiment. 

library(googlesheets4)
library(lubridate)

# Adding my Google service account credentials
gs4_auth(path = "~/.credentials/google_sheets_api/service_account.json")


# Reading the sheets and organizing the data ------------------------------
# Function to go through the tabs in a Google sheet and pull out the relevant 
# data. Do a row for each well. Rows will be combined into a giant long table 
# the uploaded to Google Sheets.


# Testing

# test_sheet <- read_sheet("1j1lbNBOFVCyKuGLXUYDNSH0r_8Z5lV6JmFFgQOhk5Nw",
#                          sheet = "2021-11-19_run_2",
#                          col_names = FALSE,
#                          col_types = "c")


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
    cell_person <- as.character(current_tab[1, 6])
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
                               person = cell_person,
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

# Processing the different spreadsheets (I was going to make it check to see 
# if it has already been processed, but it doesn't take very long so I'm just 
# leaving it).
sheets <- list(November = "1j1lbNBOFVCyKuGLXUYDNSH0r_8Z5lV6JmFFgQOhk5Nw",
               December = "12NXw2dRH6iRtq62KU3_w7R3FGQ5StdDr6pkfCuLP56Y",
               January = "1d1lk49XzVd6iRKDWsoF5BXMWeKX3OdS-CaO-fVlSYZk",
               February = "1kGYtaJf1vGXwQH_6Spuo1auYpaHvuoyGaEDZVnM620s",
               March = "1EEqrDNeKjmyKEPGlN8n3u9QBvDAIVUUjKDnfjhMqe4w")

output_df = data.frame()
for (z in seq(1, length(sheets))){
  loop_df <- process_worksheet(sheets[[z]])
  output_df <- rbind(output_df, loop_df)
}


# Uploading the organized data --------------------------------------------
destination_sheet = "1yQ5yAKiL6BzwZ-wH-Q44RoUEwMZztTYafzdvVylq6fo"
write_sheet(data = output_df, 
            ss = destination_sheet,
            sheet = "output_df")


# Looking at the data -----------------------------------------------------
# Just a little summary to see how things look
# summary <- output_df %>% group_by(accession, temp_target) %>% summarize(n = n())

# I will make another script to produce a data entry Google Sheet to manually
# look at the pollen counts for each well, then add that data to a visualization
# and counting app so I know which accessions need more plants
