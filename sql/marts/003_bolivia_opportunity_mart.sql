-- Bolivia opportunity mart from existing final outputs.
-- Intended for DuckDB execution by future users; not executed in this phase.

CREATE OR REPLACE VIEW mart_bolivia_opportunity AS
SELECT
    product_code,
    product_section,
    product_chapter,
    product_name,
    product_name_short,
    world_export_value,
    pci_final,
    ubiquity,
    natural_resource,
    demand_growth,
    density,
    opportunity_gain,
    world_market_size,
    opportunity_score,
    distance,
    opportunity_type,
    positive_years_last6,
    eligible,
    density_pct,
    pci_pct,
    opportunity_gain_pct,
    world_market_pct,
    demand_growth_pct,
    feasibility_score,
    transformation_score,
    absolute_classification,
    relative_category,
    RANK() OVER (ORDER BY opportunity_score DESC) AS opportunity_rank
FROM read_csv_auto('outputs/tables/csv/bolivia_opportunities_revised.csv', header = true);
