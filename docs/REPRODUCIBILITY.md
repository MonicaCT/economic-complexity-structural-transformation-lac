# Reproducibility

## Levels

- Level 1, public inspection: read scripts, docs, samples, paper, figures, and CSV summaries without raw data.
- Level 2, processed-cache rerun: rerun validation, figure, dashboard, paper, sample, and final-check scripts from processed outputs.
- Level 3, full rebuild: provide local source paths in `config/paths.local.yml` and run `R/99_run_all.R`.

## Local Paths

Personal absolute source paths must appear only in `config/paths.local.yml`. This file is ignored by Git. Public files should use placeholders or relative paths.

## Randomness

The Phase 2 figure scripts use seed `20260711` for network layout reproducibility.

## Expected Ignored Files

- `data/raw/`
- `data/interim/*.rds` and `data/interim/*.parquet`
- `data/processed/*.rds` and `data/processed/*.parquet`
- `outputs/models/*.rds`
- `paper/*.pdf`
- `config/paths.local.yml`

## Main Commands

```powershell
Rscript scripts/validate_project.R
Rscript scripts/phase2_stage2_validation.R
Rscript scripts/phase2_stage3_models_figures.R
Rscript scripts/phase2_stage4_dashboard_paper_docs.R
Rscript scripts/phase2_stage5_samples_tests_cleanup.R
```
