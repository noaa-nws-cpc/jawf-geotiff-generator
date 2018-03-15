dset ^temperature-climatology-%m2%d2.bin
options little_endian template
title global daily analysis: Temperature climo 
undef -9.99e8
xdef 2160 linear   0.083      0.1666666667 
ydef 1080  linear -89.917     0.1666666667
zdef 1 linear 1 1
tdef 20000 linear 01jan2011 1dy
vars 3
tmax     1  00 daily maximum temperature (C)
tmin     1  00 daily minimum temperature (C)
tmean    1  00 daily mean temperature (C)
ENDVARS
