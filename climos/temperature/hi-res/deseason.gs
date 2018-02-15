***************************************************************************************
* $Id: deseason.gs,v 1.72 2016/12/02 01:00:48 bguan Exp $
*
* Copyright (c) 2004-2016, Bin Guan
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification, are
* permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this list
*    of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or other
*    materials provided with the distribution.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
* EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
* OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
* SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
* BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
* ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
* DAMAGE.
***************************************************************************************
function main(arg)
*
* Calculate climatological mean or anomalies.
* Reference: Narapusetty, B., T. DelSole, and M. K. Tippett (2009), Optimal estimation of the climatological mean, J. Clim., 22, 4845â€“4859, doi:10.1175/2009JCLI2944.1.
*
rc=gsfallow('on')

* Define system temporary directory.
tmpdir='/tmp'
* Get username and create user-specific temporary directory.
'!echo $USER > .bGASL.txt'
rc=read('.bGASL.txt')
while(sublin(rc,1))
  '!echo $USER > .bGASL.txt'
  rc=read('.bGASL.txt')
endwhile
user=sublin(rc,2)
'!rm .bGASL.txt'
mytmpdir=tmpdir'/bGASL-'user
'!mkdir -p 'mytmpdir
* Get process ID.
pidlock=mytmpdir'/pid.lock'
pidfile=mytmpdir'/pid.txt'
'!while true; do if mkdir 'pidlock'; then break; else echo System busy. Please wait...; sleep 1; fi; done 2> /dev/null'
'!echo $PPID > 'pidfile
rc=read(pidfile)
randnum=sublin(rc,2)
'!rm -r 'pidlock

*
* Parse -v option.
*
num_var=parseopt(arg,'-','v','var')
if(num_var=0)
  usage()
  return
endif

*
* Initialize other options.
*
cnt=1
while(cnt<=num_var)
  _.anom.cnt=_.var.cnt
  _.tmpclim.cnt='tmpclim'cnt
  cnt=cnt+1
endwhile
_.limit.1=''
_.limit.2=''
_.num_Fourier.1=3
_.undef.1=-9.99e8
_.file.1=''
_.path.1='.'

*
* Parse -c option.
*
num_clim=parseopt(arg,'-','c','clim')

*
* Parse -a option.
*
num_anom=parseopt(arg,'-','a','anom')

if(num_clim>=1 & num_anom>=1)
  say '[deseason ERROR] -c and -a options cannot be used together.'
  return
endif

*
* Parse -l option.
*
rc=parseopt(arg,'-','l','limit')

*
* Parse -n option.
*
rc=parseopt(arg,'-','n','num_Fourier')
if(valnum(_.num_Fourier.1)!=1 | _.num_Fourier.1<0)
  say '[deseason ERROR] <num_Fourier> must be integer >=0.'
  return
endif

*
* Parse -u option.
*
rc=parseopt(arg,'-','u','undef')
if(!valnum(_.undef.1))
  say '[deseason ERROR] <undef> must be numeric.'
  return
endif

*
* Parse -o option.
*
rc=parseopt(arg,'-','o','file')

*
* Parse -p option.
*
rc=parseopt(arg,'-','p','path')

output='anom'
if(num_clim>=1)
  output='clim'
endif

output_media='memory'
if(_.file.1!='')
  output_media='file'
endif

*
* Process dimension information.
*
qdims(1,'mydim')
xs_int=_.mydim.xs
xe_int=_.mydim.xe
ys_int=_.mydim.ys
ye_int=_.mydim.ye
zs_int=_.mydim.zs
ze_int=_.mydim.ze
ts_int=_.mydim.ts
te_int=_.mydim.te
tims_int=_.mydim.tims
time_int=_.mydim.time
if(_.limit.1='')
  _.limit.1=tims_int
endif
if(_.limit.2='')
  _.limit.2=time_int
endif
if(_.limit.1=_.limit.2)
  say '[deseason ERROR] Time span is too short to define climatology.'
  return
endif
'set time '_.limit.1' '_.limit.2
'query dims'
line5=sublin(result,5)
ts_limit=subwrd(line5,11)
te_limit=subwrd(line5,13)

*
* Process calendar information.
*
if(_.mydim.cal!='' & _.mydim.cal!='365_day_calendar')
  say '[deseason ERROR] Unsupported calendar.'
  return
endif
if(_.mydim.cal!='')
  say '[deseason info] '_.mydim.cal' is in effect.'
endif
'set time 01JAN1999 01JAN2000'
'query dims'
line5=sublin(result,5)
ts_tmp=subwrd(line5,11)
te_tmp=subwrd(line5,13)
T1=te_tmp-ts_tmp
'set time 01JAN2000 01JAN2001'
'query dims'
line5=sublin(result,5)
ts_tmp=subwrd(line5,11)
te_tmp=subwrd(line5,13)
T2=te_tmp-ts_tmp
if(T1=T2)
  T=T1
else
  T=T1/365*365.2425
endif
* note: T is period of 1st annual harmonic expressed in # of t points (e.g., T=365.2425 if daily data with regular calendar, T=12 if monthly data regardless of calendar)
if((te_limit-ts_limit+1)<T)
  say '[deseason ERROR] Time span is too short to define climatology.'
  return
endif
if(2*_.num_Fourier.1+1>T)
  say '[deseason ERROR] <num_Fourier> is too large.'
  return
endif

'set gxout fwrite'

*
* Write .dat file for t.
*
'set x 'xs_int
'set y 'ys_int
'set z 'zs_int
'set fwrite 'mytmpdir'/t.dat.'randnum
cnt=ts_int
while(cnt<=te_int)
  'display const('cnt',-9.99e8,-u)'
  cnt=cnt+1
endwhile
'disable fwrite'

*
* Write .ctl file for t.
*
lines=11
line.1='dset ^t.dat.'randnum
line.2='undef -9.99e8'
if(_.mydim.cal='')
  line.3='*options'
else
  line.3='options '_.mydim.cal
endif
line.4='title intentionally left blank.'
line.5='xdef 1 levels '_.mydim.lons
line.6='ydef 1 levels '_.mydim.lats
line.7='zdef 1 levels '_.mydim.levs
line.8=_.mydim.tdef
line.9='vars 1'
line.10='t 0 99 t of each time step.'
line.11='endvars'
cnt=1
while(cnt<=lines)
  status=write(mytmpdir'/t.ctl.'randnum,line.cnt)
  cnt=cnt+1
endwhile
status=close(mytmpdir'/t.ctl.'randnum)

'open 'mytmpdir'/t.ctl.'randnum
file_num=file_number()
'set t 'ts_int' 'te_int
'ttmp2775=t.'file_num
'close 'file_num

*
* Prepare coefficients for annual/biannual/etc. Fourier harmonics.
*
pi=3.14159
'set x 'xs_int' 'xe_int
'set y 'ys_int' 'ye_int
'set z 'zs_int' 'ze_int
'set t 'ts_int
vcnt=1
while(vcnt<=num_var)
  'a0var'vcnt'=ave('_.var.vcnt',t='ts_limit',t='te_limit')'
  k=1
  while(k<=_.num_Fourier.1)
    'a'k'var'vcnt'=(2/sum(maskout(1,abs('_.var.vcnt')),t='ts_limit',t='te_limit'))*sum((('_.var.vcnt')-a0var'vcnt')*cos(2*'pi'/'T'*'k'*ttmp2775),t='ts_limit',t='te_limit')'
    'b'k'var'vcnt'=(2/sum(maskout(1,abs('_.var.vcnt')),t='ts_limit',t='te_limit'))*sum((('_.var.vcnt')-a0var'vcnt')*sin(2*'pi'/'T'*'k'*ttmp2775),t='ts_limit',t='te_limit')'
    k=k+1
  endwhile
  vcnt=vcnt+1
endwhile

*
* Do Fourier transform and write climatology .dat file (populated to all time steps).
*
if(output_media='memory' | output='anom')
  'set fwrite 'mytmpdir'/deseason.dat.'randnum
else
  'set fwrite '_.path.1'/'_.file.1'.dat'
endif
cnt=ts_int
while(cnt<=te_int)
  vcnt=1
  while(vcnt<=num_var)
    zcnt=zs_int
    while(zcnt<=ze_int)
      'set z 'zcnt
      'set t 'cnt
      'climtmp2775=a0var'vcnt
      k=1
      while(k<=_.num_Fourier.1)
        'climtmp2775=climtmp2775+a'k'var'vcnt'*cos(2*'pi'/'T'*'k'*ttmp2775)+b'k'var'vcnt'*sin(2*'pi'/'T'*'k'*ttmp2775)'
        k=k+1
      endwhile
      'display const(climtmp2775,'_.undef.1',-u)'
      zcnt=zcnt+1
    endwhile
    vcnt=vcnt+1
  endwhile
  cnt=cnt+1
endwhile
'disable fwrite'

*
* Write climatology .ctl file (populated to all time steps).
*
if(output_media='memory' | output='anom')
  writectl(mytmpdir'/deseason.ctl.'randnum,'^deseason.dat.'randnum,te_int-ts_int+1,tims_int,_.mydim.dtim,num_var,'tmpclim')
else
  writectl(_.path.1'/'_.file.1'.ctl','^'_.file.1'.dat',te_int-ts_int+1,tims_int,_.mydim.dtim,num_var,'clim')
endif

*
* Write anomaly .dat file if needed.
*
if(output_media='file' & output='anom')
  'set fwrite '_.path.1'/'_.file.1'.dat'
  'open 'mytmpdir'/deseason.ctl.'randnum
  file_num=file_number()
  cnt=ts_int
  while(cnt<=te_int)
    vcnt=1
    while(vcnt<=num_var)
      zcnt=zs_int
      while(zcnt<=ze_int)
        'set z 'zcnt
        'set t 'cnt
        'display const(('_.var.vcnt')-'_.tmpclim.vcnt'.'file_num','_.undef.1',-u)'
        zcnt=zcnt+1
      endwhile
      vcnt=vcnt+1
    endwhile
    cnt=cnt+1
  endwhile
  'close 'file_num
  'disable fwrite'
endif

*
* Write anomaly .ctl file if needed.
*
if(output_media='file' & output='anom')
  writectl(_.path.1'/'_.file.1'.ctl','^'_.file.1'.dat',te_int-ts_int+1,tims_int,_.mydim.dtim,num_var,anom)
endif

*
* Restore original dimension environment for variable output.
*
_.mydim.resetx
_.mydim.resety
_.mydim.resetz
_.mydim.resett

*
* Define climatology variable if needed.
*
if(output_media='memory' & output='clim')
  'open 'mytmpdir'/deseason.ctl.'randnum
  file_num=file_number()
  vcnt=1
  while(vcnt<=num_var)
    _.clim.vcnt'='_.tmpclim.vcnt'.'file_num
    vcnt=vcnt+1
  endwhile
  'close 'file_num
endif

*
* Define anomaly variable if needed.
*
if(output_media='memory' & output='anom')
  'open 'mytmpdir'/deseason.ctl.'randnum
  file_num=file_number()
  vcnt=1
  while(vcnt<=num_var)
    _.anom.vcnt'=('_.var.vcnt')-'_.tmpclim.vcnt'.'file_num
    vcnt=vcnt+1
  endwhile
  'close 'file_num
endif

*
* Clean up.
*
'undefine ttmp2775'
'undefine climtmp2775'
vcnt=1
while(vcnt<=num_var)
  'undefine a0var'vcnt
  k=1
  while(k<=_.num_Fourier.1)
    'undefine a'k'var'vcnt
    'undefine b'k'var'vcnt
    k=k+1
  endwhile
  vcnt=vcnt+1
endwhile
'!rm 'mytmpdir'/t.dat.'randnum
'!rm 'mytmpdir'/deseason.dat.'randnum

'set gxout contour'

return
***************************************************************************************
function writectl(ctlfile,datfile,nt,tims,step,nv,var)
*
* Write .ctl file.
*
lines=10
line.1='dset 'datfile
line.2='undef '_.undef.1
if(_.mydim.cal='')
  line.3='*options'
else
  line.3='options '_.mydim.cal
endif
line.4='title intentionally left blank.'
line.5=_.mydim.xdef
line.6=_.mydim.ydef
line.7=_.mydim.zdef
line.8='tdef 'nt' linear 'tims' 'step
line.9='vars 'nv
line.10='endvars'
cnt=1
while(cnt<=lines-1)
  status=write(ctlfile,line.cnt)
  cnt=cnt+1
endwhile
cnt=1
while(cnt<=nv)
  varline=_.var.cnt' '_.mydim.nz0' 99 '_.var.cnt
  status=write(ctlfile,varline)
  cnt=cnt+1
endwhile
status=write(ctlfile,line.lines)
status=close(ctlfile)

return
***************************************************************************************
function dfile()
*
* Get the default file number.
*
'q file'

line1=sublin(result,1)
dfile=subwrd(line1,2)

return dfile
***************************************************************************************
function file_number()
*
* Get the number of files opened.
*
'q files'
line1=sublin(result,1)
if(line1='No files open')
  return 0
endif

lines=1
while(sublin(result,lines+1)!='')
  lines=lines+1
endwhile

return lines/3
***************************************************************************************
function parseopt(instr,optprefix,optname,outname)
*
* Parse an option, store argument(s) in a global variable array.
*
rc=gsfallow('on')
cnt=1
cnt2=0
while(subwrd(instr,cnt)!='')
  if(subwrd(instr,cnt)=optprefix''optname)
    cnt=cnt+1
    word=subwrd(instr,cnt)
    while(word!='' & (valnum(word)!=0 | substr(word,1,1)''999!=optprefix''999))
      cnt2=cnt2+1
      _.outname.cnt2=parsestr(instr,cnt)
      cnt=_end_wrd_idx+1
      word=subwrd(instr,cnt)
    endwhile
  endif
  cnt=cnt+1
endwhile
return cnt2
***************************************************************************************
function usage()
*
* Print usage information.
*
say '  Calculate climatological mean or anomalies.'
say ''
say '  USAGE 1: deseason -v <var1> [<var2>...] [-a <anom1> [<anom2>...]] [-l <limit_start> <limit_end>] [-n <num_Fourier>] [-u <undef>] [-o <file>] [-p <path>]'
say '  USAGE 2: deseason -v <var1> [<var2>...] -c <clim1> [<clim2>...] [-l <limit_start> <limit_end>] [-n <num_Fourier>] [-u <undef>] [-o <file>] [-p <path>]'
say '    <var>: input field. Can be any GrADS expression.'
say '    <anom>: anomaly. Default=<var>.'
say '    <clim>: climatology.'
say '    <limit_start> <limit_end>: period for calculating <clim> (<anom> is calculated over current time dimension). Specified in world coordinate, such as MMMYYYY.'
say '    <num_Fourier>: climatology is defined as first <num_Fourier> Fourier harmonics (i.e., annual, biannual, triannual, etc.) plus mean. Default=3.'
say '    <undef>: undef value for .dat and .ctl. Default=-9.99e8.'
say '    <file>: common name for output .dat and .ctl files. If set, no variable is defined, only file output.'
say '    <path>: path to output files. Do NOT include trailing "/". Current path is used if unset.'
say ''
say '  NOTE: regular and 365-day calendars are supported and automatically handled. For regular calendar, a climatological year is assumed to be 365.2425 days.'
say ''
say '  EXAMPLE 1: calculate SST climatology and save to variable "sstclim" (no file output).'
say '    deseason -v sst -c sstclim'
say ''
say '  EXAMPLE 2: as example 1 except save to files "sstclim.ctl" and "sstclim.dat" (no variable is defined).'
say '    deseason -v sst -c sstclim -o sstclim'
say ''
say '  EXAMPLE 3: as example 1 except climatology is further smoothed using first 4 Fourier harmonics (i.e., annual, biannual, triannual, and quarterly) plus mean.'
say '    deseason -v sst -c sstclim -n 4'
say ''
say '  EXAMPLE 4: calculate SST anomaly and save to variable "sstanom" (no file output).'
say '    deseason -v sst -a sstanom'
say ''
say '  DEPENDENCIES: qdims.gsf parsestr.gsf'
say ''
say '  Copyright (c) 2004-2016, Bin Guan.'
return
