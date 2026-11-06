# GitHub publication checklist

1. Confirm software authorship and copyright with coauthors. The proposed maintainer is Xu Cao (xuc@ucr.edu).
2. Confirm the paper's exact bibliographic citation and add it to README or CITATION.
3. Check the repository for unpublished data, secrets, personal paths, and unrelated analysis files.
4. Install the exact source archive in a fresh R session and run `devtools::check(document = FALSE)` including vignettes.
5. Push the package contents to a new GitHub repository named `FADS`.
6. Wait for the GitHub Actions `R-CMD-check` workflow to pass; inspect any platform-specific issues.
7. Verify the GitHub repository owner is `xuc-ucr` and the repository is named `FADS`.
8. Tag the version only after verification; no CRAN submission is planned.

Do not commit simulation checkpoint `.rds` files or private research data.

Known release blocker: full vignette-enabled R CMD check previously failed on R 4.2.3 with missing doc/index.html; confirm a clean full check on a current R release before public announcement.
