How to Run
===============

Table of Contents
---------------

- [Overview](#overview)
- [Other Documents](#other-documents)
- [Operational Usage](#operational-usage)
- [Creating GeoTIFFs](#creating-geotiffs)
- [Jobs Files](#jobs-files)

Overview
---------------

The jawf-geotiff-generator application is intended to run on cron daily in CPC's operational environment, using a driver script that controls the creation of a specific set of GeoTIFF products. A rerun utility is also provided should the automated runs fail over a period of days due to a system outage or missing input data. In addition to describing the use of the operational driver script and the rerun utility, this document also provides an overview of the application components: the jobs configuration files, the GrADS scripts that generate the GeoTIFF files, and the Perl "switchboard" script that parses the jobs files and sets up the GrADS-based production. Familiarity with these components will aid the user should modifications be needed, either due to new input datasets, or new product requirements.

Other Documents
---------------

- [How to Install](HOW-TO-INSTALL.md)
- [README](../README.md)

Operational Usage
---------------

### Driver Script

### Rerun Utility

### Updating the Precipitation Archive

Creating GeoTIFFs
---------------

### GrADS GeoTIFF Generating Scripts

### Perl Switchboard Script

Jobs Files
---------------

### Format

### Allowed Variables
