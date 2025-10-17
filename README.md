# ATC Hierarchy Sunburst Plot

An interactive Shiny application for exploring and searching the WHO Anatomical Therapeutic Chemical (ATC) classification system using a dynamic sunburst plot. This project provides a simple 3-step pipeline for data preparation, processing, and visualization.

## Data Sources

- **WHO ATC-DDD**: Base classification system (7,537 ATC codes)

The ATC source file was originally created by Fabrício Kury (date: 2024-07-31).
Retrieved from https://github.com/fabkury/atcd/blob/master/WHO%20ATC-DDD%202024-07-31.csv
Adapted and reused here for learning. Do not redistribute without attribution to Fabrício Kury. 

Fabricio Kury also made an excellent WHO ATC-code scraping script available, but I noticed the WHO allows only very slow scraping (a robotic 10 seconds crawl delay rule). I therefore decided to use Fabricio Kury's 2024 ATC file to not disturb the WHO server unnecessarily with my own scrape. Instead I updated his 2024 version with the publicly available 2024 and 2025 update files from WHO, retrieved from here: https://atcddd.fhi.no/lists_of__temporary_atc_ddds_and_alterations/ 
See the prepare_data.R code for more information.

- **EMA Medicines**: Centrally authorized medicines (2,553 medicines)
The EMA Medicines source file was retrieved from https://www.ema.europa.eu/en/documents/report/medicines-output-medicines-report_en.xlsx

- **DKMA Medicines**: Danish registered medicines (7,782 medicines)
The list of approved medicines in Denmark was retrieved here: https://laegemiddelstyrelsen.dk/en/licensing/licensing-of-medicines/lists-of-authorised-and-deregistered-medicines/how-to-use-the-list-of-authorised-medicinal-products/ 
The direct link to the DKMA xlsx file:
 https://laegemiddelstyrelsen.dk/LinkArchive.ashx?id=0BD4960F0D7744E3BABC951431681ECC&lang=da 
## Features


## Project Structure

```
├── prepare_data.R              # Step 1: Data preparation and ATC hierarchy creation
├── process_data.R              # Step 2: Visualization data preparation and medicine info
├── run_app.R                   # Step 3: Interactive Shiny application
├── functions.R                 # Utility functions and data validation
├── input/
│   ├── atc_data/               # WHO ATC source files
│   ├── medicines_output_medicines_en-2.xlsx  # EMA medicines data
│   └── ListeOverGodkendteLaegemidler-2.xlsx  # DKMA medicines data
└── output/
    ├── combined_medicines.RDS  # Combined medicines database
    └── hierarchy.RDS           # Final hierarchy for visualization
```


Required R packages:
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

## Technical Details

### Data Processing Pipeline

1. **Data Preparation** (`prepare_data.R`):
Processes raw WHO ATC data into hierarchical structure
   - Loads WHO ATC base data
   - Processes Excel updates and alterations
   - Creates hierarchical ATC structure
   - Saves processed hierarchy files

2. **Data Processing** (`process_data.R`):
Creates visualization-ready data with medicine information
   - Processes EMA and DKMA medicines data
   - Creates sunburst-compatible data format
   - Adds rich hover information
   - Saves final visualization data

3. **Shiny Application** (`run_app.R`):
Interactive Shiny application with search functionality
   - Loads processed data
   - Creates interactive sunburst plot
   - Implements search and filtering functionality
   - Launches web application

Supporting files:
- **`functions.R`**: Utility functions for data validation and sunburst formatting
