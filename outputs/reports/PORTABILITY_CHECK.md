# Portability Check

Status: PASS

Checks performed:

- Public sample demo script is available at `R/98_run_demo.R`.
- Paper HTML and PDF use relative links.
- README image links point to repository-relative assets.
- Dashboard reads processed output files relative to repository root.
- `config/paths.local.yml` remains the only intended machine-specific path file.

Warning: full rebuild still requires local source data and is intentionally not portable through GitHub.
