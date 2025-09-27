# =============================================================================
# ATC VISUALIZATION DATA PROCESSING PIPELINE
# =============================================================================
#
# This script processes ATC hierarchy data and prepares it for sunburst visualization.
# It combines ATC data with EMA and DKMA medicines information to create rich
# interactive visualizations with detailed hover information.

# Load packages
source("R/packages.R")

# Source utility functions
source("R/functions.R")

# =============================================================================
# DATA PROCESSING FUNCTIONS
# =============================================================================

#' Process EMA medicines data
process_ema_data <- function(file_path) {
  message("Processing EMA medicines data...")
  
  # Read EMA data (skip first 8 rows which contain metadata)
  ema_medicines_raw <- read_excel(file_path, skip = 8)
  
  # Clean column names and process data
  ema_medicines_names <- ema_medicines_raw %>%
    janitor::clean_names()  
  
  ema_medicines <- ema_medicines_names %>%
    # Rename therapeutic area column for consistency
    rename(therapeutic_area = therapeutic_area_me_sh) %>%
    # Select relevant columns
    select(name_of_medicine, active_substance, atc_code_human, 
           therapeutic_indication, therapeutic_area, marketing_authorisation_date) %>%
    # Clean and format data
    mutate(
      active_substance = str_to_lower(active_substance), 
      therapeutic_indication = str_replace_all(therapeutic_indication, "(.{1,60})(\\s|$)", "\\1<br>"),
      marketing_authorisation_date = format(as.Date(marketing_authorisation_date, format = "%d/%m/%Y"), format = "%d/%m/%Y")
    ) %>%
    # Remove duplicates
    distinct(name_of_medicine, .keep_all = TRUE) %>%
    # Create formatted drug information for hover text
    mutate(drug_information = paste0(
      "<b>", name_of_medicine, "</b> - centrally authorised (EMA)<Br>", 
      "<b>Date authorised</b><Br>", marketing_authorisation_date, 
      "<Br><b>Indication(s)</b><Br>", str_replace_all(therapeutic_area, ";", "<Br>")
    ))
  
  message("   ✓ Processed ", nrow(ema_medicines), " EMA medicines")
  return(ema_medicines)
}

#' Process DKMA medicines data
process_dkma_data <- function(file_path, ema_columns) {
  message("Processing DKMA medicines data...")
  
  # Read DKMA data
  dkma_medicines_raw <- read_excel(file_path)
  
  # Process and format DKMA data to match EMA structure
  dkma_medicines <- dkma_medicines_raw %>%
    mutate(
      name_of_medicine = Navn,
      active_substance = str_to_lower(AktiveSubstanser),
      atc_code_human = `ATC-kode`,
      therapeutic_indication = NA,  # Not available in DKMA data
      therapeutic_area = NA,        # Not available in DKMA data
      marketing_authorisation_date = format(as.Date(Registreringsdato), "%d-%m-%Y"), 
      drug_information = paste0(
        "<b>", name_of_medicine, "</b><Br>", 
        "<b>DK registration date</b><Br>", marketing_authorisation_date
      )
    ) %>%
    # Select columns to match EMA structure
    select(all_of(ema_columns)) %>%
    # Remove duplicates
    distinct(name_of_medicine, .keep_all = TRUE)
  
  message("   ✓ Processed ", nrow(dkma_medicines), " DKMA medicines")
  return(dkma_medicines)
}

#' Create sunburst data format
create_sunburst_data <- function(atc_levels) {
  message("Creating sunburst data format...")
  
  # Create different data versions for different purposes
  # Version 1: Code-based hierarchy (for structure)
  df <- atc_levels %>%
    mutate(value = 1) %>%
    select(atc_level_01, atc_level_03, atc_level_04, atc_level_05, 
           chemical_substance, value)
  
  # Version 2: Text-based hierarchy (for hover information)
  df_text <- atc_levels %>%
    mutate(value = 1) %>%
    select(anatomical_main_group_01, therapeutic_subgroup_02, 
           pharmacological_subgroup_03, chemical_subgroup_04, 
           chemical_substance, value)
  
  # Version 3: Code-only hierarchy (for ATC code extraction)
  df_code <- atc_levels %>%
    mutate(value = 1) %>%
    select(atc_level_01, atc_level_03, atc_level_04, atc_level_05, 
           atc_code, value)
  
  # Apply sunburst formatting function to each version
  message("   Converting to sunburst format...")
  hierarchyDF <- create_sunburst_data_format(df, value_column = "value", add_root = TRUE)
  hierarchyDF_code <- create_sunburst_data_format(df_code, value_column = "value", add_root = TRUE)
  
  # Create hover information from text hierarchy
  hierarchyDF_text <- create_sunburst_data_format(df_text, value_column = "value", add_root = TRUE) %>%
    mutate(
      hover_info = sapply(ids, function(x) {
        parts <- str_split(x, " - ")[[1]]
        str_trim(tail(parts, 1))
      }),
      ids_text = ids
    ) 
  
  # Combine all information into final sunburst data
  sunburst_df <- hierarchyDF %>%
    mutate(
      hover_info = hierarchyDF_text$hover_info,
      atc_code = case_when(
        nchar(hierarchyDF_code$labels) == 7 ~ hierarchyDF_code$labels, 
        .default = NA
      ),
      ids_text = hierarchyDF_text$ids_text
    ) %>%
    arrange(desc(labels)) 
  
  message("   ✓ Created sunburst data with ", nrow(sunburst_df), " nodes")
  return(sunburst_df)
}

#' Add medicine information to sunburst data
add_medicine_info <- function(sunburst_df, combined_medicines) {
  message("Adding medicine information to sunburst data...")
  
  # Create wide format for medicines
  ema_dkma_wide <- combined_medicines %>%
    group_by(atc_code_human) %>%
    summarise(products1 = paste(unique(drug_information), collapse = "<Br><Br>")) %>%
    ungroup() %>%
    distinct()
  
  # Join medicine information
  sunburst_df_hover <- sunburst_df %>%
    left_join(ema_dkma_wide %>% 
                filter(nchar(atc_code_human) == 7), 
              join_by(atc_code == atc_code_human)) 
  
  # Create final hover information
  sunburst_hover2 <- sunburst_df_hover %>%
    mutate(hover_info = case_when(ids == "Total" ~ "ATC",
                                  !is.na(products1) ~ paste0(atc_code, " - ", hover_info, ":<Br><Br>", products1),
                                  is.na(products1) & nchar(atc_code) == 7 ~ paste0(atc_code, "<Br>", hover_info),
                                  .default = hover_info),
           labels = case_when(ids == "Total" ~ "ATC",
                              .default = labels)) %>%
    select(-products1)
  
  return(sunburst_hover2)
}

#' Create final hierarchy for visualization
create_final_hierarchy <- function(sunburst_hover2) {
  message("Creating final hierarchy for visualization...")
  
  hierarchy <- sunburst_hover2 %>%
    separate(ids_text, into = paste0("level", 1:6), sep = " - ", fill = "right") %>%
    separate(ids, into = paste0("atc_level", 1:6), sep = " - ", fill = "right", remove = FALSE) %>%
    mutate(atc_level6 = atc_code, 
           atc_level1 = atc_level2) 
  
  return(hierarchy)
}

# =============================================================================
# MAIN PROCESSING PIPELINE
# =============================================================================

#' Main function to process visualization data
process_visualization_data <- function() {
  message("=== ATC Visualization Data Processing Pipeline ===")
  message("Starting at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
  
  # Step 1: Load ATC hierarchy data
  message("\n1. Loading ATC hierarchy data...")
  
  # Find the most recent hierarchy file
  hierarchy_files <- list.files("input/atc_data/", pattern = "WHO_ATC_Hierarchy_wide_.*\\.csv", full.names = TRUE)
  if (length(hierarchy_files) == 0) {
    stop("No ATC hierarchy files found in input/atc_data/. Please run data preparation first.")
  }
  
  # Use the most recent file
  latest_file <- hierarchy_files[which.max(file.mtime(hierarchy_files))]
  atc_levels <- read_csv(latest_file)
  message("   ✓ Loaded ", nrow(atc_levels), " ATC hierarchy records from ", basename(latest_file))
  
  # Step 2: Process EMA medicines data
  message("\n2. Processing medicines data...")
  ema_medicines <- process_ema_data("input/medicines_output_medicines_en-2.xlsx")
  
  # Step 3: Process DKMA medicines data
  columns <- names(ema_medicines)
  dkma_medicines <- process_dkma_data("input/ListeOverGodkendteLaegemidler-2.xlsx", columns)
  
  # Step 4: Combine medicines data
  message("\n3. Combining medicines data...")
  combined_ema_dkma <- bind_rows(ema_medicines, dkma_medicines) 
  saveRDS(combined_ema_dkma, file = "output/combined_ema_dkma.RDS")
  message("   ✓ Combined ", nrow(combined_ema_dkma), " total medicines")
  message("   ✓ Saved: output/combined_ema_dkma.RDS")
  
  # Step 5: Create sunburst data
  message("\n4. Creating sunburst data...")
  sunburst_df <- create_sunburst_data(atc_levels)
  saveRDS(sunburst_df, "input/sunburst_df.RDS")
  write_csv(sunburst_df, "input/sunburst_df.csv")
  message("   ✓ Saved: input/sunburst_df.RDS and .csv")
  
  # Step 6: Add medicine information
  message("\n5. Adding medicine information...")
  sunburst_hover2 <- add_medicine_info(sunburst_df, combined_ema_dkma)
  saveRDS(sunburst_hover2, file = "output/sunburst_dataframe.RDS")
  message("   ✓ Saved: output/sunburst_dataframe.RDS")
  
  # Step 7: Create final hierarchy
  message("\n6. Creating final hierarchy...")
  hierarchy <- create_final_hierarchy(sunburst_hover2)
  saveRDS(hierarchy, file = "output/atc_hierarchy.rds")
  message("   ✓ Saved: output/atc_hierarchy.rds")
  
  message("\n=== Visualization Data Processing Completed Successfully! ===")
  message("Finished at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
  
  return(hierarchy)
}

# Run the processing if this script is executed directly
if (!interactive()) {
  hierarchy <- process_visualization_data()
}
