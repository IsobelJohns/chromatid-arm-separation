# Chromatid Arm Separation

An ImageJ/Fiji macro for quantifying the separation between sister-chromatid
arms on chromosome spreads.

To take a measurement, the user draws a straight line **across the pair of
sister chromatids** (perpendicular to the chromosome's long axis, at one arm).
The macro reads the fluorescence intensity profile along that line and fits
**two Gaussians of a fixed, data-estimated width** to it — one per chromatid.
The distance between the two fitted Gaussian centres is reported as the arm
separation (`PeakToPeak`), in pixels. The macro is keyboard-driven, uses the
ImageJ ROI Manager, and exports both a per-arm table and a one-row-per-image
summary table.

> **Used alongside phenotype scoring (optional).** This tool measures distance
> only. It can be run in parallel with the **Blind Analysis Tools** Fiji plugin,
> which lets you record a blinded cohesion phenotype for the same spreads; the
> two are independent but complementary, and because both number images in the
> order they are processed, their outputs can be matched afterwards on the image
> number. Using Blind Analysis Tools is not required to measure arm separation.

---

## Why fit, rather than read off the two peaks

When two sister chromatids are close, their blurred intensity profiles overlap
and the two visible peaks are pulled inward, so the separation is
underestimated by simple peak-picking. When they are very close they merge into
a single visible hump with no two peaks to pick at all. Fitting two Gaussians
whose width (σ) is fixed from the signal's own edge sharpness recovers the two
underlying centres in both cases and keeps the fit numerically stable (a free σ
is degenerate on broad, flat-topped profiles and can diverge). See
[`docs/METHODS.md`](docs/METHODS.md) for the full rationale, the equation, and a
diagram of the fit.

---

## 1. System requirements

- **Software:** [Fiji](https://fiji.sc) or ImageJ ≥ 1.53. No external plugins
  are required to run the macro.
- **Versions tested on:** Fiji (ImageJ 1.54), on macOS. The macro uses only
  core ImageJ functions, so it is expected to run on any operating system that
  runs Fiji/ImageJ (Windows, macOS, Linux).
- **Non-standard hardware:** none. Runs on any standard desktop or laptop.
- **Input images:** single-channel, 8- or 16-bit greyscale images of chromosome
  spreads.

## 2. Installation guide

The macro defines keyboard shortcuts; installing it activates them for the
current Fiji session.

1. Open Fiji.
2. `Plugins ▸ Macros ▸ Install…`
3. Select `ChromatidArmSeparation.ijm`.
4. The shortcuts (S, E, D, R, U, B; plus Fiji's built-in T) are now active. An
   image window must be the focused window for them to fire.

To load it automatically on every start, paste the macro contents into
`Plugins ▸ Macros ▸ Startup Macros…` and save.

**Typical install time:** under 1 minute.

### Optional settings (you do not need to change these)

The macro works out of the box with its defaults, so **most users can skip this
section entirely.** There are two optional settings:

| Variable | Default | Change it to… |
|---|---|---|
| `usePixels` | `true` | report distances in the image's calibrated unit instead of pixels (set `false`; requires a correct calibration in `Image ▸ Properties`). |
| `armsPerImage` | `6` | expect a different number of measurements per image (default 6 = 3 chromosomes × 2 arms). This only drives the on-screen counter — you can always measure more or fewer. |

These settings are lines of text near the top of the `.ijm` file itself. When
you install the macro through `Plugins ▸ Macros ▸ Install…` you never see those
lines, so to change a setting you must **edit the file first, then install the
edited file:**

1. **Open `ChromatidArmSeparation.ijm` in an editor.** The simplest way is to
   drag the file onto the Fiji main window — it opens in Fiji's built-in
   **Script Editor**. (Any plain-text editor also works: TextEdit on macOS,
   Notepad on Windows, or a code editor such as VS Code.)
2. **Find the two lines near the top** of the file:
   ```
   var usePixels = true;
   var armsPerImage = 6;
   ```
3. **Change the value** you want — for example `var armsPerImage = 10;` to expect
   five chromosomes per image, or `var usePixels = false;` for calibrated units.
   Keep the `var`, the `=`, and the trailing semicolon exactly as shown.
4. **Save** the file (in the Script Editor: `File ▸ Save`).
5. **Install the edited file:** `Plugins ▸ Macros ▸ Install…` and select it. The
   installed macro now uses your changed values for the rest of the session.

(If you only want to try a changed setting once without installing, you can also
press **Run** in the Script Editor — but the keyboard shortcuts described below
are only active after you **Install**.)

## 3. Demo

A worked example is in [`demo/`](demo/).

- **Input:** [`demo/IJ_exp28_CTCFYxF_Rep2_A7-1_Example1_2.tif`](demo/) — one
  chromosome spread (632 × 632, 16-bit).
- **Instructions to run:** install the macro (step 2), open the demo image, and
  measure the **three longest chromosomes** (both arms of each = 6 arms) exactly
  as in *Instructions for use* below. Press **S** to process, then **E** to
  export.
- **Expected output:** [`demo/expected_output.csv`](demo/) — six arms, each
  fitted by the Gaussian method with R² > 0.97 and a separation of roughly
  10–13 px. For reference, one run gave:

  | Chromosome | Arm | PeakToPeak (px) | R² |
  |---|---|---|---|
  | Chr1 | p | 12.64 | 0.994 |
  | Chr1 | q | 11.01 | 0.984 |
  | Chr2 | p | 10.08 | 0.994 |
  | Chr2 | q | 11.26 | 0.975 |
  | Chr3 | p | 11.11 | 0.993 |
  | Chr3 | q | 10.31 | 0.993 |

  mean ± SD = **11.07 ± 0.90 px**. Because the lines are drawn by hand, your
  values will be close to — but not identical to — these; the point is that they
  fall in the same range with high R². An example of one arm's intensity profile
  is shown in [`demo/example_intensity_profile.png`](demo/).

- **Cross-check against a manual measurement.** On the Chr3 q-arm, the visible
  peak-to-peak distance measured by hand in ImageJ (draw a line between the two
  peaks on the profile plot, `Ctrl/Cmd+M`) was **9.52 px**, versus the macro's
  fitted **10.31 px**. The fit is slightly larger, as expected: overlapping
  Gaussian tails pull the *visible* peaks inward, so the fit recovers the true,
  slightly wider centre-to-centre separation.
- **Expected run time:** pressing **S** processes all six arms of the image in
  under 1 second on a normal desktop.

## 4. Instructions for use (how to run on your own data)

**Choosing what to measure — for consistency:**
- Measure the same set of chromosomes in every spread — e.g. the **three
  longest** chromosomes (the default; raise `armsPerImage` if you want more).
- Measure the **same portion of each arm** every time — e.g. about one-third of
  the way in from the telomere end — so measurements are comparable across
  images.
- Choose chromosomes that are well separated from their neighbours (see *Data
  selection* below).

**Taking the measurements (per image):**
1. Select the **straight-line** tool from the Fiji toolbar.
2. Draw a line **across both sister chromatids** at the arm — perpendicular to
   the arm's long axis, crossing the two chromatid bodies and extending just
   into the background on either side. (Crossing both chromatids is essential:
   it is what produces the two intensity peaks the macro fits.)
3. Press **`t`** to add that line to the ROI Manager. *(This records the line —
   it does not yet measure it.)*
4. Repeat steps 2–3 for every arm you want on this image (default 6 = three
   chromosomes × p- and q-arms; you may capture more).
5. **Only once all arms for the image are recorded**, press **`S`** **once** to
   process them all. The results are added to the table.
6. Open the next image and repeat from step 2.
7. **At the very end, after all images are done, press `E` once** to export.

> **Workflow in short:** `t` after *each* line → `S` *once per image* → `E`
> *once at the very end*. You do **not** press S or E after every single arm.

**Other keys:** `D` skip the current image · `R` clear the current lines ·
`U` undo the last recorded arm (to redraw it) · `B` enlarge the Log font.

### (Optional) Reproduction instructions

The `demo/` example lets you reproduce a representative set of measurements. The
full analysis for the associated manuscript is reproduced by applying this
workflow to the imaging dataset referenced there.

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

The macro works from the **intensity profile**, so each measured arm must have a
clear, even background on **both** sides of the line — that background is what
defines where the chromatid signal begins and ends.

- Choose chromosomes that are well separated from their neighbours, with open
  space flanking the arm. If a chromosome is too crowded to have clear space on
  both sides, **pick a different, more isolated chromosome** rather than forcing
  the measurement.
- Keep the line short — extend it just into the background on each side, no
  further.
- Skip uniformly crowded spreads (`D`) rather than measuring them.

**Contrast, not colour.** The background needs to *contrast* with the
chromatids; it does not need to be dark. The macro reads the raw pixel values,
in which the chromatids are the high-intensity signal, so it works whether the
image is displayed as bright chromatids on a dark background **or** as dark
chromatids on a light background (e.g. an inverting LUT, as in the demo image) —
the display look-up table does not change the underlying measurement.

---

## How to cite

Please cite the archived software release (and the associated publication once
available). Machine-readable metadata, including the Zenodo DOI, is in
[`CITATION.cff`](CITATION.cff) — GitHub's "Cite this repository" button reads it
directly.

## License

MIT — see [`LICENSE`](LICENSE).
