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

To see which version of GrADS your system uses by default, enter:

    $ grads -blc "quit"

Steps to Install
---------------

### Download and install jawf-geotiff-generator

These instructions assume that the jawf-geotiff-generator app will be installed in `$HOME/apps`. If you install it in a different directory, modify these instructions accordingly.

1. Download jawf-geotiff-generator (this creates a directory called `jawf-geotff-generator`):

    `$ cd $HOME/apps`
    `$ git clone https://github.com/noaa-nws-cpc/jawf-geotiff-generator.git`

2. Install the application:

    `$ cd $HOME/apps/jawf-geotiff-generator`
    `$ make install`

3. Add the environment variable `$JAWF_GEOTIFFS` to `~/.profile_user` or whatever file you use to set up your profile:

    `export JAWF_GEOTIFFS="${HOME}/apps/jawf-geotiff-generator"`

### Setup climatologies

### Setup cron

1. Daily jobs (most recent 1- and 7-day):

2. Monthly jobs (most recent month and three months):

3. Annual job (most recent year):

