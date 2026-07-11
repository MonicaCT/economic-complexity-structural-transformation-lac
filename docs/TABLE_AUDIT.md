# Table Audit

Phase 3 reviewed tables used directly or indirectly by the paper. Main text tables are limited to conceptual definitions and key result summaries; detailed validation and model tables remain in outputs or appendix references.

| Table | Location | Use | Audit result |
|---|---|---|---|
| Conceptual definitions | `paper/tables/conceptual_definitions.csv` and `.md` | Main conceptual clarity | PASS: definitions, role and caveats included. |
| Bolivia 2023 validation | `outputs/tables/csv/bolivia_2023_indicator_validation.csv` | Numerical consistency | PASS: values match reported ECI, diversity, HHI and primary share. |
| Econometric model summary | `outputs/tables/csv/econometric_model_summary.csv` | Model discussion | PASS: includes estimates, standard errors, p-values, N, R2 and within R2. Text explains fixed effects and clustered SE. |
| Opportunity table | `outputs/tables/csv/bolivia_opportunities_revised.csv` | Opportunity section and dashboard | PASS: includes absolute and relative categories, scores and eligibility. Notes warn against prescriptions. |
| Figure audit | `outputs/tables/csv/figure_audit.csv` | Figure readiness | PASS: 11/11 figure records pass existence and size checks. |

Recommendation: keep detailed rankings and model outputs outside the main text and cite them as reproducible outputs.
