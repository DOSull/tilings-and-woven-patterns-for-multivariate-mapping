library(tidycensus)
library(tigris)
library(dplyr)
library(sf)
library(readr)

census_api_key("2ee25f6e096f090d63071faaf0d9b37a831c31ab", install = TRUE)

race_vars <- c(
  Total    = "B03002_001",
  White    = "B03002_003", 
  Black    = "B03002_004", 
  Asian    = "B03002_006", 
  Hispanic = "B03002_012"  
)

# 1. Fetch the raw tract-level data for Manhattan
manhattan_raw <- get_acs(
  geography = "tract",
  state = "NY",
  county = c("New York", "Bronx", "Queens", "Kings", "Richmond"), 
  variables = race_vars,
  year = 2024,
  geometry = TRUE,
  output = "wide"
)

# 2. Fetch the official 2020 Census Tract to NTA Crosswalk from NYC Open Data
crosswalk_url <- "https://data.cityofnewyork.us/api/views/hm78-6dwm/rows.csv?accessType=DOWNLOAD"

crosswalk <- read_csv(crosswalk_url, show_col_types = FALSE) %>%
  # BoroCode 1 is Manhattan
  filter(BoroCode == 1) %>%
  select(GEOID, NTACode, NTAName) |> 
  mutate(GEOID = as.character(GEOID))

# 3. Join the tract data to the crosswalk and aggregate to the NTA level
manhattan_nta <- manhattan_raw %>%
  # Ensure GEOID is a character string to match the crosswalk
  mutate(GEOID = as.character(GEOID)) %>%
  
  # Join the data (inner_join drops unpopulated water tracts that lack an NTA)
  inner_join(crosswalk, by = "GEOID") %>%
  
  # Group by the NYC Neighborhood Tabulation Area codes and names
  group_by(NTACode, NTAName) %>%
  
  # Sum the tract populations and merge the tract polygons (st_union)
  summarize(
    Total_Pop = sum(TotalE, na.rm = TRUE),
    White_Pop = sum(WhiteE, na.rm = TRUE),
    Black_Pop = sum(BlackE, na.rm = TRUE),
    Asian_Pop = sum(AsianE, na.rm = TRUE),
    Hispanic_Pop = sum(HispanicE, na.rm = TRUE),
    geometry = st_union(geometry), 
    .groups = 'drop'
  ) %>%
  
  # Calculate the 'Other' population at the NTA level and reorder columns
  mutate(Other_Pop = Total_Pop - (White_Pop + Black_Pop + Asian_Pop + Hispanic_Pop)) %>%
  relocate(Other_Pop, .before = geometry)

# See the total number of Manhattan NTAs generated in the dataframe
print(paste("Total NTAs generated:", nrow(manhattan_nta)))

# View the clean, NTA-level sf dataframe
head(manhattan_nta)


manhattan_nta_pc <- manhattan_nta |>
  erase_water(year = 2024) |>
  filter(Total_Pop > 0) |>
  mutate(across(4:8, ~ round(. / Total_Pop * 100, 1))) |>
  rename(Percent_White = White_Pop,
         Percent_Black = Black_Pop,
         Percent_Asian = Asian_Pop,
         Percent_Hispanic = Hispanic_Pop,
         Percent_Other = Other_Pop)


library(tmap)

tm_shape(manhattan_nta_pc) +
  tm_fill(fill = names(manhattan_nta_pc)[3:8],
          fill.scale = tm_scale_intervals(n = 5)) +
  tm_borders()

