# Economic Complexity and Structural Transformation in Latin America - v1.0.0

## Overview

Version 1.0.0 is the first stable academic release of a reproducible research repository on economic complexity, structural transformation and diversification opportunities in Latin America, with a detailed Product Space application for Bolivia. The release packages the public code, sample data, validation reports, working paper, policy brief, figures, dashboard source and citation metadata needed to inspect the project without distributing the large local source data.

## Main analytical components

- country-product-year panel;
- revealed comparative advantage (RCA);
- diversity and ubiquity;
- HHI and entropy;
- ECI and PCI;
- Product Space;
- macroeconomic analysis;
- Bolivia opportunity analysis;
- Shiny dashboard;
- paper and policy brief;
- reproducibility checks and tests.

## Data coverage

- 6,497,429 country-product-year observations
- 242 countries
- 1,243 HS92 four-digit products
- 1995-2023

## Bolivia module

Bolivia 2023 summary indicators:

- ECI 2023: -1.236
- Diversity: 82 products with RCA >= 1
- HHI: 0.124
- Primary-product export share: 62.7%

The product rankings are screening instruments for further sectoral research. They should not be interpreted as automatic investment recommendations or direct policy priorities without additional evidence on feasibility, regulation, firms, infrastructure, environment and market access.

## Reproducibility

- public demo based on included sample data;
- public samples for inspection and lightweight validation;
- 7/7 tests passing at release preparation;
- raw data excluded from GitHub because of size;
- local configuration separated through ignored local path files.

## Known limitations

- external references remain pending full bibliographic verification;
- public dashboard does not include a geospatial map because no public geospatial output is included;
- HS92 product 8516 has a truncated source label and should be checked against official nomenclature before sectoral interpretation;
- HS92 product 9303 belongs to a regulated category and should not be promoted as a priority productive-policy opportunity;
- econometric results are observational associations, not causal estimates;
- full reconstruction depends on large local source data that are not distributed in the repository.

## Citation

Please cite this release using `CITATION.cff`. No DOI is included in v1.0.0 because Zenodo deposition is pending.