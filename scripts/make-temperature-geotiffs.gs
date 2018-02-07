*
* make-temperature-geotiffs.gs - Create summary and statistics geotiff products using temperature obs and climatologies
*
* Usage:
*   cd ${JAWF_GEOTIFFS}/scripts
*   grads -blc "run make-temperature-geotiffs.gs ctlObs ctlClimo nFields fields start end output
*
*   Arguments:
*       ctlObs:      Filename of the GrADS data descriptor file for the observations dataset
*       ctlClimoMax: Filename of the GrADS data descriptor file for the maximum temperature climatology
*       ctlClimoMin: Filename of the GrADS data descriptor file for the minimum temperature climatology
*       start:       Start date of the observational period to utilize in DDMONYYYY format
*       end:         End date of the observational period to utilize in DDMONYYYY format
*       output:      Root of the output filenames to generate (_[product] and .tif will be appended)
*
*   Notes:
*   1. The dataset described by ctlObs must have two variables: tmax and tmin, corresponding to daily maximum and minimum temperatures.
*   2. The dataset described by ctlClimoMax must have the variable tmax
*   3. The dataset described by ctlClimoMin must have the variable tmin
*   4. The climatology ctl files should use templating in the same format as the obs
*   5. The following 6 products are created by this script:
*       [output]_tmax.tif       - GeoTIFF grid of maximum temperature during the period
*       [output]_tmax-anom.tif  - GeoTIFF grid of maximum temperature anomaly during the period
*       [output]_tmin.tif       - GeoTIFF grid of minimum temperature during the period
*       [output]_tmin-anom.tif  - GeoTIFF grid of minimum temperature anomaly during the period
*       [output]_tmean.tif      - GeoTIFF grid of period mean temperature during the period
*       [output]_tmean-anom.tif - GeoTIFF grid of period mean temperature anomaly during the period
*

function geotiffs (args)

* --- Get command line arguments ---

ctlObs=subwrd(args,1)
ctlClimoMax=subwrd(args,2)
ctlClimoMin=subwrd(args,3)
start=subwrd(args,4)
end=subwrd(args,5)
output=subwrd(args,6)

* --- Make sure all command arguments were passed ---

if(ctlObs='' | ctlClimoMax='' | ctlClimoMin='' | start='' | end='' | output='')
    say 'Cannot produce geotiffs - missing arguments'
    'quit'
endif

* --- Print out command line arguments for logging ---

say 'ctlObs given:      'ctlObs
say 'ctlClimoMax given: 'ctlClimoMax
say 'ctlClimoMin given: 'ctlClimoMin
say 'start given:       'start
say 'end given:         'end
say 'output given:      'output

* --- End GrADS script ---

'reinit'
say 'Script is done, have a nice day!'
'quit'

