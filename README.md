[![Python 3.9](https://img.shields.io/badge/python-3.9-blue.svg)](https://www.python.org/downloads/release/python-390/) [![ImageJ](https://a11ybadges.com/badge?logo=imagej)](https://imagej.net/software/fiji/downloads)
# Genotoxicity BioImage Analysis

You will find all scripts in scripts folder, with subfolders fro Python and ImageJ Scripts
## ImageJ scripts

### Sorting wells
`sort_wells.ijm` is script  that sorts all images of defined format (default .tif) in folder based on well name in their filename. The well names must be defined.

`Process_WFolder_macro_VERSION_otsu.ijm` is script for BioImage analysis of wells based on DAPI channel and Cy3 channels. (Saved as separate images).

This protocol documents an image data flow utilized and inspired by [CLIJx-Assistant](https://doi.org/10.1101/2020.11.19.386565).

 * We start our image data flow with image_1, a DAPI channel with nuclei.
 * Following, we applied "Copy" on image_1 and got a new image out, image_2.
 * As the next step, we applied "Otsu" auto threshold on image_2 and got a new image mask out, image_3. The threshold values are saved and used on all DAPI images from the same well.
 * Afterward, we applied "Analyze Particles" on image_3, and got out a region fo nuclei as a Region of Interest (ROI) set. All ROIs touching edges are skipped.
 * In the next step, we open image_4, which is the Cy3 channel. We applied "Copy" on image_4, and got a new image out, image_5.
 * We applied background substruction with rolling ball of size 50 on image_5 to subtract local background value from intensity measurements, and got image_6 out. 
 * Afterward, image_6 is selected for measuring features under ROIs from the previous step.
 * The process Log and measured features from Cy3 channel for the whole well and summary are saved in "Results" subfolder in the CSV table. A flattened image_4 with ROIs outlines is saved as JPEG for later inspection.

The macro logs version of ImageJ and BioImage plugin version on each run was tested in [ImageJ](https://imagej.net/software/fiji/downloads) version 1.53t99. The logs are also containing information about image size, count of objects, and threshold values.


## Python scripts

### Recomended conda enviroment creation
```
conda install mamba -c conda-forge
mamba create --name julab python=3.9 jupyterlab -c conda-forge
```
optional: Code Formatting Jupyter Notebooks with Black
```
mamba install -c conda-forge jupyterlab_code_formatter black isort
```

### Results processing

The following scripts were used for CSV outputs processing:
 * `SF_dataVis_and_statistics_mean_4h.ipynb`
 * `SF_dataVis_and_statistics_mean_4h.ipynb`

They expect folder with CSVs from each well, which is main result of  `Process_WFolder_macro_VERSION_otsu.ijm`. The result are charts, statistic comparison and relative area change with folds.

### Image Quality Assessment

### Binder Jupetr Notebook
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/martinschatz-cz/genotoxicity-bia.git/HEAD?labpath=/Python_scripts/SF_dataVis_and_statistics_mean_4h.ipynb)

