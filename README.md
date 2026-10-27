# Chromatid Arm Separation

An ImageJ/Fiji macro for quantifying the separation between sister-chromatid
arms on metaphase chromosome spreads.

For each line the user draws perpendicular to a chromosome arm, the macro reads
the fluorescence intensity profile and fits **two Gaussians of a fixed,
data-estimated width** to it. The distance between the two fitted Gaussian
centres is reported as the arm separation (`PeakToPeak`), in pixels. The macro
is keyboard-driven, uses the ImageJ ROI Manager, and exports both a per-arm
table and a one-row-per-image summary table.

---

## Why fit, rather than read off the two peaks

When two sister chromatids are close, their blurred intensity profiles overlap
and the two visible peaks are pulled inward, so the separation is
underestimated by simple peak-picking. When they are very close they merge into
a single visible hump with no two peaks to pick at all. Fitting two Gaussians
whose width (σ) is fixed from the signal's own edge sharpness recovers the two
underlying centres in both cases and keeps the fit numerically stable (a free σ
is degenerate on broad, flat-topped profiles and can diverge). See
`docs/METHODS.md` for the full rationale and limitations.

---

## Requirements

- **Fiji** (https://fiji.sc) or ImageJ ≥ 1.53. Developed and tested on Fiji
  (ImageJ 1.54), macOS. No external plugins are required.
- Single-channel, 8- or 16-bit greyscale images of metaphase spreads.

---

## Installation

The macro defines keyboard shortcuts; installing it activates them for the
current Fiji session.

1. Open Fiji.
2. `Plugins ▸ Macros ▸ Install…`
3. Select `ChromatidArmSeparation.ijm`.
4. The shortcuts (S, E, D, R, U, B; plus Fiji's built-in T) are now active. An
   image window must be the focused window for them to fire.

"Install" lasts for the session. To load it automatically on every start, paste
the macro contents into `Plugins ▸ Macros ▸ Startup Macros…` and save.

---

## Settings (top of the `.ijm` file)

| Variable | Default | Purpose |
|---|---|---|
| `usePixels` | `true` | Report distances in pixels. Set `false` to report in the image's calibrated unit (requires a correct spatial calibration in `Image ▸ Properties`). |
| `armsPerImage` | `6` | Expected measurements per image (3 chromosomes × 2 arms). Drives the on-screen counter only; it is **not** a hard cap. |

---

## Usage

Select the **straight-line** tool, draw a line across one chromatid arm
(perpendicular to its long axis, extending just into dark background on both
sides), then:

| Key | Action |
|---|---|
| `t` | Add the current line to the ROI Manager (ImageJ built-in) |
| `S` | Process all lines on the current image and log the results |
| `E` | Export results to CSV (writes **two** files — see below) |
| `D` | Skip the current image (logs a SKIPPED row, advances the image number) |
| `R` | Clear all lines from the ROI Manager |
| `U` | Undo the most recently logged arm (with confirmation), to redraw and re-measure |
| `B` | Enlarge the Log font (optional) |

Images are numbered 1, 2, 3… in the order they are processed. Processing images
in the same order as an independent blinded phenotype scoring makes
`Image_number` line up between the two datasets for later merging.

---

## Outputs

Pressing `E` writes two files to the chosen folder (auto-numbered `_2`, `_3`…
so nothing is overwritten):

**1. `Chromatid_Separation_Results.csv`** — one row per measured arm:

| Column | Meaning |
|---|---|
| `Image_number` | Sequential image index assigned by the macro |
| `Image_name` | Fiji image identifier (audit trail) |
| `Chromosome`, `Arm` | Auto-assigned labels (Chr1, Chr2…; p-arm / q-arm) |
| `Method` | `gaussian` = fitted; `fit_failed` = fit geometry broken (NaN); `failed` = no signal on the line; `skipped` = image skipped |
| `PeakToPeak_pixels` | Arm separation (distance between the two fitted centres). **Primary readout.** |
| `R_squared` | Goodness of fit (quality filter) |
| `Sep_over_sigma` | Separation ÷ peak width — a resolvability score (≳1.5 clearly resolved; <1 merged, separation inferred from shape) |
| `Envelope_FWHM_pixels` | Total signal width at half-maximum (independent cross-check) |

**2. `Chromatid_Separation_Results_by_image.csv`** — one row per image, with
each arm's distance in its own `Chr#_p` / `Chr#_q` column, plus `N_arms`,
`Mean_distance`, `SD_distance`, `Mean_R2`, and an `Excluded_arms` list.
`Image_name` and `Phenotype` are left blank for merging with blinded scoring on
`Image_number`. Means use the `gaussian` arms only.

> **Opening the CSV:** import with the decimal separator set to "." (in Excel:
> `Data ▸ From Text/CSV`, decimal = "."). In a comma-decimal locale, opening the
> file directly can misread "." as a thousands separator and inflate every
> distance ~1000×. This is an import setting, not a property of the data.

---

## Data selection (important for data quality)

The method assumes each scanned arm is **optically isolated**, with dark
background on both sides of the line. Choose peripheral, well-separated
chromosomes with a clear dark gap flanking the arm; keep lines short; and skip
(`D`) uniformly crowded spreads rather than forcing a measurement.

---

## Versioning

Releases follow [semantic versioning](https://semver.org). Each tagged release
is archived on Zenodo and receives its own version DOI; the concept DOI in
`CITATION.cff` always resolves to the latest version. See `CHANGELOG.md`.

---

## How to cite

Please cite **both** the software (archived release) and the associated
publication. Citation metadata is in `CITATION.cff`; see also the "Code
availability" statement in `docs/CODE_AVAILABILITY.md`.

---

## License

MIT — see `LICENSE`.
