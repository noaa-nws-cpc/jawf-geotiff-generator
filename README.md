# jawf-geotiff-generator

README
===============

- **App Owner: [Adam Allgood](mailto:adam.allgood@noaa.gov)**
- **CPC Operational Backup: [Daniel Harnos](mailto:daniel.harnos@noaa.gov)**

Table of Contents
-----------------

- [Overview](#overview)
- [Other Documents](#other-documents)
- [Global Variables Used](#global-variables-used)
- [Input Data](#input-data)
- [Output Data](#output-data)
- [Process Flow](#process-flow)
- [NOAA Disclaimer](#noaa-disclaimer)

Overview
---------------

Other Documents
---------------

| Document Link   | Description     |
| --------------- | --------------- |
| [How to Install](docs/HOW-TO-INSTALL.md)        | How to install `jawf-geotiff-generator` in a Linux environment |
| [How to Run](docs/HOW-TO-RUN.md)                | An overview of how the application runs, with a description of each component |
| [Contributing Guidelines](docs/CONTRIBUTING.md) | How to help improve this software! |
| [Software License](LICENSE)                     | Department of Commerce Software License |

Global Variables Used
---------------

- `$REALTIME_ONI` - The app location on your system
- `$DATA_IN` - Root path to input data partition
- `$DATA_OUT` - Root path to output data partition
- `$WEB_OUT` - Root path to the Web mirror
- `$FTP_OUT` - Root path to the FTP mirror

Input Data
---------------

### CPC High-Resolution Daily Temperature Grids

### CPC Land-Ocean Merged Daily Temperature Grids

### CPC Gauge-Satellite Merged Daily Precipitation Grids

Output Data
---------------

### Local Gauge-Satellite Merged Daily Precipitation Archive

### GeoTIFF Archive

Process Flow
---------------

NOAA Disclaimer
===============

This repository is a scientific product and is not official communication of the National Oceanic and Atmospheric Administration, or the United States Department of Commerce. All NOAA GitHub project code is provided on an ‘as is’ basis and the user assumes responsibility for its use. Any claims against the Department of Commerce or Department of Commerce bureaus stemming from the use of this GitHub project will be governed by all applicable Federal law. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by the Department of Commerce. The Department of Commerce seal and logo, or the seal and logo of a DOC bureau, shall not be used in any manner to imply endorsement of any commercial product or activity by DOC or the United States Government.
