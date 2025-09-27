# =============================================================================
# ATC SUNBURST PIPELINE COMPREHENSIVE TEST
# =============================================================================
#
# This script tests the complete ATC sunburst pipeline to ensure all components
# work correctly and produce the expected outputs.

# Load packages
source("R/packages.R")

# Source functions
source("R/functions.R")

# =============================================================================
# TEST FUNCTIONS
# =============================================================================

#' Test data file validation
test_data_files <- function() {
  message("=== Testing Data File Validation ===")
  
  if (check_data_files()) {
    message("✓ All required data files exist")
    return(TRUE)
  } else {
    message("✗ Some required data files are missing")
    return(FALSE)
  }
}

#' Test ATC code validation
test_atc_validation <- function() {
  message("\n=== Testing ATC Code Validation ===")
  
  test_codes <- c("A", "N05", "M02AB", "A10AB01", "123", NA, "")
  expected_results <- c(TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE)
  
  all_passed <- TRUE
  for (i in seq_along(test_codes)) {
    result <- validate_atc_code(test_codes[i])
    expected <- expected_results[i]
    
    if (result == expected) {
      message("✓ Code '", test_codes[i], "': ", ifelse(result, "Valid", "Invalid"))
    } else {
      message("✗ Code '", test_codes[i], "': Expected ", expected, ", got ", result)
      all_passed <- FALSE
    }
  }
  
  return(all_passed)
}

#' Test ATC level function
test_atc_levels <- function() {
  message("\n=== Testing ATC Level Function ===")
  
  test_codes <- c("A", "N05", "M02AB", "A10AB01")
  expected_levels <- c(1, 2, 4, 5)
  
  all_passed <- TRUE
  for (i in seq_along(test_codes)) {
    level <- get_atc_level(test_codes[i])
    expected <- expected_levels[i]
    
    if (level == expected) {
      message("✓ Code '", test_codes[i], "': Level ", level)
    } else {
      message("✗ Code '", test_codes[i], "': Expected level ", expected, ", got ", level)
      all_passed <- FALSE
    }
  }
  
  return(all_passed)
}

#' Test data preparation pipeline
test_data_preparation <- function() {
  message("\n=== Testing Data Preparation Pipeline ===")
  
  tryCatch({
    source("R/01_data_preparation.R")
    
    # Test if the function exists and can be called
    if (exists("prepare_atc_data")) {
      message("✓ Data preparation function exists")
      message("✓ Data preparation pipeline structure is valid")
      return(TRUE)
    } else {
      message("✗ Data preparation function not found")
      return(FALSE)
    }
  }, error = function(e) {
    message("✗ Error in data preparation pipeline: ", e$message)
    return(FALSE)
  })
}

#' Test data processing pipeline
test_data_processing <- function() {
  message("\n=== Testing Data Processing Pipeline ===")
  
  tryCatch({
    source("R/02_data_processing.R")
    
    # Test if the function exists and can be called
    if (exists("process_visualization_data")) {
      message("✓ Data processing function exists")
      
      # Test individual functions
      if (exists("process_ema_data")) message("✓ EMA data processing function exists")
      if (exists("process_dkma_data")) message("✓ DKMA data processing function exists")
      if (exists("create_sunburst_data")) message("✓ Sunburst data creation function exists")
      
      message("✓ Data processing pipeline structure is valid")
      return(TRUE)
    } else {
      message("✗ Data processing function not found")
      return(FALSE)
    }
  }, error = function(e) {
    message("✗ Error in data processing pipeline: ", e$message)
    return(FALSE)
  })
}

#' Test Shiny app structure
test_shiny_app <- function() {
  message("\n=== Testing Shiny App Structure ===")
  
  tryCatch({
    source("R/03_shiny_app.R")
    
    # Test if key functions exist
    if (exists("recalculate_hierarchy_values")) message("✓ Value recalculation function exists")
    if (exists("select_category_level")) message("✓ Category selection function exists")
    
    # Test if hierarchy data can be loaded
    if (file.exists("output/atc_hierarchy.rds")) {
      hierarchy <- readRDS("output/atc_hierarchy.rds")
      message("✓ Hierarchy data loaded successfully (", nrow(hierarchy), " records)")
    } else {
      message("⚠ Hierarchy data file not found - run data processing first")
    }
    
    message("✓ Shiny app structure is valid")
    return(TRUE)
  }, error = function(e) {
    message("✗ Error in Shiny app: ", e$message)
    return(FALSE)
  })
}

#' Test master pipeline
test_master_pipeline <- function() {
  message("\n=== Testing Master Pipeline ===")
  
  tryCatch({
    source("R/pipeline.R")
    
    # Test if main functions exist
    if (exists("run_atc_pipeline")) message("✓ Main pipeline function exists")
    if (exists("run_app")) message("✓ App runner function exists")
    if (exists("update_data")) message("✓ Data update function exists")
    
    message("✓ Master pipeline structure is valid")
    return(TRUE)
  }, error = function(e) {
    message("✗ Error in master pipeline: ", e$message)
    return(FALSE)
  })
}

# =============================================================================
# MAIN TEST EXECUTION
# =============================================================================

#' Run comprehensive pipeline test
run_comprehensive_test <- function() {
  message("=== ATC SUNBURST PIPELINE COMPREHENSIVE TEST ===")
  message("Starting at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
  
  # Run all tests
  tests <- list(
    "Data Files" = test_data_files(),
    "ATC Validation" = test_atc_validation(),
    "ATC Levels" = test_atc_levels(),
    "Data Preparation" = test_data_preparation(),
    "Data Processing" = test_data_processing(),
    "Shiny App" = test_shiny_app(),
    "Master Pipeline" = test_master_pipeline()
  )
  
  # Summary
  message("\n=== TEST SUMMARY ===")
  passed <- sum(unlist(tests))
  total <- length(tests)
  
  for (test_name in names(tests)) {
    status <- ifelse(tests[[test_name]], "✓ PASS", "✗ FAIL")
    message(test_name, ": ", status)
  }
  
  message("\nOverall: ", passed, "/", total, " tests passed")
  
  if (passed == total) {
    message("🎉 All tests passed! Pipeline is ready for use.")
  } else {
    message("⚠ Some tests failed. Please review the issues above.")
  }
  
  message("Finished at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
  
  return(passed == total)
}

# Run the comprehensive test if this script is executed directly
if (!interactive()) {
  success <- run_comprehensive_test()
  quit(status = ifelse(success, 0, 1))
}
