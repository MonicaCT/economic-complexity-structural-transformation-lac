# Data Dictionary

## `data/processed/trade_country_product_year.parquet`

- `country_code`: ISO3 country code.
- `product_code`: HS92 4-digit product code.
- `year`: calendar year.
- `export_value`: export value from the local ATLAS file.
- `import_value`: import value from the local ATLAS file.
- `total_country_exports`: total exports by country-year.
- `total_world_exports_product`: world exports by product-year.
- `total_world_exports`: world exports by year.
- `rca`: recomputed Balassa RCA.
- `mcp`: 1 when RCA >= 1.
- `mcp_075`: 1 when RCA >= 0.75.
- `product_section`: HS section label derived from chapter.
- `region`: Latin America and Caribbean, Comparator, or Rest of world.

## `data/processed/country_year_panel.csv`

Country-year indicators merged with CEPII macro controls. Includes ECI, diversity, HHI, entropy, primary share, manufacturing share, GDP per capita PPP, and five-year-ahead GDP per capita growth.

## `outputs/tables/csv/bolivia_opportunities.csv`

Bolivia opportunity ranking for products without RCA >= 1 in 2023. Includes density, PCI, opportunity gain, market size, demand growth, normalized components, score, distance, and typology.