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

This script can be run with no arguments, which is the default usage:

`$JAWF_GEOTIFFS/drivers/run-jawf-production.csh`

The script alternatively takes a date in YYYYMMDD format as an argument, e.g., to generate GeoTIFFs for periods ending August 31, 2018:

`$JAWF_GEOTIFFS/drivers/run-jawf-production.csh 20180831`

This driver script does the following:

1. Sets the update date, which is the ending date for the GeoTIFF summary periods (e.g., 7-days ending on the update date, or month ending on the update date, etc.). The default date when the script is given no arguments is the date 2-days prior to the system time as returned by the Linux `date` utility. This default is overridden by a date passed as an argument.
2. Updates an archive of precipitation data using `$JAWF_GEOTIFFS/scripts/update-precipitation-archive.pl` - this step is needed because the CPC gauge-satellite merged data is currently stored as zipped tarfiles.
3. Creates GeoTIFF temperature and precipitation products for the past 1- and 7-days ending on the update date.
4. 

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
