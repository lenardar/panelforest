## Submission notes

This is version 0.2.0 of `panelforest`.

## Test Environments

- Local macOS (R 4.5)
- `R CMD check --as-cran`

## R CMD check Results

0 errors | 0 warnings | 0 notes (expected)

## Notes

- The package includes two vignettes, both of which build successfully with `pandoc` installed.
- Visual regression tests use `vdiffr`. When `vdiffr` is not installed, the
  visual test is skipped automatically via `_R_CHECK_FORCE_SUGGESTS_=false`.
- An `unable to verify current time` NOTE may appear in offline environments;
  this is not a package issue.
