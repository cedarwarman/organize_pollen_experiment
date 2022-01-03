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
library(tidyr)

# Adding my Google service account credentials
gs4_auth(path = "~/.credentials/google_sheets_api/service_account.json")


# Loading the sheets ------------------------------------------------------
bench_url <- "1eVTw35VZk2Kidy1fWb-ob0lhmec1iWHUZ_b2zJ70FHg"
counting_url <- "10_lG9N0wGvgOmxDGuX5PXILB7QwC7m6CuYXzi78Qe3Q"
worksheet_url <- "1yQ5yAKiL6BzwZ-wH-Q44RoUEwMZztTYafzdvVylq6fo"
greenhouse_info_url <- "1ZJxIig0rGVVXgvLTO8SjPY2A9y3itntssLxHtGn7mSU"
flower_url <- "1YAbstZeZfTu6bItHQXVr02WrD1JmNNvn4dd-m88omLY"

# Need to read all the tabs in the bench layouts sheet
bench_layout <- bind_rows(lapply(tail(sheet_names(bench_url), 4), function(x){
  read_sheet(bench_url, sheet = x)
}))

# Same for the flower measurements
flower_measurements <- bind_rows(lapply(sheet_names(flower_url), function(x){
  read_sheet(flower_url, sheet = x)
}))
pollen_counts <- read_sheet(counting_url)
greenhouse_info <- read_sheet(greenhouse_info_url)
worksheets <- read_sheet(worksheet_url)


# Building the app data sheet ---------------------------------------------
# Start with bench layout to get list of accessions currently in the 
# greenhouse and their positions:
#      ____                  __       __                        __
#     / __ )___  ____  _____/ /_     / /___ ___  ______  __  __/ /_
#    / __  / _ \/ __ \/ ___/ __ \   / / __ `/ / / / __ \/ / / / __/
#   / /_/ /  __/ / / / /__/ / / /  / / /_/ / /_/ / /_/ / /_/ / /_
#  /_____/\___/_/ /_/\___/_/ /_/  /_/\__,_/\__, /\____/\__,_/\__/
#                                         /____/
#         ┌─────┐  ┌─────┐
#  ◭    4 │     │  │     │ 8
#  N      └─────┘  └─────┘                ┌────┬────┬────┬────┬────┐
#         ┌─────┐  ┌─────┐                │ 16 │ 17 │ 18 │ 19 │ 20 │
#       3 │     │  │     │ 7              ├────┼────┼────┼────┼────┤
#         └─────┘  └─────┘      ─────╲    │ 11 │ 12 │ 13 │ 14 │ 15 │
#         ┌─────┐  ┌─────┐      ─────╱    ├────┼────┼────┼────┼────┤
#       2 │     │  │     │ 6              │ 6  │ 7  │ 8  │ 9  │ 10 │
#         └─────┘  └─────┘                ├────┼────┼────┼────┼────┤
#         ┌─────┐  ┌─────┐                │ 1  │ 2  │ 3  │ 4  │ 5  │
#       1 │     │  │     │ 5              └────┴────┴────┴────┴────┘
#         └─────┘  └─────┘

app_df <- bench_layout

# Adding counts for number of good image sequences (correct amount of pollen)
# at control and heat stress. First, adding accession name to the 
# pollen_counts sheet.
pollen_counts <- left_join(pollen_counts, 
  worksheets[ , c("date", "run", "well", "temp_target", "accession")])

# Only keeping the good runs ("g") 
pollen_counts <- pollen_counts[! is.na(pollen_counts$count), ]
pollen_counts <- pollen_counts[pollen_counts$count == "g", ]

# Summarizing the counts
pollen_counts <- pollen_counts %>%
  group_by(accession, temp_target) %>%
  summarize(good_run_count = n())

# Making pollen_counts wider for joining with the app_df
pollen_counts <- pollen_counts %>%
  pivot_wider(id_cols = accession, 
              names_from = temp_target,
              values_from = good_run_count,
              names_prefix = "good_run_count_")
pollen_counts[is.na(pollen_counts)] <- 0

# Joining the counts to the app_df
app_df <- left_join(app_df, pollen_counts)
app_df[is.na(app_df)] <- 0

# Adding flower measurement counts
# Group by accession, delete na's, count rows, left join





