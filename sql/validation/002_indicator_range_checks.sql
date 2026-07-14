-- Indicator range checks for final public outputs.
-- Intended for future DuckDB checks; not executed in this phase.

WITH country_year AS (
    SELECT *
    FROM read_csv_auto('outputs/tables/csv/country_year_indicators.csv', header = true)
),
opportunities AS (
    SELECT *
    FROM read_csv_auto('outputs/tables/csv/bolivia_opportunities_revised.csv', header = true)
)
SELECT 'hhi_out_of_range' AS check_name, COUNT(*) AS issue_count
FROM country_year
WHERE hhi < 0 OR hhi > 1
UNION ALL
SELECT 'primary_share_out_of_range' AS check_name, COUNT(*) AS issue_count
FROM country_year
WHERE primary_share < 0 OR primary_share > 1
UNION ALL
SELECT 'manufacturing_share_out_of_range' AS check_name, COUNT(*) AS issue_count
FROM country_year
WHERE manufacturing_share < 0 OR manufacturing_share > 1
UNION ALL
SELECT 'density_out_of_range' AS check_name, COUNT(*) AS issue_count
FROM opportunities
WHERE density < 0 OR density > 1
UNION ALL
SELECT 'feasibility_score_out_of_range' AS check_name, COUNT(*) AS issue_count
FROM opportunities
WHERE feasibility_score < 0 OR feasibility_score > 1
UNION ALL
SELECT 'transformation_score_out_of_range' AS check_name, COUNT(*) AS issue_count
FROM opportunities
WHERE transformation_score < 0 OR transformation_score > 1;
