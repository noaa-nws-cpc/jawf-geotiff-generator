*
* reformat-temperature-climos.gs - Reformat the lo-res temperature climatology for compatibility with the jawf-geotiff-generator application
*
* Usage:
*   cd ${JAWF_GEOTIFFS}/climos
*   grads -blc "run reformat-temperature-climos.gs ctlMax ctlMin
*
*   Arguments:
*       ctlMax:      Filename of the GrADS data descriptor file for the maximim temperature climatology
*       ctlMin:      Filename of the GrADS data descriptor file for the minimum temperature climatology
*
*   Notes:
*   1. Input data (described by ctlMax and ctlMin) are assumed to be daily climatology spanning 365 days
*   2. This script will do the following:
*       a. Open the maximum and minimum temperature datasets
*       b. For t=1 to t=365, write out a separate binary file containing the max, min, and mean grids
*   3. A separate script will rename these output files by date in MMDD format, and copy 0301 to 0229 for leap years
*

function reformat (args)

* --- Get command line arguments and log them ---

ctlMax=subwrd(args,1)
ctlMin=subwrd(args,2)

if(ctlMax='' | ctlMin='')
    say 'Cannot run this script - missing arguments'
    'quit'
endif

say 'ctlMax given: 'ctlMax
say 'ctlMin given: 'ctlMin

* --- Open the files, loop the dates, and write out the reformatted files ---

'open 'ctlMax
'open 'ctlMin
tCount=1

while(tCount<366)
    'set t 'tCount
    'set x 1 720'
    'set y 1 360'
    'set gxout fwrite'
    'set fwrite temperature-climatology-'tCount'.bin'
    'd tmax.1'
    'd tmin.2'
    'd (tmax.1+tmin.2)/2'
    'disable fwrite'
    tCount=tCount+1
endwhile

* --- End GrADS script ---

'reinit'
say 'Script is done, have a nice day!'
'quit'

