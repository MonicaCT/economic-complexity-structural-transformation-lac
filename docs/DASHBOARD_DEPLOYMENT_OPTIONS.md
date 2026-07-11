# Dashboard Deployment Options

No dashboard deployment is performed in v1.0.0. This document compares options for a later public deployment.

## shinyapps.io

- Cost: good entry-level option if usage is modest; paid tiers may be needed for sustained traffic.
- Ease: easiest path for an R/Shiny app.
- Limits: constrained by account quotas, memory and usage hours.
- Data size: suitable only if the app uses the included public outputs or a reduced public bundle.
- Privacy: avoid uploading raw local data or private paths.
- Maintenance: moderate; update by redeploying the app.
- Reproducibility: good for demonstration, but the repository remains the canonical reproducibility source.

## Posit Connect

- Cost: usually institutional or paid infrastructure.
- Ease: strong if an institution already provides it.
- Limits: depends on server configuration and administrator policy.
- Data size: can handle more controlled deployments if resources are configured.
- Privacy: strongest option when hosted inside a trusted institutional environment.
- Maintenance: requires server administration or institutional support.
- Reproducibility: strong when combined with pinned dependencies and documented deployment settings.

## Local execution

- Cost: no hosting cost.
- Ease: suitable for reviewers and collaborators with R installed.
- Limits: depends on the user's machine and installed packages.
- Data size: safest for large local data because raw files remain outside GitHub.
- Privacy: best for private/local data.
- Maintenance: minimal hosting maintenance; users run the app from the repository.
- Reproducibility: strongest for archival transparency when paired with sample data and documented dependencies.

## GitHub Codespaces

- Cost: may incur usage charges after free quotas.
- Ease: useful technical option for reproducible cloud execution.
- Limits: resource and session limits may affect Shiny performance.
- Data size: not appropriate for the full raw-data environment.
- Privacy: only public/reduced data should be used.
- Maintenance: requires devcontainer or environment setup in a later phase.
- Reproducibility: potentially strong, but not implemented in v1.0.0.

## Container

- Cost: depends on hosting provider and compute needs.
- Ease: more setup work than shinyapps.io or local execution.
- Limits: flexible, but requires image maintenance and deployment infrastructure.
- Data size: can be designed for reduced public outputs; full raw data should stay local/private.
- Privacy: depends on registry, secrets and runtime configuration.
- Maintenance: higher; image rebuilds and security updates are needed.
- Reproducibility: strong future option if dependencies need tighter pinning.

## Recommendation

For the next phase, keep local execution as the authoritative reproducibility path and consider shinyapps.io for a public lightweight demonstration using only the public outputs already included in the repository. Posit Connect is preferable if an institutional server is available. Codespaces and containers should remain future technical options, not v1.0.0 tasks.