'=================================================================
'  Mass-list export for every scan
'  Folder name: YYMMDD_<SampleName>_mass_list_analysis_HHMM
'=================================================================
Option Explicit

'----- helper: zero-padding --------------------------------------
Function Pad(n, width)
  Pad = Right(String(width, "0") & CStr(n), width)
End Function

'----- date/time & sample info -----------------------------------
Dim dt      : dt      = Now
Dim stamp   : stamp   = Right(Year(dt),2) & Pad(Month(dt),2) & Pad(Day(dt),2)   'YYMMDD
Dim tcode   : tcode   = Pad(Hour(dt),2) & Pad(Minute(dt),2)                     'HHMM

Dim rawName : rawName = Analysis.Name                                           'e.g. “PbSe1.d”
If InStrRev(rawName, ".") > 0 Then rawName = Left(rawName, InStrRev(rawName,".")-1)

Dim folderName : folderName = stamp & "_" & rawName & "_mass_list_analysis_" & tcode

'----- make output folder next to the *.d directory ---------------
Dim fso        : Set fso = CreateObject("Scripting.FileSystemObject")
Dim parentDir  : parentDir = fso.GetParentFolderName(Analysis.Path)
Dim outDir     : outDir   = parentDir & "\" & folderName
If Not fso.FolderExists(outDir) Then fso.CreateFolder outDir

'----- find total scans, work-out padding width -------------------
Dim nScans : nScans = Analysis.Properties.SpectraCount
Dim digits : digits = Len(CStr(nScans))        '3 digits for 357 scans

'----- loop over each raw scan ------------------------------------
Dim scanNo
For scanNo = 1 To nScans
    '1) copy into Compound Spectra
    Analysis.Spectra.Add scanNo, daAuto
    
    '2) grab the just-added spectrum (it is last in the collection)
    Dim spec : Set spec = Analysis.Spectra(Analysis.Spectra.Count)

    '3) peak-pick so Mass List is populated
    spec.MassListFind spec.FirstMass, spec.LastMass

    '4) export Mass List
    Dim csvPath : csvPath = outDir & "\Scan_" & Pad(scanNo, digits) & ".csv"
    spec.ExportMassList csvPath, daCSV
Next

MsgBox nScans & " Mass Lists exported to:" & vbCrLf & outDir, vbInformation, "Finished"
'=================================================================
