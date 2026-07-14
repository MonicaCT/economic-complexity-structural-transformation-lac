# Data Quality Report

This report summarizes existing validation outputs. It does not rerun the pipeline and does not modify the data.

## Data-integrity summary

Source: `outputs/tables/csv/data_integrity_summary.csv`

| Metric | Value | Interpretation |
|---|---:|---|
| Rows | 6,497,429 | Processed country-product-year observations. |
| Countries | 242 | Country coverage in processed panel. |
| Products | 1,243 | HS92 four-digit product coverage. |
| Minimum year | 1995 | First analytical year. |
| Maximum year | 2023 | Last analytical year. |
| Bolivia latest year | 2023 | Latest Bolivia analytical year. |
| Unique keys | 1 | Final key uniqueness check passed. |
| Negative exports | 0 | No negative export values in final validation output. |
| Duplicate keys | 0 | No duplicate country-product-year keys reported. |
| Missing RCA | 0 | No missing RCA values reported. |
| Invalid country codes | 0 | No invalid country codes reported. |
| Invalid product codes | 2,991 | Existing validation warning retained from final output. |
| Zero-export country-year rows | 14 | Existing edge-case count retained from final output. |

## Indicator validation

Sources:

- `outputs/tables/csv/eci_validation_summary.csv`
- `outputs/tables/csv/pci_validation_summary.csv`

The validation files provide annual counts, means, standard deviations, minima, maxima and invalid-value checks for ECI and PCI. These diagnostics support the interpretation that indicators are standardized within year and should be read as relative annual positions.

## Product Space validation

Source: `outputs/tables/csv/product_space_network_diagnostics.csv`

The Product Space diagnostics document the analytical and visual network layers. The repository distinguishes between the full analytical edge set used for density and opportunity calculations and a smaller visual subset used for communication.

## Quality interpretation

| Area | Status | Notes |
|---|---|---|
| Key uniqueness | PASS | No duplicate keys reported in final integrity summary. |
| RCA completeness | PASS | Missing RCA count is zero in the final integrity summary. |
| Negative exports | PASS | Negative export count is zero. |
| ECI diagnostics | PASS | Annual validation summary exists for all analytical years. |
| PCI diagnostics | PASS | Annual validation summary exists for all analytical years. |
| Product Space diagnostics | PASS | Network diagnostic output exists. |
| Product-code validation | WARNING | Final integrity output reports 2,991 invalid product-code observations. This is documented and should be interpreted as a validation warning, not silently ignored. |
| Zero-export rows | WARNING | Final integrity output reports 14 zero-export country-year rows. |

## Privacy and reproducibility

- The public repository exposes processed and aggregated analytical outputs, documentation and presentation files.
- Large raw source folders are not required for the static portfolio website.
- This report contains no local file-system paths, credentials or individual-level data.
- No models, figures, tables or scientific results were regenerated for this documentation layer.
