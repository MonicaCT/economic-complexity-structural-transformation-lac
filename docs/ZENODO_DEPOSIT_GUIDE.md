# Zenodo Deposit Guide

This guide prepares the manual Zenodo step for release `v1.0.0`. It does not claim that Zenodo is already connected and does not invent a DOI.

## Manual steps

1. Sign in to Zenodo with the account that should own the record.
2. Link the Zenodo account to GitHub from Zenodo's GitHub integration settings.
3. Activate the repository `MonicaCT/economic-complexity-structural-transformation-lac` in Zenodo.
4. Check that Zenodo detects the GitHub release `v1.0.0`.
5. Wait for Zenodo to generate the deposition record from the release archive.
6. Verify the imported metadata before publishing the record.
7. Copy the DOI specific to version `v1.0.0` after Zenodo assigns it.
8. Copy the Concept DOI if Zenodo provides one for all versions of the record.
9. Add the version DOI to `CITATION.cff` in a later metadata commit.
10. Add the DOI badge to `README.md` after the DOI is known.
11. Create and push a separate post-release metadata commit documenting the DOI.

## Checks before accepting the Zenodo record

- Title matches the repository title.
- Creator is listed as Monica Cueto Tapia.
- Version is `1.0.0`.
- Publication date matches the GitHub release date.
- License matches the repository license.
- Related identifier points to the GitHub repository.
- No affiliation, ORCID or DOI is added unless explicitly verified.

## Current status

Zenodo linkage is pending manual authentication and authorization by the repository owner.