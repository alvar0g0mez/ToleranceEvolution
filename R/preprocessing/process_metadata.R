# All necessary modifications to the metadata file so as to be able to use it properly


# Libraries
library(dplyr)
library(tidyr)
library(data.table)


# Load data
metadata <- as.data.frame(fread("/data/cephfs-1/home/users/algo12_c/work/ToleranceEvo_Wenxi/Data/metadata/2025-07-14_AF_30-0156_metadata.txt"))





######################### Processing #########################
metadata <- metadata %>%
  dplyr::mutate(Sample.Name = case_when(Sample.Type == "MS.QC" ~                                    # Here we name the QC samples with _01, _02, etc.
                                          gsub("-", 
                                               "_", 
                                               str_extract(File.Name, "(?<=P00_).*(?=\\.d$)")),      # $ asserts that we are at the end of the string
                                        TRUE ~ gsub("-", "_", Sample.Name)),                        # And here we also turn hyphens to underscores in other Sample.Names
                Strain.Name = case_when(grepl("QC", Sample.Name) ~ "QC",                                  # Create strain name column (just the strain)
                                        TRUE ~ substr(Sample.Name, 1, 3)),                          # Strain, passage and treatment
                Strain.Type = case_when(grepl("QC", Sample.Name) ~ "QC",                                  # Create strain name column (just the strain)
                                        substr(Sample.Name, 1, 1) == "C" ~ "Lab strain",
                                        substr(Sample.Name, 1, 1) == "H" ~ "High tolerance",
                                        substr(Sample.Name, 1, 1) == "I" ~ "Heteroresistant"),
                Passage = case_when(grepl("QC", Sample.Name) ~ "QC",                                      # Create passage column
                                    TRUE ~ substr(Sample.Name, 2, 2)),
                Treatment = case_when(grepl("QC", Sample.Name) ~ "QC",                                    # Create treatment column
                                      substr(Sample.Name, 3, 3) == "P" ~ "Pellet",
                                      substr(Sample.Name, 3, 3) == "L" ~ "Liquid",
                                      substr(Sample.Name, 3, 3) == "F" ~ "Fluconazole"))
                
  




# Save processed version of metadata
fwrite(metadata, "/data/cephfs-1/home/users/algo12_c/work/ToleranceEvo_Wenxi/Data/metadata/metadata_processed.txt")










  







