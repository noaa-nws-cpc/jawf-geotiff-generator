#!/bin/csh
#
#######################################################################################
# File:              run-jawf-production.csh
# App Name:          jawf-geotiff-generator
# Functionality:     Driver script to generate geotiffs for JAWF operations
# Author:            Adam Allgood
# Date created:      2018-05-11
#######################################################################################
#

# --- Set the time period ending date for generating the geotiff files ---

# Default date!

set upDate = `date +%Y%m%d --d '2 days ago'`

# Override the default with a date from the command line if supplied!

if ($#argv >= 1) then
    set upDate = $1
endif

# Validate the date!

set date_test = `date --d ${upDate}`
echo

if ($?) then
   echo The date $upDate is invalid!
   goto error
else
   echo The date $upDate has been validated!
endif

# --- Set target date for 1-day shifted data for the U.S. ---

set usDate = `date +%Y%m%d --d "${upDate} - 1day"`

set mnum = `date +%m --d ${usDate}`
set mday = `date +%d --d ${usDate}`

# --- Set up failure flag ---

set failure = 0

# --- Update precipitation archive ---

echo
echo Updating CMORPH-Gauge merge precipitation archive
perl ${JAWF_GEOTIFFS}/scripts/update-precipitation-archive.pl -d ${upDate} -l ${JAWF_GEOTIFFS}/jobs/update-precipitation-archive.dates -f ${JAWF_GEOTIFFS}/jobs/update-precipitation-archive.dates

if ( $status != 0) then
    set failure = 1
endif

# --- Daily and weekly geotiffs ---

echo
echo Generating daily and weekly JAWF geotiffs
perl ${JAWF_GEOTIFFS}/scripts/generate-geotiffs.pl -j ${JAWF_GEOTIFFS}/jobs/daily-temperature.jobs -d ${upDate}

if ( $status != 0) then
    set failure = 1
endif

perl ${JAWF_GEOTIFFS}/scripts/generate-geotiffs.pl -j ${JAWF_GEOTIFFS}/jobs/daily-precipitation.jobs -d ${upDate}

if ( $status != 0) then
    set failure = 1
endif

perl ${JAWF_GEOTIFFS}/scripts/generate-geotiffs.pl -j ${JAWF_GEOTIFFS}/jobs/daily-precipitation-us.jobs -d ${usDate}

if ( $status != 0) then
    set failure = 1
endif

# --- Monthly and seasonal geotiffs ---

# Determine if usDate is the last day of a month!

set mdayp1 = `date +%d --d "${usDate} + 1day"`

if ( $mdayp1 < $mday ) then
    echo
    echo Generating monthly and seasonal geotiffs
    perl ${JAWF_GEOTIFFS}/scripts/generate-geotiffs.pl -j ${JAWF_GEOTIFFS}/jobs/monthly-temperature.jobs -d ${usDate}

    if ( $status != 0 ) then
        set failure = 1
    endif

    perl ${JAWF_GEOTIFFS}/scripts/generate-geotiffs.pl -j ${JAWF_GEOTIFFS}/jobs/monthly-precipitation.jobs -d ${usDate}

    if ( $status != 0 ) then
        set failure = 1
    endif

# --- Annual geotiffs ---

    if ($mnum == '12' ) then
        echo
        echo Generating annual geotiffs
        perl ${JAWF_GEOTIFFS}/scripts/generate-geotiffs.pl -j ${JAWF_GEOTIFFS}/jobs/annual-temperature.jobs -d ${usDate}

        if ( $status != 0 ) then
            set failure = 1
        endif

        perl ${JAWF_GEOTIFFS}/scripts/generate-geotiffs.pl -j ${JAWF_GEOTIFFS}/jobs/annual-precipitation.jobs -d ${usDate}

        if ( $status != 0 ) then
            set failure = 1
        endif

    endif

endif

# --- End script ---

if ($failure != 0) then
    goto error
endif

echo
echo All done for ${upDate}!
echo

exit 0

error:
echo
echo "Exiting with driver script errors :("
echo

exit 1

