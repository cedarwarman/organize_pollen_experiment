# Organize pollen experiment
R project to organize pollen experiment worksheets.

## Contents

### process_worksheets.R
**This R script is run first.** It pulls data from a series of Google sheets that are formatted to be easy to use while doing experiments, but are not great for computation. The output is a single spreadsheet in a machine-readable format containing all the metadata describing which accessions have been imaged.

### build_pollen_count_sheet.R
**This R script is run second.** It pulls data from the output of the previous spreadsheet and puts it into a format that makes it easy to enter pollen count data for each well.

## Requirements
For authorization, a JSON file identifying a Google service account with access to the spreadsheets must be present at "~/.credentials/google_sheets_api/service_account.json".

- R 4.0.5
- lubridate 1.7.10
- forcats 0.5.1
- stringr 1.4.0
- dplyr 1.0.7
- purrr 0.3.4
- readr 1.4.0
- tidyr 1.1.3
- tibble 3.1.3
- ggplot2 3.3.3
- tidyverse 1.3.1
- googlesheets4 1.0.0
