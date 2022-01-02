# Introduction ------------------------------------------------------------
# This builds / modifies a spreadsheet that the pollen experiment app uses 
# on the backend. It draws data from a few Google sheets:
# 1) Greenhouse bench layout
#    1eVTw35VZk2Kidy1fWb-ob0lhmec1iWHUZ_b2zJ70FHg
# 2) Organized computer-readable worksheets
#    1yQ5yAKiL6BzwZ-wH-Q44RoUEwMZztTYafzdvVylq6fo
# 3) Big spreadsheet summarizing all the greenhouse information
#    1ZJxIig0rGVVXgvLTO8SjPY2A9y3itntssLxHtGn7mSU
# 4) Flower measurements
#    1YAbstZeZfTu6bItHQXVr02WrD1JmNNvn4dd-m88omLY
# The output is a nice organized sheet that contains all the info necessary
# for the app to run.

library(googlesheets4)
library(dplyr)

# Adding my Google service account credentials
gs4_auth(path = "~/.credentials/google_sheets_api/service_account.json")


# Loading the sheets ------------------------------------------------------
bench_url <- "1eVTw35VZk2Kidy1fWb-ob0lhmec1iWHUZ_b2zJ70FHg"
worksheet_url <- "1yQ5yAKiL6BzwZ-wH-Q44RoUEwMZztTYafzdvVylq6fo"
greenhouse_info_url <- "1ZJxIig0rGVVXgvLTO8SjPY2A9y3itntssLxHtGn7mSU"
flower_url <- "1YAbstZeZfTu6bItHQXVr02WrD1JmNNvn4dd-m88omLY"

bench_layout <- read_sheet(bench_url)
worksheets <- read_sheet(worksheet_url)
greenhouse_info <- read_sheet(greenhouse_info_url)
flower_meaasurements <- read_sheet(flower_url)


# Building the app data sheet ---------------------------------------------








