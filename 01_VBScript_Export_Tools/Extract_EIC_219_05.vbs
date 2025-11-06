Option Explicit  ' *** Required by DataAnalysis VBScript engine ***

'==============================================
' USER SETTINGS - SPECIFIC MASS TARGET
'==============================================
Const TARGET_MASS = 219.05        ' Target m/z for EIC extraction
Const TOL_DA      = 0.01          ' Tolerance window (±0.01 Da)
Const OUT_SUBFOLDER = "EIC_exports_219_05"  ' Output folder for EIC exports
Const DELIM       = ","           ' CSV delimiter

Dim POLARITY_SETTING: POLARITY_SETTING = daPositive   ' daPositive | daNegative

'==============================================
' 1. Canonicalise & extract PbSe sample token
'==============================================
Function Canon(txt)
  txt = LCase(txt)
  Dim ch
  For Each ch In Array(Chr(34), "'", " ", "-", "_", "/", "\\", ".d")
    txt = Replace(txt, ch, "")
  Next
  Canon = txt
End Function

Function ExtractSampleToken(raw)
  Dim RE: Set RE = CreateObject("VBScript.RegExp")
  RE.Pattern = "pbse\d+_?pos[_]?\d+"  ' matches PbSe10_Pos_3 etc.
  RE.IgnoreCase = True
  If RE.Test(raw) Then
    ExtractSampleToken = Canon(RE.Execute(raw)(0).Value)
  Else
    ExtractSampleToken = Canon(raw)
  End If
End Function

'==============================================
' 2. Resolve output folder
'==============================================
If Application.Analyses.Count = 0 Then MsgBox "Open .d files first", vbExclamation: WScript.Quit
Dim fso: Set fso = CreateObject("Scripting.FileSystemObject")
Dim firstPath: firstPath = Application.Analyses(1).Path  ' 1-based collection
Dim rootDir : rootDir  = fso.GetParentFolderName(firstPath)
Dim outDir  : If OUT_SUBFOLDER = "" Then outDir = rootDir Else outDir = fso.BuildPath(rootDir, OUT_SUBFOLDER): If Not fso.FolderExists(outDir) Then fso.CreateFolder outDir

'==============================================
' 3. Export EIC for target mass (219.05) for each sample
'==============================================
Dim analysisObj, exported: exported = 0
For Each analysisObj In Application.Analyses
  ' Extract sample token for naming
  Dim token: token = ExtractSampleToken(analysisObj.Name)
  
  ' -- add TIC
  On Error Resume Next
  Dim TICdef: Set TICdef = CreateObject("DataAnalysis.TICChromatogramDefinition")
  If Err.Number = 0 Then
    With TICdef: .MSFilter.Type = daMSFilterMS: .ScanMode = daScanModeFullScan: .Polarity = POLARITY_SETTING: End With
    analysisObj.Chromatograms.AddChromatogram TICdef
  End If
  On Error GoTo 0

  ' -- add EIC for target mass (219.05)
  On Error Resume Next
  Dim EICdef: Set EICdef = CreateObject("DataAnalysis.EICChromatogramDefinition")
  If Err.Number = 0 Then
    With EICdef
      .MSFilter.Type = daMSFilterMS
      .ScanMode      = daScanModeFullScan
      .Polarity      = POLARITY_SETTING
      .Range         = CStr(TARGET_MASS)
      .WidthLeft     = TOL_DA
      .WidthRight    = TOL_DA
    End With
    analysisObj.Chromatograms.AddChromatogram EICdef
  End If
  On Error GoTo 0

  ' -- collect chromatogram data
  Dim n: n = analysisObj.Chromatograms.Count
  ReDim RT(n - 1): ReDim INTENSITY(n - 1): ReDim NAME(n - 1)

  Dim idx: idx = 0
  Dim tempRT, tempIntensity
  Dim chrom
  For Each chrom In analysisObj.Chromatograms
    chrom.ChromatogramData tempRT, tempIntensity
    RT(idx) = tempRT
    INTENSITY(idx) = tempIntensity
    If idx = 0 Then
      NAME(idx) = "TIC"
    ElseIf idx = 1 Then
      NAME(idx) = "EIC@" & TARGET_MASS
    Else
      NAME(idx) = "Chrom" & idx   ' safety for any pre-existing traces
    End If
    idx = idx + 1
  Next

  ' -- find longest row count
  Dim maxRows, arrL
  maxRows = 0
  For idx = 0 To n - 1
    arrL = UBound(RT(idx))
    If arrL > maxRows Then maxRows = arrL
  Next

  ' -- write CSV file
  Dim baseName: baseName = Left(analysisObj.Name, InStrRev(analysisObj.Name, ".") - 1)
  Dim csvPath: csvPath = fso.BuildPath(outDir, baseName & "_EIC_219_05.csv")
  Dim fhOut: Set fhOut = fso.CreateTextFile(csvPath, True)
  
  ' Write header
  Dim header: header = "RT"
  For idx = 0 To n - 1: header = header & DELIM & NAME(idx): Next
  fhOut.WriteLine header

  ' Write data rows
  Dim row, col, line
  For row = 0 To maxRows
    ' RT column (use first chromatogram's RT array—assumed common)
    If row <= UBound(RT(0)) Then
      line = RT(0)(row)
    Else
      line = ""
    End If
    ' add intensity columns
    For col = 0 To n - 1
      If row <= UBound(INTENSITY(col)) Then
        line = line & DELIM & INTENSITY(col)(row)
      Else
        line = line & DELIM & ""
      End If
    Next
    fhOut.WriteLine line
  Next
  fhOut.Close
  exported = exported + 1
Next

MsgBox "Exported " & exported & " CSV file(s) to " & outDir & vbCrLf & "Target mass: " & TARGET_MASS & " ± " & TOL_DA & " Da", vbInformation, "Done"
