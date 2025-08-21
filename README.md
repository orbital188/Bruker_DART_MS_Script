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
- ChemCalc API integration for molecular formula analysis
- Advanced compound analysis and validation

## Repository Structure

The repository is organized into numbered folders for easy navigation and logical workflow:

### 01_VBScript_Export_Tools/
Core VBScript tools for data export from Bruker DataAnalysis (numbered for easy reference):

#### Basic Data Export Scripts
1. **`01_Export_Chromatograms_Spectra_MassLists.vbs`** - Basic export of chromatograms, spectra, and mass lists to TSV format
2. **`02_Export_Chromatograms_Spectra_MassLists_Copy.vbs`** - Copy of the basic export script for backup purposes
3. **`03_Export_Chromatograms_Spectra_MassLists_WithRawSpectra.vbs`** - Enhanced export including raw spectrum data and additional metadata

#### EIC Export Scripts
4. **`04_Export_TIC_and_EICs_TSV.vbs`** - Export Total Ion Chromatogram (TIC) and Extracted Ion Chromatograms (EICs) to TSV format
5. **`05_Export_TIC_and_EICs_CSV_ParallelColumns.vbs`** - Export TIC and EICs to CSV format with parallel column layout
6. **`06_Export_TIC_and_EICs_TSV_ParallelColumns.vbs`** - Export TIC and EICs to TSV format with parallel column layout

#### Batch Processing Scripts
7. **`07_Batch_Export_MassLists_AllAnalyses.vbs`** - Batch export mass lists from all opened analyses
8. **`08_Batch_Export_EICs_AllAnalyses.vbs`** - Batch export EICs from all opened analyses
9. **`09_Export_MassLists_SingleAnalysis.vbs`** - Export mass lists from a single selected analysis

#### Advanced EIC Export Scripts
10. **`10_Batch_Export_EICs_CompoundMapping.vbs`** - Advanced EIC export with compound mapping and identification
11. **`11_Batch_Export_EICs_TheoreticalMatches.vbs`** - EIC export with theoretical mass-to-charge ratio matching
12. **`12_Batch_Export_EICs_TheoreticalMatches_Enhanced.vbs`** - Enhanced version with improved theoretical matching algorithms
13. **`13_Batch_Export_EICs_SelectedCompounds.vbs`** - Selective EIC export for specific compounds of interest

### 02_Python_Analysis_Scripts/
Python tools for data analysis and visualization:
- **`download_chemcalc_data.py`** - Automated ChemCalc API data downloader with rate limiting and error handling
- **`plot_compounds_json.py`** - Advanced compound analysis tool with automated detection and validation using JSON data
- **`Plot_Compounds_Validation_Analysis.py`** - Python script for plotting and analyzing compound validation data

### 03_Reference_Data/
Reference databases and calculated theoretical data:
- **`merged_chemcalc_data.json`** - Comprehensive JSON database with isotopic distribution data for 54 compounds, generated from ChemCalc API queries
- **`NIST_Atomic_Isotopic_Database.csv`** - Comprehensive database of atomic masses and isotopic abundances from NIST
- **`NIST_Atomic_Isotopic_Data_Documentation.txt`** - Documentation and reference information for the atomic isotopic database
- **`Theoretical_MZ_Calculations_Final.csv`** - Final theoretical mass-to-charge ratio calculations for compounds
- **`Theoretical_MZ_PositiveMode_Cleaned.csv`** - Cleaned theoretical m/z data for positive mode analysis
- **`Theoretical_MZ_PositiveMode_Cleaned_NoMZ.csv`** - Theoretical calculations without m/z values for processing

### 04_Input_Data/
Input files for analysis:
- **`dart_td_ms_positive_comprehensive.csv`** - Input file containing compound names and molecular formulas for ChemCalc API analysis

### 05_Configuration_Files/
Project configuration files:
- **`Bruker_DART_MS_Script.code-workspace`** - VS Code workspace configuration file for the project

## Usage Instructions

### Basic Data Export
1. Open Bruker DataAnalysis software
2. Load your analysis files
3. Navigate to `01_VBScript_Export_Tools/` and run the appropriate VBScript based on your export needs:
   - Use scripts 01-03 for basic chromatogram and spectrum export
   - Use scripts 04-06 for EIC-specific exports
   - Use scripts 07-09 for batch processing

### Advanced Analysis
1. Use scripts 10-13 in `01_VBScript_Export_Tools/` for compound-specific EIC analysis
2. Run the Python scripts in `02_Python_Analysis_Scripts/` for data visualization and validation
3. Utilize the ChemCalc integration and reference data in `03_Reference_Data/` for molecular formula analysis

### ChemCalc Integration Workflow
1. Prepare your compound list in `04_Input_Data/dart_td_ms_positive_comprehensive.csv`
2. Run `02_Python_Analysis_Scripts/download_chemcalc_data.py` to fetch isotopic distribution data
3. Use `02_Python_Analysis_Scripts/plot_compounds_json.py` for advanced compound analysis
4. Analyze results using the generated JSON database in `03_Reference_Data/`

## File Organization

The repository is organized into numbered folders for logical workflow progression:

### Folder Structure Overview
- **01_VBScript_Export_Tools/**: VBScript automation tools for Bruker DataAnalysis
  - **01-03**: Basic export functionality
  - **04-06**: EIC export with different formats
  - **07-09**: Batch processing capabilities
  - **10-13**: Advanced compound analysis features
- **02_Python_Analysis_Scripts/**: Python tools for data analysis and visualization
- **03_Reference_Data/**: Reference databases, theoretical calculations, and generated results
- **04_Input_Data/**: Input files for analysis workflows
- **05_Configuration_Files/**: Project configuration and workspace files

### Recommended Workflow
1. **Data Export**: Use VBScripts in `01_VBScript_Export_Tools/` to extract data from Bruker DataAnalysis
2. **Data Analysis**: Process exported data using Python scripts in `02_Python_Analysis_Scripts/`
3. **Reference Lookup**: Utilize databases and calculations in `03_Reference_Data/` for compound identification
4. **Input Preparation**: Prepare input files in `04_Input_Data/` for batch processing

## Requirements

- **Bruker DataAnalysis** software (for VBScript execution)
- **Python 3.x** (for Python analysis scripts)
- **Required Python packages**: pandas, matplotlib, numpy, requests, json
- **Internet connection** (for ChemCalc API integration)

## Installation

1. Clone or download this repository
2. Ensure Bruker DataAnalysis is installed and accessible
3. Install required Python packages: `pip install pandas matplotlib numpy requests`
4. Configure your workspace in VS Code using `05_Configuration_Files/Bruker_DART_MS_Script.code-workspace`
5. Place your input data files in `04_Input_Data/` for analysis

## Notes

- VBScripts in `01_VBScript_Export_Tools/` must be run within Bruker DataAnalysis software
- Python scripts in `02_Python_Analysis_Scripts/` can be run independently for data analysis
- The ChemCalc integration requires internet connectivity
- All scripts include error handling and user feedback
- The numbered folder structure provides a logical workflow progression from data export to analysis
- Reference data in `03_Reference_Data/` is continuously updated as analyses are performed

## Support

For questions or issues with the scripts, refer to the Bruker DataAnalysis documentation or consult with your mass spectrometry facility staff.

