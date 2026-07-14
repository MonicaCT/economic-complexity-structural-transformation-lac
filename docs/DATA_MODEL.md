# Data Model

This document defines a professional analytics model for the existing final outputs. It is a design contract for DuckDB/SQL presentation and does not run transformations in this phase.

## Grain

| Entity | Grain |
|---|---|
| `fact_country_year_complexity` | One row per country-year. |
| `fact_product_year_complexity` | One row per product-year. |
| `fact_bolivia_product_opportunity` | One row per Bolivia candidate product. |
| `fact_product_space_edge` | One row per product-product visual edge. |
| `fact_data_quality_metric` | One row per validation metric. |

## Dimensions

| Dimension | Key | Description |
|---|---|---|
| `dim_country` | `country_code` | Country identifiers and region labels inferred from final country-year outputs. |
| `dim_year` | `year` | Analytical calendar years. |
| `dim_product` | `product_code` | HS92 four-digit product labels and sector/chapter metadata. |
| `dim_product_section` | `product_section` | HS section-level grouping used for filters. |
| `dim_opportunity_category` | `relative_category` | Bolivia opportunity-screening categories. |
| `dim_validation_metric` | `metric` | Data-quality and validation metric labels. |

## Fact tables

### `fact_country_year_complexity`

Primary source: `outputs/tables/csv/country_year_indicators.csv`

Measures:

- `export_value`
- `import_value`
- `diversity`
- `diversity_075`
- `hhi`
- `entropy`
- `primary_share`
- `manufacturing_share`
- `eci`
- `diversity_complexity`

### `fact_product_year_complexity`

Primary source: `outputs/tables/csv/product_year_indicators.csv`

Measures:

- `world_export_value`
- `ubiquity`
- `source_pci`
- `pci`
- `ubiquity_complexity`
- `pci_final`

### `fact_bolivia_product_opportunity`

Primary source: `outputs/tables/csv/bolivia_opportunities_revised.csv`

Measures:

- `density`
- `distance`
- `opportunity_gain`
- `world_market_size`
- `demand_growth`
- `opportunity_score`
- `feasibility_score`
- `transformation_score`

### `fact_product_space_edge`

Primary source: `outputs/networks/product_space_visual_edges.csv`

Measures:

- `proximity`

## Suggested SQL flow

1. Load existing CSV outputs as external tables or DuckDB views.
2. Create dimensions from distinct keys in the final outputs.
3. Create marts for country ranking, product ranking, Bolivia opportunity screening and Product Space diagnostics.
4. Run validation SQL to check uniqueness, null keys, value ranges and category coverage.

## Publication rule

Only aggregated or derived public outputs should be exposed in GitHub Pages. Raw source data and local working paths are not part of the public data model.
