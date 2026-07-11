root <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
required <- c("outputs/figures/png/eci_latin_america_trends.png", "outputs/figures/png/bolivia_density_pci.png", "outputs/tables/xlsx/bolivia_opportunities.xlsx", "outputs/reports/VALIDATION_REPORT.html")
stopifnot(all(file.exists(file.path(root, required))))