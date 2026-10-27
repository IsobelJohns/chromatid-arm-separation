# Changelog

All notable changes to this project are documented here. This project adheres
to [Semantic Versioning](https://semver.org).

## [1.0.0] — 2026-10-27

First public release, archived on Zenodo. This is the version used for the
analysis in the associated manuscript.

### Method
- Fixed-sigma two-Gaussian fit of a perpendicular line-scan intensity profile;
  the distance between the two fitted centres is reported as the arm separation.
- Peak width (σ) estimated per profile from the 25–75% edge rise and held
  constant during the fit, removing the degeneracy that destabilises a
  free-width two-Gaussian fit on broad, flat-topped profiles.
- Signal window located by walking out from the brightest point to a
  near-background foot threshold, so a deep inter-peak valley between widely
  separated sisters is not mistaken for the signal end.
- Arms whose fit geometry is invalid are flagged `fit_failed` (NaN) for
  remeasurement rather than being replaced by a less reliable estimate.

### Workflow
- Keyboard-driven ROI-Manager workflow: add line (T), process (S), export (E),
  skip image (D), clear ROIs (R), undo last arm (U), enlarge Log font (B).
- Export writes a per-arm table and a one-row-per-image wide summary (per-image
  N, mean, SD, mean R²), with blank `Image_name`/`Phenotype` columns for
  merging with independent blinded phenotype scoring on `Image_number`.

> Development note: this release corresponds to internal working version "v11".
> Earlier internal iterations are not part of the public record.
