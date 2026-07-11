# Methodology

This document summarizes the validated methodology used in the repository. It does not rerun the full pipeline.

## RCA and MCP

Revealed comparative advantage is the product export share in the country divided by the product export share in the world. The binary MCP matrix equals one when RCA >= 1.

## Country-Year Indicators

Diversity counts RCA products. HHI is the sum of squared product export shares. Entropy measures dispersion. Primary and manufacturing shares are computed from HS section groupings.

## ECI and Temporal Comparability

ECI is computed separately for each year from the binary RCA matrix. The second eigenvector is standardized within year and sign-oriented to correlate positively with diversity. Because the series is annually standardized, ECI supports relative within-year comparison and ranking. Longitudinal changes should be described as changes in relative annual position, not as absolute units of productive capabilities gained or lost.

## PCI

PCI is a projected product index created by projecting country ECI through the product side of the RCA matrix and standardizing within year. It is not claimed to be an independent external product-side eigen-decomposition.

## Product Space and Density

Product proximity is based on conditional co-export relationships. The analytical 2023 Product Space contains 701,978 positive edges. The 698-edge visual graph is used for legibility only. Density and Opportunity Gain use the full analytical matrix.

## Opportunity Scores

The absolute classification preserves conservative global thresholds. The relative classification ranks products within Bolivia's eligible universe using percentile-normalized density, projected PCI, Opportunity Gain, market size and demand growth. Scores are screening tools, not investment recommendations.

## Econometric Models

The fixed-effects models are observational. They include country and year fixed effects and country-clustered standard errors. They are used to describe associations, not causal effects.
