-- Validation SQL contract for public final outputs.
-- Intended for future DuckDB checks; not executed in this phase.

WITH country_year AS (
    SELECT *
    FROM read_csv_auto('outputs/tables/csv/country_year_indicators.csv', header = true)
),
product_year AS (
    SELECT *
    FROM read_csv_auto('outputs/tables/csv/product_year_indicators.csv', header = true)
),
opportunities AS (
    SELECT *
    FROM read_csv_auto('outputs/tables/csv/bolivia_opportunities_revised.csv', header = true)
)
SELECT 'country_year_duplicate_keys' AS check_name,
       COUNT(*) - COUNT(DISTINCT country_code || '-' || CAST(year AS VARCHAR)) AS issue_count
FROM country_year
UNION ALL
SELECT 'product_year_duplicate_keys' AS check_name,
       COUNT(*) - COUNT(DISTINCT product_code || '-' || CAST(year AS VARCHAR)) AS issue_count
FROM product_year
UNION ALL
SELECT 'opportunity_duplicate_products' AS check_name,
       COUNT(*) - COUNT(DISTINCT product_code) AS issue_count
FROM opportunities;
