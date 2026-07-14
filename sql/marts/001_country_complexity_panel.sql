-- Country complexity mart from existing final outputs.
-- Intended for DuckDB execution by future users; not executed in this phase.

CREATE OR REPLACE VIEW mart_country_complexity_panel AS
SELECT
    country_code,
    year,
    region,
    export_value,
    import_value,
    diversity,
    diversity_075,
    hhi,
    entropy,
    primary_share,
    manufacturing_share,
    eci,
    diversity_complexity,
    RANK() OVER (PARTITION BY year ORDER BY eci DESC) AS eci_rank
FROM read_csv_auto('outputs/tables/csv/country_year_indicators.csv', header = true);
