# GitHub File Policy

## Include in GitHub

- Source code in `R/`, `scripts/`, `dashboard/` and `tests/`.
- Configuration examples, but not `config/paths.local.yml`.
- Public documentation and audit reports.
- Small CSV outputs, XLSX opportunity workbook, HTML paper and policy brief.
- Final PNG and PDF figures.
- `paper/main.pdf`, because it is small and useful for human review.
- Public sample data in `data/sample/`.

## Exclude from GitHub

- Raw data and original local source folders.
- Large processed caches such as parquet files and large intermediate CSV caches.
- Model RDS files, logs, LaTeX auxiliary files and temporary files.
- Machine-specific paths, credentials or private data.

## Rationale

The repository should be reviewable on GitHub without publishing 168.3 GB of source data. Small final artifacts that help human reviewers are included; large caches and local-only files are excluded.

## Reconstruct Excluded Files

Copy `config/paths.example.yml` to ignored `config/paths.local.yml`, edit local paths, then run `Rscript R/99_run_all.R` for a full rebuild.
