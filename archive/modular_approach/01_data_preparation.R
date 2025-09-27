# =============================================================================
# ATC HIERARCHY DATA PREPARATION PIPELINE
# =============================================================================
# 
# This script processes raw WHO ATC data and creates the hierarchical structure
# needed for the sunburst visualization.

# Load packages
source("R/packages.R")

# Source utility functions
source("R/functions.R")

# =============================================================================
# DATA PREPARATION FUNCTIONS
# =============================================================================

#' Read and process WHO ATC Excel files
read_who_atc_files <- function(files, n_sheets = 6) {
  
  # Helper function to read first n sheets of a single file
  read_first_sheets <- function(file, n_sheets = 6) {
    sheets <- excel_sheets(file)[1:n_sheets]
    sheet_list <- map(sheets, ~ read_excel(file, sheet = .x))
    names(sheet_list) <- paste0(basename(file), "_sheet", seq_along(sheet_list))
    sheet_list
  }
  
  # Read all files and flatten the list
  all_sheets_list <- map(files, read_first_sheets) %>% flatten()
  
  # Helper function to bind all sheets of a given index across files
  bind_sheets_by_index <- function(sheet_index) {
    sheet_pattern <- paste0("sheet", sheet_index)
    matching_sheets <- all_sheets_list[grep(sheet_pattern, names(all_sheets_list))]
    bind_rows(matching_sheets)
  }
  
  # Return organized list of combined sheets
  list(
    sheet1 = bind_sheets_by_index(1),  # New ATC codes and substance names
    sheet2 = bind_sheets_by_index(2), # ATC codes and new level names
    sheet3 = bind_sheets_by_index(3), # Previous ATC codes (for removal)
    sheet4 = bind_sheets_by_index(4), # ATC codes for removal
    sheet5 = bind_sheets_by_index(5)  # Additional data (if needed)
  )
}

#' Create hierarchical ATC structure
create_atc_hierarchy <- function(all_atc) {
  
  # Step 1: Extract main category headings (ATC codes with 1-5 characters)
  atc_headings <- all_atc %>%
    filter(nchar(atc_code) <= 5) 
  
  # Helper function to join ATC headings at specific hierarchy levels
  join_atc_heading <- function(data, headings, level_len, new_name, by_col) {
    data %>%
      left_join(
        headings %>%
          filter(nchar(atc_code) == level_len) %>%
          rename(!!new_name := atc_name),
        by = setNames("atc_code", by_col)
      )
  }
  
  # Main pipeline: Create hierarchical structure
  atc_levels <- all_atc %>%
    # Only process codes longer than 5 characters (chemical substances)
    filter(nchar(atc_code) > 5) %>%
    # Extract hierarchy level codes
    mutate(
      atc_level_01 = substr(atc_code, 1, 1),  # Anatomical main group
      atc_level_03 = substr(atc_code, 1, 3),  # Therapeutic subgroup
      atc_level_04 = substr(atc_code, 1, 4),  # Pharmacological subgroup
      atc_level_05 = substr(atc_code, 1, 5)   # Chemical subgroup
    ) %>%
    # Join descriptive names for each level
    join_atc_heading(atc_headings, 1, "anatomical_main_group_01", "atc_level_01") %>%
    join_atc_heading(atc_headings, 3, "therapeutic_subgroup_02", "atc_level_03") %>%
    join_atc_heading(atc_headings, 4, "pharmacological_subgroup_03", "atc_level_04") %>%
    join_atc_heading(atc_headings, 5, "chemical_subgroup_04", "atc_level_05") %>%
    # Rename and organize final columns
    rename(chemical_substance = atc_name) %>%
    distinct(atc_code, .keep_all = TRUE) %>%
    select(
      atc_level_01, anatomical_main_group_01,
      atc_level_03, therapeutic_subgroup_02,
      atc_level_04, pharmacological_subgroup_03,
      atc_level_05, chemical_subgroup_04,
      atc_code, chemical_substance
    )
  
  return(atc_levels)
}

# =============================================================================
# MAIN DATA PREPARATION PIPELINE
# =============================================================================

#' Main function to prepare ATC hierarchy data
prepare_atc_data <- function() {
  message("=== ATC Data Preparation Pipeline ===")
  message("Starting at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
  
  # Step 1: Load base ATC data
  message("\n1. Loading base ATC data...")
  atc_scrape_2024 <- read_csv("input/atc_data/WHO ATC-DDD 2024-07-31.csv") %>%
    mutate(atc_name = tolower(atc_name))
  message("   ✓ Loaded ", nrow(atc_scrape_2024), " base ATC records")
  
  # Step 2: Define Excel files for updates
  files <- c(
    "input/atc_data/1_temporary_and_final_atc_and_ddd_final.xlsx",
    "input/atc_data/atc_ddd_new_and_alterations_2025_final.xlsx"
  )
  
  # Step 3: Process WHO Excel files
  message("\n2. Processing WHO Excel files...")
  sheets_data <- read_who_atc_files(files)
  message("   ✓ Processed ", length(sheets_data), " sheet types")
  
  # Step 4: Combine raw data
  message("\n3. Combining raw ATC data...")
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
  message("   ✓ Combined ", nrow(atc_scrape), " total ATC records")
  
  # Step 5: Remove obsolete codes
  message("\n4. Removing obsolete ATC codes...")
  atc_scrape_remove_previous <- atc_scrape %>%
    filter(!(atc_code %in% sheets_data$sheet3$"Previous ATC code")) %>%
    filter(!(atc_code %in% sheets_data$sheet4$"ATC code"))
  
  # Step 6: Clean replacement codes
  combined_sheet3_clean <- sheets_data$sheet3 %>% 
    select("New ATC code", "ATC level name") %>%
    rename(atc_code = "New ATC code",
           atc_name = "ATC level name") %>%
    filter(atc_code != "deleted")
  
  combined_sheet4_clean <- sheets_data$sheet4 %>%
    select("ATC code", "New ATC level name") %>%
    rename(atc_code = "ATC code",
           atc_name = "New ATC level name")
  
  # Step 7: Create final combined dataset
  all_atc <- bind_rows(atc_scrape_remove_previous, 
                       combined_sheet3_clean, 
                       combined_sheet4_clean) %>%
    select(atc_code, atc_name) %>%
    arrange(atc_code)
  
  message("   ✓ Final dataset contains ", nrow(all_atc), " unique ATC codes")
  
  # Step 8: Save full hierarchy CSV
  message("\n5. Saving data files...")
  output_file <- paste0("input/atc_data/WHO_ATC_Hierarchy_", Sys.Date(), ".csv")
  write_csv(all_atc, output_file)
  message("   ✓ Saved: ", output_file)
  
  # Step 9: Create hierarchical structure
  message("\n6. Creating hierarchical structure...")
  atc_levels <- create_atc_hierarchy(all_atc)
  message("   ✓ Created hierarchy with ", nrow(atc_levels), " chemical substances")
  
  # Step 10: Save hierarchical data
  hierarchy_file <- paste0("input/atc_data/WHO_ATC_Hierarchy_wide_", Sys.Date(), ".csv")
  write_csv(atc_levels, hierarchy_file)
  message("   ✓ Saved: ", hierarchy_file)
  
  message("\n=== Data Preparation Completed Successfully! ===")
  message("Finished at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
  
  return(atc_levels)
}

# Run the preparation if this script is executed directly
if (!interactive()) {
  atc_levels <- prepare_atc_data()
}
