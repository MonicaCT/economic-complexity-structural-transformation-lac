required <- c("data.table", "arrow", "Matrix", "igraph", "ggplot2", "fixest", "openxlsx", "countrycode", "shiny", "plotly", "DT")
installed <- rownames(installed.packages())
missing <- setdiff(required, installed)
if (length(missing)) {
  stop("Missing packages: ", paste(missing, collapse=", "), ". Install from an approved local/CRAN setup before running.")
}
cat("All required packages are installed.\n")