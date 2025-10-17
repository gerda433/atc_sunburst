# =============================================================================
# ATC SUNBURST UTILITY FUNCTIONS
# =============================================================================
# The function below is from the following source:

#' Create sunburst data format for Plotly visualization
create_sunburst_data_format <- function(DF_plotly, value_column = NULL, add_root = FALSE, drop_na_nodes = TRUE){
  colNamesDF_plotly <- names(DF_plotly)
  
  if(is.data.table(DF_plotly)){
    DT <- copy(DF_plotly)
  } else {
    DT <- data.table(DF_plotly, stringsAsFactors = FALSE)
  }
  
  if(add_root){
    DT[, root := "Total"]  
  }
  
  colNamesDT <- names(DT)
  hierarchy_columns <- setdiff(colNamesDT, value_column)
  numeric_hierarchy_columns <- names(which(unlist(lapply(DT, is.numeric))))
  
  if(is.null(value_column) && add_root){
    setcolorder(DT, c("root", colNamesDF_plotly))
  } else if(!is.null(value_column) && !add_root) {
    setnames(DT, value_column, "values", skip_absent=TRUE)
    setcolorder(DT, c(setdiff(colNamesDF_plotly, value_column), "values"))
  } else if(!is.null(value_column) && add_root) {
    setnames(DT, value_column, "values", skip_absent=TRUE)
    setcolorder(DT, c("root", setdiff(colNamesDF_plotly, value_column), "values"))
  }
  
  for(current_column in setdiff(numeric_hierarchy_columns, c("root", value_column))){
    DT[, (current_column) := apply(.SD, 1, function(x){fifelse(is.na(x), yes = NA_character_, no = toTitleCase(gsub("_"," ", paste(names(x), x, sep = ": ", collapse = " | "))))}), .SDcols = current_column]
  }
  
  hierarchyList <- list()
  for(i in seq_along(hierarchy_columns)){
    current_columns <- colNamesDT[1:i]
    
    if(is.null(value_column)){
      currentDT <- unique(DT[, ..current_columns][, values := .N, by = current_columns], by = current_columns)
    } else {
      currentDT <- DT[, lapply(.SD, sum, na.rm = TRUE), by=current_columns, .SDcols = "values"]
    }
    
    setnames(currentDT, length(current_columns), "labels")
    currentDT[, depth := length(current_columns)-1]
    hierarchyList[[i]] <- currentDT
  }
  
  hierarchyDT <- rbindlist(hierarchyList, use.names = TRUE, fill = TRUE)
  
  if(drop_na_nodes){
    hierarchyDT <- na.omit(hierarchyDT, cols = "labels")
    parent_columns <- setdiff(names(hierarchyDT), c("labels", "values", "depth", value_column))
    hierarchyDT[, parents := apply(.SD, 1, function(x){fifelse(all(is.na(x)), yes = NA_character_, no = paste(x[!is.na(x)], sep = ":", collapse = " - "))}), .SDcols = parent_columns]
  } else {
    parent_columns <- setdiff(names(hierarchyDT), c("labels", "values", value_column))
    hierarchyDT[, parents := apply(.SD, 1, function(x){fifelse(x["depth"] == "0", yes = NA_character_, no = paste(x[seq(2, as.integer(x["depth"])+1)], sep = ":", collapse = " - "))}), .SDcols = parent_columns]
  }
  
  hierarchyDT[, ids := apply(.SD, 1, function(x){paste(c(if(is.na(x["parents"])){NULL}else{x["parents"]}, x["labels"]), collapse = " - ")}), .SDcols = c("parents", "labels")]
  hierarchyDT[, union(parent_columns, "depth") := NULL]
  
  return(hierarchyDT)
}

# =============================================================================
# DATA VALIDATION FUNCTIONS
# =============================================================================

#' Validate ATC code format
validate_atc_code <- function(atc_code) {
  if (is.na(atc_code) || nchar(atc_code) == 0) return(FALSE)
  
  # ATC codes should be 1-7 characters: letter followed by 0-6 alphanumeric characters
  pattern <- "^[A-Z][A-Z0-9]{0,6}$"
  return(grepl(pattern, toupper(atc_code)))
}

#' Check if required data files exist
check_data_files <- function() {
  required_files <- c(
    "input/atc_data/WHO ATC-DDD 2024-07-31.csv",
    "input/atc_data/1_temporary_and_final_atc_and_ddd_final.xlsx",
    "input/atc_data/atc_ddd_new_and_alterations_2025_final.xlsx",
    "input/medicines_output_medicines_en-2.xlsx",
    "input/ListeOverGodkendteLaegemidler-2.xlsx"
  )
  
  missing_files <- required_files[!file.exists(required_files)]
  
  if (length(missing_files) > 0) {
    message("Missing required files:")
    for (file in missing_files) {
      message("  - ", file)
    }
    return(FALSE)
  }
  
  return(TRUE)
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

#' Get ATC hierarchy level from code length
get_atc_level <- function(atc_code) {
  code_length <- nchar(atc_code)
  if (code_length <= 1) return(1)
  if (code_length <= 3) return(2)
  if (code_length <= 4) return(3)
  if (code_length <= 5) return(4)
  if (code_length <= 7) return(5)
  return(NA)
}

#' Format ATC code for display
format_atc_code <- function(atc_code) {
  if (is.na(atc_code)) return(NA)
  return(toupper(str_trim(atc_code)))
}
