#!/bin/bash

# rename-temperature-climos.sh - Rename the files created by reformat-temperature-climos.gs
#
# To work with the CPC lo-res global temperature climatology datasets in the jawf-geotiff-generator 
# application, some reformatting was needed. This reformatting is done via the GrADS script 
# reformat-temperature-climos.gs, which outputs 365 files named 
# temperature-climatology-[1,2,...,365].bin. This script simply renames those files, changing the 
# numbers to the corresponding month and day number of the year (assuming a non leap year). Then 
# the temperature-climatology-0301.bin file is copied to temperature-climatology-0229.bin, to 
# account for leap years.

refday=`date --d "19801231"`
t=1

while [ $t -le 365 ]
do
    climoday=`date +%m%d --d "${refday} + ${t}days"`
    mv temperature-climatology-${t}.bin temperature-climatology-${climoday}.bin
    ((t++))
done

cp temperature-climatology-0301.bin temperature-climatology-0229.bin

echo Done!
exit 0

