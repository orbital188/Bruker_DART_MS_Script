Option Explicit  ' *** Required by DataAnalysis VBScript engine ***

'==============================================
' USER SETTINGS - UPDATED FOR THEORETICAL MATCHES
'==============================================
Const THEORETICAL_MATCHES_DIR = "observed_comparison"  ' Directory containing theoretical matches
Const TOL_DA        = 0.01          ' half-window (Da) - increased for theoretical matches
Const OUT_SUBFOLDER = "EIC_exports_theoretical"  ' Output folder for EIC exports
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
' 2. Load theoretical matches from observed_comparison directory
'==============================================
Sub LoadTheoreticalMatches(theoreticalDir, ByRef dictOut)
  Dim fso: Set fso = CreateObject("Scripting.FileSystemObject")
  If Not fso.FolderExists(theoreticalDir) Then Exit Sub
  
  ' Get all theoretical match files
  Dim folder: Set folder = fso.GetFolder(theoreticalDir)
  Dim file
  For Each file In folder.Files
    If LCase(Right(file.Name, 4)) = ".csv" And InStr(file.Name, "theoretical_matches") > 0 Then
      Call LoadSingleTheoreticalFile(file.Path, dictOut)
    End If
  Next
End Sub

Sub LoadSingleTheoreticalFile(filePath, ByRef dictOut)
  Dim fso: Set fso = CreateObject("Scripting.FileSystemObject")
  If Not fso.FileExists(filePath) Then Exit Sub
  
  Dim fh: Set fh = fso.OpenTextFile(filePath, 1)
  If fh.AtEndOfStream Then fh.Close: Exit Sub
  
  ' Skip header
  Dim header: header = fh.ReadLine
  
  Do Until fh.AtEndOfStream
    Dim ln: ln = fh.ReadLine
    If Len(Trim(ln)) > 0 Then
      Dim parts: parts = Split(Replace(ln, Chr(34), ""), ",")
      If UBound(parts) >= 0 Then
        ' Extract sample name and observed m/z
        Dim sampleName: sampleName = Trim(parts(0))  ' sample_name column
        Dim observedMz: observedMz = Trim(parts(5))  ' observed_mz column
        Dim theoreticalCompound: theoreticalCompound = Trim(parts(1))  ' theoretical_compound column
        
        If IsNumeric(observedMz) Then
          Dim mzVal: mzVal = CDbl(observedMz)
          Dim token: token = ExtractSampleToken(sampleName)
          
          If Not dictOut.Exists(token) Then 
            dictOut.Add token, CreateObject("Scripting.Dictionary")
          End If
          
          ' Use compound name + m/z as key to avoid duplicates
          Dim key: key = theoreticalCompound & "_" & CStr(mzVal)
          If Not dictOut(token).Exists(key) Then 
            dictOut(token).Add key, mzVal
          End If
        End If
      End If
    End If
  Loop
  fh.Close
End Sub

'==============================================
' 3. Numeric-sort helper - safe on 0/1-element arrays
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
' 4. Resolve folders & load theoretical matches
'==============================================
If Application.Analyses.Count = 0 Then MsgBox "Open .d files first", vbExclamation: WScript.Quit
Dim fso: Set fso = CreateObject("Scripting.FileSystemObject")
Dim firstPath: firstPath = Application.Analyses(1).Path  ' 1-based collection
Dim rootDir : rootDir  = fso.GetParentFolderName(firstPath)
Dim outDir  : If OUT_SUBFOLDER = "" Then outDir = rootDir Else outDir = fso.BuildPath(rootDir, OUT_SUBFOLDER): If Not fso.FolderExists(outDir) Then fso.CreateFolder outDir

Dim sampleMz: Set sampleMz = CreateObject("Scripting.Dictionary")
Call LoadTheoreticalMatches(fso.BuildPath(rootDir, THEORETICAL_MATCHES_DIR), sampleMz)
If sampleMz.Count = 0 Then MsgBox "No theoretical matches found in " & THEORETICAL_MATCHES_DIR, vbCritical: WScript.Quit

'==============================================
' 5. Export loop
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

    ' -- add EICs for theoretical matches
    Dim mzKeys: mzKeys = SortedKeys(mzDict)
    Dim i, mzVal, compoundName
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
        ' Use m/z value for naming
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
    Dim csvPath: csvPath = fso.BuildPath(outDir, baseName & "_EICs_theoretical_matches.csv")
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

MsgBox "Exported " & exported & " CSV file(s) to " & outDir & vbCrLf & "Using theoretical matches from " & THEORETICAL_MATCHES_DIR, vbInformation, "Done" 