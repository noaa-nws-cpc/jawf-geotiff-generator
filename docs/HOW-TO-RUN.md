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
3. Creates GeoTIFF temperature and precipitation products using `$JAWF_GEOTIFFS/scripts/generate_geotiffs.pl` and the job configuration files `$JAWF_GEOTIFFS/jobs/daily-*.jobs`. This updates the GeoTIFF archive for 1- and 7-day summaries.
4. If the update date is the last day of a month, creates GeoTIFF temperature and precipitation products using the job configuration files `$JAWF_GEOTIFFS/jobs/monthly-*.jobs`. This updates the GeoTIFF archive for the past 1- (monthly) and 3-month (seasonal) summaries.
5. If the update date is the last day of a year, creates GeoTIFF temperature and precipitation products using the job configuration files `$JAWF_GEOTIFFS/jobs/annual-*.jobs`. This updates the GeoTIFF archive for the past year (annual) summaries.

### Rerun Utility

When the driver script needs to be run over multiple dates, to build an archive or to rerun missed days due to a system or data outage, a rerun utility is provided. This script is run with two arguments: a start date and an end date. The script loops through all of the days from the start date to the end date, and runs the driver script with each date as an argument.

For example, to create 1-day, 7-day, monthly, seasonal, and an annual summary for every day and month in 2017, execute the following:

`$JAWF_GEOTIFFS/drivers/rerun-jawf-production.csh 20170101 20171231`

Updating the Precipitation Archive
---------------

### NOTE: This component of the application may change or be removed depending on the available format and location of CPC's gridded gauge-satellite merged precipitation data.

The jawf-geotiff-generator application requires the input datasets to be accessible via GrADS [data descriptor files](http://cola.gmu.edu/grads/gadoc/descriptorfile.html) that use [templating](http://cola.gmu.edu/grads/gadoc/templates.html) over time. Currently, the CPC gauge-satellite merged daily precipitation dataset is archived in zipped tarballs, which are not GrADS-readable. To solve this problem, a script is provided that unpacks these data and stores them in an unformatted binary archive with a directory structure based on dates that can be templated. This script is executed by the driver script, but it can be run independently if needed for whatever reason. This is the script usage statement:

```
Usage:
     $JAWF_GEOTIFFS/scripts/update-precipitation-archive.pl [-l|-d]
     $JAWF_GEOTIFFS/scripts/update-precipitation-archive.pl -h
     $JAWF_GEOTIFFS/scripts/update-precipitation-archive.pl -man

     [OPTION]            [DESCRIPTION]                                    [VALUES]

     -date, -d           Date forecast data are available                 yyyymmdd
     -list, -l           File containing a list of dates to archive       filename
     -failed, -f         Write dates where archiving failed to file       filename
     -help, -h           Print usage message and exit
     -manual, -man       Display script documentation
```

Given a `-date` argument, the script attempts to update the archive for data valid on that date. Additionally, the archive is scanned for existing and non-empty files for the 30-days prior to that date, and if missing files are found, those dates are added to a list of dates to update.

In addition to the `date` argument and the 30-day scan, a text file listing one or more dates can also be provided as an argument. The script will add dates from this file to the list of dates it attempts to update in the archive.

For example, suppose a file is created in `$JAWF_GEOTIFFS/jobs` called `update-precipitation-archive.dates` that contains the following text:

```
20170630
20170701
20170705
```

Executing the precipitation archiving script with the following arguments:

`$JAWF_GEOTIFFS/scripts/update-precipitation-archive.pl -d 20180722 -l $JAWF_GEOTIFFS/jobs/update-precipitation-archive.dates`

will attempt to update the precipitation archive for June 30, July 1, July 5, 2017, July 22, 2018, and any dates between June 22 and July 22, 2018 where binary files are missing in the archive. Additionally, if the script is unsuccessful at updating the archive for any of these dates, the failed dates can be written out to a file by supplying a file name via the `-failed` option. If the `-list` and `-failed` options are set to the same file, a running list of dates that need to be updated can be maintained, and as dates are successfully updated in subsequent runs (i.e., on cron), they get removed from the list of dates that still need to be updated.

`$JAWF_GEOTIFFS/scripts/update-precipitation-archive.pl -d 20180722 -l $JAWF_GEOTIFFS/jobs/update-precipitation-archive.dates -f $JAWF_GEOTIFFS/jobs/update-precipitation-archive.dates`

Creating GeoTIFFs
---------------

### GrADS GeoTIFF Generating Scripts

### Perl Switchboard Script

Jobs Files
---------------

### Format

### Allowed Variables
