library(data.table)
root <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
eci <- fread(file.path(root, "data/processed/country_year_complexity.csv"))
stopifnot(nrow(eci) > 0)
by_year <- eci[, .(m = mean(eci, na.rm=TRUE), s = sd(eci, na.rm=TRUE)), by=year]
stopifnot(max(abs(by_year$m), na.rm=TRUE) < 1e-8)
stopifnot(all(by_year$s > 0.9 & by_year$s < 1.1, na.rm=TRUE))