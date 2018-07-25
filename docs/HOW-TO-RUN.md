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

will attempt to update the precipitation archive for June 30, July 1, July 5, 2017, July 22, 2018, and any dates between June 22 and July 22, 2018 where binary files are missing in the archive. In case the script is unsuccessful at updating the archive for any of these dates and you want to capture that information, the failed dates can be written out to a file by supplying the filename using the `-failed` option. If the `-list` and `-failed` options are both set to the same file, a running list of dates that need to be updated can be maintained, with dates that failed previously being supplied to the script during subsequent runs. This is how the script is utilized in the driver script.

`$JAWF_GEOTIFFS/scripts/update-precipitation-archive.pl -d ${upDate} -l $JAWF_GEOTIFFS/jobs/update-precipitation-archive.dates -f $JAWF_GEOTIFFS/jobs/update-precipitation-archive.dates`

A date set by the script (`${upDate}`) is added to a list of dates to update in the archive. The 30 days prior to that date in the archive are scanned, and any dates with missing data are also added to the list. Next, any dates in the file supplied by the `-list` option are added to the list. Then the script attempts to update the archive for all of these dates. If any dates are unsuccessful, they get written back to the file supplied.

Creating GeoTIFFs
---------------

GeoTIFF data are created by the jawf-geotiff-generator application using the following steps:

1. An ascii jobs configuration file is passed to the Perl switchboard script `$JAWF_GEOTIFFS/scripts/generate-geotiffs.pl`
2. The switchboard script combines calendar information with the information from the jobs file to set up a list of GrADS commands to create the GeoTIFF data.
3. The GrADS commands are executed using the CPC::SpawnGrads package from the CPC Perl5 Library. These commands involve executing GrADS scripts in batch mode with arguments to create the GeoTIFF products.
4. The output from GrADS is captured and evaluated to check for errors, and the GeoTIFF files are confirmed to exist.

### Jobs Files

Information about what GeoTIFF products to create are passed to the Perl switchboard script using static, ascii-text jobs configuration files. Each GeoTIFF production job occupies a separate line in the file, and elements are delimited by pipes (`|`). Lines starting with `#` are considered comments and ignored. The first line of the file is the header line, which describes the required elements of each job:

`gradsScript|ctlObs|ctlClimo|vartype|level|period|archiveRoot|fileRoot`

- `gradsScript`: Identifies which GrADS script to run in the GrADS batch command. The Perl switchboard script changes into the `$JAWF_GEOTIFFS`/scripts directory before executing GrADS, so it is assumed that the script is located in that directory. Currently two GrADS scripts are available for use: `make-temperature-geotiffs.gs` and `make-precipitation-geotiffs.gs`.
- `ctlObs`: Identifies the GrADS data descriptor (ctl) file to be used for the observational dataset (e.g., the real-time daily temperature or precipitation data). The full path to the ctl file must be supplied, but there are several allowed variables defined by the Perl switchboard that map to CPC operational paths.
- `ctlClimo`: Identifies the GrADS data descriptor (ctl) file to be used for the climatology dataset (e.g., the daily temperature or precipitation climatology corresponding to the daily data described by `ctlObs`). The full path to the ctl file must be supplied, but there are several allowed variables defined by the Perl switchboard that map to CPC operational paths.
- `vartype`: This field is passed to the GrADS scripts as an argument, and it allows the script to work with input data in different formats. It is not important if `gradsScript` is `make-precipitation-geotiffs.gs`, but it must still be set to something. See the GrADS GeoTIFF Generating Scripts section for more information.
- `level`: This field is passed to the GrADS script as an argument, and provides the level (Z-axis) setting when loading the climatology data. This field is necessary because some climatologies are percentile-based, with the various percentiles delineated by the ctl file as levels. Typically the value is 1 (not a percentile climatology), or 50 (to set the climatology to the 50th percentile).
- `period`: Defines the temporal window for the GeoTIFF summary. If it is set to an integer value (N), the GeoTIFF products will be N-day summaries. If it is set to `month`, then the products will be calendar monthly summaries. If set to `seasonal`, they will be 3-calendar monthly summaries. If set to `year`, they will be annual summaries. The ending date of the summary period(s) is determined by the `-date` argument to the Perl switchboard script. See below for more information.
- `archiveRoot`: The directory where the GeoTIFFs will be written. Files will go into subdirectories that are based on the ending date of the summary period. See [README](../README.md) for more information.
- `fileRoot`: The first part of the GeoTIFF output's filename. Since the GrADS scripts create multiple products, the product type is appended to this root filename.

The application comes with several jobs files that create the set of GeoTIFF products required by JAWF. These can be found in `$JAWF_GEOTIFFS/jobs`.

### Perl Switchboard Script

`$JAWF_GEOTIFFS/scripts/generate-geotiffs.pl`
```
Usage:
     $JAWF_GEOTIFFS/scripts/generate-geotiffs.pl [-d|-j]
     $JAWF_GEOTIFFS/scripts/generate-geotiffs.pl -h
     $JAWF_GEOTIFFS/scripts/generate-geotiffs.pl -man

     [OPTION]            [DESCRIPTION]                                         [VALUES]

     -date, -d           Ending date of the calendar period to be used         yyyymmdd
     -failed, -f         Print failed job information to this file             filename
     -help, -h           Print usage message and exit
     -jobs, -j           Configuration file with jobs information              filename
     -manual, -man       Display script documentation
```

Given a date and a jobs configuration file, this script sets up and executes GrADS commands that utilize GrADS scripts to create the GeoTIFF products. This is done by parsing the elements of the jobs file into arguments to be passed to the GrADS scripts, and using the dates and the `period` field of the job to set the starting and ending dates of the summary period. The output from the GrADS command to STDOUT is captured and evaluated for possible errors, and the output archive is scanned to confirm whether the GeoTIFF files were created or not. Optionally, jobs that were unsuccessful at producing GeoTIFF data can be written to a text file using the `-failed` option. This could save time when rerunning.

The summary periods to use for the GeoTIFF products are determined as follows, given a `-date` value of YYYYMMDD:

| Job `period` field | Description   |
| ------------------ | ------------- |
| Integer N          | N-days ending on YYYYMMDD |
| month              | Every day in the month YYYYMM |
| seasonal           | Every day in the 3 calendar month period ending on the last day of the month YYYYMM |
| year               | Every day in the year YYYY |

### GrADS GeoTIFF Generating Scripts

These scripts take numerous arguments and are designed to be executed by a GrADS command set up by the Perl switchboard script. For reference, the usage statement for the precipitation product generator is:

`make-precipitation-geotiffs.gs`
```
Usage:
  cd ${JAWF_GEOTIFFS}/scripts
  grads -blc "run make-precipitation-geotiffs.gs ctlObs ctlClimo start end output

  Arguments:
      ctlObs:      Filename of the GrADS data descriptor file for the observations dataset
      ctlClimo:    Filename of the GrADS data descriptor file for the precipitation climatology
      vartype:     Dummy variable - ignored by script but present to make consistent with temperature creator args
      level:       Z-Axis value
      start:       Start date of the observational period to utilize in DDMONYYYY format
      end:         End date of the observational period to utilize in DDMONYYYY format
      output:      Root of the output filenames to generate (_[product].tif will be appended)

  Notes:
  1. The dataset described by ctlObs must have the variable bld - daily precipitation based on gauge satellite merged analysis.
  2. The dataset described by ctlClimoClimo must have the variable
  3. The climatology ctl files should use templating in the same format as the obs
  4. The following 3 products are created by this script:
      [output]_accumulated.tif - GeoTIFF grid of total accumulated precipitation observed during the period
      [output]_anomaly.tif     - GeoTIFF grid of the departure from climatology precipitation observed during the period
      [output]_percent-normal.tif - GeoTIFF grid of the percent of climatology precipitation observed during the period
```

Note that a `vartype` argument is required but not needed. This argument is needed by the temperature product generator. The usage statement for that script, which includes the 4 possible `vartype` values is:

`make-temperature-geotiffs.gs`
```
Usage:
  cd ${JAWF_GEOTIFFS}/scripts
  grads -blc "run make-temperature-geotiffs.gs ctlObs ctlClimo start end output

  Arguments:
      ctlObs:      Filename of the GrADS data descriptor file for the observations dataset
      ctlClimo:    Filename of the GrADS data descriptor file for the temperature climatology
      vartype:     maxmin - Dataset contains max/min temperatures. Create geotiff full-field and anomaly data for mean, maximum, and minimum temperature
                   max    - Dataset contains max temperatures. Create geotiff full-field and anomaly data for maximum temperatures only
                   mix    - Dataset contains min temperatures. Create geotiff full-field and anomaly data for minimum temperatures only
                   mean   - Dataset contains mean temperatures. Create geotiff full-field and anomaly data for mean temperatures only
      level:       Z-Axis setting
      start:       Start date of the observational period to utilize in DDMONYYYY format
      end:         End date of the observational period to utilize in DDMONYYYY format
      output:      Root of the output filenames to generate (_[product] and .tif will be appended)

  Notes:
  1. If 'maxmin' is passed as vartype, ctlObs and ctlClimo must have tmax and tmin specified as variables corresponding to daily maximum and minimum temperatures
  2. If 'max' is passed as vartype, the data descriptors must have a variable called tmax
  3. If 'min' is passed as vartype, the data descriptors must have a variable called tmin
  4. If 'mean' is passed as vartype, the data descriptors must have a variable called tmean
  5. The climatology ctl files should use templating in the same format as the obs
  6. The following (up to 6) products are created by this script:
      [output]_maximum.tif          - GeoTIFF grid of maximum temperature observed during the period - only plotted when vartype=maxmin
      [output]_maximum-anomaly.tif  - GeoTIFF grid of maximum temperature anomaly observed during the period - only plotted when vartype=maxmin
      [output]_minimum.tif          - GeoTIFF grid of minimum temperature observed during the period - only plotted when vartype=maxmin
      [output]_minimum-anomaly.tif  - GeoTIFF grid of minimum temperature anomaly observed during the period - only plotted when vartype=maxmin
      [output]_mean.tif             - GeoTIFF grid of period mean temperature observed during the period
      [output]_mean-anomaly.tif     - GeoTIFF grid of period mean temperature anomaly observed during the period
```

The biggest important takeaway with regard to these scripts is the requirement that the variable names as specified in the GrADS data descriptor (ctl) files must have specific names. This somewhat narrow scope works well with CPC's operational datasets, but if you need to expand this application to work with other temperature or precipitation datasets, either use bld as the variable name for precipitation and tmax/tmin/tmean for temperature, or modify these scripts accordingly. A future release of this software may attempt more flexibility by requiring the variable names to be passed as arguments (and hence included in the jobs configuration files).
