-- Dimension contracts for the economic-complexity analytics model.
-- These statements are documentation-ready DuckDB SQL and are not executed in this phase.

CREATE TABLE IF NOT EXISTS dim_country (
    country_code VARCHAR PRIMARY KEY,
    region VARCHAR
);

CREATE TABLE IF NOT EXISTS dim_year (
    year INTEGER PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS dim_product (
    product_code VARCHAR PRIMARY KEY,
    product_section VARCHAR,
    product_chapter VARCHAR,
    product_name VARCHAR,
    product_name_short VARCHAR
);

CREATE TABLE IF NOT EXISTS dim_product_section (
    product_section VARCHAR PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS dim_opportunity_category (
    relative_category VARCHAR PRIMARY KEY,
    category_description VARCHAR
);

CREATE TABLE IF NOT EXISTS dim_validation_metric (
    metric VARCHAR PRIMARY KEY,
    metric_group VARCHAR,
    interpretation VARCHAR
);
