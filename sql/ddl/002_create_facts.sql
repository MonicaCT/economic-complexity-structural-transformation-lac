-- Fact-table contracts for the economic-complexity analytics model.
-- These statements document the target analytical schema and are not executed in this phase.

CREATE TABLE IF NOT EXISTS fact_country_year_complexity (
    country_code VARCHAR,
    year INTEGER,
    export_value DOUBLE,
    import_value DOUBLE,
    diversity DOUBLE,
    diversity_075 DOUBLE,
    hhi DOUBLE,
    entropy DOUBLE,
    primary_share DOUBLE,
    manufacturing_share DOUBLE,
    eci DOUBLE,
    diversity_complexity DOUBLE,
    PRIMARY KEY (country_code, year)
);

CREATE TABLE IF NOT EXISTS fact_product_year_complexity (
    product_code VARCHAR,
    year INTEGER,
    world_export_value DOUBLE,
    ubiquity DOUBLE,
    source_pci DOUBLE,
    pci DOUBLE,
    ubiquity_complexity DOUBLE,
    pci_final DOUBLE,
    PRIMARY KEY (product_code, year)
);

CREATE TABLE IF NOT EXISTS fact_bolivia_product_opportunity (
    product_code VARCHAR PRIMARY KEY,
    world_export_value DOUBLE,
    pci_final DOUBLE,
    ubiquity DOUBLE,
    natural_resource VARCHAR,
    demand_growth DOUBLE,
    density DOUBLE,
    opportunity_gain DOUBLE,
    world_market_size DOUBLE,
    opportunity_score DOUBLE,
    distance DOUBLE,
    opportunity_type VARCHAR,
    eligible VARCHAR,
    feasibility_score DOUBLE,
    transformation_score DOUBLE,
    absolute_classification VARCHAR,
    relative_category VARCHAR
);

CREATE TABLE IF NOT EXISTS fact_product_space_edge (
    from_product_code VARCHAR,
    to_product_code VARCHAR,
    proximity DOUBLE,
    PRIMARY KEY (from_product_code, to_product_code)
);

CREATE TABLE IF NOT EXISTS fact_data_quality_metric (
    metric VARCHAR PRIMARY KEY,
    value VARCHAR
);
