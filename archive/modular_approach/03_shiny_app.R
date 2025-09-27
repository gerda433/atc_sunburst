# =============================================================================
# ATC HIERARCHY INTERACTIVE VISUALIZATION APP
# =============================================================================
#
# This Shiny application provides an interactive interface for exploring the
# WHO Anatomical Therapeutic Chemical (ATC) classification system using
# dynamic sunburst plots with advanced search and filtering capabilities.

# Load packages
source("../R/packages.R")

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

#' Recalculate hierarchy values for filtered data
recalculate_hierarchy_values <- function(filtered_data, leaf_node_ids) {
  # Set all leaf nodes to value 1
  filtered_data$values <- ifelse(filtered_data$ids %in% leaf_node_ids, 1, filtered_data$values)
  
  # Get all unique depths in the hierarchy
  depths <- sapply(strsplit(filtered_data$ids, " - "), function(x) length(x))
  max_depth <- max(depths, na.rm = TRUE)
  
  # Recalculate parent node values from deepest to shallowest level
  for (level in max_depth:1) {
    # Find nodes at this level
    level_nodes <- filtered_data[depths == level, ]
    
    # Update each node's value based on its children
    for (i in seq_len(nrow(level_nodes))) {
      node_id <- level_nodes$ids[i]
      children <- filtered_data[filtered_data$parents == node_id, ]
      
      if (nrow(children) > 0) {
        # Only update if we have valid children values
        child_values <- children$values[!is.na(children$values)]
        if (length(child_values) > 0) {
          filtered_data$values[filtered_data$ids == node_id] <- sum(child_values)
        }
      }
    }
  }
  
  return(filtered_data)
}

#' Select and filter ATC hierarchy based on search criteria
select_category_level <- function(hierarchy, text_input = NULL, atc_input = NULL) {
  
  # Start with full hierarchy
  filtered_data <- hierarchy
  
  # Apply ATC code filtering if provided
  if (!is.null(atc_input) && nzchar(atc_input)) {
    # Clean the input - remove spaces and convert to uppercase
    atc_search <- str_trim(toupper(atc_input))
    
    # Find all hierarchy paths that start with the ATC code
    matching_paths <- filtered_data %>%
      filter(if_any(starts_with("atc_level"), 
                    ~ str_starts(.x, atc_search)))
    
    # Extract all unique hierarchy paths from matching rows
    all_paths <- unique(matching_paths$ids)
    
    # Check if we have any matches
    if (length(all_paths) == 0) {
      # No matches found, return empty data
      filtered_data <- filtered_data[0, ]
    } else {
      # Create a function to get all parent paths for a given path
      get_all_parent_paths <- function(path) {
        parts <- str_split(path, " - ")[[1]]
        parent_paths <- character(0)
        for (i in 1:(length(parts) - 1)) {
          parent_paths <- c(parent_paths, paste(parts[1:i], collapse = " - "))
        }
        return(parent_paths)
      }
      
      # Get all parent paths for all matching paths
      all_parent_paths <- unique(unlist(lapply(all_paths, get_all_parent_paths)))
      all_required_paths <- unique(c(all_parent_paths, all_paths))
      
      # Filter to include all required hierarchy paths
      filtered_data <- filtered_data %>%
        filter(ids %in% all_required_paths)
      
      # Recalculate values for proper sunburst display
      filtered_data <- recalculate_hierarchy_values(filtered_data, all_paths)
    }
  }
  
  # Apply text filtering if provided
  if (!is.null(text_input) && nzchar(text_input)) {
    # Clean the input
    text_search <- str_trim(text_input)
    
    # Find all hierarchy paths that contain the search term
    matching_paths <- filtered_data %>%
      filter(if_any(starts_with("level"), 
                    ~ str_detect(.x, regex(text_search, ignore_case = TRUE))))
    
    # Extract all unique hierarchy paths from matching rows
    all_paths <- unique(matching_paths$ids)
    
    # Check if we have any matches
    if (length(all_paths) == 0) {
      # No matches found, return empty data
      filtered_data <- filtered_data[0, ]
    } else {
      # Create a function to get all parent paths for a given path
      get_all_parent_paths <- function(path) {
        parts <- str_split(path, " - ")[[1]]
        parent_paths <- character(0)
        for (i in 1:(length(parts) - 1)) {
          parent_paths <- c(parent_paths, paste(parts[1:i], collapse = " - "))
        }
        return(parent_paths)
      }
      
      # Get all parent paths for all matching paths
      all_parent_paths <- unique(unlist(lapply(all_paths, get_all_parent_paths)))
      all_required_paths <- unique(c(all_parent_paths, all_paths))
      
      # Filter to include all required hierarchy paths
      filtered_data <- filtered_data %>%
        filter(ids %in% all_required_paths)
      
      # Recalculate values for proper sunburst display
      filtered_data <- recalculate_hierarchy_values(filtered_data, all_paths)
    }
  }
  
  # If no data remains after filtering, return empty plot
  if (nrow(filtered_data) == 0) {
    return(plot_ly() %>% 
           add_trace(type = "sunburst") %>%
           layout(title = "No data found matching search criteria"))
  }
  
  # Determine if filtering has been applied
  is_filtered <- (!is.null(atc_input) && nzchar(atc_input)) || 
                 (!is.null(text_input) && nzchar(text_input))
  
  # Use appropriate branchvalues setting
  branch_setting <- "total"  # Use total for both filtered and unfiltered data
  
  # Sort data alphabetically by labels to ensure proper ATC code ordering
  # Use descending order to compensate for plotly's reverse display
  filtered_data <- filtered_data[order(filtered_data$labels, decreasing = TRUE), ]
  
  # Build sunburst plot
  plot_ly(
    filtered_data,
    ids = ~ids,
    labels = ~labels,
    parents = ~parents,
    values = ~values,
    type = "sunburst",
    branchvalues = branch_setting,
    hovertext = ~hover_info,
    hoverinfo = "text",
    sort = FALSE
  ) %>%
    layout(
      title = if (is.null(atc_input) && is.null(text_input)) {
        "Complete ATC Hierarchy"
      } else {
        paste("ATC Hierarchy", 
              if (!is.null(atc_input) && nzchar(atc_input)) paste("(ATC:", atc_input, ")"),
              if (!is.null(text_input) && nzchar(text_input)) paste("(Text:", text_input, ")"))
      },
      sunburst = list(
        rotation = 0,
        branchvalues = branch_setting
      )
    )
}

# =============================================================================
# SHINY APPLICATION
# =============================================================================

# Load hierarchy data
message("Loading ATC hierarchy data...")
hierarchy <- readRDS("output/atc_hierarchy.rds")
message("✓ Loaded ", nrow(hierarchy), " hierarchy records")

# UI Definition
ui <- fluidPage(
  titlePanel("ATC Hierarchy Sunburst Plot"),
  sidebarLayout(
    sidebarPanel(
      h4("Search Filters"),
      textInput("atc_code", "Enter ATC code", "", 
                placeholder = "e.g., A, N05, M02AB"),
      helpText("Enter an ATC code to filter the hierarchy. Examples: 'A' shows all A* codes, 'N05' shows all N05* codes."),
      br(),
      textInput("category", "Enter text search", "", 
                placeholder = "e.g., nervous, antibiotic"),
      helpText("Search for text in category descriptions (case-insensitive)."),
      br(),
      actionButton("clear_filters", "Clear All Filters", 
                   style = "background-color: #dc3545; color: white;")
    ),
    mainPanel(
      plotlyOutput("plot", height = "800px", width = "100%")
    )
  )
)

# Server Definition
server <- function(input, output, session) {
  
  # Clear filters button
  observeEvent(input$clear_filters, {
    updateTextInput(session, "atc_code", value = "")
    updateTextInput(session, "category", value = "")
  })
  
  # Reactive plot
  output$plot <- renderPlotly({
    select_category_level(hierarchy, 
                          atc_input = input$atc_code, 
                          text_input = input$category)
  })
}

# Run the application
shinyApp(ui = ui, server = server)
