' VBScript to export all chromatogram, spectrum, and formatted mass list data from all loaded analyses in Bruker DataAnalysis

Dim fso, shellApp
Set fso = CreateObject("Scripting.FileSystemObject")
Set shellApp = CreateObject("Shell.Application")

Dim analysis, analysisName, analysisPath, baseName, outputFile
Dim rt(), intensity(), chrom, i
Dim spec, peak, maxIntensity, relI, idx, fwhm, resolution
Dim file

' Loop through all loaded analyses
For Each analysis In Application.Analyses
    analysisName = analysis.Name         ' e.g., "Sample.d"
    analysisPath = analysis.Path         ' e.g., "C:\Data\Sample.d"
    baseName = Left(analysisName, InStrRev(analysisName, ".") - 1)
    outputFile = fso.GetParentFolderName(analysisPath) & "\" & baseName & "_export.tsv"

    ' Create export file
    Set file = fso.CreateTextFile(outputFile, True)

    ' ========== 1. Export chromatograms ==========
    file.WriteLine("=== Chromatograms ===")
    For Each chrom In analysis.Chromatograms
        chrom.ChromatogramData rt, intensity
        file.WriteLine("Chromatogram:" & vbTab & chrom.Name)
        file.WriteLine("RetentionTime" & vbTab & "Intensity")
        For i = 0 To UBound(rt)
            file.WriteLine(rt(i) & vbTab & intensity(i))
        Next
        file.WriteLine("")
    Next

    ' ========== 2. Export spectra ========== 
file.WriteLine("=== Spectra and Mass List ===")
For Each spec In analysis.Spectra
    file.WriteLine("Spectrum:" & vbTab & spec.Name)
    file.WriteLine("FirstMass:" & vbTab & spec.FirstMass & vbTab & "LastMass:" & vbTab & spec.LastMass)
    file.WriteLine("MaximumIntensity:" & vbTab & spec.MaximumIntensity & vbTab & "MinimumIntensity:" & vbTab & spec.MinimumIntensity)
    file.WriteLine("Precursor:" & vbTab & spec.Precursor)
    file.WriteLine("Polarity:" & vbTab & spec.Polarity)
    file.WriteLine("ScanMode:" & vbTab & spec.ScanMode)
    file.WriteLine("")

    ' === 2.1 Export FULL raw spectrum (all m/z-intensity pairs) ===
    Dim mz_data(), spec_intensity_data()
    spec.SpectrumData mz_data, spec_intensity_data
    file.WriteLine("FullSpectrum m/z" & vbTab & "Intensity")
    For j = 0 To UBound(mz_data)
        file.WriteLine(mz_data(j) & vbTab & spec_intensity_data(j))
    Next
    file.WriteLine("")

    ' === 2.2 Export peak-picked mass list (existing code) ===
    maxIntensity = 0
    For Each peak In spec.MSPeakList
        If peak.Intensity > maxIntensity Then maxIntensity = peak.Intensity
    Next

    file.WriteLine("#" & vbTab & "m/z" & vbTab & "Res." & vbTab & "S/N" & vbTab & "I" & vbTab & "I %" & vbTab & "FWHM")
    idx = 1
    For Each peak In spec.MSPeakList
        If maxIntensity > 0 Then
            relI = 100 * peak.Intensity / maxIntensity
        Else
            relI = 0
        End If

        On Error Resume Next
        fwhm = 0
        If Not IsNull(peak.Width) Then fwhm = peak.Width
        If fwhm = "" Then fwhm = 0
        On Error GoTo 0

        If fwhm > 0 Then
            resolution = peak.m_over_z / fwhm
        Else
            resolution = 0
        End If

        file.WriteLine(idx & vbTab & peak.m_over_z & vbTab & resolution & vbTab & peak.SignalToNoise & vbTab & peak.Intensity & vbTab & relI & vbTab & fwhm)
        idx = idx + 1
    Next

    file.WriteLine("")
Next

    file.Close
Next

MsgBox "All chromatograms, spectra, and formatted mass lists were written to parent folders of loaded analyses."
' Open the last output folder
shellApp.Open fso.GetParentFolderName(outputFile)
