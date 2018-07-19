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
*       vartype:     maxmin - Dataset contains max/min temperatures. Create geotiff full-field and anomaly data for mean, maximum, and minimum temperature
*                    max    - Dataset contains max temperatures. Create geotiff full-field and anomaly data for maximum temperatures only
*                    mix    - Dataset contains min temperatures. Create geotiff full-field and anomaly data for minimum temperatures only
*                    mean   - Dataset contains mean temperatures. Create geotiff full-field and anomaly data for mean temperatures only
*       start:       Start date of the observational period to utilize in DDMONYYYY format
*       end:         End date of the observational period to utilize in DDMONYYYY format
*       output:      Root of the output filenames to generate (_[product] and .tif will be appended)
*
*   Notes:
*   1. If 'maxmin' is passed as vartype, ctlObs and ctlClimo must have tmax and tmin specified as variables corresponding to daily maximum and minimum temperatures
*   2. If 'max' is passed as vartype, the data descriptors must have a variable called tmax
*   3. If 'min' is passed as vartype, the data descriptors must have a variable called tmin
*   4. If 'mean' is passed as vartype, the data descriptors must have a variable called tmean
*   5. The climatology ctl files should use templating in the same format as the obs
*   6. The following (up to 6) products are created by this script:
*       [output]_maximum.tif          - GeoTIFF grid of maximum temperature observed during the period - only plotted when vartype=maxmin
*       [output]_maximum-anomaly.tif  - GeoTIFF grid of maximum temperature anomaly observed during the period - only plotted when vartype=maxmin
*       [output]_minimum.tif          - GeoTIFF grid of minimum temperature observed during the period - only plotted when vartype=maxmin
*       [output]_minimum-anomaly.tif  - GeoTIFF grid of minimum temperature anomaly observed during the period - only plotted when vartype=maxmin
*       [output]_mean.tif             - GeoTIFF grid of period mean temperature observed during the period
*       [output]_mean-anomaly.tif     - GeoTIFF grid of period mean temperature anomaly observed during the period
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

if(ctlObs='' | ctlClimo='' | vartype='' | start='' | end='' | output='')
    say 'Cannot produce geotiffs - missing arguments'
    'quit'
endif

* --- Print out command line arguments for logging ---

say 'ctlObs given:      'ctlObs
say 'ctlClimo given:    'ctlClimo
say 'vartype given:     'vartype
say 'start given:       'start
say 'end given:         'end
say 'output given:      'output

* --- Obtain 0.25 degree reference grid for regridding ---

'open grads_ref/global-0.25deg-gridref.ctl'
'define qtrdeg=gridref'
'close 1'

* --- Open observations and climatology datasets ---

'open 'ctlObs
'open 'ctlClimo

* --- Calculate full-field observations and anomalies over the period ---

'set lon -180 180'

if(vartype='maxmin')
    'define maxobs=max(tmax.1,time='start',time='end')'
    'define minobs=min(tmin.1,time='start',time='end')'
    'define meanobs=ave((tmax.1+tmin.1)/2,time='start',time='end')'

    'define maxclimo=max(tmax.2,time='start',time='end')'
    'define minclimo=min(tmin.2,time='start',time='end')'
    'define meanclimo=ave(tmean.2,time='start',time='end')'

    'define maxanom=maxobs-maxclimo'
    'define minanom=minobs-minclimo'
    'define meananom=meanobs-meanclimo'
endif

if(vartype='mean')
    'define meanobs=ave(tmean.1,time='start',time='end')'
    'define meanclimo=ave(tmean.2,time='start',time='end')'
    'define meananom=meanobs-meanclimo'
endif

if(vartype='max')
    'define maxobs=max(tmax.1,time='start',time='end')'
    'define maxclimo=max(tmax.2,time='start',time='end')'
    'define maxanom=maxobs-maxclimo'
endif

if(vartype='min')
    'define minobs=min(tmin.1,time='start',time='end')'
    'define minclimo=min(tmin.2,time='start',time='end')'
    'define minanom=minobs-minclimo'
endif

* --- Generate regridded geotiffs ---

if(vartype='maxmin')
    'set gxout geotiff'
    'set geotiff 'output'_maximum'
    'd lterp(maxobs,qtrdeg,aave,1)'

    'set gxout geotiff'
    'set geotiff 'output'_maximum-anomaly'
    'd lterp(maxanom,qtrdeg,aave,1)'

    'set gxout geotiff'
    'set geotiff 'output'_minimum'
    'd lterp(minobs,qtrdeg,aave,1)'

    'set gxout geotiff'
    'set geotiff 'output'_minimum-anomaly'
    'd lterp(minanom,qtrdeg,aave,1)'

    'set gxout geotiff'
    'set geotiff 'output'_mean'
    'd lterp(meanobs,qtrdeg,aave,1)'

    'set gxout geotiff'
    'set geotiff 'output'_mean-anomaly'
    'd lterp(meananom,qtrdeg,aave,1)'
endif

if(vartype='max')
    'set gxout geotiff'
    'set geotiff 'output'_maximum'
    'd lterp(maxobs,qtrdeg,aave,1)'

    'set gxout geotiff'
    'set geotiff 'output'_maximum-anomaly'
    'd lterp(maxanom,qtrdeg,aave,1)'
endif

if(vartype='min')
    'set gxout geotiff'
    'set geotiff 'output'_minimum'
    'd lterp(minobs,qtrdeg,aave,1)'

    'set gxout geotiff'
    'set geotiff 'output'_minimum-anomaly'
    'd lterp(minanom,qtrdeg,aave,1)'
endif

if(vartype='mean')
    'set gxout geotiff'
    'set geotiff 'output'_mean'
    'd lterp(meanobs,qtrdeg,aave,1)'

    'set gxout geotiff'
    'set geotiff 'output'_mean-anomaly'
    'd lterp(meananom,qtrdeg,aave,1)'
endif

* --- End GrADS script ---

'reinit'
say 'Script is done, have a nice day!'
'quit'

