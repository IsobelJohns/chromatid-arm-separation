// ============================================================================
//  Chromatid Arm Separation — an ImageJ/Fiji macro
// ============================================================================
//  Measures the separation between sister-chromatid arms on metaphase
//  chromosome spreads by fitting two fixed-width Gaussians to a perpendicular
//  line-scan intensity profile and reporting the distance between their
//  centres. Keyboard-driven, ROI-Manager based; exports per-arm and
//  per-image (wide) CSV tables.
//
//  Version:  1.0.0
//  Author:   Isobel Johns   (ORCID: 0000-0002-3148-2183)
//  Affil.:   Netherlands Cancer Institute (NKI-AVL), Amsterdam, The Netherlands
//  Contact:  isobeljohns@gmail.com
//  License:  MIT (see LICENSE)
//  Repo:     https://github.com/IsobelJohns/chromatid-arm-separation
//  Archive:  https://doi.org/10.5281/zenodo.23703875
//
//  If you use this macro, please cite the archived release (see CITATION.cff)
//  and the associated publication (see README.md).
//
//  Tested with: Fiji (ImageJ 1.54), macOS. Requires no external plugins.
// ============================================================================

// ============================================================================
// Sister Chromatid Arm Separation Macro — CLEAN BUILD
// ============================================================================
// T = add line to ROI Manager | S = process | E = export
// D = skip image | R = clear ROIs | U = undo last arm | B = big log font
//
// There are always two sister chromatids, so a distance is always reported.
// armsPerImage sets how many measurements you expect per image (default 6 =
// 3 chromosomes x 2 arms). Raise it to capture more chromosomes per image.
// ============================================================================

var usePixels = true;
var armsPerImage = 6;        // measurements expected per image (raise for more)
var resultsTitle = "Chromatid_Separation_Results";
var imageCounter = 0;
var lastImageID = -1;
var roisDoneForCurrentImage = 0;

// --- Prominent count banner in the Log (impossible to miss) ----------------
function countBanner(num, done) {
    print("");
    print("==================================================");
    print("====   IMAGE  " + num + "      " + done + " / " + armsPerImage + "  DONE   ====");
    print("==================================================");
    print("");
}

// --- Keep the Results table scrolled to the newest row ---------------------
// Runs as the LAST action of a macro: even if the scripting bridge is
// unavailable, all measuring/logging is already complete.
function scrollResultsBottom() {
    js = "var f=Packages.ij.WindowManager.getFrame('" + resultsTitle + "');" +
         "if(f!=null){var tp=f.getTextPanel();var n=tp.getLineCount();" +
         "if(n>0){tp.setSelection(n-1,n-1);}}";
    eval("js", js);
}

// --- Build the one-row-per-image summary (wide layout) ---------------------
// Reads the results table and writes a CSV: each image on one line, arm
// distances spread across Chr#_p / Chr#_q columns, plus N / mean / SD / mean R2
// and a list of any non-gaussian (excluded) arms. Image_name and Phenotype are
// left blank for merging with blinded scoring on Image_number.
function exportWideByImage(savePath) {
    selectWindow(resultsTitle);
    N = Table.size;
    if (N == 0) { print("No rows to summarise."); return; }
    if (usePixels) { units = "pixels"; ulab = "px"; }
    else { getPixelSize(units, pw, ph); ulab = units; }
    p2pCol = "PeakToPeak_" + units;

    imgN = newArray(N); chrom = newArray(N); armv = newArray(N);
    meth = newArray(N); p2p = newArray(N); r2 = newArray(N); fid = newArray(N);
    maxImg = 0; maxChr = 1;
    for (i = 0; i < N; i++) {
        imgN[i]  = Table.get("Image_number", i);
        fid[i]   = Table.getString("Image_name", i);
        chrom[i] = Table.getString("Chromosome", i);
        armv[i]  = Table.getString("Arm", i);
        meth[i]  = Table.getString("Method", i);
        p2p[i]   = Table.get(p2pCol, i);
        r2[i]    = Table.get("R_squared", i);
        if (imgN[i] > maxImg) maxImg = imgN[i];
        if (meth[i] == "gaussian" && startsWith(chrom[i], "Chr")) {
            cn = parseInt(substring(chrom[i], 3));
            if (!isNaN(cn) && cn > maxChr) maxChr = cn;
        }
    }
    nArmCols = maxChr * 2;

    fVal = newArray((maxImg + 1) * nArmCols);
    fHas = newArray((maxImg + 1) * nArmCols);
    for (k = 0; k < fVal.length; k++) { fVal[k] = 0; fHas[k] = 0; }
    sSum = newArray(maxImg + 1); sSq = newArray(maxImg + 1);
    sCnt = newArray(maxImg + 1); sR2 = newArray(maxImg + 1);
    seen = newArray(maxImg + 1); fijiOf = newArray(maxImg + 1); exclOf = newArray(maxImg + 1);
    for (im = 0; im <= maxImg; im++) {
        sSum[im]=0; sSq[im]=0; sCnt[im]=0; sR2[im]=0; seen[im]=0; fijiOf[im]=""; exclOf[im]="";
    }

    for (i = 0; i < N; i++) {
        im = imgN[i];
        if (im < 1 || im > maxImg) continue;
        seen[im] = 1;
        if (fijiOf[im] == "") fijiOf[im] = fid[i];
        if (meth[i] == "gaussian") {
            sSum[im] = sSum[im] + p2p[i];
            sSq[im]  = sSq[im] + p2p[i]*p2p[i];
            sCnt[im] = sCnt[im] + 1;
            sR2[im]  = sR2[im] + r2[i];
            if (startsWith(chrom[i], "Chr")) {
                cn = parseInt(substring(chrom[i], 3));
                sfx = 0; if (armv[i] != "p-arm") sfx = 1;
                col = (cn - 1) * 2 + sfx;
                if (!isNaN(cn) && col >= 0 && col < nArmCols) {
                    idx = im * nArmCols + col;
                    fVal[idx] = p2p[i]; fHas[idx] = 1;
                }
            }
        } else {
            ab = armv[i];
            if (ab == "p-arm") ab = "p"; else if (ab == "q-arm") ab = "q";
            mm = meth[i]; if (mm == "") mm = "blank";
            tag = chrom[i] + "_" + ab + "(" + mm + ")";
            if (exclOf[im] == "") exclOf[im] = tag; else exclOf[im] = exclOf[im] + ";" + tag;
        }
    }

    hdr = "Image_number,Image_name,Phenotype,FIJI_image_id";
    for (c = 1; c <= maxChr; c++) hdr = hdr + ",Chr" + c + "_p,Chr" + c + "_q";
    hdr = hdr + ",N_arms,Mean_distance_" + ulab + ",SD_distance_" + ulab + ",Mean_R2,Excluded_arms";
    out = hdr + "\n";

    for (im = 1; im <= maxImg; im++) {
        if (seen[im] == 0) continue;
        line = "" + im + ",,," + fijiOf[im];
        for (col = 0; col < nArmCols; col++) {
            idx = im * nArmCols + col;
            if (fHas[idx] == 1) line = line + "," + d2s(fVal[idx], 3);
            else line = line + ",";
        }
        cnt = sCnt[im];
        if (cnt > 0) {
            line = line + "," + cnt + "," + d2s(sSum[im]/cnt, 3) + ",";
            if (cnt > 1) {
                v = (sSq[im] - sSum[im]*sSum[im]/cnt) / (cnt - 1);
                if (v < 0) v = 0;
                line = line + d2s(sqrt(v), 3);
            } else line = line + "NaN";
            line = line + "," + d2s(sR2[im]/cnt, 3);
        } else {
            line = line + ",0,NaN,NaN,NaN";
        }
        line = line + "," + exclOf[im];
        out = out + line + "\n";
    }

    File.saveString(out, savePath);
    print("Saved (per-image summary): " + savePath);
}

// --- ENVELOPE FWHM --------------------------------------------------------
function measureEnvelopeFWHM(prof) {
    n = prof.length;
    mx = 0;
    mxi = 0;
    for (i = 0; i < n; i++) {
        if (prof[i] > mx) { mx = prof[i]; mxi = i; }
    }
    hm = mx / 2;
    li = 0;
    for (i = mxi - 1; i >= 0; i--) {
        if (prof[i] <= hm) {
            d = prof[i+1] - prof[i];
            if (d != 0) li = i + (hm - prof[i]) / d;
            else li = i;
            break;
        }
    }
    ri = n - 1;
    for (i = n - 1; i > mxi; i--) {
        if (prof[i] > hm) {
            for (j = i; j < n; j++) {
                if (prof[j] <= hm) {
                    d = prof[j-1] - prof[j];
                    if (d != 0) ri = j - (hm - prof[j]) / d;
                    else ri = j;
                    break;
                }
            }
            break;
        }
    }
    return ri - li;
}

// --- CORE MEASUREMENT ------------------------------------------------------
function measureOneROI() {
    prof = getProfile();
    np = prof.length;

    if (usePixels) { ps = 1; }
    else { getPixelSize(uu, pw, ph); ps = pw; }
    getLine(x1, y1, x2, y2, lw);
    ll = sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1));
    st = ll / (np - 1);
    if (!usePixels) st = st * ps;

    // FWHM on raw profile
    fwhm = measureEnvelopeFWHM(prof) * st;

    // Light smooth (radius 2) for peak/valley detection
    sm = newArray(np);
    for (i = 0; i < np; i++) {
        s = 0; c = 0;
        for (j = i - 2; j <= i + 2; j++) {
            if (j >= 0 && j < np) { s = s + prof[j]; c = c + 1; }
        }
        sm[i] = s / c;
    }

    // Global max and background (min) of smoothed profile
    gmax = 0;
    gmin = 1e30;
    for (i = 0; i < np; i++) {
        if (sm[i] > gmax) gmax = sm[i];
        if (sm[i] < gmin) gmin = sm[i];
    }

    // ===== FIND SIGNAL WINDOW BY WALKING OUT FROM THE BRIGHTEST POINT =====
    // Locate the global max, then walk left and right until the trace drops
    // to near background. This trims flat background tails (which otherwise
    // let a Gaussian wander into the baseline) and excludes elevated edges
    // from adjacent material that would corrupt valley detection.
    gmaxIdx = 0;
    for (i = 0; i < np; i++) {
        if (sm[i] > gmax - 1e-9 && sm[i] >= gmax) { gmaxIdx = i; i = np; }
    }
    // (gmax/gmin already computed above)
    // Foot threshold close to true background (15% of range) so that a deep
    // valley between widely-separated sisters is NOT mistaken for the signal end.
    footThresh = gmin + (gmax - gmin) * 0.15;

    leftFoot = 0;
    for (i = gmaxIdx - 1; i >= 0; i--) {
        if (sm[i] < footThresh) { leftFoot = i; i = -1; }
    }
    rightFoot = np - 1;
    for (i = gmaxIdx + 1; i < np; i++) {
        if (sm[i] < footThresh) { rightFoot = i; i = np; }
    }

    // Small margin to recapture Gaussian tails, clamped to profile bounds
    sL = leftFoot - 2; if (sL < 0) sL = 0;
    sR = rightFoot + 2; if (sR > np - 1) sR = np - 1;
    sW = sR - sL;

    // Valley: minimum in central 60% of the signal window
    cL = sL + round(sW * 0.2);
    cR = sR - round(sW * 0.2);
    if (cL < sL) cL = sL;
    if (cR > sR) cR = sR;
    if (cL >= cR) { cL = sL; cR = sR; }

    vMin = 1e30;
    vIdx = round((cL + cR) / 2);
    for (i = cL; i <= cR; i++) {
        if (sm[i] < vMin) { vMin = sm[i]; vIdx = i; }
    }

    // Peak 1: max LEFT of valley (within window)
    p1v = 0; p1i = sL;
    for (i = sL; i < vIdx; i++) {
        if (sm[i] > p1v) { p1v = sm[i]; p1i = i; }
    }
    // Peak 2: max RIGHT of valley (within window)
    p2v = 0; p2i = sR;
    for (i = vIdx + 1; i <= sR; i++) {
        if (sm[i] > p2v) { p2v = sm[i]; p2i = i; }
    }

    // ===== ALWAYS TWO PEAKS — locate the two chromatid centres =====
    // There are always two sister chromatids, so we always report a distance.
    // Strategy: estimate the intrinsic peak width (sigma) from the signal's
    // edge sharpness, FIX it, and fit two Gaussians for the two centres only.
    // Fixing sigma removes the degeneracy that let the old fit blow up.
    // If the fit geometry is broken, the arm is flagged (NaN) for remeasurement.

    // Discrete peak-to-peak (visible maxima — comparison only)
    p2pDiscrete = abs(p2i - p1i) * st;

    // --- Estimate sigma from the outer edge sharpness (25-75% rise) ---
    range = gmax - gmin;
    p25 = gmin + 0.25 * range;
    p75 = gmin + 0.75 * range;

    x25L = sL;
    for (i = sL; i <= gmaxIdx; i++) { if (sm[i] >= p25) { x25L = i; i = gmaxIdx + 1; } }
    x75L = sL;
    for (i = sL; i <= gmaxIdx; i++) { if (sm[i] >= p75) { x75L = i; i = gmaxIdx + 1; } }
    leftRise = x75L - x25L;

    x75R = gmaxIdx;
    for (i = sR; i >= gmaxIdx; i--) { if (sm[i] >= p75) { x75R = i; i = gmaxIdx - 1; } }
    x25R = sR;
    for (i = sR; i >= gmaxIdx; i--) { if (sm[i] >= p25) { x25R = i; i = gmaxIdx - 1; } }
    rightFall = x25R - x75R;

    avgRise = (leftRise + rightFall) / 2.0;
    if (avgRise <= 0) avgRise = sW / 5.0;
    sigEst = avgRise / 0.907;          // 25-75% span = 0.907*sigma for a Gaussian
    if (sigEst < 1.2) sigEst = 1.2;
    if (sigEst > sW * 0.35) sigEst = sW * 0.35;

    // Valley depth (how distinct the two humps are)
    lp = minOf(p1v, p2v);
    if (lp > 0) dipFrac = (lp - vMin) / lp; else dipFrac = 0;

    // Build windowed x (original indices) and y arrays for the fit
    nWin = sR - sL + 1;
    xpts = newArray(nWin);
    ypts = newArray(nWin);
    for (i = 0; i < nWin; i++) {
        xpts[i] = sL + i;
        ypts[i] = prof[sL + i];
    }

    // --- Fixed-sigma two-Gaussian fit (5 free params: bg, A1, m1, A2, m2) ---
    // Sigma is baked into the equation string as a constant, so it can't drift.
    sig2 = 2 * sigEst * sigEst;
    eq = "y = a + b*exp(-(x-c)*(x-c)/" + d2s(sig2,5) + ") + d*exp(-(x-e)*(x-e)/" + d2s(sig2,5) + ")";

    a1Est = p1v - gmin; if (a1Est < 1) a1Est = 1;
    a2Est = p2v - gmin; if (a2Est < 1) a2Est = 1;
    init = newArray(gmin, a1Est, p1i, a2Est, p2i);

    p2p = NaN;
    r2 = 0;
    fm1 = NaN;
    fm2 = NaN;
    method = "none";
    mt = 2;

    if (range < 8) {
        // No real signal (line drawn in background) — cannot find peaks
        mt = 2;
        method = "failed";
    } else {
        // There IS signal, so there are two chromatids: always report a distance.
        fitOK = false;
        if (sW >= 4) {
            Fit.doFit(eq, xpts, ypts, init);
            r2 = Fit.rSquared;
            fA1 = Fit.p(1);
            fm1 = Fit.p(2);
            fA2 = Fit.p(3);
            fm2 = Fit.p(4);

            // Use the Gaussian whenever its geometry is sound. R2 is recorded
            // for filtering. If the geometry is broken the arm is flagged as
            // failed (NaN) rather than substituted with a less reliable estimate.
            valid = true;
            if (fA1 <= 0 || fA2 <= 0) valid = false;
            if (fm1 < sL || fm1 > sR) valid = false;
            if (fm2 < sL || fm2 > sR) valid = false;

            if (valid) {
                fitOK = true;
                p2p = abs(fm2 - fm1) * st;
                method = "gaussian";
            }
        }

        if (!fitOK) {
            // Fit geometry broken: flag for remeasurement rather than guess
            p2p = NaN;
            method = "fit_failed";
        }

        // Type is informational only; a distance is always reported
        if (dipFrac > 0.05) mt = 0; else mt = 1;   // 0=resolved, 1=merged
    }

    // Resolvability index: separation in units of the peak width
    if (sigEst > 0) sepSig = (p2p / st) / sigEst; else sepSig = NaN;

    // Debug
    print("  win=[" + sL + "-" + sR + "] sigma=" + d2s(sigEst,2) +
          " R2=" + d2s(r2,3) +
          " m1=" + d2s(fm1,1) + " m2=" + d2s(fm2,1) +
          " dip=" + d2s(dipFrac*100,1) + "%" +
          " p2p=" + d2s(p2p,2) + " [" + method + "]" +
          " (discrete=" + d2s(p2pDiscrete,1) + ")");

    call("ij.Prefs.set", "chromatid.fwhm", d2s(fwhm, 6));
    call("ij.Prefs.set", "chromatid.p2p", d2s(p2p, 6));
    call("ij.Prefs.set", "chromatid.p2pdisc", d2s(p2pDiscrete, 6));
    call("ij.Prefs.set", "chromatid.method", method);
    call("ij.Prefs.set", "chromatid.sigma", d2s(sigEst * st, 6));
    call("ij.Prefs.set", "chromatid.r2", d2s(r2, 6));
    call("ij.Prefs.set", "chromatid.sepsig", d2s(sepSig, 6));
    call("ij.Prefs.set", "chromatid.type", d2s(mt, 0));
}


// === PROCESS ROIS ==========================================================
macro "Process Chromatid ROIs [s]" {
    if (nImages == 0) exit("No image open.");
    nROIs = roiManager("count");
    if (nROIs == 0) exit("ROI Manager empty. Draw lines + press T first.");

    cID = getImageID();
    iTitle = getTitle();

    if (cID == lastImageID) {
        iNum = imageCounter;
    } else {
        if (lastImageID != -1 && roisDoneForCurrentImage > 0 && roisDoneForCurrentImage < armsPerImage) {
            showMessage("Previous image had " + roisDoneForCurrentImage + "/" + armsPerImage + ". Moving on.");
        }
        imageCounter = imageCounter + 1;
        iNum = imageCounter;
        lastImageID = cID;
        roisDoneForCurrentImage = 0;
    }

    // armsPerImage is the expected count (drives the counter), not a hard cap.
    // Going over is allowed so you can capture extra arms on a given image.

    if (usePixels) units = "pixels";
    else { getPixelSize(units, pw, ph); }

    // Ensure table exists
    found = false;
    wl = getList("window.titles");
    for (i = 0; i < wl.length; i++) {
        if (wl[i] == resultsTitle) found = true;
    }
    if (!found) Table.create(resultsTitle);

    tLabels = newArray("resolved","merged","failed");

    print("\\Clear");
    print("--- Image " + iNum + " (" + iTitle + ") ---");

    for (r = 0; r < nROIs; r++) {
        selectImage(cID);
        roiManager("select", r);

        if (selectionType() != 5) {
            print("ROI " + (r+1) + ": not a line - skipped");
            continue;
        }
        tp = getProfile();
        nPts = tp.length;
        if (nPts < 5) {
            print("ROI " + (r+1) + ": too short - skipped");
            continue;
        }

        print("ROI " + (r+1) + ":");
        measureOneROI();

        ef = parseFloat(call("ij.Prefs.get", "chromatid.fwhm", "NaN"));
        pp = parseFloat(call("ij.Prefs.get", "chromatid.p2p", "NaN"));
        pd = parseFloat(call("ij.Prefs.get", "chromatid.p2pdisc", "NaN"));
        sg = parseFloat(call("ij.Prefs.get", "chromatid.sigma", "NaN"));
        r2 = parseFloat(call("ij.Prefs.get", "chromatid.r2", "0"));
        ss = parseFloat(call("ij.Prefs.get", "chromatid.sepsig", "NaN"));
        mth = call("ij.Prefs.get", "chromatid.method", "none");
        mt = parseInt(call("ij.Prefs.get", "chromatid.type", "2"));

        // Dynamic labels: 2 arms per chromosome, any number of chromosomes
        slot = roisDoneForCurrentImage;
        ch = "Chr" + (floor(slot / 2) + 1);
        if (slot % 2 == 0) ar = "p-arm"; else ar = "q-arm";

        selectWindow(resultsTitle);
        row = Table.size;
        Table.set("Image_number", row, iNum);
        Table.set("Image_name", row, iTitle);
        Table.set("Chromosome", row, ch);
        Table.set("Arm", row, ar);
        Table.set("Method", row, mth);
        Table.set("PeakToPeak_"+units, row, pp);
        Table.set("R_squared", row, r2);
        Table.set("Sep_over_sigma", row, ss);
        Table.set("Envelope_FWHM_"+units, row, ef);
        Table.update();

        roisDoneForCurrentImage = roisDoneForCurrentImage + 1;
    }

    roiManager("deselect");
    roiManager("delete");

    if (roisDoneForCurrentImage < armsPerImage) {
        print("Need " + (armsPerImage - roisDoneForCurrentImage) + " more (or open next image). Draw + T, then S.");
    } else {
        print("Target reached. Draw + T + S to add more arms, or open next image.");
    }
    countBanner(iNum, roisDoneForCurrentImage);

    scrollResultsBottom();
}


// === SKIP ==================================================================
macro "Skip Image [d]" {
    if (nImages == 0) exit("No image open.");
    cID = getImageID();
    iTitle = getTitle();
    if (cID != lastImageID) {
        imageCounter = imageCounter + 1;
        lastImageID = cID;
        roisDoneForCurrentImage = 0;
    }
    iNum = imageCounter;

    if (usePixels) units = "pixels";
    else { getPixelSize(units, pw, ph); }

    found = false;
    wl = getList("window.titles");
    for (i = 0; i < wl.length; i++) {
        if (wl[i] == resultsTitle) found = true;
    }
    if (!found) Table.create(resultsTitle);

    selectWindow(resultsTitle);
    row = Table.size;
    Table.set("Image_number", row, iNum);
    Table.set("Image_name", row, iTitle);
    Table.set("Chromosome", row, "SKIPPED");
    Table.set("Arm", row, "SKIPPED");
    Table.set("Method", row, "skipped");
    Table.set("PeakToPeak_"+units, row, NaN);
    Table.update();

    if (roiManager("count") > 0) { roiManager("deselect"); roiManager("delete"); }
    lastImageID = -1;
    roisDoneForCurrentImage = 0;

    print("");
    print("==================================================");
    print("====   IMAGE  " + iNum + "      SKIPPED   ====");
    print("==================================================");
    print("");

    scrollResultsBottom();
}


// === EXPORT ================================================================
macro "Export Chromatid Results to CSV [e]" {
    found = false;
    wl = getList("window.titles");
    for (i = 0; i < wl.length; i++) {
        if (wl[i] == resultsTitle) found = true;
    }
    if (!found) exit("No results table found.");

    saveDir = getDirectory("Choose folder to save results");
    if (lengthOf(saveDir) == 0) exit("Cancelled.");

    base = "Chromatid_Separation_Results";
    sp = saveDir + base + ".csv";
    n = 1;
    while (File.exists(sp)) {
        n = n + 1;
        sp = saveDir + base + "_" + n + ".csv";
    }

    selectWindow(resultsTitle);
    Table.save(sp);
    print("Saved (per-arm): " + sp);

    // also write the one-row-per-image summary (wide layout with averages)
    if (n == 1) wsp = saveDir + base + "_by_image.csv";
    else        wsp = saveDir + base + "_by_image_" + n + ".csv";
    exportWideByImage(wsp);
}


// === CLEAR ROIS ============================================================
macro "Clear ROIs [r]" {
    if (roiManager("count") > 0) { roiManager("deselect"); roiManager("delete"); }
    print("ROIs cleared. Image " + imageCounter + ": " + roisDoneForCurrentImage + "/" + armsPerImage + " done.");
}


// === UNDO LAST ARM =========================================================
// Removes the most recently logged arm for the CURRENT image so you can
// redraw and re-measure it. Press repeatedly to peel off several arms;
// press until 0/N to redo a whole image from scratch.
macro "Undo Last Arm [u]" {
    found = false;
    wl = getList("window.titles");
    for (i = 0; i < wl.length; i++) if (wl[i] == resultsTitle) found = true;
    if (!found) exit("No results table yet.");

    selectWindow(resultsTitle);
    n = Table.size;
    if (n == 0) exit("Nothing to undo.");

    lastNum = Table.get("Image_number", n - 1);
    lastChr = Table.getString("Chromosome", n - 1);
    lastArm = Table.getString("Arm", n - 1);

    if (!getBoolean("Undo last entry?\n\nImage " + lastNum + "  -  " + lastChr + " " + lastArm +
                    "\n\nThis removes that row so you can redraw and re-measure."))
        exit("Undo cancelled.");

    Table.deleteRows(n - 1, n - 1);
    Table.update();

    // keep the per-image counter in step if we are still on that image
    if (nImages > 0 && getImageID() == lastImageID && roisDoneForCurrentImage > 0)
        roisDoneForCurrentImage = roisDoneForCurrentImage - 1;
    if (roiManager("count") > 0) { roiManager("deselect"); roiManager("delete"); }

    print("");
    print("--- UNDO: removed Image " + lastNum + " " + lastChr + " " + lastArm +
          ".  Now " + roisDoneForCurrentImage + "/" + armsPerImage +
          ". Redraw + T + S to redo. ---");

    scrollResultsBottom();
}


// === BIG LOG FONT (optional) ==============================================
// Press once if you want the Log text enlarged and bold. Isolated from the
// scoring workflow so it can never interfere with measuring.
macro "Big Log Font [b]" {
    print("Log font enlarged.");
    js = "var lw=Packages.ij.WindowManager.getWindow('Log');" +
         "if(lw!=null){var tp=lw.getTextPanel();" +
         "tp.setFont(new java.awt.Font('SansSerif',java.awt.Font.BOLD,18));" +
         "tp.repaint();}";
    eval("js", js);
}
