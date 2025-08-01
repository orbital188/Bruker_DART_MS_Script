# Bruker DART MS Script

This repository provides a small collection of VBScript tools for exporting chromatogram and spectrum data from **Bruker DataAnalysis**.  Each script can be renamed with a `.vbs` extension and executed inside DataAnalysis.

## Usage
1. Open *Bruker DataAnalysis* and load the desired `.d` analyses.
2. Rename `To_TSV_DART_MS_beta8.txt` to `To_TSV_DART_MS_beta8.vbs` and run it from within DataAnalysis.
3. The script generates `<analysis-name>_export.tsv` next to each loaded analysis.  Files contain chromatograms, spectra and formatted mass lists.

`To_TSV_DART_MS_test_beta9.txt` is a variant of the above script that also exports the full raw spectrum for each scan.

## Repository contents
- `Bruker_DART_MS_Script.code-workspace` – VS Code workspace definition.
- `To_TSV_DART_MS_beta8.txt` – export chromatograms, spectra and mass lists for all loaded analyses.
- `To_TSV_DART_MS_beta8 - Copy.txt` – duplicate of the above script.
- `To_TSV_DART_MS_test_beta9.txt` – adds export of full raw spectra in addition to mass lists.
- `EIC_export_scripts.txt` – exports TIC plus multiple extracted ion chromatograms (EICs) to a TSV file along with spectra and mass lists.
- `EIC_export_csv_parallel.txt` – writes TIC and EIC traces in parallel columns to a CSV file for easy import into spreadsheets.
- `EIC_export_tsv_parallel.txt` – same as the CSV version but outputs a TSV file.
- `batch_export_Mass_Lists_for_opened_files.txt` – batch routine that walks all open analyses and saves a CSV mass list for each raw scan in memory‑efficient manner.
- `batched_EIC_export_scripts` – batch exporter that writes one parallel‑column EIC CSV per open analysis.
- `mass_lists_for_every_scan.txt` – single‑analysis script creating a time‑stamped folder containing a CSV mass list for every scan.

