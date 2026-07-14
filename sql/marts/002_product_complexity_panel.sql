-- Product complexity mart from existing final outputs.
-- Intended for DuckDB execution by future users; not executed in this phase.

CREATE OR REPLACE VIEW mart_product_complexity_panel AS
SELECT
    product_code,
    year,
    product_section,
    product_chapter,
    world_export_value,
    ubiquity,
    source_pci,
    pci,
    ubiquity_complexity,
    pci_final,
    RANK() OVER (PARTITION BY year ORDER BY pci_final DESC) AS pci_rank
FROM read_csv_auto('outputs/tables/csv/product_year_indicators.csv', header = true);
