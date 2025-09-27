# ATC Sunburst Pipeline - Master Script
# This script runs the complete pipeline from data preparation to visualization

# Load packages
source("R/packages.R")

# Set working directory to project root
if (basename(getwd()) != "atc_sunburst") {
  if (file.exists("atc_sunburst.Rproj")) {
    setwd(".")
  } else {
    stop("Please run this script from the project root directory")
  }
}

#' Run the complete ATC sunburst pipeline
run_atc_pipeline <- function(skip_data_prep = FALSE, skip_processing = FALSE, run_app = TRUE) {
  
  message("=== ATC Sunburst Pipeline ===")
  message("Starting at: ", Sys.time())
  
  # Step 1: Data Preparation
  if (!skip_data_prep) {
    message("\n--- Step 1: Data Preparation ---")
    source("R/01_data_preparation.R")
    atc_levels <- prepare_atc_data()
  } else {
    message("\n--- Step 1: Data Preparation (SKIPPED) ---")
    message("Using existing data files...")
  }
  
  # Step 2: Data Processing
  if (!skip_processing) {
    message("\n--- Step 2: Data Processing ---")
    source("R/02_data_processing.R")
    hierarchy <- process_visualization_data()
  } else {
    message("\n--- Step 2: Data Processing (SKIPPED) ---")
    message("Using existing processed files...")
  }
  
  # Step 3: Launch Application
  if (run_app) {
    message("\n--- Step 3: Launching Shiny App ---")
    source("R/03_shiny_app.R")
  } else {
    message("\n--- Step 3: Shiny App (SKIPPED) ---")
    message("Pipeline completed. Run 'shiny::runApp(\"R/03_shiny_app.R\")' to launch the app.")
  }
  
  message("\n=== Pipeline Completed ===")
  message("Finished at: ", Sys.time())
}

# Run the complete pipeline if this script is executed directly
if (!interactive()) {
  # Check command line arguments
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) == 0) {
    # No arguments - run full pipeline
    run_atc_pipeline()
  } else if (args[1] == "app") {
    # Just run the app
    message("Launching ATC Sunburst Shiny App...")
    source("R/03_shiny_app.R")
  } else if (args[1] == "data") {
    # Just update data
    message("Updating ATC data...")
    run_atc_pipeline(skip_data_prep = FALSE, skip_processing = FALSE, run_app = FALSE)
    message("Data update completed!")
  } else if (args[1] == "help") {
    # Show help
    cat("ATC Sunburst Pipeline Usage:\n")
    cat("  Rscript pipeline.R          - Run complete pipeline\n")
    cat("  Rscript pipeline.R app      - Run only the Shiny app\n")
    cat("  Rscript pipeline.R data     - Update data only\n")
    cat("  Rscript pipeline.R help     - Show this help\n")
  } else {
    cat("Unknown argument:", args[1], "\n")
    cat("Use 'Rscript pipeline.R help' for usage information\n")
  }
}
