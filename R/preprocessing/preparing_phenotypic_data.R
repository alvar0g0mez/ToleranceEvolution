# The point of this file is to get the information of the tolerance and resistance of each strain at each passage and summarize it 
# in a simple table that I can use for all the rest of the analysis. I start from an Excel file provided by Wenxi, which has a separate
# sheet for each of the strains. It also has different columns for RAD and FoG (we use the 20 ones) and not clear columns for replicate,
# strain, passage... so will also create those, and output a single nice dataframe with all of this information. 

# I will keep only RAD20 and FoG20 and rename them respectively "Resistance" and "Tolerance" to ease further analysis, I can always come
# back here and change it. Probably ask Wenxi at some point why we use the 20 one and if we would consider using a different one.

# At passage 7 there are 2 versions, one with 25mg of fluconazole in the media (the same as in all other passages) and another one with 50mg
# (need to ask Wenxi why he did that one), going to be using only the 25mg one for now! Otherwise, change it later

# Created on: 13.10.2025
# Last modified on: 15.10.2025


# Libraries
library(xlsx)
library(dplyr)
library(data.table)
library(stringr)



# Set up
working_from <- "home"

if (working_from == "home") {
  base_dir = "/home/alvaro/MyStuff/"
} else
  if (working_from == "charite") {
    base_dir = "C:/MyStuff/"
  }

save_files_to <- "local"
if (save_files_to == "s") {
  location_to_save <- "S:/AG/AG-CF-HTMS/AG-Ralser-Share/30-0156_WenxiQi-ToleranceEvo/05_DataAnalysis/11_Analysis_Alvaro/"
} else if (save_files_to == "local") {
  location_to_save <- paste(base_dir, "ToleranceEvo_Wenxi/", sep="")
}


# Load data
## Metadata
metadata <- as.data.frame(fread(paste(base_dir, "ToleranceEvo_Wenxi/Data/metadata/metadata_processed.txt", sep="")))

## Phenotypic data
pheno_lab_strain <- as.data.frame(read.xlsx(paste(base_dir, "ToleranceEvo_Wenxi/Data/phenotypic_data/Allevo_df.xlsx", sep = ""), sheetName = "SC_evo_df", header = T))
pheno_heteroresistant <- as.data.frame(read.xlsx(paste(base_dir, "ToleranceEvo_Wenxi/Data/phenotypic_data/Allevo_df.xlsx", sep = ""), sheetName = "I_evo_df", header = T))
pheno_high_tolerance <- as.data.frame(read.xlsx(paste(base_dir, "ToleranceEvo_Wenxi/Data/phenotypic_data/Allevo_df.xlsx", sep = ""), sheetName = "H_evo_df", header = T))




# Processing
## 1. Create strain column, replicate column and passage column,
## remove unnecessary columns, and rename Type (Replicate) and FoG20_48
pheno_lab_strain <- pheno_lab_strain %>%
  dplyr::mutate(Strain.Type = "Lab strain") %>%
  dplyr::rename(Replicate = type) %>%
  dplyr::mutate(Passage = as.character(as.numeric(str_extract(name, "(?<=pa)."))-1)) %>%
  #dplyr::filter(!grepl("50-24", name)) %>%
  dplyr::select(-c(name, line, RAD80, RAD50, FoG80, FoG50, FoG20,
                   name_48, line_48, type_48, RAD80_48, RAD50_48, RAD20_48, FoG80_48, FoG50_48)) %>%
  dplyr::rename(FoG20 = FoG20_48)

pheno_heteroresistant <- pheno_heteroresistant %>%
  dplyr::mutate(Strain.Type = "Heteroresistant") %>%
  dplyr::rename(Replicate = type) %>%
  dplyr::mutate(Passage = as.character(as.numeric(str_extract(name, ".(?=I)"))-1)) %>%
  #dplyr::filter(!grepl("50mg", name)) %>%
  dplyr::select(-c(name, line, RAD80, RAD50, FoG80, FoG50, FoG20,
                   name_48, line_48, type_48, RAD80_48, RAD50_48, RAD20_48, FoG80_48, FoG50_48)) %>%
  dplyr::rename(FoG20 = FoG20_48)

pheno_high_tolerance <- pheno_high_tolerance %>%
  dplyr::mutate(Strain.Type = "High tolerance") %>%
  dplyr::rename(Replicate = type) %>%
  dplyr::mutate(Passage = as.character(as.numeric(str_extract(name, ".(?=H)"))-1)) %>%
  #dplyr::filter(!grepl("50mg", name)) %>%
  dplyr::select(-c(name, line, RAD80, RAD50, FoG80, FoG50, FoG20,
                   name_48, line_48, type_48, RAD80_48, RAD50_48, RAD20_48, FoG80_48, FoG50_48)) %>%
  dplyr::rename(FoG20 = FoG20_48)


## 2. Join all strains into a single dataframe
pheno_full <- rbind(pheno_high_tolerance, rbind(pheno_lab_strain, pheno_heteroresistant))

### Save this full dataframe with all passages - can't do it after matching to metadata, because there are only passages 0, 4 and 7 there
fwrite(pheno_full, paste(base_dir, "ToleranceEvo_Wenxi/Data/phenotypic_data/processed_phenotypic_data_all_passages.tsv", sep = ""))

### Keep only passages 0, 4 and 7 and save separately
pheno_full <- pheno_full %>%
  dplyr::filter(Passage %in% c(0, 4, 7))


## 3. Match to metadata (this is subject to confirming that the replicates here is where the replicates at the proteomic
## level were generated - need to ask Wenxi tomorrow!)
### 3.1. Create a new column in the metadata with the replicate, so that I can match phenotypic data to metadata
metadata <- metadata %>%
  dplyr::mutate(Replicate = as.numeric(substr(Sample.Name, nchar(Sample.Name), nchar(Sample.Name))))

### 3.2. Match them - creates a dataset where the phenotypic information is repeated 3 times for each sample, since it creates a row 
### for each pellet, liquid and fluconazole from each of the original phenotypic data replicate that they came from (again, confirm
### with Wenxi).
temp_metadata <- metadata %>%
  dplyr::select(Replicate, Strain.Type, Passage, Strain.Name, Sample.Name)

final_pheno <- left_join(temp_metadata, pheno_full, by = c("Replicate", "Strain.Type", "Passage"))

### Save dataset
fwrite(final_pheno, paste(base_dir, "ToleranceEvo_Wenxi/Data/phenotypic_data/processed_phenotypic_data.tsv", sep = ""))





