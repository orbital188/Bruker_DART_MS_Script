# Bruker DART MS Script

This repository contains VBScript utilities for exporting mass spectrometry data from **Bruker DataAnalysis**. The scripts loop through all loaded analyses and create tab-separated value (TSV) files containing chromatogram and spectrum information.

## Usage
1. Open *Bruker DataAnalysis* and load the desired `.d` analyses.
2. Rename `To_TSV_DART_MS_beta8.txt` to `To_TSV_DART_MS_beta8.vbs` and run it from within DataAnalysis.
3. The script generates `<analysis-name>_export.tsv` alongside each loaded analysis containing chromatograms, spectra, and formatted mass lists.

`To_TSV_DART_MS_test_beta9.txt` is a variant with additional features.

## Repository contents
- `To_TSV_DART_MS_beta8.txt` – main VBScript to export data.
- `To_TSV_DART_MS_test_beta9.txt` – test version of the script.
- `Bruker_DART_MS_Script.code-workspace` – VS Code workspace configuration.
