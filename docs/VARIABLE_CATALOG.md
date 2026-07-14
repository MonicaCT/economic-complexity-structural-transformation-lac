# Variable Catalog

This catalog documents variables exposed by the existing final analytical outputs used for the portfolio website and SQL layer. It does not define new indicators and does not recalculate results.

## Country-year indicators

Source file: `outputs/tables/csv/country_year_indicators.csv`

| Variable | Type | Unit | Analytical meaning | Quality status |
|---|---|---|---|---|
| `country_code` | string | ISO-like code | Country identifier used in final country-year panel. | Confirmed |
| `year` | integer | calendar year | Analytical year, 1995-2023. | Confirmed |
| `region` | string | category | Region label used for filtering and comparison. | Confirmed |
| `export_value` | numeric | trade value | Total export value in the processed panel. | Confirmed |
| `import_value` | numeric | trade value | Total import value in the processed panel. | Confirmed |
| `diversity` | numeric | product count | Count of products with RCA at the project threshold. | Confirmed |
| `diversity_075` | numeric | product count | Alternative diversity count at RCA 0.75. | Confirmed |
| `hhi` | numeric | index | Export concentration measured as Herfindahl-Hirschman index. | Confirmed |
| `entropy` | numeric | index | Export-basket dispersion measure. | Confirmed |
| `primary_share` | numeric | share | Share of exports in primary-product groupings. | Confirmed |
| `manufacturing_share` | numeric | share | Share of exports in manufacturing groupings. | Confirmed |
| `eci` | numeric | standardized index | Economic Complexity Index, standardized within year. | Confirmed |
| `diversity_complexity` | numeric | composite or supporting index | Existing final output used for complexity-diversity comparison. | Confirmed |

## Product-year indicators

Source file: `outputs/tables/csv/product_year_indicators.csv`

| Variable | Type | Unit | Analytical meaning | Quality status |
|---|---|---|---|---|
| `product_code` | string | HS92 code | Four-digit product identifier. | Confirmed |
| `year` | integer | calendar year | Analytical year. | Confirmed |
| `product_section` | string | HS section | Product section used for sector navigation. | Confirmed |
| `product_chapter` | string | HS chapter | Product chapter grouping. | Confirmed |
| `world_export_value` | numeric | trade value | World export value by product-year. | Confirmed |
| `ubiquity` | numeric | country count | Number of countries exporting the product with RCA threshold. | Confirmed |
| `source_pci` | numeric | index | Source PCI before final selection or harmonization. | Confirmed |
| `pci` | numeric | standardized index | Product Complexity Index candidate value. | Confirmed |
| `ubiquity_complexity` | numeric | supporting index | Product-side complexity proxy in existing outputs. | Confirmed |
| `pci_final` | numeric | standardized index | Final PCI value used in opportunity screens. | Confirmed |

## Bolivia opportunity screen

Source file: `outputs/tables/csv/bolivia_opportunities_revised.csv`

| Variable | Type | Unit | Analytical meaning | Quality status |
|---|---|---|---|---|
| `product_code` | string | HS92 code | Candidate product identifier. | Confirmed |
| `product_section` | string | HS section | Sector for filtering and reporting. | Confirmed |
| `product_chapter` | string | HS chapter | Product chapter grouping. | Confirmed |
| `world_export_value` | numeric | trade value | World market size proxy. | Confirmed |
| `pci_final` | numeric | standardized index | Final product complexity score. | Confirmed |
| `ubiquity` | numeric | country count | Product ubiquity. | Confirmed |
| `product_name` | string | label | Full product label. | Confirmed |
| `product_name_short` | string | label | Short product label for tables and dashboards. | Confirmed |
| `natural_resource` | boolean/category | flag | Natural-resource classification used in screening. | Confirmed |
| `demand_growth` | numeric | growth proxy | Demand-growth measure from existing output. | Confirmed |
| `density` | numeric | score | Product Space proximity to Bolivia's current capabilities. | Confirmed |
| `opportunity_gain` | numeric | score | Complexity gain proxy from the opportunity model. | Confirmed |
| `world_market_size` | numeric | score/value | Market-size variable used in opportunity scoring. | Confirmed |
| `opportunity_score` | numeric | score | Existing combined opportunity score. | Confirmed |
| `distance` | numeric | score | Inverse proximity measure. | Confirmed |
| `opportunity_type` | string | category | Opportunity category from existing screening. | Confirmed |
| `eligible` | boolean/category | flag | Inclusion flag for candidate screening. | Confirmed |
| `feasibility_score` | numeric | 0-1 score | Existing feasibility score. | Confirmed |
| `transformation_score` | numeric | 0-1 score | Existing transformation score. | Confirmed |
| `absolute_classification` | string | category | Classification using absolute thresholds. | Confirmed |
| `relative_category` | string | category | Classification within Bolivia's eligible universe. | Confirmed |

## Product Space network

Source file: `outputs/networks/product_space_visual_edges.csv`

| Variable | Type | Unit | Analytical meaning | Quality status |
|---|---|---|---|---|
| `from` | string | HS92 code | Source product node in visual edge list. | Confirmed |
| `to` | string | HS92 code | Target product node in visual edge list. | Confirmed |
| `proximity` | numeric | 0-1 score | Conditional co-export proximity used for visual subset. | Confirmed |

## Data-quality and validation outputs

Sources: `outputs/tables/csv/data_integrity_summary.csv`, `outputs/tables/csv/eci_validation_summary.csv`, `outputs/tables/csv/pci_validation_summary.csv`, `outputs/tables/csv/product_space_network_diagnostics.csv`

| Variable | Type | Unit | Analytical meaning | Quality status |
|---|---|---|---|---|
| `metric` | string | label | Validation or diagnostic metric. | Confirmed |
| `value` | string/numeric | mixed | Metric value as written in final validation output. | Confirmed |
| `countries` | numeric | count | Country count by validation year. | Confirmed |
| `products` | numeric | count | Product count by validation year. | Confirmed |
| `mean_eci`, `sd_eci`, `min_eci`, `max_eci` | numeric | standardized index | Annual ECI validation statistics. | Confirmed |
| `mean_pci`, `sd_pci`, `min_pci`, `max_pci` | numeric | standardized index | Annual PCI validation statistics. | Confirmed |
| `infinite` | numeric | count | Invalid infinite indicator values. | Confirmed |
| `zero_diversity`, `zero_ubiquity` | numeric | count | Edge-case validation counts. | Confirmed |
