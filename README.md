# Bruker DART MS Script

This repository provides a comprehensive collection of VBScript tools and data analysis scripts for processing and analyzing mass spectrometry data from **Bruker DataAnalysis** software, specifically focused on DART-MS (Direct Analysis in Real Time - Mass Spectrometry) applications.

## Overview

The repository contains tools for:
- Exporting chromatogram and spectrum data from Bruker DataAnalysis
- Batch processing of multiple analyses
- Extracted Ion Chromatogram (EIC) generation and export
- Mass list extraction and analysis
- Compound identification and validation
- Data visualization and plotting
- Theoretical mass calculations and isotopic data

## Repository Contents

### Core VBScript Export Tools (Numbered for Easy Reference)

#### Basic Data Export Scripts
- **`01_Export_Chromatograms_Spectra_MassLists.vbs`** – Main export script that generates TSV files containing chromatograms, spectra, and formatted mass lists for all loaded analyses. Exports retention time vs intensity data and peak-picked mass lists with resolution, signal-to-noise, and FWHM data.
- **`02_Export_Chromatograms_Spectra_MassLists_Copy.vbs`** – Duplicate of the main export script.
- **`03_Export_Chromatograms_Spectra_MassLists_WithRawSpectra.vbs`** – Enhanced version that includes full raw spectrum export (all m/z-intensity pairs) in addition to peak-picked mass lists.

#### EIC (Extracted Ion Chromatogram) Export Scripts
- **`04_Export_TIC_and_EICs_TSV.vbs`** – Exports TIC (Total Ion Chromatogram) plus multiple EICs to TSV format. User-configurable target m/z values with customizable tolerance windows and polarity settings.
- **`05_Export_TIC_and_EICs_CSV_ParallelColumns.vbs`** – Generates parallel-column CSV output with retention time in the first column and each chromatogram (TIC + EICs) in subsequent columns for easy import into Excel/Origin.
- **`06_Export_TIC_and_EICs_TSV_ParallelColumns.vbs`** – Same functionality as CSV version but outputs TSV format for Origin compatibility.

#### Batch Processing Scripts
- **`07_Batch_Export_MassLists_AllAnalyses.vbs`** – Memory-efficient batch processor that exports CSV mass lists for every scan in all open analyses. Creates timestamped folders and processes files sequentially to avoid memory issues.
- **`08_Batch_Export_EICs_AllAnalyses.vbs`** – Batch exporter that generates one parallel-column EIC CSV file per open analysis. Configurable target m/z values and tolerance settings.
- **`09_Export_MassLists_SingleAnalysis.vbs`** – Single-analysis script that creates a timestamped folder containing CSV mass lists for every scan in the current analysis.

#### Advanced EIC Export Scripts
- **`10_Batch_Export_EICs_CompoundMapping.vbs`** – Intelligent batch EIC exporter that reads compound mapping from CSV files and automatically generates EICs for detected compounds. Includes sample token extraction and compound matching logic.
- **`11_Batch_Export_EICs_TheoreticalMatches.vbs`** – Updated version for theoretical compound matches with increased tolerance (0.01 Da) and support for observed comparison data.
- **`12_Batch_Export_EICs_TheoreticalMatches_Enhanced.vbs`** – Enhanced version that uses compound names + m/z as unique keys to avoid duplicates in theoretical match processing.
- **`13_Batch_Export_EICs_SelectedCompounds.vbs`** – Selected version of the EIC batch export script with compound mapping from specific CSV files.

### Data Files and Analysis Results

#### Reference Data
- **`NIST_Atomic_Isotopic_Database.csv`** – Comprehensive database of atomic and isotopic data including element symbols, isotope masses, abundances, and valencies. Based on NIST standards for molecular formula calculations and isotopic pattern simulations.
- **`NIST_Atomic_Isotopic_Data_Documentation.txt`** – Detailed documentation of the isotopic data sources, including NIST references and version information.

#### Theoretical Mass Calculations
- **`Theoretical_MZ_Calculations_Final.csv`** – Final theoretical m/z values for compounds including protonated, deprotonated, and isotopic variants. Contains molecular formulas, mass types, and calculation sources.
- **`Theoretical_MZ_PositiveMode_Cleaned.csv`** – Cleaned theoretical m/z data for positive mode analysis.
- **`Theoretical_MZ_PositiveMode_Cleaned_NoMZ.csv`** – Theoretical compound data without m/z values.

#### Fragment Ion Data
- **`Fragment_Ions_PositiveMode_Comprehensive.csv`** – Comprehensive fragment ion data for positive mode analysis.
- **`Fragment_Ions_PositiveMode_250803_v1.csv`** – Fragment ion data for positive mode analysis from August 25, 2023.
- **`Fragment_Ions_PositiveMode_250803_v1_CorrectedMZ.csv`** – Fragment ion data with corrected m/z values.
- **`Fragment_Ions_PositiveMode_250803_v1_CorrectedMZ_Fixed.csv`** – Fragment ion data with corrected m/z values (fixed version).
- **`Fragment_Ions_PositiveMode_250803_v1_CorrectedMZ_Validated.csv`** – Validated fragment ion data with corrected m/z values.
- **`Fragment_Ions_PositiveMode_250803_v1_CorrectedMZ_Validated_Fixed.csv`** – Final validated and fixed fragment ion data.
- **`Fragment_Ions_PositiveMode_250803_v1_WithMZ.csv`** – Fragment ion data with m/z values included.

#### Compound Analysis Results
- **`Compound_Matches_Summary_WithClusters.csv`** – Summary of compound matches across multiple samples with clustering information, including theoretical vs observed m/z values and intensity data.
- **`Extra_Compound_Matches.csv`** – Additional compound matches not included in the main summary.
- **`MZ_Matches_Detailed_Analysis.csv`** – Detailed m/z matching results with comprehensive metadata.
- **`MZ_Matches_Summary.csv`** – Summarized m/z matching results.
- **`Compound_Validation_Report.csv`** – Validation report for compound identification and matching.

### Analysis and Visualization Tools

#### Python Scripts
- **`Plot_Compounds_Validation_Analysis.py`** – Clean, modular Python script for generating sample vs reference plots for validated compounds. Features include peak detection, compound mapping, and customizable plotting configurations for compounds like Oleic acid, TOP, TOPO, and TOPSe.

### Configuration and Workspace Files
- **`Bruker_DART_MS_Script.code-workspace`** – VS Code workspace definition for the project.
- **`README.md`** – This comprehensive documentation file.

## Usage Instructions

### Basic Export
1. Open *Bruker DataAnalysis* and load the desired `.d` analyses.
2. Choose the appropriate VBScript file (numbered 01-13) based on your needs.
3. Run the script from within DataAnalysis.
4. Output files will be generated in the parent folders of loaded analyses.

### EIC Export
1. Use scripts 04-06 for basic EIC export or scripts 10-13 for advanced compound mapping.
2. Modify the target m/z values in the script header section.
3. Adjust tolerance settings and polarity as needed.
4. Run the script to generate TIC + EIC chromatograms.
5. Choose between TSV or CSV output formats based on your analysis software.

### Batch Processing
1. Open multiple analyses in DataAnalysis.
2. Use scripts 07-08 for batch mass list export or scripts 10-13 for batch EIC export.
3. Run batch scripts to process all open analyses simultaneously.
4. Check output folders for timestamped results.

### Compound Analysis
1. Use scripts 10-13 with your CSV data files for compound mapping.
2. Ensure proper file naming conventions for sample identification.
3. Review validation reports for compound identification accuracy.

## File Naming Conventions

- **VBScript files**: Numbered 01-13 for easy reference and logical workflow
- **Timestamped folders**: `YYMMDD_<SampleName>_mass_list_analysis_HHMM`
- **Export files**: `<analysis-name>_export.tsv` or `<sample>_EICs.csv`
- **Mass lists**: `Scan_<number>.csv` with zero-padded scan numbers

## Dependencies

- **Bruker DataAnalysis** software for VBScript execution
- **Python 3.x** with packages: pymzml, pandas, numpy, scipy, matplotlib (for plotting scripts)
- **CSV/TSV** compatible software for data analysis (Excel, Origin, etc.)

## Data Sources

- **Isotopic data**: Based on NIST Atomic Weights and Isotopic Compositions (version 3.0)
- **Theoretical masses**: Calculated using standard atomic weights and isotopic abundances
- **Compound identification**: Based on observed m/z values and theoretical calculations

## Notes

- All VBScript files now have descriptive names and are numbered for easy reference
- Memory management is critical for large datasets; use batch processing scripts for multiple analyses
- Tolerance settings can be adjusted based on instrument resolution and analysis requirements
- Output formats are optimized for compatibility with common data analysis software
- The new naming convention makes it easy to identify the right tool for your specific needs

## Support

For questions or issues with the scripts, refer to the Bruker DataAnalysis documentation or consult with your mass spectrometry facility staff.

