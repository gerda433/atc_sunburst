# =============================================================================
# PACKAGE LOADING - CENTRALIZED
# =============================================================================

# Load all required packages for the ATC Sunburst Pipeline
load_packages <- function() {
  suppressPackageStartupMessages({
    # Core data manipulation
    library(dplyr)
    library(tidyr)
    library(stringr)
    library(purrr)
    
    # Data I/O
    library(readr)
    library(readxl)
    
    # Visualization
    library(plotly)
    library(htmlwidgets)
    
    # Shiny
    library(shiny)
    
    # Data processing
    library(data.table)
    
    # Utilities
    library(janitor)
  })
  
  message("✓ All packages loaded successfully")
}

# Load packages when sourced
load_packages()
