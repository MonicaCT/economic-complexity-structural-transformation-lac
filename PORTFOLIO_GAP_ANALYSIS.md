# Productos existentes

- Repositorio publicado, limpio y versionado en `main`, con `README.md`, `CITATION.cff`, `LICENSE`, `CHANGELOG.md`, documentación de contribución y metadatos Zenodo.
- Paper completo disponible en `paper/main.pdf`, `paper/main.html`, `paper/main.qmd`, `paper/executive_summary.md`, `paper/key_findings.md`, `paper/policy_brief.html` y anexos.
- Pipeline R modular ya construido en `R/00_utils.R` a `R/17_export_results.R`, además de `R/98_run_demo.R` y `R/99_run_all.R`.
- Dashboard Shiny existente en `dashboard/app.R`, con pestañas de Executive Overview, Country Explorer, Product Explorer, Product Space, Bolivia Opportunity Lab, Econometric Evidence y Data and Methods.
- Resultados analíticos versionados en `outputs/tables/csv/`, incluyendo indicadores país-año, producto-año, oportunidades de Bolivia, validaciones ECI/PCI/RCA, diagnósticos Product Space, modelos econométricos y checks finales.
- Figuras analíticas versionadas en `outputs/figures/png/` y `outputs/figures/pdf/`, incluyendo tendencias ECI, complejidad-ingreso, diversidad/concentración, composición exportadora LAC, dashboard estructural de Bolivia, Product Space, densidad-PCI, matriz de oportunidades, top oportunidades y coeficientes de modelos.
- Product Space ya generado en `outputs/networks/`, con edges analíticos, visuales y top 50,000.
- Activos visuales existentes en `docs/assets/`, incluyendo `dashboard_preview.png`, `repository_banner.png` y `repository_banner.svg`.
- Capturas y verificaciones visuales existentes en `outputs/reports/visual/`, incluyendo dashboard ejecutivo, país, producto, Product Space, econometría, métodos y vistas móviles.
- Documentación técnica completa en `docs/`, incluyendo metodología, diccionario de datos, reproducibilidad, estrategia empírica, auditorías de figuras/tablas/modelos/referencias, validaciones ECI/PCI/Product Space y notas de release.
- Datos públicos de muestra en `data/sample/`, incluyendo muestras de comercio, país-año y oportunidades de Bolivia.

# Productos faltantes

- `assets/dashboard-screenshots/` no existe como carpeta estándar de capturas visibles para README orientado a reclutadores.
- `sql/` no existe; faltan vistas SQL ejecutivas para KPIs, oportunidades, rankings, Product Space y resultados econométricos ya calculados.
- `powerbi/` no existe; falta documentación Power BI o BI-ready que traduzca los outputs existentes a modelo de datos, medidas y especificación de dashboard.
- `docs/VALIDATION_REPORT.md` no existe como reporte final unificado en Markdown para esta nueva fase de presentación profesional, aunque sí hay múltiples reportes previos en `outputs/reports/`.
- `docs/executive_tables.md` no existe; faltan tablas ejecutivas consolidadas para Data Analyst, aunque sus insumos ya existen en `outputs/tables/csv/`.
- El README ya es sólido académicamente, pero la primera pantalla puede orientarse más a reclutadores con captura principal, KPIs, botones ejecutivos, hallazgos y stack analítico visibles sin desplazar demasiado.
- El dashboard existe y funciona como producto analítico, pero puede requerir una presentación pública más ejecutiva si se decide replicar el estándar aplicado a `InclusiveCreditRiskAnalytics-Bolivia`.
- No se observa una carpeta raíz `assets/`; los activos están en `docs/assets/` y `outputs/reports/visual/`, por lo que falta una convención visual simple para README.

# Productos reutilizables

- Reutilizar `docs/assets/dashboard_preview.png` como primera imagen candidata de portada o README.
- Reutilizar capturas existentes de `outputs/reports/visual/`, especialmente `dashboard_executive_overview.png`, `dashboard_opportunity_lab.png`, `dashboard_product_space.png`, `dashboard_econometric.png`, `dashboard_methods.png` y capturas por país/producto.
- Reutilizar las figuras principales de `outputs/figures/png/`: `01_eci_latin_america_trends.png`, `02_complexity_income.png`, `03_diversity_concentration.png`, `04_lac_export_composition.png`, `05_bolivia_structural_dashboard.png`, `06_bolivia_product_space.png`, `07_bolivia_density_pci.png`, `08_bolivia_opportunity_matrix.png`, `09_bolivia_top_opportunities.png` y `10_model_coefficients.png`.
- Reutilizar las tablas de `outputs/tables/csv/`, especialmente `country_year_indicators.csv`, `product_year_indicators.csv`, `bolivia_opportunities_revised.csv`, `bolivia_top40_economic_review.csv`, `bolivia_strategic_bets_human_review.csv`, `econometric_model_summary.csv`, `eci_validation_summary.csv`, `pci_validation_summary.csv`, `rca_validation_sample.csv` y `product_space_network_diagnostics.csv`.
- Reutilizar `outputs/networks/product_space_visual_edges.csv` y `outputs/networks/product_space_edges.csv` para documentación visual o SQL/BI-ready sin regenerar Product Space.
- Reutilizar `paper/executive_summary.md`, `paper/key_findings.md`, `paper/policy_brief.html` y `paper/main.pdf` para texto ejecutivo y enlaces.
- Reutilizar `docs/METHODOLOGY.md`, `docs/DATA_DICTIONARY.md`, `docs/REPRODUCIBILITY.md`, `docs/EMPIRICAL_STRATEGY.md`, `docs/BOLIVIA_OPPORTUNITY_AUDIT.md`, `docs/PRODUCT_SPACE_VALIDATION.md` y `docs/ECONOMETRIC_MODEL_AUDIT.md` como respaldo técnico.
- Reutilizar `outputs/reports/FINAL_REPOSITORY_CHECK.md`, `outputs/reports/NUMERICAL_CONSISTENCY_CHECK.md`, `outputs/reports/LINK_CHECK.md`, `outputs/reports/PRIVACY_AND_SECURITY_CHECK.md` y `outputs/reports/DASHBOARD_TEST_REPORT.md` como base para un reporte de validación final, sin reejecutar pipeline.

# Productos que no deben tocarse

- No tocar datos crudos, datos procesados locales ni datos de muestra salvo revisión explícita posterior.
- No tocar ni recalcular RCA, ECI, PCI, Product Space, densidad, oportunidades de Bolivia, rankings, modelos econométricos, robustez ni validaciones científicas.
- No modificar `outputs/tables/csv/` salvo que exista un error específico autorizado.
- No modificar `outputs/figures/png/`, `outputs/figures/pdf/` ni `outputs/networks/`.
- No modificar `paper/main.qmd`, `paper/main.pdf`, `paper/main.html`, referencias, metodología, interpretación científica ni conclusiones.
- No ejecutar `R/99_run_all.R`, no reconstruir la base, no descargar BACI/CEPII/HS92 u otras fuentes y no regenerar resultados existentes.
- No crear releases, tags, DOI, Zenodo metadata nueva ni cambios administrativos de publicación en esta fase.
- No renombrar el repositorio ni cambiar la identidad científica del proyecto.

# Estimación de trabajo restante

- Trabajo mínimo recomendado: 3 a 5 horas.
- Crear o copiar capturas estándar desde activos existentes: 30 a 45 minutos.
- Reorganizar primera pantalla del README con enfoque Data Analyst: 60 a 90 minutos.
- Crear `docs/executive_tables.md` reutilizando outputs existentes: 45 a 60 minutos.
- Crear `sql/executive_views.sql` con vistas sobre CSV ya versionados: 45 a 75 minutos.
- Crear documentación `powerbi/` sin `.pbix`: 45 a 60 minutos.
- Crear `docs/VALIDATION_REPORT.md` basado en reportes existentes y checks ligeros: 30 a 45 minutos.
- Validar enlaces, privacidad, render README y estado Git sin pipeline completo: 30 a 45 minutos.
