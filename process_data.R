# =============================================================================
# PROCESS DATA - Step 2
# =============================================================================
# Simple script to process data for visualization
# Run this second: source("process_data.R")

# Load packages
suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(readr)
  library(readxl)
  library(purrr)
  library(plotly)
  library(data.table)
  library(htmlwidgets)
  library(tidyr)
})

# Source utility functions
source("functions.R")

# Load ATC hierarchy data
message("Loading ATC hierarchy data...")
atc_levels <- read_csv("input/atc_data/WHO_ATC_Hierarchy_wide_latest.csv")
message("✓ Loaded ", nrow(atc_levels), " ATC hierarchy records")

# Process EMA medicines data
message("Processing EMA medicines data...")
ema_medicines_raw <- read_excel("input/medicines_output_medicines_en-2.xlsx", skip = 8)

ema_medicines <- ema_medicines_raw %>%
  janitor::clean_names() %>%
  rename(therapeutic_area = therapeutic_area_me_sh) %>%
  select(name_of_medicine, active_substance, atc_code_human, 
         therapeutic_indication, therapeutic_area, marketing_authorisation_date) %>%
  mutate(
    active_substance = str_to_lower(active_substance), 
    therapeutic_indication = str_replace_all(therapeutic_indication, "(.{1,60})(\\s|$)", "\\1<br>"),
    marketing_authorisation_date = format(as.Date(marketing_authorisation_date, format = "%d/%m/%Y"), format = "%d/%m/%Y")
  ) %>%
  distinct(name_of_medicine, .keep_all = TRUE) %>%
  mutate(drug_information = paste0(
    "<b>", name_of_medicine, "</b> - centrally authorised (EMA)<Br>", 
    "<b>Date authorised</b><Br>", marketing_authorisation_date, 
    "<Br><b>Indication(s)</b><Br>", str_replace_all(therapeutic_area, ";", "<Br>")
  ))

message("✓ Processed ", nrow(ema_medicines), " EMA medicines")

# Process DKMA medicines data
message("Processing DKMA medicines data...")
dkma_medicines_raw <- read_excel("input/ListeOverGodkendteLaegemidler-2.xlsx")

columns <- names(ema_medicines)
dkma_medicines <- dkma_medicines_raw %>%
  mutate(
    name_of_medicine = Navn,
    active_substance = str_to_lower(AktiveSubstanser),
    atc_code_human = `ATC-kode`,
    therapeutic_indication = NA,
    therapeutic_area = NA,
    marketing_authorisation_date = format(as.Date(Registreringsdato), "%d-%m-%Y"), 
    drug_information = paste0(
      "<b>", name_of_medicine, "</b><Br>", 
      "<b>DK registration date</b><Br>", marketing_authorisation_date
    )
  ) %>%
  select(all_of(columns)) %>%
  distinct(name_of_medicine, .keep_all = TRUE)

message("✓ Processed ", nrow(dkma_medicines), " DKMA medicines")

# Combine medicines data
message("Combining medicines data...")
combined_medicines <- bind_rows(ema_medicines, dkma_medicines)
message("✓ Combined ", nrow(combined_medicines), " total medicines")

# Create sunburst data
message("Creating sunburst data...")
df <- atc_levels %>%
  mutate(value = 1) %>%
  select(atc_level_01, atc_level_03, atc_level_04, atc_level_05, 
         chemical_substance, value)

df_text <- atc_levels %>%
  mutate(value = 1) %>%
  select(anatomical_main_group_01, therapeutic_subgroup_02, 
         pharmacological_subgroup_03, chemical_subgroup_04, 
         chemical_substance, value)

df_code <- atc_levels %>%
  mutate(value = 1) %>%
  select(atc_level_01, atc_level_03, atc_level_04, atc_level_05, 
         atc_code, value)

# Apply sunburst formatting
hierarchyDF <- create_sunburst_data_format(df, value_column = "value", add_root = TRUE)
hierarchyDF_code <- create_sunburst_data_format(df_code, value_column = "value", add_root = TRUE)

hierarchyDF_text <- create_sunburst_data_format(df_text, value_column = "value", add_root = TRUE) %>%
  mutate(
    hover_info = sapply(ids, function(x) {
      parts <- str_split(x, " - ")[[1]]
      str_trim(tail(parts, 1))
    }),
    ids_text = ids
  ) 

sunburst_df <- hierarchyDF %>%
  mutate(
    hover_info = hierarchyDF_text$hover_info,
    atc_code = case_when(
      nchar(hierarchyDF_code$labels) == 7 ~ hierarchyDF_code$labels, 
      .default = NA
    ),
    ids_text = hierarchyDF_text$ids_text
  ) %>%
  arrange(desc(labels)) 

message("✓ Created sunburst data with ", nrow(sunburst_df), " nodes")

# Add medicine information
message("Adding medicine information...")
ema_dkma_wide <- combined_medicines %>%
  group_by(atc_code_human) %>%
  summarise(products1 = paste(unique(drug_information), collapse = "<Br><Br>")) %>%
  ungroup() %>%
  distinct()

sunburst_df_hover <- sunburst_df %>%
  left_join(ema_dkma_wide %>% 
              filter(nchar(atc_code_human) == 7), 
            join_by(atc_code == atc_code_human)) 

sunburst_hover2 <- sunburst_df_hover %>%
  mutate(hover_info = case_when(ids == "Total" ~ "ATC",
                                !is.na(products1) ~ paste0(atc_code, " - ", hover_info, ":<Br><Br>", products1),
                                is.na(products1) & nchar(atc_code) == 7 ~ paste0(atc_code, "<Br>", hover_info),
                                .default = hover_info),
         labels = case_when(ids == "Total" ~ "ATC",
                            .default = labels)) %>%
  select(-products1)

# Create final hierarchy
hierarchy <- sunburst_hover2 %>%
  separate(ids_text, into = paste0("level", 1:6), sep = " - ", fill = "right") %>%
  separate(ids, into = paste0("atc_level", 1:6), sep = " - ", fill = "right", remove = FALSE) %>%
  mutate(atc_level6 = atc_code, 
         atc_level1 = atc_level2) 

# Save processed data
saveRDS(combined_medicines, "output/combined_medicines.RDS")
saveRDS(hierarchy, "output/hierarchy.RDS")

message("✓ Data processing completed!")
message("✓ Saved: output/combined_medicines.RDS")
message("✓ Saved: output/hierarchy.RDS")
