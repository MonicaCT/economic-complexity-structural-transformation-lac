# Stakeholder Requirements

## Stakeholder groups

| Stakeholder | Primary need | Repository response |
|---|---|---|
| Recruiters | Quickly understand technical and analytical capability. | README snapshot, recruiter guide, static website and interactive explorer. |
| Development analysts | Identify country and product patterns relevant to diversification. | Country indicators, Product Space diagnostics and Bolivia opportunity screen. |
| Policy teams | Translate complex metrics into cautious, decision-relevant categories. | Policy brief, executive summary, limitations and opportunity classifications. |
| Researchers | Inspect methods, validation and reproducibility. | Methodology, validation outputs, data model and SQL contracts. |
| Portfolio reviewers | Navigate across project, portal and supporting artifacts. | Public website links, repository links and citation metadata. |

## Functional requirements

| Requirement | Status | Evidence |
|---|---|---|
| Present executive summary | Implemented | `docs/EXECUTIVE_SUMMARY.md` |
| Document KPIs | Implemented | `docs/KPI_DICTIONARY.md` |
| Document variables | Implemented | `docs/VARIABLE_CATALOG.md` |
| Document data quality | Implemented | `docs/DATA_QUALITY_REPORT.md` |
| Provide recruiter guide | Implemented | `docs/RECRUITER_GUIDE.md` |
| Provide data model | Implemented | `docs/DATA_MODEL.md` |
| Provide SQL contracts | Implemented | `sql/ddl`, `sql/marts`, `sql/validation` |
| Provide interactive exploration | Implemented | `docs/explore/index.html` |
| Provide paper and policy links | Implemented | Existing `paper/` outputs |

## Non-functional requirements

| Requirement | Standard |
|---|---|
| Privacy | No local paths, credentials or private microdata in public documentation. |
| Reproducibility | Links point to existing final outputs and documented methodology. |
| Maintainability | Static explorer uses relative paths and lightweight JavaScript. |
| Accessibility | Public pages use semantic sections, readable contrast and keyboard-friendly controls. |
| Scientific caution | Limitations and non-causal interpretation are explicit. |
| Portfolio consistency | Documentation follows the shared flagship standard used across the portfolio. |

## Out of scope for this phase

- Rebuilding RCA, ECI, PCI or Product Space.
- Re-estimating econometric models.
- Modifying figures, tables, paper, policy brief or raw data.
- Creating Power BI or Tableau artifacts.
- Changing GitHub Pages settings.
