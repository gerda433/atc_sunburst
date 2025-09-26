

library(dplyr)
library(readr)
library(tidyr)
library(plotly)
library(stringr)
library(data.table)
library(shiny)
library(shinyjs)
library(shinydashboard)
library(tools)



# read:
atc_levels <- read_csv("../input/WHO_ATC_Hierarchy_wide_2025-09-16.csv")

source("functions.R")

# I need a little work-around to get the format I need. Might be better ways out there
# original code version:
df <- atc_levels %>%
  mutate(value = 1) %>%
  select(atc_level_01, atc_level_03, atc_level_04, atc_level_05, atc_code, chemical_substance, value)

# text version:
df_text <- atc_levels %>%
  mutate(value = 1) %>%
  select(anatomical_main_group_01, therapeutic_subgroup_02, pharmacological_subgroup_03, chemical_subgroup_04, atc_code, chemical_substance, value)


# Apply his function to the dataset:
hierarchyDF <- create_sunburst_data_format(df, value_column = "value", add_root = TRUE)

# To create the relevant hover information, the next step is a little unusual, probably a better solution out there:
hierarchyDF_text <- create_sunburst_data_format(df_text, value_column = "value", add_root = TRUE) %>%
  mutate(
    hover_info = sapply(ids, function(x) {
      parts <- str_split(x, " - ")[[1]]   # split by " - "
      str_trim(tail(parts, 1))            # take last segment, trim spaces
    })
  ) %>%
  mutate(hover_info = str_replace(hover_info, "^(.)", toupper)) %>%
  mutate(ids_text = ids)


sunburst_df <- hierarchyDF %>%
  mutate(hover_info = hierarchyDF_text$hover_info,
         ids_text = hierarchyDF_text$ids_text) %>%
  mutate(hover_info = case_when(ids == "Total" ~ "ATC",
                                .default = hover_info),
         labels = case_when(ids == "Total" ~ "ATC",
                            .default = labels))

  hierarchy <- sunburst_df %>%
  separate(ids_text, into = paste0("level", 1:10), sep = " - ", fill = "right", remove = FALSE) %>%
  separate(ids, into = paste0("atc_level", 1:10), sep = " - ", fill = "right", remove = FALSE)


#---- Helper function ----
# Internal function to search hierarchy safely
search_hierarchy <- function(hierarchy, term_text = NULL, term_atc = NULL) {
  
  # Handle empty strings as NULL
  if (!is.null(term_text) && term_text == "") term_text <- NULL
  if (!is.null(term_atc) && term_atc == "") term_atc <- NULL
  
  # If no search terms, return all data
  if (is.null(term_text) && is.null(term_atc)) {
    return(hierarchy)
  }
  
  hits <- hierarchy
  
  # Filter by text term if provided
  if (!is.null(term_text)) {
    hits <- hits %>%
      filter(if_any(starts_with("level"), ~ str_detect(.x, regex(term_text, ignore_case = TRUE))))
  }
  
  # Filter by ATC code term if provided  
  if (!is.null(term_atc)) {
    hits <- hits %>%
      filter(if_any(starts_with("atc_level"), ~ str_detect(.x, regex(term_atc, ignore_case = TRUE))))
  }
  
  return(hits)
}
# ---- Wrapper to build sunburst ----
select_category_level <- function(hierarchy, text_input = NULL, atc_input = NULL) {
  data <- search_hierarchy(hierarchy, term_text = text_input, term_atc = atc_input)
  
  # Add debugging:
  cat("Number of rows returned:", nrow(data), "\n")
  cat("Columns:", paste(names(data), collapse = ", "), "\n")
  if(nrow(data) > 0) {
    cat("First few ids:", head(data$ids, 3), "\n")
    cat("First few labels:", head(data$labels, 3), "\n")
  }

  plot_ly(
    data,
    ids = ~ids,
    labels = ~labels,
    parents = ~parents,
    values = ~values,
    type = "sunburst",
    branchvalues = "total",
    hovertext = ~hover_info,
    hoverinfo = "text"
  )
}
#---- App ----  

ui <- fluidPage(
  textInput("text", "Search text:"),
  textInput("atc", "Search ATC code:"),
  verbatimTextOutput("debug_info"),  # Add this line
  plotlyOutput("sunburst")
)



#server <- function(input, output) { 
#  output$sunburst <- renderPlotly({
#    select_category_level(hierarchy, text_input = input$text, atc_input = input$atc)
#  })
#}


# Add this to your server:
server <- function(input, output) { 
output$debug_info <- renderText({
  # Clean the inputs
  clean_text <- if(is.null(input$text) || str_trim(input$text) == "") NULL else str_trim(input$text)
  clean_atc <- if(is.null(input$atc) || str_trim(input$atc) == "") NULL else str_trim(input$atc)
  
  data <- search_hierarchy(hierarchy, term_text = clean_text, term_atc = clean_atc)
  
  paste(
    "=== SEARCH DEBUG ===", "\n",
    "Raw text: '", input$text, "'", "\n",
    "Raw ATC: '", input$atc, "'", "\n",
    "Clean text:", if(is.null(clean_text)) "NULL" else paste("'", clean_text, "'"), "\n",
    "Clean ATC:", if(is.null(clean_atc)) "NULL" else paste("'", clean_atc, "'"), "\n",
    "Rows returned:", nrow(data), "\n",
    "=== PLOT DATA CHECK ===", "\n",
    "Has required columns:", all(c("ids", "labels", "parents", "values") %in% names(data)), "\n",
    "Any NA values in ids:", any(is.na(data$ids)), "\n",
    "Any NA values in labels:", any(is.na(data$labels)), "\n",
    "Any NA values in parents:", any(is.na(data$parents)), "\n",
    "Any NA values in values:", any(is.na(data$values)), "\n",
    "Sample ids:", paste(head(data$ids, 3), collapse = ", "), "\n",
    "Sample labels:", paste(head(data$labels, 3), collapse = ", "), "\n",
    "Sample parents:", paste(head(data$parents, 3), collapse = ", "), "\n",
    "Sample values:", paste(head(data$values, 3), collapse = ", ")
  )
})


output$sunburst <- renderPlotly({
  # Clean the inputs
  clean_text <- if(is.null(input$text) || str_trim(input$text) == "") NULL else str_trim(input$text)
  clean_atc <- if(is.null(input$atc) || str_trim(input$atc) == "") NULL else str_trim(input$atc)
  
  data <- search_hierarchy(hierarchy, term_text = clean_text, term_atc = clean_atc)
  
  # Try the exact same structure as your working version
  plot_ly(
    data,
    ids = ~ids,
    labels = ~labels,
    parents = ~parents,
    values = ~values,
    type = "sunburst",
    branchvalues = "total",
    hovertext = ~hover_info,
    hoverinfo = "text",
    sort = FALSE,
    rotation = 90
  )
})

}


shinyApp(ui = ui, server = server)
