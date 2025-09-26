# From ismirsehregal on Stackoverflow:

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


