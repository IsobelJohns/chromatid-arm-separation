# Demo

A worked example for the Chromatid Arm Separation macro.

## Files
- `IJ_exp28_CTCFYxF_Rep2_A7-1_Example1_2.tif` — one chromosome spread
  (632 × 632, 16-bit). The chromatids are displayed dark-on-light via an
  inverting LUT; the macro reads the raw pixel values, so this works exactly as
  a bright-on-dark image would.
- `expected_output.csv` — the per-arm result expected from measuring the three
  longest chromosomes (6 arms).
- `example_intensity_profile.png` — one arm's intensity profile, as shown by
  `Ctrl/Cmd+K` in ImageJ (the two peaks are the two sister chromatids).

## How to run
1. Install the macro (`Plugins ▸ Macros ▸ Install… ▸ ChromatidArmSeparation.ijm`).
2. Open the demo image.
3. With the straight-line tool, draw a line across **both sister chromatids** at
   an arm, then press **`t`**. Repeat for the three longest chromosomes, both
   arms each (6 lines).
4. Press **`S`** once to process, then **`E`** once to export.

## Expected output
Six arms, all fitted by the `gaussian` method with R² > 0.97 and a separation of
~10–13 px (mean ± SD ≈ 11.07 ± 0.90 px in the reference run). Because the lines
are hand-drawn, your values will be close to — not identical to —
`expected_output.csv`. Processing the image takes under 1 second.
