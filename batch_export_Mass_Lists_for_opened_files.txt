'──────────────────────────────────────────────────────────────────────────────
'  Batch Mass-List exporter – memory-safe / no DoEvents
'──────────────────────────────────────────────────────────────────────────────
Option Explicit

'----- helper: zero-pad --------------------------------------------------------
Function Pad(n, w): Pad = Right(String(w, "0") & CStr(n), w): End Function

'----- export ONE analysis -----------------------------------------------------
Sub ExportMassLists(ana)

    '1. create YYMMDD_<Sample>_mass_list_analysis_HHMM folder
    Dim dt: dt = Now
    Dim stamp: stamp = Right(Year(dt),2) & Pad(Month(dt),2) & Pad(Day(dt),2)
    Dim tcode: tcode = Pad(Hour(dt),2) & Pad(Minute(dt),2)

    Dim fso:  Set fso = CreateObject("Scripting.FileSystemObject")
    Dim rawName: rawName = fso.GetBaseName(ana.Path)
    Dim outDir: outDir  = fso.GetParentFolderName(ana.Path) & "\" & _
                          stamp & "_" & rawName & "_mass_list_analysis_" & tcode
    If Not fso.FolderExists(outDir) Then fso.CreateFolder outDir

    '2. loop over all raw scans
    Dim nScans: nScans = ana.Properties.SpectraCount
    Dim digits: digits = Len(CStr(nScans))

    Dim scanNo, lastIdx, spec, csv
    For scanNo = 1 To nScans

        '--- add raw scan ───────────────────────────────────────────────
        ana.Spectra.Add scanNo, daAuto
        lastIdx = ana.Spectra.Count
        Set spec = ana.Spectra(lastIdx)

        '--- peak-pick so Mass List exists ─────────────────────────────
        spec.MassListFind spec.FirstMass, spec.LastMass

        '--- export Mass List ──────────────────────────────────────────
        csv = outDir & "\Scan_" & Pad(scanNo, digits) & ".csv"
        spec.ExportMassList csv, daCSV

        '--- free memory immediately ──────────────────────────────────
        spec.MassListClear           'clear peaks
        ana.Spectra.Delete lastIdx   'remove spectrum node
        Set spec = Nothing
    Next
End Sub
'======================  BATCH DRIVER =========================================
Dim ana, done: done = 0
For Each ana In Application.Analyses
    ExportMassLists ana
    done = done + 1
Next

MsgBox "Export complete for " & done & " analyses.", vbInformation, "Mass-List batch"
'──────────────────────────────────────────────────────────────────────────────
