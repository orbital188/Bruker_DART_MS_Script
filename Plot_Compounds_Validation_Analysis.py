#!/usr/bin/env python3
"""
Clean Compound Plotting Script
Generates sample vs reference plots for validated compounds with corrected peak detection.

Features:
- Clean, modular design following clean code principles
- Easy configuration at the top of the file
- Scalable for adding new compounds and samples
- Beginner-friendly with clear documentation
- Easy to maintain and update


Date: [Current Date]
"""

import pymzml
import pandas as pd
import numpy as np
from scipy.signal import find_peaks
import matplotlib.pyplot as plt
import os
import warnings
from typing import Dict, List, Optional, Tuple, Any
warnings.filterwarnings('ignore')

# =============================================================================
# CONFIGURATION SECTION - Easy to modify for users
# =============================================================================

# Input/Output Configuration
INPUT_DIRS = {
    'mzml_files': 'mzml_raw_files',
    'reference_data': '.',  # Directory containing reference CSV files
    'analysis_results': '.'  # Directory containing analysis result CSV files
}

OUTPUT_DIRS = {
    'plots': 'clean_compound_plots',
    'logs': 'plotting_logs'
}

# Analysis Result Files
ANALYSIS_FILES = {
    'adjusted_compounds': 'adjusted_compound_analysis_results.csv',
    'topse_compounds': 'topse_optimal_rt_results.csv'
}

# Compound Configuration
COMPOUNDS = {
    'Oleic_acid': {
        'formula': 'C18H35O2',
        'reference_file': 'C18H35O2.csv',
        'color': '#1f77b4',  # Blue
        'target_mz': 283.2637,
        'validation_source': 'adjusted_compounds'
    },
    'TOP': {
        'formula': 'C24H52P',
        'reference_file': 'C24H52P.csv',
        'color': '#ff7f0e',  # Orange
        'target_mz': 371.3807,
        'validation_source': 'adjusted_compounds'
    },
    'TOPO': {
        'formula': 'C24H52OP',
        'reference_file': 'C24H52OP.csv',
        'color': '#2ca02c',  # Green
        'target_mz': 387.3756,
        'validation_source': 'adjusted_compounds'
    },
    'TOPSe': {
        'formula': 'C24H52PSe',
        'reference_file': 'C24H52PSe.csv',
        'color': '#d62728',  # Red
        'target_mz': 451.2973,
        'validation_source': 'topse_compounds'
    }
}

# Sample Configuration
SAMPLE_MAPPING = {
    'PbSe1_Pos_1.mzML': 'PbSe1_Pos_1',
    'PbSe1_Pos_2.mzML': 'PbSe1_Pos_2',
    'PbSe1_Pos_3.mzML': 'PbSe1_Pos_3',
    'PbSe1_Pos_4.mzML': 'PbSe1_Pos_4',
    'PbSe1_Pos_5.mzML': 'PbSe1_Pos_5',
    'PbSe1_Pos_6.mzML': 'PbSe1_Pos_6',
    'PbSe7_Pos_1.mzML': 'PbSe7_Pos_1',
    'PbSe7_Pos_2.mzML': 'PbSe7_Pos_2',
    'PbSe7_Pos_3.mzML': 'PbSe7_Pos_3',
    'PbSe10_Pos_1.mzML': 'PbSe10_Pos_1',
    'PbSe10_Pos_2.mzML': 'PbSe10_Pos_2',
    'PbSe10_Pos_3.mzML': 'PbSe10_Pos_3'
}

# Plotting Configuration
PLOT_CONFIG = {
    'figure_size': (12, 8),
    'dpi': 300,
    'mz_window': 2.0,  # ±2 Da around reference m/z range
    'peak_detection_tolerance': 0.1,  # Da tolerance for peak finding
    'min_relative_intensity': 1.0,  # Only show reference peaks above 1%
    'grid_alpha': 0.3,
    'sample_line_alpha': 0.7,
    'sample_line_width': 1.5,
    'peak_marker_size': 100,
    'info_box_position': (0.98, 0.65)
}

# Validation Configuration
VALIDATION_CONFIG = {
    'min_intensity_threshold': 0,  # No minimum intensity limit
    'mz_tolerance': 0.1,  # Da tolerance for m/z matching
    'intensity_tolerance': 0.3,  # Relative intensity tolerance
    'min_isotope_matches': 3  # Minimum isotope peaks to match
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

def create_directories() -> None:
    """Create necessary output directories."""
    for directory in OUTPUT_DIRS.values():
        os.makedirs(directory, exist_ok=True)

def load_reference_data(csv_file: str) -> Dict[str, np.ndarray]:
    """Load reference isotope data from CSV file.
    
    Args:
        csv_file: Path to reference CSV file
        
    Returns:
        Dictionary with 'mz' and 'intensity' arrays
    """
    try:
        file_path = os.path.join(INPUT_DIRS['reference_data'], csv_file)
        df = pd.read_csv(file_path)
        return {
            'mz': df['mz'].values,
            'intensity': df['intensity'].values
        }
    except Exception as e:
        print(f"Warning: Could not load {csv_file}: {e}")
        return {'mz': np.array([]), 'intensity': np.array([])}

def safe_rt_extraction(spectrum) -> Optional[float]:
    """Safely extract retention time from spectrum.
    
    Args:
        spectrum: pymzml spectrum object
        
    Returns:
        Retention time in seconds or None if extraction fails
    """
    try:
        rt_value = spectrum.scan_time
        if isinstance(rt_value, (tuple, list)) and len(rt_value) > 0:
            return rt_value[0]
        elif isinstance(rt_value, (int, float)):
            return rt_value
        return None
    except:
        return None

# =============================================================================
# CORE ANALYSIS CLASSES
# =============================================================================

class CompoundDataLoader:
    """Handles loading and validation of compound detection results."""
    
    def __init__(self):
        self.validated_results = {}
        self._load_all_results()
    
    def _load_all_results(self) -> None:
        """Load all validated detection results from analysis files."""
        # Load adjusted compound analysis (Oleic_acid, TOP, TOPO)
        self._load_adjusted_compounds()
        
        # Load TOPSe optimal RT results
        self._load_topse_compounds()
    
    def _load_adjusted_compounds(self) -> None:
        """Load results from adjusted compound analysis."""
        try:
            file_path = os.path.join(INPUT_DIRS['analysis_results'], 
                                   ANALYSIS_FILES['adjusted_compounds'])
            df = pd.read_csv(file_path)
            
            for _, row in df.iterrows():
                sample_name = row['Sample']
                self.validated_results[sample_name] = {}
                
                for compound in ['Oleic_acid', 'TOP', 'TOPO']:
                    if pd.notna(row[f'{compound}_scan']) and row[f'{compound}_validated']:
                        self.validated_results[sample_name][compound] = {
                            'scan': int(row[f'{compound}_scan']),
                            'rt': row[f'{compound}_rt'],
                            'mz': row[f'{compound}_mz'],
                            'intensity': row[f'{compound}_intensity'],
                            'validated': True
                        }
                    else:
                        self.validated_results[sample_name][compound] = None
                        
        except Exception as e:
            print(f"Warning: Could not load {ANALYSIS_FILES['adjusted_compounds']}: {e}")
    
    def _load_topse_compounds(self) -> None:
        """Load TOPSe optimal RT results."""
        try:
            file_path = os.path.join(INPUT_DIRS['analysis_results'], 
                                   ANALYSIS_FILES['topse_compounds'])
            df = pd.read_csv(file_path)
            
            for _, row in df.iterrows():
                sample_name = row['Sample']
                if sample_name not in self.validated_results:
                    self.validated_results[sample_name] = {}
                
                if pd.notna(row['TOPSe_optimal_scan']) and row['TOPSe_validated']:
                    self.validated_results[sample_name]['TOPSe'] = {
                        'scan': int(row['TOPSe_optimal_scan']),
                        'rt': row['TOPSe_optimal_rt'],
                        'mz': row['TOPSe_optimal_mz'],
                        'intensity': row['TOPSe_optimal_intensity'],
                        'validated': True
                    }
                else:
                    self.validated_results[sample_name]['TOPSe'] = None
                    
        except Exception as e:
            print(f"Warning: Could not load {ANALYSIS_FILES['topse_compounds']}: {e}")

class PeakDetector:
    """Handles peak detection and correction logic."""
    
    @staticmethod
    def find_true_peak_maximum(mz_array: np.ndarray, 
                              intensity_array: np.ndarray, 
                              target_mz: float, 
                              tolerance: float = 0.1) -> Optional[Dict[str, Any]]:
        """Find the true peak maximum within the tolerance window.
        
        Args:
            mz_array: Array of m/z values
            intensity_array: Array of intensity values
            target_mz: Target m/z value to search around
            tolerance: M/z tolerance window in Da
            
        Returns:
            Dictionary with peak information or None if no peak found
        """
        # Find region around target m/z
        mask = (mz_array >= target_mz - tolerance) & (mz_array <= target_mz + tolerance)
        
        if not np.any(mask):
            return None
        
        region_mz = mz_array[mask]
        region_intensity = intensity_array[mask]
        
        # Use scipy find_peaks to locate actual peaks
        if len(region_intensity) > 3:
            peak_indices, _ = find_peaks(
                region_intensity, 
                height=np.max(region_intensity) * 0.1,
                distance=3,
                prominence=np.max(region_intensity) * 0.05
            )
            
            if len(peak_indices) > 0:
                # Find the highest peak
                best_peak_idx = peak_indices[np.argmax(region_intensity[peak_indices])]
                true_peak_mz = region_mz[best_peak_idx]
                true_peak_intensity = region_intensity[best_peak_idx]
                
                return {
                    'mz': true_peak_mz,
                    'intensity': true_peak_intensity,
                    'corrected': True
                }
        
        # Fallback: use simple maximum
        max_idx = np.argmax(region_intensity)
        return {
            'mz': region_mz[max_idx],
            'intensity': region_intensity[max_idx],
            'corrected': False
        }

class SpectrumExtractor:
    """Handles extraction of spectrum data from mzML files."""
    
    def __init__(self, mzml_dir: str):
        self.mzml_dir = mzml_dir
    
    def extract_spectrum_at_scan(self, mzml_file: str, target_scan: int) -> Optional[Dict[str, Any]]:
        """Extract spectrum data at specific scan number.
        
        Args:
            mzml_file: Path to mzML file
            target_scan: Target scan number
            
        Returns:
            Dictionary with spectrum data or None if not found
        """
        try:
            run = pymzml.run.Reader(mzml_file)
            
            for spectrum in run:
                if spectrum.ms_level == 1:
                    scan_num = self._extract_scan_number(spectrum.ID)
                    
                    if scan_num == target_scan:
                        rt = safe_rt_extraction(spectrum)
                        
                        return {
                            'mz_array': spectrum.mz,
                            'intensity_array': spectrum.i,
                            'rt': rt,
                            'scan_id': scan_num
                        }
            
            return None
            
        except Exception as e:
            print(f"Error reading {mzml_file}: {e}")
            return None
    
    def _extract_scan_number(self, scan_id) -> Optional[int]:
        """Extract scan number from spectrum ID."""
        if isinstance(scan_id, int):
            return scan_id
        
        if isinstance(scan_id, str):
            try:
                return int(scan_id.split('scan=')[-1])
            except:
                return None
        
        return None

class PlotGenerator:
    """Handles the generation of compound vs reference plots."""
    
    def __init__(self, compound_config: Dict[str, Any], 
                 plot_config: Dict[str, Any]):
        self.compound_config = compound_config
        self.plot_config = plot_config
        self.reference_data = load_reference_data(compound_config['reference_file'])
    
    def generate_plot(self, sample_name: str, 
                     detection_info: Dict[str, Any],
                     spectrum_data: Dict[str, Any],
                     corrected_peak: Dict[str, Any]) -> str:
        """Generate a single compound vs reference plot.
        
        Args:
            sample_name: Name of the sample
            detection_info: Detection information for the compound
            spectrum_data: Spectrum data at optimal scan
            corrected_peak: Corrected peak information
            
        Returns:
            Path to saved plot file
        """
        fig, ax = plt.subplots(figsize=self.plot_config['figure_size'])
        
        # Prepare data for plotting
        plot_data = self._prepare_plot_data(spectrum_data, corrected_peak)
        
        # Create the plot
        self._plot_reference_data(ax)
        self._plot_sample_data(ax, plot_data)
        self._highlight_corrected_peak(ax, corrected_peak)
        
        # Format the plot
        self._format_plot(ax, sample_name, detection_info, corrected_peak)
        
        # Save the plot
        filename = self._save_plot(sample_name)
        plt.close()
        
        return filename
    
    def _prepare_plot_data(self, spectrum_data: Dict[str, Any], 
                          corrected_peak: Dict[str, Any]) -> Dict[str, np.ndarray]:
        """Prepare data for plotting."""
        # Determine m/z range based on reference data
        ref_mz_min = np.min(self.reference_data['mz'])
        ref_mz_max = np.max(self.reference_data['mz'])
        center_mz = (ref_mz_min + ref_mz_max) / 2
        mz_range = max(self.plot_config['mz_window'], 
                      (ref_mz_max - ref_mz_min) / 2 + 1)
        
        # Extract sample data in the m/z range
        mask = (spectrum_data['mz_array'] >= center_mz - mz_range) & \
               (spectrum_data['mz_array'] <= center_mz + mz_range)
        
        sample_mz = spectrum_data['mz_array'][mask]
        sample_intensity = spectrum_data['intensity_array'][mask]
        
        # Normalize intensities
        corrected_intensity = corrected_peak['intensity']
        sample_intensity_norm = (sample_intensity / corrected_intensity) * 100
        
        return {
            'mz': sample_mz,
            'intensity': sample_intensity_norm,
            'center_mz': center_mz,
            'mz_range': mz_range
        }
    
    def _plot_reference_data(self, ax: plt.Axes) -> None:
        """Plot reference isotope data."""
        ref_intensity_norm = (self.reference_data['intensity'] / 
                             np.max(self.reference_data['intensity'])) * 100
        
        # Filter out low intensity reference points
        significant_mask = ref_intensity_norm > self.plot_config['min_relative_intensity']
        ref_mz_filtered = self.reference_data['mz'][significant_mask]
        ref_intensity_filtered = ref_intensity_norm[significant_mask]
        
        # Plot reference data with black color
        ref_stems = ax.stem(ref_mz_filtered, ref_intensity_filtered, 
                           linefmt='k-', markerfmt='ko', basefmt=' ',
                           label=f'{self.compound_config["formula"]} Reference')
        
        # Set alpha for stem plot elements
        for artist in ref_stems:
            if hasattr(artist, 'set_alpha'):
                artist.set_alpha(0.8)
    
    def _plot_sample_data(self, ax: plt.Axes, plot_data: Dict[str, np.ndarray]) -> None:
        """Plot sample data."""
        ax.plot(plot_data['mz'], plot_data['intensity'], 
                color=self.compound_config['color'], 
                linewidth=self.plot_config['sample_line_width'], 
                alpha=self.plot_config['sample_line_alpha'],
                label=f'Sample Data (Peak = 100%)')
    
    def _highlight_corrected_peak(self, ax: plt.Axes, corrected_peak: Dict[str, Any]) -> None:
        """Highlight the corrected peak with a red star."""
        ax.scatter(corrected_peak['mz'], 100, 
                  color='red', s=self.plot_config['peak_marker_size'], 
                  marker='*', zorder=5,
                  label=f'Corrected Peak: {corrected_peak["mz"]:.4f} m/z')
    
    def _format_plot(self, ax: plt.Axes, sample_name: str, 
                    detection_info: Dict[str, Any], 
                    corrected_peak: Dict[str, Any]) -> None:
        """Format the plot with labels, title, and grid."""
        # Labels and title
        ax.set_xlabel('m/z', fontsize=12, fontweight='bold')
        ax.set_ylabel('Relative Intensity (Corrected Peak = 100%)', fontsize=12, fontweight='bold')
        
        rt_display = f"RT: {detection_info['rt']:.1f}s" if detection_info['rt'] is not None else f"Scan: {detection_info['scan']}"
        correction_status = "CORRECTED" if corrected_peak['corrected'] else "VERIFIED"
        
        ax.set_title(f'{sample_name}: {self.compound_config["formula"]} vs Reference\n'
                    f'{correction_status} {rt_display} | Scan {detection_info["scan"]}', 
                    fontsize=14, fontweight='bold')
        
        # Grid and limits
        ax.grid(True, alpha=self.plot_config['grid_alpha'])
        ax.legend(loc='upper right')
        
        # Add info box
        self._add_info_box(ax, detection_info, corrected_peak)
    
    def _add_info_box(self, ax: plt.Axes, detection_info: Dict[str, Any], 
                     corrected_peak: Dict[str, Any]) -> None:
        """Add information box to the plot."""
        info_text = f"{'CORRECTED' if corrected_peak['corrected'] else 'VERIFIED'} DETECTION\n"
        info_text += f"Scan: {detection_info['scan']}\n"
        info_text += f"RT: {detection_info['rt']:.1f}s\n"
        info_text += f"Peak m/z: {corrected_peak['mz']:.6f}\n"
        info_text += f"Intensity: {corrected_peak['intensity']:,.0f}"
        
        box_color = 'lightgreen' if corrected_peak['corrected'] else 'lightblue'
        
        ax.text(*self.plot_config['info_box_position'], info_text, 
                transform=ax.transAxes, 
                verticalalignment='top', horizontalalignment='right', 
                fontsize=10,
                bbox=dict(boxstyle='round', facecolor=box_color, alpha=0.8))
    
    def _save_plot(self, sample_name: str) -> str:
        """Save the plot to file."""
        filename = f'{OUTPUT_DIRS["plots"]}/{sample_name}_{self.compound_config["formula"]}_vs_reference.png'
        plt.savefig(filename, dpi=self.plot_config['dpi'], bbox_inches='tight')
        return filename

# =============================================================================
# MAIN PLOTTING CLASS
# =============================================================================

class CleanCompoundPlotter:
    """Main class for generating compound plots with clean architecture."""
    
    def __init__(self):
        self.data_loader = CompoundDataLoader()
        self.spectrum_extractor = SpectrumExtractor(INPUT_DIRS['mzml_files'])
        self.peak_detector = PeakDetector()
    
    def plot_all_compounds(self) -> int:
        """Generate plots for all validated compounds."""
        print("🎨 Starting clean compound plotting...")
        print(f"📊 Processing {len(COMPOUNDS)} compounds across {len(self.data_loader.validated_results)} samples")
        
        plot_count = 0
        successful_plots = []
        failed_plots = []
        
        for sample_name in sorted(self.data_loader.validated_results.keys()):
            print(f"\n📊 Processing {sample_name}...")
            
            for compound_name, compound_config in COMPOUNDS.items():
                detection_info = self.data_loader.validated_results[sample_name].get(compound_name)
                
                if detection_info:
                    try:
                        filename = self._plot_single_compound(sample_name, compound_name, 
                                                           compound_config, detection_info)
                        if filename:
                            successful_plots.append(f"{sample_name}_{compound_name}")
                            plot_count += 1
                        else:
                            failed_plots.append(f"{sample_name}_{compound_name}")
                            
                    except Exception as e:
                        print(f"   ❌ Error plotting {compound_name}: {e}")
                        failed_plots.append(f"{sample_name}_{compound_name}")
                else:
                    print(f"   ⚪ {compound_name}: Not validated (skipping)")
        
        self._generate_summary_report(plot_count, successful_plots, failed_plots)
        return plot_count
    
    def _plot_single_compound(self, sample_name: str, compound_name: str,
                             compound_config: Dict[str, Any], 
                             detection_info: Dict[str, Any]) -> Optional[str]:
        """Plot a single compound for a single sample."""
        # Get mzML file
        mzml_file = self._get_mzml_file(sample_name)
        if not mzml_file:
            return None
        
        # Extract spectrum at validated scan
        spectrum_data = self.spectrum_extractor.extract_spectrum_at_scan(
            mzml_file, detection_info['scan'])
        if spectrum_data is None:
            return None
        
        # Find true peak maximum
        corrected_peak = self.peak_detector.find_true_peak_maximum(
            spectrum_data['mz_array'], 
            spectrum_data['intensity_array'], 
            compound_config['target_mz'],
            PLOT_CONFIG['peak_detection_tolerance']
        )
        
        if not corrected_peak:
            return None
        
        # Generate plot
        plot_generator = PlotGenerator(compound_config, PLOT_CONFIG)
        return plot_generator.generate_plot(sample_name, detection_info, 
                                          spectrum_data, corrected_peak)
    
    def _get_mzml_file(self, sample_name: str) -> Optional[str]:
        """Get the mzML file path for a sample."""
        for file, mapped_name in SAMPLE_MAPPING.items():
            if mapped_name == sample_name:
                file_path = os.path.join(INPUT_DIRS['mzml_files'], file)
                if os.path.exists(file_path):
                    return file_path
                else:
                    print(f"mzML file not found: {file_path}")
                    return None
        return None
    
    def _generate_summary_report(self, plot_count: int, 
                               successful_plots: List[str], 
                               failed_plots: List[str]) -> None:
        """Generate summary report of plotting results."""
        print(f"\n📈 PLOTTING SUMMARY")
        print("=" * 70)
        print(f"Total plots generated: {plot_count}")
        
        # Summary by compound
        print(f"\nPlots by compound:")
        for compound_name in COMPOUNDS.keys():
            plotted_count = sum(1 for plot in successful_plots if compound_name in plot)
            print(f"  {compound_name}: {plotted_count} plots")
        
        if failed_plots:
            print(f"\n⚠️  Failed plots ({len(failed_plots)}):")
            for failed in failed_plots[:5]:
                print(f"   - {failed}")
            if len(failed_plots) > 5:
                print(f"   ... and {len(failed_plots)-5} more")

# =============================================================================
# MAIN EXECUTION
# =============================================================================

def main():
    """Main execution function."""
    print("🎨 Starting Clean Compound Plotting System")
    print("📊 Following clean code principles for maintainability")
    
    # Create output directories
    create_directories()
    
    # Generate plots
    plotter = CleanCompoundPlotter()
    plot_count = plotter.plot_all_compounds()
    
    print(f"\n✅ Clean compound plotting complete!")
    print(f"📁 {plot_count} plots saved in '{OUTPUT_DIRS['plots']}/' directory")
    print("🔍 Each plot shows sample data vs reference with corrected peak detection")
    print("📝 Code is clean, maintainable, and easy to modify")

if __name__ == "__main__":
    main()
