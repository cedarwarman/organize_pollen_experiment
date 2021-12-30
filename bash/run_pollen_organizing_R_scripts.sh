#!/usr/bin/env bash

# Organizing experiment worksheets into a more computer-friendly format
printf "\nProcessing worksheets\n"
Rscript /home/cedar/git/organize_pollen_experiment/R/process_worksheets.R

# Building a pollen-counting sheet from the output of the previous script
printf "\nBuilding pollen counting sheet\n"
Rscript /home/cedar/git/organize_pollen_experiment/R/build_pollen_count_sheet.R

printf "\nFinished\n"
