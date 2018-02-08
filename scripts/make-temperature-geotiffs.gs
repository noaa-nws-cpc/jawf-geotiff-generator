*
* make-temperature-geotiffs.gs - Create summary and statistics geotiff products using temperature obs and climatologies
*
* Usage:
*   cd ${JAWF_GEOTIFFS}/scripts
*   grads -blc "run make-temperature-geotiffs.gs ctlObs ctlClimo start end output
*
*   Arguments:
*       ctlObs:      Filename of the GrADS data descriptor file for the observations dataset
*       ctlClimo:    Filename of the GrADS data descriptor file for the temperature climatology
*       start:       Start date of the observational period to utilize in DDMONYYYY format
*       end:         End date of the observational period to utilize in DDMONYYYY format
*       output:      Root of the output filenames to generate (_[product] and .tif will be appended)
*
*   Notes:
*   1. The dataset described by ctlObs must have two variables: tmax and tmin, corresponding to daily maximum and minimum temperatures.
*   2. The dataset described by ctlClimo must have two variables: tmax and tmin, corresponding to daily maximum and minimum temperature climatologies.
*   4. The climatology ctl files should use templating in the same format as the obs
*   5. The following 6 products are created by this script:
*       [output]_maximum.tif          - GeoTIFF grid of maximum temperature observed during the period
*       [output]_maximum-anomaly.tif  - GeoTIFF grid of maximum temperature anomaly observed during the period
*       [output]_minimum.tif          - GeoTIFF grid of minimum temperature observed during the period
*       [output]_minimum-anomaly.tif  - GeoTIFF grid of minimum temperature anomaly observed during the period
*       [output]_mean.tif             - GeoTIFF grid of period mean temperature observed during the period
*       [output]_mean-anomaly.tif     - GeoTIFF grid of period mean temperature anomaly observed during the period
*

function geotiffs (args)

* --- Get command line arguments ---

ctlObs=subwrd(args,1)
ctlClimo=subwrd(args,2)
start=subwrd(args,3)
end=subwrd(args,4)
output=subwrd(args,5)

* --- Make sure all command arguments were passed ---

if(ctlObs='' | ctlClimo='' | start='' | end='' | output='')
    say 'Cannot produce geotiffs - missing arguments'
    'quit'
endif

* --- Print out command line arguments for logging ---

say 'ctlObs given:      'ctlObs
say 'ctlClimo given: 'ctlClimo
say 'start given:       'start
say 'end given:         'end
say 'output given:      'output

* --- End GrADS script ---

'reinit'
say 'Script is done, have a nice day!'
'quit'

