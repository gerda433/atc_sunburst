# =============================================================================
# PREPARE DATA - Step 1
# =============================================================================
# Simple script to prepare ATC hierarchy data
# Run this first: source("prepare_data.R")

# Load packages
suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(readr)
  library(readxl)
  library(purrr)
})

# Source utility functions
source("functions.R")

# Load base ATC data
message("Loading base ATC data...")
atc_scrape_2024 <- read_csv("input/atc_data/WHO ATC-DDD 2024-07-31.csv") %>%
  mutate(atc_name = tolower(atc_name))
message("✓ Loaded ", nrow(atc_scrape_2024), " base ATC records")

# Define Excel files for updates
# Source: https://atcddd.fhi.no/lists_of__temporary_atc_ddds_and_alterations/
files <- c(
  "input/atc_data/1_temporary_and_final_atc_and_ddd_final.xlsx",
  "input/atc_data/atc_ddd_new_and_alterations_2025_final.xlsx"
)

# Process WHO Excel files
message("Processing WHO Excel files...")
read_first_sheets <- function(file, n_sheets = 6) {
  sheets <- excel_sheets(file)[1:n_sheets]
  sheet_list <- map(sheets, ~ read_excel(file, sheet = .x))
  names(sheet_list) <- paste0(basename(file), "_sheet", seq_along(sheet_list))
  sheet_list
}

all_sheets_list <- map(files, read_first_sheets) %>% flatten()

bind_sheets_by_index <- function(sheet_index) {
  sheet_pattern <- paste0("sheet", sheet_index)
  matching_sheets <- all_sheets_list[grep(sheet_pattern, names(all_sheets_list))]
  bind_rows(matching_sheets)
}

sheets_data <- list(
  sheet1 = bind_sheets_by_index(1),
  sheet2 = bind_sheets_by_index(2),
  sheet3 = bind_sheets_by_index(3),
  sheet4 = bind_sheets_by_index(4),
  sheet5 = bind_sheets_by_index(5)
)

# Combine raw data
message("Combining raw ATC data...")
atc_scrape <- bind_rows(
  sheets_data$sheet1 %>% 
    select(1:2) %>%
    rename(atc_code = "New ATC code", 
           atc_name = "Substance name"), 
  sheets_data$sheet2 %>% 
    select(1:2) %>%
    rename(atc_code = "ATC code",
           atc_name = "New ATC level name"),
  atc_scrape_2024
)

# Remove obsolete codes
atc_scrape_remove_previous <- atc_scrape %>%
  filter(!(atc_code %in% sheets_data$sheet3$"Previous ATC code")) %>%
  filter(!(atc_code %in% sheets_data$sheet4$"ATC code"))

# Clean replacement codes
combined_sheet3_clean <- sheets_data$sheet3 %>% 
  select("New ATC code", "ATC level name") %>%
  rename(atc_code = "New ATC code",
         atc_name = "ATC level name") %>%
  filter(atc_code != "deleted")

combined_sheet4_clean <- sheets_data$sheet4 %>%
  select("ATC code", "New ATC level name") %>%
  rename(atc_code = "ATC code",
         atc_name = "New ATC level name")

# Create final combined dataset
all_atc <- bind_rows(atc_scrape_remove_previous, 
                     combined_sheet3_clean, 
                     combined_sheet4_clean) %>%
  select(atc_code, atc_name) %>%
  arrange(atc_code)

message("✓ Final dataset contains ", nrow(all_atc), " unique ATC codes")

# Create hierarchical structure
message("Creating hierarchical structure...")
atc_headings <- all_atc %>%
  filter(nchar(atc_code) <= 5) 

join_atc_heading <- function(data, headings, level_len, new_name, by_col) {
  data %>%
    left_join(
      headings %>%
        filter(nchar(atc_code) == level_len) %>%
        rename(!!new_name := atc_name),
      by = setNames("atc_code", by_col)
    )
}

atc_levels <- all_atc %>%
  filter(nchar(atc_code) > 5) %>%
  mutate(
    atc_level_01 = substr(atc_code, 1, 1),
    atc_level_03 = substr(atc_code, 1, 3),
    atc_level_04 = substr(atc_code, 1, 4),
    atc_level_05 = substr(atc_code, 1, 5)
  ) %>%
  join_atc_heading(atc_headings, 1, "anatomical_main_group_01", "atc_level_01") %>%
  join_atc_heading(atc_headings, 3, "therapeutic_subgroup_02", "atc_level_03") %>%
  join_atc_heading(atc_headings, 4, "pharmacological_subgroup_03", "atc_level_04") %>%
  join_atc_heading(atc_headings, 5, "chemical_subgroup_04", "atc_level_05") %>%
  rename(chemical_substance = atc_name) %>%
  distinct(atc_code, .keep_all = TRUE) %>%
  select(
    atc_level_01, anatomical_main_group_01,
    atc_level_03, therapeutic_subgroup_02,
    atc_level_04, pharmacological_subgroup_03,
    atc_level_05, chemical_subgroup_04,
    atc_code, chemical_substance
  )

message("✓ Created hierarchy with ", nrow(atc_levels), " chemical substances")

# Save data
write_csv(all_atc, "input/atc_data/WHO_ATC_Hierarchy_latest.csv")
write_csv(atc_levels, "input/atc_data/WHO_ATC_Hierarchy_wide_latest.csv")

message("✓ Data preparation completed!")
message("✓ Saved: input/atc_data/WHO_ATC_Hierarchy_latest.csv")
message("✓ Saved: input/atc_data/WHO_ATC_Hierarchy_wide_latest.csv")
