# jawf-geotiff-generator

README
===============

- **App Owner: [Adam Allgood](mailto:adam.allgood@noaa.gov)**
- **CPC Operational Backup: [David Miskus](mailto:david.miskus@noaa.gov)**

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

This application summarizes daily gridded precipitation and temperature data created and maintained by the Climate Prediction Center for 1-day, 7-day, monthly, seasonal, and annual periods, and produces GeoTIFF products intended for use by the [Joint Agricultural Weather Facility (JAWF)](https://www.usda.gov/oce/weather). JAWF is a partnership between the National Weather Service's [Climate Prediction Center (CPC)](https://www.cpc.ncep.noaa.gov) and the United States Department of Agriculture's World Agricultural Outlook Board (WAOB).

To monitor international weather and climate conditions and generate content for the [Weekly Weather and Crop Bulletin](https://www.usda.gov/oce/weather/pubs/Weekly/Wwcb/index.htm) publication, JAWF meteorologists utilize daily, weekly, monthly, seasonal, and annual summaries of precipitation (accumulated, anomalous, and percent of normal) and temperature (mean, departure from normal, extreme maximum, extreme minimum). The `jawf-geotiff-generator` application creates these summaries from the daily data available at CPC, and provides output data in 0.25-degree GeoTIFF format with longitudes ranging from -180 to 180, in order to facilitate working with these data in GIS.

CPC maintains Python-based applications that utilize ArcGIS to create graphical products for the WWCB based on these GeoTIFF data. Additionally, the GeoTIFFs themselves are available for use by CPC and USDA meteorologists.

Other Documents
---------------

| Document Link   | Description     |
| --------------- | --------------- |
| [How to Install](docs/HOW-TO-INSTALL.md)        | How to install `jawf-geotiff-generator` in a Linux environment |
| [How to Run](docs/HOW-TO-RUN.md)                | An overview of how the application works, with a description of each component |
| [Contributing Guidelines](docs/CONTRIBUTING.md) | How to help improve this software! |
| [Software License](LICENSE)                     | Department of Commerce Software License |

Global Variables Used
---------------

The following global environment variables are utilized by `jawf-geotiff-generator`:

- `$REALTIME_ONI` - The app location on your system
- `$DATA_IN` - Root path to input data partition
- `$DATA_OUT` - Root path to output data partition

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
