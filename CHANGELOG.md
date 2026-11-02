# Changelog

All notable changes to this project are documented here. This project adheres
to [Semantic Versioning](https://semver.org).

## [1.1.0] — 2026-11-02

Documentation and demonstration update. **The analysis code is unchanged from
1.0.0** — only comments, documentation, and supporting materials changed.

### Added
- A worked example in `demo/`: a chromosome-spread image, its expected per-arm
  output (`expected_output.csv`), and an example intensity profile.
- A diagram of the two-Gaussian fit in `docs/`, referenced from `METHODS.md`.

### Changed
- README restructured under the headings System requirements / Installation
  guide / Demo / Instructions for use, and expanded.
- Clarified that a measurement line is drawn **across both sister chromatids**
  (not one arm), and that the workflow is `t` after each line → `S` once per
  image → `E` once at the end.
- Expanded data-selection guidance: pick an isolated chromosome with clear space
  on both sides, and note that the background must *contrast* with the chromatids
  but need not be dark (an inverting display LUT works).
- Noted optional parallel use with the Blind Analysis Tools plugin for
  cohesion-phenotype scoring.
- Terminology: "metaphase spread" → "chromosome spread" throughout.

## [1.0.0] — 2026-10-27

First public release, archived on Zenodo.

### Method
- Fixed-sigma two-Gaussian fit of a line-scan intensity profile drawn across
  both sister chromatids; the distance between the two fitted centres is
  reported as the arm separation.
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
