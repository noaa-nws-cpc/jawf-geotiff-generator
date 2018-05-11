#!/bin/csh
#
#########################################################################################
# File:              rerun-jawf-production.csh
# App Name:          jawf-geotiff-generator
# Functionality:     Run run-jawf-production.csh for multiple dates
# Author:            Adam Allgood
# Date created:      2018-05-11
#########################################################################################
#

echo

# --- Get rerun date range from command line ---

if ($#argv < 2) then
    echo Date arguments were not supplied - please try again
    goto error
else
    set startDate = $1
    set endDate   = $2
endif

# Validate the dates!

set date_test = `date --d ${startDate}`

if ($?) then
   echo The date $startDate is invalid!
   goto error
endif

set date_test = `date --d ${endDate}`

if ($?) then
   echo The date $endDate is invalid!
   goto error
endif

if ($startDate > $endDate) then
    echo Warning! The start date is later than the ending date - switching dates
    set tempDate  = ${endDate}
    set endDate   = ${startDate}
    set startDate = ${tempDate}
endif

echo The start date: $startDate has been validated!
echo The ending date: $endDate has been validated!

# --- Loop date range ---

set yyyymmdd = $startDate

while ( ${yyyymmdd} <= ${endDate} )
    echo Running $JAWF_GEOTIFFS/drivers/run-jawf-production.csh $yyyymmdd
    $JAWF_GEOTIFFS/drivers/run-jawf-production.csh ${yyyymmdd}
    set yyyymmdd = `date +%Y%m%d --d "${yyyymmdd} + 1day"`
end

exit 0

error:
echo
echo "Exiting rerun script with errors :("
echo

exit 1

