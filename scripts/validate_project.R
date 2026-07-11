root <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
if (basename(root) == "scripts") root <- dirname(root)
if (!dir.exists(file.path(root, "outputs")) && dir.exists(file.path(root, "..", "outputs"))) root <- normalizePath(file.path(root, ".."), winslash = "/")
required <- c("docs/DATA_INVENTORY.csv", "docs/DATA_FEASIBILITY_REPORT.md", "data/processed/trade_country_product_year.parquet", "data/processed/country_year_panel.csv", "outputs/tables/csv/bolivia_opportunities.csv", "outputs/reports/VALIDATION_REPORT.html")
missing <- required[!file.exists(file.path(root, required))]
if (length(missing)) stop("Missing required outputs: ", paste(missing, collapse=", "))
cat("Validation file-presence checks passed.\n")