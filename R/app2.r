# read:
hierarchy <- readRDS("output/atc_hierarchy.rds")

# load: 
library(dplyr)
library(tidyr)
library(plotly)
library(stringr)
library(shiny)

# functions:

select_category_level <- function(hierarchy, text_input = NULL, atc_input = NULL) {
  
  # Internal function to search hierarchy safely
  search_hierarchy <- function(hierarchy, term_text = NULL, term_atc = NULL) {
    hits <- hierarchy
    
    # filter by text input if not empty
    if (!is.null(term_text) && nzchar(term_text)) {
      hits <- hits %>%
        filter(if_any(starts_with("level"),
                      ~ str_detect(.x, regex(term_text, ignore_case = TRUE))))
    }
    
    # filter by atc input if not empty
    if (!is.null(term_atc) && nzchar(term_atc)) {
      hits <- hits %>%
        filter(if_any(starts_with("atc_level"),
                      ~ str_detect(.x, regex(term_atc, ignore_case = TRUE))))
    }
    
    # if nothing left, return early
    if (nrow(hits) == 0) return(hits)
    
    # 3️⃣ Identify first unique match across both hierarchies
    first_category <- hits %>%
      pivot_longer(
        cols = c(starts_with("level"), starts_with("atc_level")),
        names_to = "level",
        values_to = "value"
      ) %>%
      { 
        df <- .
        # Apply str_detect only if term_text or term_atc exists
        if (!is.null(term_text) & !is.null(term_atc)) {
          df %>% filter(str_detect(value, regex(term_text, ignore_case = TRUE)) |
                          str_detect(value, regex(term_atc, ignore_case = TRUE)))
        } else if (!is.null(term_text)) {
          df %>% filter(str_detect(value, regex(term_text, ignore_case = TRUE)))
        } else if (!is.null(term_atc)) {
          df %>% filter(str_detect(value, regex(term_atc, ignore_case = TRUE)))
        } else {
          df
        }
      } %>%
      distinct(value) %>%
      slice(1) %>%
      pull(value)
    
    # 4️⃣ Keep only rows where that category appears in the hierarchy path
    hits %>%
      filter(if_any(c(starts_with("level"), starts_with("atc_level")), ~ .x == first_category))
  }
  
  # Apply search
  data <- search_hierarchy(hierarchy, term_text = text_input, term_atc = atc_input)
  
  # Build sunburst
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
}


ui <- fluidPage(
textInput("atc_code", "Enter ATC code", "A1"),
textInput("category", "Enter text", ""),
plotlyOutput("plot")
)
  
  
server <- function(input, output, session) {
  output$plot <- renderPlotly({
    select_category_level(hierarchy, 
                          atc_input = input$atc_code, 
                          text_input = input$category)
  })
}
  
shinyApp(ui = ui, server = server)





