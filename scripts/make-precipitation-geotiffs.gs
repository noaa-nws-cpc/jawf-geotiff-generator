*
* make-precipitation-geotiffs.gs - Create summary and statistics geotiff products using precipitation obs and climatologies
*
* Usage:
*   cd ${JAWF_GEOTIFFS}/scripts
*   grads -blc "run make-precipitation-geotiffs.gs ctlObs ctlClimo start end output
*
*   Arguments:
*       ctlObs:      Filename of the GrADS data descriptor file for the observations dataset
*       ctlClimo:    Filename of the GrADS data descriptor file for the precipitation climatology
*       vartype:     Dummy variable - ignored by script but present to make consistent with temperature creator args
*       start:       Start date of the observational period to utilize in DDMONYYYY format
*       end:         End date of the observational period to utilize in DDMONYYYY format
*       output:      Root of the output filenames to generate (_[product].tif will be appended)
*
*   Notes:
*   1. The dataset described by ctlObs must have the variable bld - daily precipitation based on gauge satellite merged analysis.
*   2. The dataset described by ctlClimoClimo must have the variable 
*   3. The climatology ctl files should use templating in the same format as the obs
*   4. The following 3 products are created by this script:
*       [output]_accumulated.tif - GeoTIFF grid of total accumulated precipitation observed during the period
*       [output]_anomaly.tif     - GeoTIFF grid of the departure from climatology precipitation observed during the period
*       [output]_percent-normal.tif - GeoTIFF grid of the percent of climatology precipitation observed during the period
*

function geotiffs (args)

* --- Get command line arguments ---

ctlObs=subwrd(args,1)
ctlClimo=subwrd(args,2)
vartype=subwrd(args,3)
start=subwrd(args,4)
end=subwrd(args,5)
output=subwrd(args,6)

* --- Make sure all command arguments were passed ---

if(ctlObs='' | ctlClimo='' | start='' | end='' | output='')
    say 'Cannot produce geotiffs - missing arguments'
    'quit'
endif

* --- Print out command line arguments for logging ---

say 'ctlObs given:      'ctlObs
say 'ctlClimo given:    'ctlClimo
say 'start given:       'start
say 'end given:         'end
say 'output given:      'output

* --- Open observations and climatology datasets ---

'open 'ctlObs
'open 'ctlClimo

* --- Summarize obs and climos over the period ---

'set lon -180 180'

'define prec=sum(bld.1,time='start',time='end')'
'define precClim=sum(bld.2,time='start',time='end')'

* --- Compute anomaly and percent of normal precipitation ---

'define anomaly=prec-precClim'
'define pctnml=100*(prec/(precClim+0.0001))'

* --- Generate geotiffs ---

'set gxout geotiff'
'set geotiff 'output'_accumulated'
'd prec'

'set gxout geotiff'
'set geotiff 'output'_anomaly'
'd anomaly'

'set gxout geotiff'
'set geotiff 'output'_percent-normal'
'd pctnml'

* --- End GrADS script ---

'reinit'
say 'Script is done, have a nice day!'
'quit'

