"""
Created on 20.08.2025
Python version

@autor Álvaro Gómez Pérez

This is just a quick file where I can do the pre-processing for my current projects (mainly Wenxi's Tolerance Evolution,
possibly ts-alleles) using Boris' functions, while the pre-processing pipeline is not fully developed. Not intended for
long term use.
"""


# Import libraries
import pandas as pd


import numpy as np

# Import Boris' functions
import sys
sys.path.insert(1, r"S:/AG/AG-Ralser/Daten/Boris/Scripts/")
import Python.Preprocessing.preprocessing as Boris


# Load data
## Load dataset (precursors in rows, samples in columns, intensities in cells)
df = pd.read_csv("C:/MyStuff/ToleranceEvo_Wenxi/Data/Preprocessing_steps/report_wide_filtered_norm_log2.csv", index_col=0)

## Check % of missing values in this initial dataset
percent_missing = df.isnull().sum() * 100 / len(df)
missing_value_df = pd.DataFrame({'column_name': df.columns,
                                 'percent_missing': percent_missing})
print(missing_value_df.loc[:, 'percent_missing'].mean())

## Load metadata and keep only the columns we are interested in for confounder correction
metadata_full = pd.read_csv("C:/MyStuff/ToleranceEvo_Wenxi/Data/metadata/metadata_processed.txt")
metadata = metadata_full[["Sample.Name", "Injection"]]
metadata = metadata.set_index("Sample.Name")

## Load correspondence between protein IDs and precursor IDs, and remove those not in our dataset
precursor_to_protein_match = pd.read_csv("C:/MyStuff/ToleranceEvo_Wenxi/Data/Preprocessing_steps/precursor_protein_correspondence.tsv")
precursor_to_protein_match = precursor_to_protein_match[precursor_to_protein_match["Precursor.Id"].isin(df.index)]



# Imputation - using KNN
df_imputed, filter_mask, filter_mask_description = Boris.knn_imputation(peptide_profiles = df, mask = None, keep_track = False, transposed = True)
df_imputed.to_csv("C:/MyStuff/ToleranceEvo_Wenxi/Data/Preprocessing_steps/report_wide_filtered_norm_fully_imputed_log2.csv")

## Create my own mask, to remember where the NAs where
na_mask = df.isna()
print(na_mask.values.sum())
print(na_mask.values.sum() / na_mask.size * 100)
na_mask.to_csv("C:/MyStuff/ToleranceEvo_Wenxi/Data/Preprocessing_steps/missingness_mask.csv")

## Keep imputed values which were MAR, set imputed values which were MNAR back to NA
print("Started fixing mask")
for protein in precursor_to_protein_match["Protein.Ids"].unique():                                                                     # Iterate over proteins
    precursors = precursor_to_protein_match.loc[precursor_to_protein_match["Protein.Ids"] == protein, "Precursor.Id"].tolist()         # Grab all precursors in this protein
    for col in na_mask.columns:                                                                                                        # Iterate over samples
        # Select values of the current column at the precursor indices
        vals = na_mask.loc[precursors, col]

        # Check how many are False
        if (vals == False).sum() >= 2:
            # Set them all to False
            na_mask.loc[precursors, col] = False
print("Finished fixing mask, here are total missing values and % of missing values in new mask:")
print(na_mask.values.sum())
print(na_mask.values.sum() / na_mask.size * 100)





# Confounder correction
## Create datatype_df
datatype_df = pd.DataFrame(["continuous"], columns=["DataType"], index=["Injection"])

## Load imputed df
df_imputed = pd.read_csv("C:/MyStuff/ToleranceEvo_Wenxi/Data/Preprocessing_steps/report_wide_filtered_norm_fully_imputed_log2.csv", index_col=0)

## Run confounder correction
df_corrected_for_confounders = Boris.correct_for_confounders(profiles_uncorr = df_imputed, metadata_df = metadata, datatype_df = datatype_df, sample_col = None)
df_corrected_for_confounders[0].to_csv("C:/MyStuff/ToleranceEvo_Wenxi/Data/Preprocessing_steps/report_wide_filtered_norm_fully_imputed_drift_corrected_log2.csv")
df_corrected_for_confounders[1].to_csv("C:/MyStuff/ToleranceEvo_Wenxi/Data/Preprocessing_steps/drift_correction_profiles.csv")

## Put NAs back and save dataframe
df_final = df_corrected_for_confounders[0]
df_final = df_final.mask(na_mask)
df_final.to_csv("C:/MyStuff/ToleranceEvo_Wenxi/Data/Preprocessing_steps/report_wide_filtered_norm_MAR_imputed_drift_corrected_log2.csv")






