Option Explicit  ' *** Required by DataAnalysis VBScript engine ***

'==============================================
' USER SETTINGS
'==============================================
Const MAP1_FILE     = "compound_matches_summary_with_clusters.csv"
Const MAP2_FILE     = "extra_compound_matches.csv"
Const TOL_DA        = 0.005          ' half-window (Da)
Const OUT_SUBFOLDER = "EIC_exports"  ' "" -> export next to .d files
Const DELIM         = ","           ' CSV delimiter

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
' 2. Detect column indices in CSV header
'==============================================
Sub ParseHeader(header, ByRef cSample, ByRef cMz)
  Dim cells, i, key
  cells = Split(Replace(header, Chr(34), ""), ",")
  cSample = -1: cMz = -1
  For i = 0 To UBound(cells)
    key = Canon(cells(i))
    If cSample = -1 Then If key = "filename" Or key = "file" Or key = "sample" Or key = "samplename" Then cSample = i
    If cMz = -1 Then If key = "mzobserved" Or key = "observedmz" Or key = "obsmz" Or key = "mz" Or key = "m/z" Then cMz = i
  Next
End Sub

'==============================================
' 3. Load mapping CSVs  (sampleToken -> Dict(mz))
'==============================================
Sub LoadMapping(csvPath, ByRef dictOut)
  Dim fso: Set fso = CreateObject("Scripting.FileSystemObject")
  If Not fso.FileExists(csvPath) Then Exit Sub
  Dim fh: Set fh = fso.OpenTextFile(csvPath, 1)
  If fh.AtEndOfStream Then fh.Close: Exit Sub
  Dim header: header = fh.ReadLine
  Dim colS, colMz: Call ParseHeader(header, colS, colMz)
  If colS = -1 Or colMz = -1 Then fh.Close: Exit Sub

  Do Until fh.AtEndOfStream
    Dim ln: ln = fh.ReadLine
    If Len(Trim(ln)) > 0 Then
      Dim parts: parts = Split(Replace(ln, Chr(34), ""), ",")
      If UBound(parts) >= colS And UBound(parts) >= colMz Then
        Dim rawName: rawName = Trim(parts(colS))
        Dim token  : token  = ExtractSampleToken(rawName)
        Dim mzStr  : mzStr  = Trim(parts(colMz))
        If IsNumeric(mzStr) Then
          Dim mzVal: mzVal = CDbl(mzStr)
          If Not dictOut.Exists(token) Then dictOut.Add token, CreateObject("Scripting.Dictionary")
          If Not dictOut(token).Exists(CStr(mzVal)) Then dictOut(token).Add CStr(mzVal), mzVal
        End If
      End If
    End If
  Loop
  fh.Close
End Sub

'==============================================
' 4. Numeric-sort helper - safe on 0/1-element arrays
'==============================================
Function SortedKeys(d)
  Dim arr, i, j, tmp, tmpArr
  
  ' Check if dictionary is empty
  If d.Count = 0 Then
    SortedKeys = Array()  ' Empty array
    Exit Function
  End If
  
  On Error Resume Next
  arr = d.Keys
  If Err.Number <> 0 Then
    SortedKeys = Array()
    Exit Function
  End If
  On Error GoTo 0

  ' If the dictionary has only one key, d.Keys is *not* an array -> wrap it
  If Not IsArray(arr) Then
    ReDim tmpArr(0)
    tmpArr(0) = CStr(arr)
    SortedKeys = tmpArr
    Exit Function
  End If

  ' Check if array is empty
  On Error Resume Next
  If UBound(arr) < 0 Then
    SortedKeys = arr
    Exit Function
  End If
  On Error GoTo 0

  ' Simple in-place bubble sort (small arrays, max tens of m/z values)
  On Error Resume Next
  For i = LBound(arr) To UBound(arr) - 1
    For j = i + 1 To UBound(arr)
      If IsNumeric(arr(i)) And IsNumeric(arr(j)) Then
        If CDbl(arr(i)) > CDbl(arr(j)) Then
          tmp      = arr(i)
          arr(i)   = arr(j)
          arr(j)   = tmp
        End If
      End If
    Next
  Next
  On Error GoTo 0
  SortedKeys = arr
End Function

'==============================================
' 5. Resolve folders & load mappings
'==============================================
If Application.Analyses.Count = 0 Then MsgBox "Open .d files first", vbExclamation: WScript.Quit
Dim fso: Set fso = CreateObject("Scripting.FileSystemObject")
Dim firstPath: firstPath = Application.Analyses(1).Path  ' 1-based collection
Dim rootDir : rootDir  = fso.GetParentFolderName(firstPath)
Dim outDir  : If OUT_SUBFOLDER = "" Then outDir = rootDir Else outDir = fso.BuildPath(rootDir, OUT_SUBFOLDER): If Not fso.FolderExists(outDir) Then fso.CreateFolder outDir

Dim sampleMz: Set sampleMz = CreateObject("Scripting.Dictionary")
Call LoadMapping(fso.BuildPath(rootDir, MAP1_FILE), sampleMz)
Call LoadMapping(fso.BuildPath(rootDir, MAP2_FILE), sampleMz)
If sampleMz.Count = 0 Then MsgBox "Mapping CSVs contain no usable entries", vbCritical: WScript.Quit

'==============================================
' 6. Export loop
'==============================================
Dim analysisObj, exported: exported = 0
For Each analysisObj In Application.Analyses
  Dim token: token = ExtractSampleToken(analysisObj.Name)
  If sampleMz.Exists(token) Then
    Dim mzDict: Set mzDict = sampleMz(token)

    ' -- add TIC
    On Error Resume Next
    Dim TICdef: Set TICdef = CreateObject("DataAnalysis.TICChromatogramDefinition")
    If Err.Number = 0 Then
      With TICdef: .MSFilter.Type = daMSFilterMS: .ScanMode = daScanModeFullScan: .Polarity = POLARITY_SETTING: End With
      analysisObj.Chromatograms.AddChromatogram TICdef
    End If
    On Error GoTo 0

    ' -- add EICs
    Dim mzKeys: mzKeys = SortedKeys(mzDict)
    Dim i, mzVal
    If mzDict.Count > 0 And IsArray(mzKeys) Then
      On Error Resume Next
      If UBound(mzKeys) >= 0 Then
                For i = 0 To UBound(mzKeys)
          If IsNumeric(mzKeys(i)) Then
            mzVal = CDbl(mzKeys(i))
            On Error Resume Next
            Dim EICdef: Set EICdef = CreateObject("DataAnalysis.EICChromatogramDefinition")
            If Err.Number = 0 Then
              With EICdef
                .MSFilter.Type = daMSFilterMS
                .ScanMode      = daScanModeFullScan
                .Polarity      = POLARITY_SETTING
                .Range         = CStr(mzVal)
                .WidthLeft     = TOL_DA
                .WidthRight    = TOL_DA
              End With
              analysisObj.Chromatograms.AddChromatogram EICdef
            End If
            On Error GoTo 0
          End If
        Next
      End If
      On Error GoTo 0
    End If

    ' -- collect arrays
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
      ElseIf IsArray(mzKeys) And UBound(mzKeys) >= 0 And idx - 1 <= UBound(mzKeys) And idx - 1 >= 0 Then
        NAME(idx) = "EIC@" & mzKeys(idx - 1)
      Else
        NAME(idx) = "Chrom" & idx   ' safety for pre-existing traces
      End If
      idx = idx + 1
    Next

    ' -- longest row count
    Dim maxRows, arrL
    maxRows = 0
    For idx = 0 To n - 1
      arrL = UBound(RT(idx))
      If arrL > maxRows Then maxRows = arrL
    Next

    ' -- write CSV
    Dim baseName: baseName = Left(analysisObj.Name, InStrRev(analysisObj.Name, ".") - 1)
    Dim csvPath: csvPath = fso.BuildPath(outDir, baseName & "_EICs_parallel.csv")
    Dim fhOut: Set fhOut = fso.CreateTextFile(csvPath, True)
    Dim header: header = "RT"
    For idx = 0 To n - 1: header = header & DELIM & NAME(idx): Next
    fhOut.WriteLine header

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
  End If ' token present
Next

MsgBox "Exported " & exported & " CSV file(s) to " & outDir, vbInformation, "Done"
