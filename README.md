# Organize pollen experiment
R project to organize pollen experiment worksheets.

## Contents

### run_pollen_organizing_R_scripts.sh
This bash script runs the following two R scripts. I have set it up to run each night using the following crontab line:

    0 20 * * * bash ~/git/organize_pollen_experiment/bash/run_pollen_organizing_R_scripts.sh

### process_worksheets.R
**This R script is run first.** It pulls data from a series of Google sheets that are formatted to be easy to use while doing experiments, but are not great for computation. The output is a single spreadsheet in a machine-readable format containing all the metadata describing which accessions have been imaged.

### build_pollen_count_sheet.R
**This R script is run second.** It pulls data from the output of the previous spreadsheet and puts it into a format that makes it easy to enter pollen count data for each well.

## Requirements
For authorization, a JSON file identifying a Google service account with access to the spreadsheets must be present at "~/.credentials/google_sheets_api/service_account.json".

- R 4.0.5
- lubridate 1.7.10
- dplyr 1.0.7
- googlesheets4 1.0.0
