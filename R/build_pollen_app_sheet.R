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
library(ggplot2)

# Adding my Google service account credentials
gs4_auth(path = "~/.credentials/google_sheets_api/service_account.json")


# Loading the sheets ------------------------------------------------------
bench_url <- "1eVTw35VZk2Kidy1fWb-ob0lhmec1iWHUZ_b2zJ70FHg"
counting_url <- "10_lG9N0wGvgOmxDGuX5PXILB7QwC7m6CuYXzi78Qe3Q"
worksheet_url <- "1yQ5yAKiL6BzwZ-wH-Q44RoUEwMZztTYafzdvVylq6fo"
greenhouse_info_url <- "1ZJxIig0rGVVXgvLTO8SjPY2A9y3itntssLxHtGn7mSU"
flower_url <- "1YAbstZeZfTu6bItHQXVr02WrD1JmNNvn4dd-m88omLY"

# Need to read all the tabs in the bench layouts sheet
wave_vec <- c("wave_9", "wave_10", "wave_11")
bench_layout <- bind_rows(lapply(sheet_names(bench_url), function(x){
  print(x)
  if (x %in% wave_vec) {
    read_sheet(bench_url, sheet = x)
  }
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
#  ◭    1 │     │  │     │ 2
#  N      └─────┘  └─────┘                ┌────┬────┬────┬────┬────┐
#         ┌─────┐  ┌─────┐                │ 16 │ 17 │ 18 │ 19 │ 20 │
#       3 │     │  │     │ 4              ├────┼────┼────┼────┼────┤
#         └─────┘  └─────┘      ─────╲    │ 11 │ 12 │ 13 │ 14 │ 15 │
#         ┌─────┐  ┌─────┐      ─────╱    ├────┼────┼────┼────┼────┤
#       5 │     │  │     │ 6              │ 6  │ 7  │ 8  │ 9  │ 10 │
#         └─────┘  └─────┘                ├────┼────┼────┼────┼────┤
#         ┌─────┐  ┌─────┐                │ 1  │ 2  │ 3  │ 4  │ 5  │
#       7 │     │  │     │ 8              └────┴────┴────┴────┴────┘
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
flower_measurements <- flower_measurements %>%
  group_by(accession_id) %>%
  drop_na %>%
  summarise(flowers_measured = n())

app_df <- left_join(app_df, flower_measurements,
                       by = c("accession" = "accession_id"))
app_df[is.na(app_df)] <- 0

# Adding frozen pollen counts
frozen_pollen <- greenhouse_info[ , c("accession_id", "frozen_pollen")]
# I was running into a bug here where there were two copies of the same accession
# that got replanted. One had n number of frozen pollen samples, one had NA for 
# none. Before I made the NA 0 after joining, but now I'll make it 0 before then 
# add up the numbers (which should always just be 0 plus a number) to collapse the
# duplicates. I can't just remove the NAs because then I'll lose some. Although now
# that I'm thinking about it, maybe a better join would just make NA's for the ones 
# without pairs, which would be zero? Would be slightly more efficient. Tried it.
# Will probably have to make an exception if I collect frozen pollen from more than 
# one wave for the same accession, will probably only happen with CW0000.
frozen_pollen <- frozen_pollen[complete.cases(frozen_pollen), ]
app_df <- left_join(app_df, frozen_pollen,
                    by = c("accession" = "accession_id"))
app_df$frozen_pollen[is.na(app_df$frozen_pollen)] <- 0
app_df <- app_df %>% distinct() # I don't think this is necessary anymore

# Add factor for whether or not the accession is ready for frozen pollen 
# collection. Also if the pollen is finished.
app_df$ready_for_frozen_pollen <- NA
app_df$ready_for_frozen_pollen[app_df$good_run_count_26 >= 8 &
                               app_df$good_run_count_34 >= 8 &
                               app_df$flowers_measured == 12] <- "ready"
app_df$ready_for_frozen_pollen[app_df$good_run_count_26 >= 8 &
                               app_df$good_run_count_34 >= 8 &
                               app_df$flowers_measured < 12] <- "pollen_finished"
app_df$ready_for_frozen_pollen[is.na(app_df$ready_for_frozen_pollen)] <- "not_ready"

# Adding an exception for CW0000, I always want these flowers trimmed, so I don't 
# ever want a marked for it being finished (which comes from this factor in the app)
app_df$ready_for_frozen_pollen[app_df$accession == "CW0000"] <- "not_ready"
  
# Add factor for if the accession has been removed
# (I also fill this one out last, after the plants have been removed)
accession_removed_df <- greenhouse_info[ , c("accession_id", "hairy_style")]
accession_removed_df$plant_removed <- NA
accession_removed_df$plant_removed[is.na(accession_removed_df$hairy_style)] <- "plant_not_removed"
accession_removed_df$plant_removed[!is.na(accession_removed_df$hairy_style)] <- "plant_removed"
accession_removed_df <- accession_removed_df[ , c(1, 3)]

app_df <- left_join(app_df, accession_removed_df,
                    by = c("accession" = "accession_id"))
app_df <- app_df %>% distinct()

# Running into a problem where some plants have been planted twice, so the most recent
# plantings haven't actually been removed. Just fixing this manually here.
not_actually_removed <- c("CW1005", "CW1003", "CW0024", "CW0023", "CW0022", "CW0019", "CW0020")
app_df$plant_removed[app_df$accession %in% not_actually_removed] <- "plant_not_removed"
app_df <- app_df %>% distinct()

# Adding coordinate info for plotting -------------------------------------
# Making some test plots here to get things up and running before 
# transferring to the app.

# First add x and y coordinates based on the bench position
#   ┌────┬────┬────┬────┬────┐            ┌────┬────┬────┬────┬────┐
#   │ 16 │ 17 │ 18 │ 19 │ 20 │            │1,4 │2,4 │3,4 │4,4 │5,4 │
#   ├────┼────┼────┼────┼────┤            ├────┼────┼────┼────┼────┤
#   │ 11 │ 12 │ 13 │ 14 │ 15 │   ─────╲   │1,3 │2,3 │3,3 │4,3 │5,3 │
#   ├────┼────┼────┼────┼────┤   ─────╱   ├────┼────┼────┼────┼────┤
#   │ 6  │ 7  │ 8  │ 9  │ 10 │            │1,2 │2,2 │3,2 │4,2 │5,2 │
#   ├────┼────┼────┼────┼────┤            ├────┼────┼────┼────┼────┤
#   │ 1  │ 2  │ 3  │ 4  │ 5  │            │1,1 │2,1 │3,1 │4,1 │5,1 │
#   └────┴────┴────┴────┴────┘            └────┴────┴────┴────┴────┘

# This is very tedious, but can't think of a faster way to do it
app_df$x <- NA
app_df$y <- NA
app_df$height <- 1

app_df$x[app_df$position == 1] <- 1
app_df$y[app_df$position == 1] <- 1

app_df$x[app_df$position == 2] <- 2
app_df$y[app_df$position == 2] <- 1

app_df$x[app_df$position == 3] <- 3
app_df$y[app_df$position == 3] <- 1

app_df$x[app_df$position == 4] <- 4
app_df$y[app_df$position == 4] <- 1

app_df$x[app_df$position == 5] <- 5
app_df$y[app_df$position == 5] <- 1

app_df$x[app_df$position == 6] <- 1
app_df$y[app_df$position == 6] <- 2

app_df$x[app_df$position == 7] <- 2
app_df$y[app_df$position == 7] <- 2

app_df$x[app_df$position == 8] <- 3
app_df$y[app_df$position == 8] <- 2

app_df$x[app_df$position == 9] <- 4
app_df$y[app_df$position == 9] <- 2

app_df$x[app_df$position == 10] <- 5
app_df$y[app_df$position == 10] <- 2

app_df$x[app_df$position == 11] <- 1
app_df$y[app_df$position == 11] <- 3

app_df$x[app_df$position == 12] <- 2
app_df$y[app_df$position == 12] <- 3

app_df$x[app_df$position == 13] <- 3
app_df$y[app_df$position == 13] <- 3

app_df$x[app_df$position == 14] <- 4
app_df$y[app_df$position == 14] <- 3

app_df$x[app_df$position == 15] <- 5
app_df$y[app_df$position == 15] <- 3

app_df$x[app_df$position == 16] <- 1
app_df$y[app_df$position == 16] <- 4

app_df$x[app_df$position == 17] <- 2
app_df$y[app_df$position == 17] <- 4

app_df$x[app_df$position == 18] <- 3
app_df$y[app_df$position == 18] <- 4

app_df$x[app_df$position == 19] <- 4
app_df$y[app_df$position == 19] <- 4

app_df$x[app_df$position == 20] <- 5
app_df$y[app_df$position == 20] <- 4

# Fixing the coordinates for the end cases
for (x in seq(1:8)){
  # Left side
  if(!any(app_df$bench == x & app_df$x == 1 & app_df$y == 3)){
    app_df$y[app_df$bench == x & app_df$x == 1 & app_df$y == 2] <- 2.5
  }
  if(!any(app_df$bench == x & app_df$x == 5 & app_df$y == 3)){
    app_df$y[app_df$bench == x & app_df$x == 5 & app_df$y == 2] <- 2.5
  }
}


# Manually resetting counts for camera change -----------------------------
# I got a new camera, so I want to reset the partially phenotyped accessions
# that I did with the old camera (PMT trans). I'll do it manually here based
# on the counts as of 2022-05-25.

# Bench 7
app_df$good_run_count_26[app_df$accession == "CW0158"] <- app_df$good_run_count_26[app_df$accession == "CW0158"] - 12
app_df$good_run_count_34[app_df$accession == "CW0158"] <- app_df$good_run_count_34[app_df$accession == "CW0158"] - 5

app_df$good_run_count_26[app_df$accession == "CW0162"] <- app_df$good_run_count_26[app_df$accession == "CW0162"] - 6
app_df$good_run_count_34[app_df$accession == "CW0162"] <- app_df$good_run_count_34[app_df$accession == "CW0162"] - 6

app_df$good_run_count_26[app_df$accession == "CW0163"] <- app_df$good_run_count_26[app_df$accession == "CW0163"] - 4
app_df$good_run_count_34[app_df$accession == "CW0163"] <- app_df$good_run_count_34[app_df$accession == "CW0163"] - 5

app_df$good_run_count_26[app_df$accession == "CW0164"] <- app_df$good_run_count_26[app_df$accession == "CW0164"] - 5
app_df$good_run_count_34[app_df$accession == "CW0164"] <- app_df$good_run_count_34[app_df$accession == "CW0164"] - 5

app_df$good_run_count_26[app_df$accession == "CW0165"] <- app_df$good_run_count_26[app_df$accession == "CW0165"] - 4
app_df$good_run_count_34[app_df$accession == "CW0165"] <- app_df$good_run_count_34[app_df$accession == "CW0165"] - 7

# Bench 5
app_df$good_run_count_26[app_df$accession == "CW0170"] <- app_df$good_run_count_26[app_df$accession == "CW0170"] - 5
app_df$good_run_count_34[app_df$accession == "CW0170"] <- app_df$good_run_count_34[app_df$accession == "CW0170"] - 8

app_df$good_run_count_26[app_df$accession == "CW0169"] <- app_df$good_run_count_26[app_df$accession == "CW0169"] - 4
app_df$good_run_count_34[app_df$accession == "CW0169"] <- app_df$good_run_count_34[app_df$accession == "CW0169"] - 8

app_df$good_run_count_26[app_df$accession == "CW0168"] <- app_df$good_run_count_26[app_df$accession == "CW0168"] - 2
app_df$good_run_count_34[app_df$accession == "CW0168"] <- app_df$good_run_count_34[app_df$accession == "CW0168"] - 10

app_df$good_run_count_26[app_df$accession == "CW0167"] <- app_df$good_run_count_26[app_df$accession == "CW0167"] - 1
app_df$good_run_count_34[app_df$accession == "CW0167"] <- app_df$good_run_count_34[app_df$accession == "CW0167"] - 2

app_df$good_run_count_26[app_df$accession == "CW0166"] <- app_df$good_run_count_26[app_df$accession == "CW0166"] - 1
app_df$good_run_count_34[app_df$accession == "CW0166"] <- app_df$good_run_count_34[app_df$accession == "CW0166"] - 8

app_df$good_run_count_26[app_df$accession == "CW0171"] <- app_df$good_run_count_26[app_df$accession == "CW0171"] - 4
app_df$good_run_count_34[app_df$accession == "CW0171"] <- app_df$good_run_count_34[app_df$accession == "CW0171"] - 1

app_df$good_run_count_26[app_df$accession == "CW0160"] <- app_df$good_run_count_26[app_df$accession == "CW0160"] - 3
app_df$good_run_count_34[app_df$accession == "CW0160"] <- app_df$good_run_count_34[app_df$accession == "CW0160"] - 5

app_df$good_run_count_26[app_df$accession == "CW0172"] <- app_df$good_run_count_26[app_df$accession == "CW0172"] - 3
app_df$good_run_count_34[app_df$accession == "CW0172"] <- app_df$good_run_count_34[app_df$accession == "CW0172"] - 3

app_df$good_run_count_26[app_df$accession == "CW1032"] <- app_df$good_run_count_26[app_df$accession == "CW1032"] - 2
app_df$good_run_count_34[app_df$accession == "CW1032"] <- app_df$good_run_count_34[app_df$accession == "CW1032"] - 4

app_df$good_run_count_26[app_df$accession == "CW1033"] <- app_df$good_run_count_26[app_df$accession == "CW1033"] - 1
app_df$good_run_count_34[app_df$accession == "CW1033"] <- app_df$good_run_count_34[app_df$accession == "CW1033"] - 0

# Bench 3
app_df$good_run_count_34[app_df$accession == "CW0006"] <- app_df$good_run_count_34[app_df$accession == "CW0006"] - 2

# Bench 1
app_df$good_run_count_34[app_df$accession == "CW1001"] <- app_df$good_run_count_34[app_df$accession == "CW1001"] - 3

app_df$good_run_count_34[app_df$accession == "CW0002"] <- app_df$good_run_count_34[app_df$accession == "CW0002"] - 2

# Bench 6
app_df$good_run_count_26[app_df$accession == "CW1005"] <- app_df$good_run_count_26[app_df$accession == "CW1005"] - 12
app_df$good_run_count_34[app_df$accession == "CW1005"] <- app_df$good_run_count_34[app_df$accession == "CW1005"] - 6

app_df$good_run_count_34[app_df$accession == "CW1007"] <- app_df$good_run_count_34[app_df$accession == "CW1007"] - 2

# Bench 8
app_df$good_run_count_34[app_df$accession == "CW1016"] <- app_df$good_run_count_34[app_df$accession == "CW1016"] - 2

app_df$good_run_count_26[app_df$accession == "CW0020"] <- app_df$good_run_count_26[app_df$accession == "CW0020"] - 2

app_df$good_run_count_34[app_df$accession == "CW0012"] <- app_df$good_run_count_34[app_df$accession == "CW0012"] - 3

app_df$good_run_count_34[app_df$accession == "CW0011"] <- app_df$good_run_count_34[app_df$accession == "CW0011"] - 3





# Writing out the app df to a sheet ---------------------------------------
# This is the real sheet
write_sheet(app_df, "15oanRivQrhWl0EFmv4zxZqsIB1pLp9InEP43pjqkfGs", sheet = "Sheet1")

# This is a sheet for testing, should be commented out
# write_sheet(app_df, "1b2TgPBwmNqq-RkeSDeP4nS60JQ7QZCPP8G4u6s98d1c", sheet = "Sheet1")


# Making a test plot ------------------------------------------------------
# This will be done in the app, but testing it here.
# ggplot(app_df[app_df$bench == 5, ], aes(x, y,
#                                         fill = good_run_count_34,
#                                         label = paste0(accession, "\n", good_run_count_34))) +
#   geom_tile(aes(height = height), color = "black", size = 2) +
#   geom_text(color = "black", fontface = "bold", size = 5) +
#   scale_fill_gradient(low = "white",
#                       high = "#ff00f7",
#                       na.value = "green",
#                       lim = c(0, 7)) +
#   coord_fixed() +
#   theme_void() +
#   theme(legend.position = "none")
# For the heat stress just use blue for the gradient, and flowers like yellow or something


# Making some temp sheets for ranking accessions --------------------------
# Just for today I need some accessions to target, so I'll make a few temp
# sheets here. I'll delete this later because the app will do it automatically.
# wave_3_34_top <- app_df[app_df$wave == "3", ]
# wave_3_34_top <- wave_3_34_top[order(wave_3_34_top$good_run_count_34), ]
# wave_3_34_top <- wave_3_34_top[ , 1:7]
# write_sheet(wave_3_34_top, "1u793jwMhifrHfm5vJIXA-in06ML8bhmYgJAup83glbk", sheet = "wave_3")
# 
# wave_4_34_top <- app_df[app_df$wave == "4", ]
# wave_4_34_top <- wave_4_34_top[order(wave_4_34_top$good_run_count_34), ]
# wave_4_34_top <- wave_4_34_top[ , 1:7]
# write_sheet(wave_4_34_top, "1u793jwMhifrHfm5vJIXA-in06ML8bhmYgJAup83glbk", sheet = "wave_4")











