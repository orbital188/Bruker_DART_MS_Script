'──────────────────────────────────────────────────────────────────────────
'  Batch‑EIC exporter – writes one CSV per open Analysis
'──────────────────────────────────────────────────────────────────────────
Option Explicit

'======================= 1.  USER SETTINGS ================================
Const outRoot = "E:\Zhang\DART\Kevin\2023\December\PbSe\Export\"   '<< end with "\"
Dim targetMz : targetMz = Array( _
    102.1229, 130.0651, 147.0449, 187.0733, 197.0648, 203.0682, _
    219.0575, 242.2246, 255.2324, 257.2481, 281.2481, 283.2637, _
    285.2794, 371.3807, 387.3756, 449.2811, 451.2972, 453.2807 )
Dim tol      : tol      = 0.005      'half‑window in Da  (±0.005 Da)
Dim PolaritySetting : PolaritySetting = daPositive   'or daNegative
'=========================================================================

'---------- helper: be sure the export folder exists ---------------------
Sub EnsureFolder(path)
    Dim fso: Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(path) Then fso.CreateFolder path
End Sub

'---------- helper: base name of the .d folder ---------------------------
Function SampleBaseName(ana)          'ana = Analysis
    Dim fso: Set fso = CreateObject("Scripting.FileSystemObject")
    SampleBaseName = fso.GetBaseName(ana.Path)
End Function

'---------- export ONE analysis to CSV -----------------------------------
Sub ExportCurrent(ana)
    Const delim = ","
    Dim fso: Set fso = CreateObject("Scripting.FileSystemObject")
    Dim fileName : fileName = outRoot & SampleBaseName(ana) & "_EICs.csv"
    Dim csv:  Set csv = fso.CreateTextFile(fileName, True)

    '--------- add TIC ----------------------------------------------------
    Dim TICdef: Set TICdef = CreateObject("DataAnalysis.TICChromatogramDefinition")
    With TICdef
        .MSFilter.Type = daMSFilterMS
        .ScanMode      = daScanModeFullScan
        .Polarity      = PolaritySetting
    End With
    ana.Chromatograms.AddChromatogram TICdef

    '--------- add one EIC per target m/z ---------------------------------
    Dim i, mz, EICdef
    For i = LBound(targetMz) To UBound(targetMz)
        mz = targetMz(i)
        Set EICdef = CreateObject("DataAnalysis.EICChromatogramDefinition")
        With EICdef
            .MSFilter.Type = daMSFilterMS
            .ScanMode      = daScanModeFullScan
            .Polarity      = PolaritySetting
            .Range      = CStr(mz)
            .WidthLeft  = tol
            .WidthRight = tol
        End With
        ana.Chromatograms.AddChromatogram EICdef
    Next

    '--------- collect XY data -------------------------------------------
    Dim cCount: cCount = ana.Chromatograms.Count
    Dim rt(), it(), names()
    ReDim rt(cCount-1), it(cCount-1), names(cCount-1)

    Dim idx: idx = 0 : Dim chrom
    For Each chrom In ana.Chromatograms
        chrom.ChromatogramData rt(idx), it(idx)
        names(idx) = chrom.Name
        idx = idx + 1
    Next

    '--------- write header ----------------------------------------------
    Dim line: line = "RT"
    For i = 0 To cCount-1: line = line & delim & names(i): Next
    csv.WriteLine line

    '--------- write rows (pad shorter vectors) --------------------------
    Dim row, j, maxLen: maxLen = 0
    For i = 0 To cCount-1
        If UBound(rt(i)) > maxLen Then maxLen = UBound(rt(i))
    Next

    For row = 0 To maxLen
        If row <= UBound(rt(0)) Then
            line = rt(0)(row)
        Else
            line = ""
        End If
        For j = 0 To cCount-1
            If row <= UBound(it(j)) Then
                line = line & delim & it(j)(row)
            Else
                line = line & delim & ""
            End If
        Next
        csv.WriteLine line
    Next
    csv.Close
End Sub

'=======================  MAIN LOOP  =====================================
EnsureFolder outRoot

Dim ana
For Each ana In Application.Analyses          'all files already open
    ExportCurrent ana
Next

MsgBox "Finished exporting to " & outRoot, vbInformation
'=========================================================================
