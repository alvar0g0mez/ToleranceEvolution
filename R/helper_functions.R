library(roxygen2)


################################################################################
################ Functions for basic evaluation of DIA-NN report ###############
################################################################################


#' Count IDd precursors per sample
#' 
count_precursors_per_sample <- function(report) {
  report <- report %>%
    summarize_mine("File.Name", "Precursors_per_sample")
  return(report)
}


#' Add injection order from metadata to report
#' 
add_injection_order_from_metadata_to_report <- function(report, metadata) {
  metadata <- metadata %>%
    dplyr::mutate(Injection_order = paste(Date, Injection, sep="_")) %>%
    dplyr::select(File.Name, Injection_order, Sample.Type)
  report <- left_join(report, metadata, by = "File.Name")
  return(report)
}





















################################################################################
# dplyr::summarize without collapsing
################################################################################
#' Take a dataframe, the name of one of its columns and a name for the new output
#' column that will be produced. Return the same dataframe with an extra column,
#' containing the number of times the term in that row and in the afore 
#' mentioned column appears throughout the whole column. Basically what 
#' dplyr::summarize does, but without actually summarizing or collapsing the 
#' dataset in any way.
#' 
#' @param df Input dataframe
#' @param column_name A string, with the name of the column containing the
#' terms we want to count 
#' @param output_column_name A string, with the desired column name for the new
#' column in the dataframe
#' 
#' @return The input dataframe with a new column, counting the appearances of 
#' the terms in the specified column
summarize_mine <- function(df, column_name, output_column_name) {
  # Perform the count
  temp <- df %>%
    group_by(get(column_name)) %>%
    dplyr::count()
  
  # Match to full dataset
  colnames(temp) <- c(column_name, output_column_name)
  df <- left_join(df, temp, by = column_name)
  
  # Return output
  return(df)
}






