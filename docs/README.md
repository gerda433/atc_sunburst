# ATC Hierarchy Sunburst Plot

A simple, interactive Shiny application for exploring the WHO Anatomical Therapeutic Chemical (ATC) classification system using dynamic sunburst plots. This project provides a straightforward 3-step pipeline for data preparation, processing, and visualization.

## Features

- **Interactive Sunburst Visualization**: Explore the complete ATC hierarchy with full 360-degree display
- **Advanced Search Functionality**:
  - **ATC Code Search**: Filter by ATC codes (e.g., "A", "N05", "M02AB")
  - **Text Search**: Search category descriptions (e.g., "nervous", "antibiotic")
  - **Combined Filtering**: Use both search methods simultaneously
- **Rich Hover Information**: Detailed drug information from EMA and DKMA databases
- **Simple Sequential Pipeline**: Easy-to-follow 3-step process
- **Intuitive Layout**: ATC codes displayed in alphabetical order with A codes at North (top)
- **Real-time Updates**: Dynamic filtering with instant plot updates

## Project Structure

```
├── prepare_data.R              # Step 1: Data preparation and ATC hierarchy creation
├── process_data.R              # Step 2: Visualization data preparation and medicine info
├── run_app.R                   # Step 3: Interactive Shiny application
├── R/
│   └── functions.R             # Utility functions and data validation
├── docs/                       # Documentation
│   ├── README.md
│   ├── HANDOVER_DOCUMENTATION.md
│   ├── PROJECT_RULES.md
│   └── REFINEMENT_SUMMARY.md
├── archive/                    # Archived files (not used in current pipeline)
│   ├── modular_approach/       # Old modular R files
│   ├── old_outputs/           # Old output files
│   ├── quarto_files/          # Quarto/HTML files
│   └── test_files/            # Test files
├── input/
│   ├── atc_data/               # WHO ATC source files
│   ├── medicines_output_medicines_en-2.xlsx  # EMA medicines data
│   └── ListeOverGodkendteLaegemidler-2.xlsx  # DKMA medicines data
└── output/
    ├── combined_medicines.RDS  # Combined medicines database
    └── hierarchy.RDS           # Final hierarchy for visualization
```

## Quick Start

### Simple 3-Step Process

**Step 1: Prepare Data**
```r
source("prepare_data.R")
```

**Step 2: Process Data**
```r
source("process_data.R")
```

**Step 3: Run App**
```r
source("run_app.R")
```

The app will open automatically in RStudio's Viewer pane!

## Prerequisites

Install required R packages:
```r
install.packages(c("shiny", "plotly", "dplyr", "tidyr", "stringr", 
                   "readr", "readxl", "purrr", "data.table", 
                   "htmlwidgets", "janitor"))
```

## Usage Instructions

### Running the Application

1. **Open RStudio**
2. **Set working directory** to the project folder
3. **Run the three scripts in order**:
   ```r
   source("prepare_data.R")
   source("process_data.R") 
   source("run_app.R")
   ```

### Using the App

- **Search by ATC Code**: Enter codes like "A", "N05", "M02AB" to filter the hierarchy
- **Search by Text**: Enter terms like "nervous", "antibiotic" to find relevant categories
- **Clear Filters**: Use the "Clear All Filters" button to reset
- **Navigate**: Click on segments to zoom into specific parts of the hierarchy
- **View Details**: Hover over segments to see detailed medicine information

## Data Sources

- **WHO ATC-DDD**: Base classification system (7,537 ATC codes)
- **EMA Medicines**: Centrally authorized medicines (2,553 medicines)
- **DKMA Medicines**: Danish registered medicines (7,782 medicines)

## Performance Metrics

- **Processing Time**: ~3 seconds for complete pipeline
- **Data Volume**: 7,537 ATC codes → 5,680 chemical substances
- **Medicines**: 10,335 total medicines with detailed information
- **Visualization**: 6,878 interactive nodes

## Maintenance & Updates

### Regular Updates
- **WHO Data**: Update `input/atc_data/` files when new WHO releases available
- **Medicines Data**: Refresh EMA and DKMA files as needed
- **Pipeline**: Run `source("prepare_data.R")` then `source("process_data.R")` to update processed data

### Troubleshooting
- **Missing Files**: Check that all input files exist in `input/` directory
- **Package Issues**: Check `install.packages()` requirements above
- **Data Errors**: Review console output for specific error messages

## Technical Details

### Data Processing Pipeline

1. **Data Preparation** (`prepare_data.R`):
   - Loads WHO ATC base data
   - Processes Excel updates and alterations
   - Creates hierarchical ATC structure
   - Saves processed hierarchy files

2. **Data Processing** (`process_data.R`):
   - Processes EMA and DKMA medicines data
   - Creates sunburst-compatible data format
   - Adds rich hover information
   - Saves final visualization data

3. **Shiny Application** (`run_app.R`):
   - Loads processed data
   - Creates interactive sunburst plot
   - Implements search and filtering functionality
   - Launches web application

### Key Features

- **Hierarchical Filtering**: Maintains complete tree structure when filtering
- **Value Recalculation**: Properly adjusts segment sizes based on filtered data
- **Medicine Integration**: Rich hover information from multiple data sources
- **Responsive Design**: Works in both RStudio Viewer and web browsers

## File Descriptions

- **`prepare_data.R`**: Processes raw WHO ATC data into hierarchical structure
- **`process_data.R`**: Creates visualization-ready data with medicine information
- **`run_app.R`**: Interactive Shiny application with search functionality
- **`R/functions.R`**: Utility functions for data validation and sunburst formatting

## Support

This project is designed to be simple and maintainable. The sequential script approach makes it easy to understand and modify. Each script has a single responsibility and can be run independently if needed.

For questions or issues, refer to the console output for specific error messages and ensure all required packages are installed.