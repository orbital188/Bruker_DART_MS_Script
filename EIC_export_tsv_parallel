Option Explicit  ' must be the very first statement

' VBScript to export chromatograms (TIC + multi‑EIC) in parallel columns for Origin
' ============================================================================
'  USER SETTINGS — adjust only this block ------------------------------------
Dim targetMz: targetMz = Array(86.0923, 102.1227, 130.0525, 147.0374, 187.0887, _
                               197.0512, 203.0837, 219.0477, 242.2054, 255.2209, _
                               257.233 , 281.2359, 283.252 , 285.2581, 371.366 , _
                               387.3607, 449.2811, 451.2801, 453.2807)
Dim tol            : tol            = 0.005         ' half‑window (Da)
Dim PolaritySetting: PolaritySetting = daPositive    ' daPositive or daNegative
Dim outFileName    : outFileName    = "output_EICs_parallel.tsv"
' ----------------------------------------------------------------------------

' === Workspace arrays ===
Dim rt(), intensity()

' === Build output path in user Documents ===
Const ssfPROFILE = &H28
Dim oShell:   Set oShell = CreateObject("Shell.Application")
Dim homePath: homePath  = oShell.NameSpace(ssfPROFILE).Self.Path

Dim fso: Set fso = CreateObject("Scripting.FileSystemObject")
Dim filePath: filePath = homePath & "\Documents\" & outFileName
Dim file:    Set file = fso.CreateTextFile(filePath, True)

' ============================================================================
' 1.  Add TIC and EIC definitions
' ============================================================================
Dim TICdef: Set TICdef = CreateObject("DataAnalysis.TICChromatogramDefinition")
With TICdef
    .MSFilter.Type = daMSFilterMS
    .ScanMode      = daScanModeFullScan
    .Polarity      = PolaritySetting
End With
Analysis.Chromatograms.AddChromatogram TICdef

Dim i, mzValue, EICdef
For i = LBound(targetMz) To UBound(targetMz)
    mzValue = targetMz(i)
    Set EICdef = CreateObject("DataAnalysis.EICChromatogramDefinition")
    With EICdef
        .MSFilter.Type = daMSFilterMS
        .ScanMode      = daScanModeFullScan
        .Polarity      = PolaritySetting
        .Range         = CStr(mzValue)  ' centre m/z
        .WidthLeft     = tol            ' ± window
        .WidthRight    = tol
    End With
    Analysis.Chromatograms.AddChromatogram EICdef
Next

' ============================================================================
' 2.  Collect chromatogram data
' ============================================================================
Dim chromCount: chromCount = Analysis.Chromatograms.Count
ReDim chromNames(chromCount-1)
ReDim chromInt(chromCount-1)
ReDim chromRT(chromCount-1)

Dim idxC: idxC = 0
Dim chrom
For Each chrom In Analysis.Chromatograms
    chrom.ChromatogramData rt, intensity
    chromRT(idxC)  = rt
    chromInt(idxC) = intensity
    chromNames(idxC) = chrom.Name
    idxC = idxC + 1
Next

' Determine longest scan length (safety)
Dim maxLen, arrL
maxLen = 0
For i = 0 To chromCount-1
    arrL = UBound(chromRT(i))
    If arrL > maxLen Then maxLen = arrL
Next

' ============================================================================
' 3.  Write parallel‑column TSV (RT | TIC | EIC…)
' ============================================================================
Dim header: header = "RT"
For i = 0 To chromCount-1: header = header & vbTab & chromNames(i): Next
file.WriteLine header

Dim row, j, line
For row = 0 To maxLen
    If row <= UBound(chromRT(0)) Then
        line = chromRT(0)(row)
    Else
        line = ""
    End If
    For j = 0 To chromCount-1
        If row <= UBound(chromInt(j)) Then
            line = line & vbTab & chromInt(j)(row)
        Else
            line = line & vbTab & ""
        End If
    Next
    file.WriteLine line
Next

file.Close
MsgBox "Parallel‑column chromatogram TSV saved → " & filePath, vbInformation, "Export complete"
