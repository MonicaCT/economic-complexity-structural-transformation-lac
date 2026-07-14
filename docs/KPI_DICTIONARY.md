# KPI Dictionary

This dictionary defines the main analytical indicators used in the repository and portfolio explorer.

| KPI | Definition | Source | Interpretation | Caveat |
|---|---|---|---|---|
| RCA | Product export share in a country divided by product export share in the world. | Methodology and analytical pipeline outputs. | Identifies products in which a country has revealed comparative advantage. | RCA is a revealed trade measure, not a direct measure of productivity. |
| Diversity | Count of products exported with RCA at the project threshold. | `country_year_indicators.csv` | Breadth of productive/export capabilities. | Sensitive to threshold and product classification. |
| Diversity 0.75 | Alternative diversity count at RCA 0.75. | `country_year_indicators.csv` | Broader capability proxy using a lower threshold. | Should not be mixed with baseline diversity without labeling. |
| HHI | Sum of squared product export shares. | `country_year_indicators.csv` | Export concentration. Higher values indicate more concentration. | Product aggregation affects index values. |
| Entropy | Export-basket dispersion measure. | `country_year_indicators.csv` | Alternative diversification measure. | Interpretation differs from HHI scale. |
| Primary share | Share of exports in primary-product groupings. | `country_year_indicators.csv` | Resource and primary-product orientation. | Depends on HS section grouping. |
| Manufacturing share | Share of exports in manufacturing groupings. | `country_year_indicators.csv` | Manufacturing orientation. | Depends on HS section grouping. |
| ECI | Economic Complexity Index standardized within each year. | `country_year_indicators.csv` | Relative annual country complexity position. | Year-to-year changes are relative position changes, not absolute capability units. |
| PCI | Product Complexity Index candidate value. | `product_year_indicators.csv` | Product complexity score. | Final dashboards use `pci_final` where available. |
| PCI final | Final product complexity score used in opportunity screening. | `product_year_indicators.csv`, `bolivia_opportunities_revised.csv` | Product complexity after project-specific harmonization. | Should be read with ubiquity and density. |
| Ubiquity | Count of countries exporting a product with RCA threshold. | `product_year_indicators.csv` | Commonness of a product in global export baskets. | High ubiquity may indicate lower complexity or broad accessibility. |
| Density | Product Space proximity to Bolivia's current capabilities. | `bolivia_opportunities_revised.csv` | Feasibility proxy. Higher density means closer to current capabilities. | A screening metric, not a feasibility study. |
| Distance | Inverse proximity measure. | `bolivia_opportunities_revised.csv` | Difficulty or remoteness proxy. | Must be interpreted with density and sector context. |
| Opportunity gain | Complexity gain proxy from opportunity model. | `bolivia_opportunities_revised.csv` | Potential upgrading value of entering a product. | Not a demand forecast or investment return. |
| Opportunity score | Combined opportunity ranking metric. | `bolivia_opportunities_revised.csv` | Prioritizes candidates for review. | Weights reflect project design and should be transparent. |
| Feasibility score | Normalized feasibility dimension. | `bolivia_opportunities_revised.csv` | Practical closeness to current capabilities. | Not a firm-level feasibility assessment. |
| Transformation score | Normalized transformation dimension. | `bolivia_opportunities_revised.csv` | Upgrading potential. | High transformation can coincide with low feasibility. |
| Relative category | Within-Bolivia opportunity classification. | `bolivia_opportunities_revised.csv` | Recruiter- and policy-facing classification of candidates. | Classification supports discussion, not automatic selection. |
| Proximity | Conditional co-export similarity between products. | `product_space_visual_edges.csv` | Product Space relationship used for network visualization. | Visual edge list is a reduced subset. |
