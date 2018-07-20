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

The following software must be installed on your system in order to install and use realtime-oni:

- [git](https://git-scm.com/book/en/v1/Getting-Started-Installing-Git)
- [CPC Perl5 Library](https://github.com/noaa-nws-cpc/cpc-perl5-lib)
- [GrADS v2.0.2 or later](http://cola.gmu.edu/grads/downloads.php)

To see which version of GrADS your system uses by default, enter:

    $ grads -blc "quit"

Steps to Install
---------------

**NOTE:** This application was developed and tested in a Linux environment (RHEL 6), and these instructions are intended for installation in a similar environment. If you want to try installing this in a different operating system, you will have to modify the instructions on your own.

### Download and set up realtime-oni on your system

These instructions assume that the realtime-oni app will be installed in `$HOME/apps`. If you install it in a different directory, modify these instructions accordingly.

1. Download realtime-oni (this creates a directory called `realtime-oni`):

    `$ cd $HOME/apps`
    
    `$ git clone https://github.com/noaa-nws-cpc/realtime-oni.git`

2. Add the environment variable `$REALTIME_ONI` to `~/.profile_user` or whatever file you use to set up your profile:

    `export REALTIME_ONI="${HOME}/apps/realtime-oni"`

3. Set up the application, including initialization of the SST archive with the past 120 days of daily data:

    `$ cd $HOME/apps/realtime-oni`
    
    `$ make install`

### Setup cron

**Sample basic cron entry:**

`00 12 * * * $REALTIME_ONI/drivers/daily/update-archives.csh 1> $REALTIME_ONI/logs/update-archives.txt 2>&1`

**Sample CPC operational cron entry:**

`00 12 * * * /situation/bin/flagrun.pl CPCOPS_RH6 '$REALTIME_ONI/drivers/daily/update-archives.csh 1> $REALTIME_ONI/logs/update-archives.txt 2>&1'`

**Sample CPC operational cron entry with later attempt to get final data using [keep-trying](https://github.com/mikecharles/keep-trying), and emailing a logfile to the app owner:**

`00 12 * * * /situation/bin/flagrun.pl CPCOPS_RH6 'keep-trying -i 600 -t 600 -e app.owner\@email.domain -s \"realtime-oni updater FAILED - Check attached logfile\" -l $REALTIME_ONI/logs/update-archives.txt -- $REALTIME_ONI/drivers/daily/update-archives.csh'`
