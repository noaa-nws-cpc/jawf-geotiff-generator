dset ^precipitation-climatology-%m2%d2.bin
* 
options  little_endian template  
* 
title Gaguge-CMORPH Blended Daily Precipitation Climatology (1998-2017)  
* 
undef -999.0
* 
xdef 1440 linear    0.125  0.25 
* 
ydef  720 linear  -89.875  0.25  
* 
zdef 1 linear 1 1
* 
tdef 20000 linear 01jan2011 1dy
*
vars 1  
bld     1  00 CMORPH V1.0 BLD Climo (mm/day)
ENDVARS
*  1998-2017 climatology  
*  summation of first 6 harmonics   
*  clim for Feb.29 defined as the mean of those for Feb.28 and Mar.1    
