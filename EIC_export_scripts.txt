' VBScript to export chromatograms (TIC + multi‑EIC), spectra and mass lists from Bruker DataAnalysis
' -----------------------------------------------------------------------------
'  USER‑EDITABLE SECTION (lines 15‑22)
'    • targetMz     – list of centre m/z values
'    • tol          – ± Da half‑window (change to 0.01 when needed)
'    • Polarity     – daPositive or daNegative
' -----------------------------------------------------------------------------
Option Explicit

' === USER PARAMETERS ===
Dim targetMz
 targetMz = Array(86.0923, 102.1227, 130.0525, 147.0374, 187.0887, _
                  197.0512, 203.0837, 219.0477, 242.2054, 255.2209, _
                  257.233 , 281.2359, 283.252 , 285.2581, 371.366 , _
                  387.3607, 449.2811, 451.2801, 453.2807)

Dim tol            : tol            = 0.005         ' half‑window (Da). e.g. 0.01
Dim PolaritySetting: PolaritySetting = daPositive    ' daPositive or daNegative
' ======================================================================

' === Arrays for chromatogram data ===
Dim rt(), intensity()

' === Build output TSV path (user Documents) ===
Const ssfPROFILE = &H28
Dim oShell      : Set oShell = CreateObject("Shell.Application")
Dim homePath    : homePath   = oShell.NameSpace(ssfPROFILE).Self.Path

Dim fso         : Set fso = CreateObject("Scripting.FileSystemObject")
Dim filePath    : filePath = homePath & "\Documents\output_EICs.tsv"
Dim file        : Set file = fso.CreateTextFile(filePath, True)

' ======================================================================
' 1.  Add a TIC (same polarity as EICs)
' ======================================================================
Dim TICdef: Set TICdef = CreateObject("DataAnalysis.TICChromatogramDefinition")
With TICdef
    .MSFilter.Type = daMSFilterMS
    .ScanMode      = daScanModeFullScan
    .Polarity      = PolaritySetting
End With
Analysis.Chromatograms.AddChromatogram TICdef

' ======================================================================
' 2.  Generate EICs – DataAnalysis will now label them “m/z ± tol”
'     by defining a centre (.Range) plus WidthLeft/WidthRight.
' ======================================================================
Dim i, mzValue, EICdef
For i = LBound(targetMz) To UBound(targetMz)
    mzValue = targetMz(i)

    Set EICdef = CreateObject("DataAnalysis.EICChromatogramDefinition")
    With EICdef
        .MSFilter.Type = daMSFilterMS
        .ScanMode      = daScanModeFullScan
        .Polarity      = PolaritySetting
        .Range         = CStr(mzValue)              ' centre value only
        .WidthLeft     = tol                        ' left half‑window
        .WidthRight    = tol                        ' right half‑window
    End With
    Analysis.Chromatograms.AddChromatogram EICdef
Next

' ======================================================================
' 3.  Export ALL chromatograms (TIC + EICs) to TSV
' ======================================================================
file.WriteLine "=== Chromatograms ==="
Dim chrom, k, chromName
k = 0
For Each chrom In Analysis.Chromatograms
    chrom.ChromatogramData rt, intensity
    chromName = ""
    On Error Resume Next: chromName = chrom.Name: On Error GoTo 0
    If chromName = "" Then chromName = "Chromatogram_" & CStr(k)

    file.WriteLine "Chromatogram:" & vbTab & chromName
    file.WriteLine "RetentionTime" & vbTab & "Intensity"
    For k = 0 To UBound(rt)
        file.WriteLine rt(k) & vbTab & intensity(k)
    Next
    file.WriteLine ""
    k = k + 1
Next

' ======================================================================
' 4.  Export spectra + mass lists (unchanged from previous version)
' ======================================================================
file.WriteLine "=== Spectra and Mass List ==="
Dim spec, peak, maxI, relI, idx, fwhm, reso, specName
For Each spec In Analysis.Spectra
    specName = "": On Error Resume Next: specName = spec.Name: On Error GoTo 0
    If specName = "" Then specName = "Spectrum_" & CStr(idx)

    file.WriteLine "Spectrum:" & vbTab & specName
    file.WriteLine "FirstMass:" & vbTab & spec.FirstMass & vbTab & _
                   "LastMass:" & vbTab & spec.LastMass
    file.WriteLine "MaximumIntensity:" & vbTab & spec.MaximumIntensity & vbTab & _
                   "MinimumIntensity:" & vbTab & spec.MinimumIntensity
    file.WriteLine "Precursor:" & vbTab & spec.Precursor
    file.WriteLine "Polarity:" & vbTab & spec.Polarity
    file.WriteLine "ScanMode:" & vbTab & spec.ScanMode & vbCrLf

    ' --- relative intensity base peak ---
    maxI = 0
    For Each peak In spec.MSPeakList: If peak.Intensity > maxI Then maxI = peak.Intensity
    Next

    file.WriteLine "#" & vbTab & "m/z" & vbTab & "Res." & vbTab & "S/N" & vbTab & _
                   "I" & vbTab & "I %" & vbTab & "FWHM"
    idx = 1
    For Each peak In spec.MSPeakList
        If maxI > 0 Then relI = 100 * peak.Intensity / maxI Else relI = 0
        fwhm = "": On Error Resume Next: If Not IsNull(peak.Width) Then fwhm = peak.Width: On Error GoTo 0
        If fwhm <> "" Then reso = peak.m_over_z / fwhm Else reso = ""

        file.WriteLine idx & vbTab & peak.m_over_z & vbTab & reso & vbTab & _
                       peak.SignalToNoise & vbTab & peak.Intensity & vbTab & relI & vbTab & fwhm
        idx = idx + 1
    Next
    file.WriteLine ""
Next

file.Close
MsgBox "Export complete → " & filePath, vbInformation, "TIC + " & (UBound(targetMz)+1) & " EICs saved"
