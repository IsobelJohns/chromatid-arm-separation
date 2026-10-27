# Method

A concise description of what the macro computes, suitable as a basis for the
manuscript Methods. Prose is deliberately implementation-independent; see the
macro source for exact parameter values.

## Measurement

The operator draws a straight line across a chromosome arm, perpendicular to
its long axis and extending just into background on both sides, and the macro
reads the intensity profile along it (`getProfile`). The profile is lightly
smoothed (moving average, radius 2) only for peak and window detection; all
reported quantities are computed from the raw profile.

## Signal window

The brightest point of the smoothed profile is located and the macro walks
outward in both directions until the trace falls below a foot threshold set at
15% of the background-to-peak range. This trims flat background tails and
excludes elevated edges from neighbouring material, while keeping the threshold
close to true background so that a deep valley between two widely separated
sisters is not mistaken for the end of the signal.

## Two-Gaussian model with fixed width

Each sister chromatid is modelled as a Gaussian. The intensity profile is fit
as the sum of two Gaussians of equal, fixed width on a flat background:

    I(x) = a + A1·exp(−(x−m1)² / 2σ²) + A2·exp(−(x−m2)² / 2σ²)

The width σ is **estimated from the data and then held fixed** during fitting:
it is derived from the 25–75% rise distance on the outer edges of the signal
(for a Gaussian, the 25–75% span equals 0.907·σ), bounded to a physically
sensible range. Only the background, the two amplitudes and the two centres are
free parameters. Fixing σ removes the parameter degeneracy that makes an
unconstrained two-Gaussian fit unstable on broad, flat-topped profiles (where a
free fit can trade width against separation and diverge). The reported arm
separation is the distance between the fitted centres, |m2 − m1|, converted to
the chosen unit.

Fixing a single shared σ assumes the two sisters have the same apparent width,
which is reasonable as they are the same physical structure imaged under the
same optics.

## Why fitting, not peak-picking

Overlapping Gaussian tails pull the *visible* maxima of two nearby peaks
inward, so naive peak-to-peak underestimates the true centre-to-centre
separation; and when the separation falls below roughly the optical peak width
the two peaks merge into a single visible hump with no maxima to pick. Fitting
recovers the two centres in both regimes. The apparent peak width is set largely
by the microscope point-spread function, so "looks like one peak" is the
expected signature of unresolved-but-separate sisters rather than evidence of
fusion.

## Reported quality metrics

- `R_squared` — goodness of fit; a filter for poor fits.
- `Sep_over_sigma` — separation in units of the peak width; a resolvability
  index (comfortably above 1 = two clearly resolved peaks; near or below 1 =
  merged, separation inferred from the shape of a single hump).
- `Envelope_FWHM` — full width at half-maximum of the whole signal; an
  independent, model-free cross-check.

An arm whose fit is geometrically invalid (non-positive amplitude, or a centre
outside the signal window) is flagged `fit_failed` and reported as NaN for
remeasurement, rather than substituted with a less reliable estimate.

## Limitations

- Assumes optically isolated arms with clean background on both sides; crowded
  spreads are the main failure mode and are best excluded at the selection
  stage.
- Below the optical resolution limit the separation is derived from the modelled
  shape rather than two resolved peaks; `Sep_over_sigma` makes these cases
  explicit.
- Line placement is operator-dependent; for multi-operator studies an
  inter-operator agreement check on a shared set of spreads is advisable.
