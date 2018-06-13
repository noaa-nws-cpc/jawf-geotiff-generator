#!/bin/bash

# rename-temperature-climos.sh - Rename the files copied from /cpc/prcp
#
# To add precipitation climatology to jawf-geotiff-generator and make it consistent with the
# temperature climos, this script renames the precip climo files copied into the project.

refday=`date --d "20111231"`
t=1

while [ $t -le 365 ]
do
    climoday=`date +%m%d --d "${refday} + ${t}days"`
    mv CMORPH_V1.0BETA_BLD_0.25deg-DLY_EOD_CLIM_1998-2017.lnx.${climoday} precipitation-climatology-${climoday}.bin
    ((t++))
done

echo Done!
exit 0

