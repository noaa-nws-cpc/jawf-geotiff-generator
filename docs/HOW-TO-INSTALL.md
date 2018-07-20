How to Install
===============

Table of Contents
---------------

- [Other Documents](#other-documents)
- [Prerequisites](#prerequisites)
- [Steps to Install](#steps-to-install)

Other Documents
---------------

- [README](../README.md)
- [How to Run](HOW-TO-RUN.md)

Prerequisites
---------------

The following software must be installed on your system in order to install and use jawf-geotiff-generator:

- [git](https://git-scm.com/book/en/v1/Getting-Started-Installing-Git)
- [CPC Perl5 Library](https://github.com/noaa-nws-cpc/cpc-perl5-lib)
- [GrADS v2.0.2 or later](http://cola.gmu.edu/grads/downloads.php)

To see if git is installed and what version your system has, enter:

    $ git --version

To see if the CPC Perl5 Library is available, enter:

    $ echo $PERL5LIB

To see which version of GrADS your system uses by default, enter:

    $ grads -blc "quit"

Steps to Install
---------------

**NOTE:** This application was developed and tested in a Linux environment (RHEL 6), and these instructions are intended for installation in a similar environment. If you want to try installing this in a different operating system, you will have to modify the instructions on your own.

### Download and set up jawf-geotiff-generator on your system

These instructions assume that the jawf-geotiff-generator app will be installed in `$HOME/apps`. If you install it in a different directory, modify these instructions accordingly.

1. Download jawf-geotiff-generator (this creates a directory called `jawf-geotiff-generator`):

    `$ cd $HOME/apps`
    
    `$ git clone https://github.com/noaa-nws-cpc/jawf-geotiff-generator.git`

2. Add the environment variable `$JAWF_GEOTIFFS` to `~/.profile_user` or whatever file you use to set up your profile:

    `export REALTIME_ONI="${HOME}/apps/realtime-oni"`

3. Set up the application, including initialization of the SST archive with the past 120 days of daily data:

    `$ cd $JAWF_GEOTIFFS`
    
    `$ make install`

### Setup cron

**Sample basic cron entry:**

`00 10 * * * $JAWF_GEOTIFFS/drivers/run-jawf-production.csh 1> $JAWF_GEOTIFFS/logs/run-jawf-production.csh 2>&1`

**Sample CPC operational cron entry:**

`00 10 * * * /situation/bin/flagrun.pl CPCOPS_RH6 '$JAWF_GEOTIFFS/drivers/run-jawf-production.csh 1> $JAWF_GEOTIFFS/logs/run-jawf-production.txt 2>&1'`

**Sample CPC operational cron entry with later attempt to get final data using [keep-trying](https://github.com/mikecharles/keep-trying), and emailing a logfile to the app owner:**

`00 10 * * * /situation/bin/flagrun.pl CPCOPS_RH6 'keep-trying -i 60 -t 60 -e app.owner\@email.domain -s \"jawf-geotiff-generator production FAILED - Check attached logfile\" -l $JAWF_GEOTIFFS/logs/run-jawf-production.txt -- $JAWF_GEOTIFFS/drivers/run-jawf-production.csh'`
