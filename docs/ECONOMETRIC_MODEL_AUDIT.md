# Econometric Model Audit

All models are observational fixed-effects regressions over Latin America and the Caribbean. Standard errors are clustered by country. These specifications describe conditional associations and are not causal estimates.

- Model sample rows: 783; countries: 27; years: 1995-2023.
- Income-level model observations: 723.
- Five-year-ahead growth model observations: 588.
- Growth-volatility model observations: 672.

Main safeguards:

- Country and year fixed effects absorb time-invariant country heterogeneity and common annual shocks.
- The five-year growth outcome is forward-looking and drops observations without adequate future GDP coverage.
- Coefficients should be read with the validation tables and missingness report, not as policy treatment effects.

Machine-readable outputs: `outputs/tables/csv/econometric_model_summary.csv`, `outputs/tables/csv/model_missingness.csv`, and `outputs/tables/csv/model_sample_composition.csv`.
