# Code availability — text for the manuscript and Reporting Summary

Fill the placeholders (`<...>`) before submission. The same wording should
appear in the manuscript's **Code Availability** statement and in the
**Reporting Summary**.

---

## Manuscript "Code availability" statement (recommended wording)

> The custom ImageJ/Fiji macro used to quantify sister-chromatid arm separation
> on metaphase chromosome spreads is openly available under the MIT license.
> Source code is deposited on Zenodo (version 1.0.0; DOI
> <https://doi.org/10.5281/zenodo.XXXXXXX>) and developed at
> <https://github.com/><user>/chromatid-arm-separation. No restrictions apply
> to its use.

If a reviewer or editor prefers a single sentence:

> The custom ImageJ/Fiji macro for chromatid arm-separation measurement is
> available under the MIT license at
> https://doi.org/10.5281/zenodo.XXXXXXX (v1.0.0).

---

## Reporting Summary wording

Most Nature-family Reporting Summaries ask, under "Software and code → Data
analysis", that custom code be listed with a persistent identifier. Add an
entry such as:

> Custom ImageJ/Fiji macro "Chromatid Arm Separation" v1.0.0 (MIT license),
> deposited at Zenodo, DOI 10.5281/zenodo.XXXXXXX; source at
> github.com/<user>/chromatid-arm-separation. Used to measure sister-chromatid
> arm separation from line-scan intensity profiles of metaphase spreads.

Also list the host application so the analysis is reproducible, e.g.:

> Fiji (ImageJ v1.54) — chromosome-spread line-scan measurement via the custom
> macro above.

---

## Checklist before the DOI is final

- [ ] GitHub repository created and public (or private until acceptance, then public).
- [ ] Zenodo linked to the repository; a GitHub **release** (tag `v1.0.0`) created so Zenodo mints the DOI automatically.
- [ ] Replace `XXXXXXX` / `<CONCEPT_DOI>` with the real Zenodo DOI in: this file, `README.md`, `CITATION.cff`, `.zenodo.json`, and the macro header.
- [ ] Fill author surname and ORCID in `LICENSE`, `CITATION.cff`, `.zenodo.json`, and the macro header.
- [ ] Add the published-paper DOI to the `references` block of `CITATION.cff` once available.
- [ ] Confirm the license choice with your institution's tech-transfer / contracts office (NKI) — MIT is permissive; some institutions prefer BSD-3-Clause or require a copyright line naming the institute.

> Note on the Zenodo DOI: Zenodo issues a **concept DOI** that always points to
> the newest version, plus a **version DOI** for each release. Cite the version
> DOI (v1.0.0) for exact reproducibility; the concept DOI is fine for a general
> "latest version" pointer.
