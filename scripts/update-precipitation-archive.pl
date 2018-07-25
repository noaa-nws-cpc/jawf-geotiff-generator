#!/usr/bin/perl

=pod

=head1 NAME

update-precipitation-archive - Download, unzip, and archive global CMORPH-Gauge merge precipitation data

=head1 SYNOPSIS

 $JAWF_GEOTIFFS/scripts/update-precipitation-archive.pl [-l|-d]
 $JAWF_GEOTIFFS/scripts/update-precipitation-archive.pl -h
 $JAWF_GEOTIFFS/scripts/update-precipitation-archive.pl -man

 [OPTION]            [DESCRIPTION]                                    [VALUES]

 -date, -d           Date forecast data are available                 yyyymmdd
 -list, -l           File containing a list of dates to archive       filename
 -failed, -f         Write dates where archiving failed to file       filename
 -help, -h           Print usage message and exit
 -manual, -man       Display script documentation

=head1 DESCRIPTION

=head2 PURPOSE

Given a date, this script:

=over 3

=item * Obtains the associated global CMORPH-Gauge merge precipitation data file from CPC and unzips it

=item * Writes the data into a GrADS template-friendly binary archive

=back

=head2 REQUIREMENTS

The following must be installed on the system running this script:

=over 3

=item * GrADS (2.0.2 or above)

=item * Perl CPAN library

=item * CPC Perl5 Library

=back

=head1 AUTHOR

L<Adam Allgood|mailto:Adam.Allgood@noaa.gov>

L<Climate Prediction Center - NOAA/NWS/NCEP|http://www.cpc.ncep.noaa.gov>

This documentation was last updated on: 13JUN2018

=cut

# --- Standard and CPAN Perl packages ---

use strict;
use warnings;
use Getopt::Long;
use File::Basename qw(fileparse basename);
use File::Copy qw(copy move);
use File::Path qw(mkpath);
use Scalar::Util qw(blessed looks_like_number openhandle);
use List::MoreUtils qw(uniq);
use Pod::Usage;

# --- CPC Perl5 Library packages ---

use CPC::Day;
use CPC::Env qw(CheckENV RemoveSlash);
use CPC::SpawnGrads qw(grads);

# --- Establish script environment ---

my($scriptName,$scriptPath,$scriptSuffix);

BEGIN { ($scriptName,$scriptPath,$scriptSuffix) = fileparse($0, qr/\.[^.]*/); }

my $APP_PATH;
my($DATA_IN,$DATA_OUT);

BEGIN {
    die "JAWF_GEOTIFFS must be set to a valid directory - exiting" unless(CheckENV('JAWF_GEOTIFFS'));
    $APP_PATH     = $ENV{JAWF_GEOTIFFS};
    $APP_PATH     = RemoveSlash($APP_PATH);
    die "DATA_IN must be set to a valid directory - exiting" unless(CheckENV('DATA_IN'));
    $DATA_IN = $ENV{DATA_IN};
    $DATA_IN = RemoveSlash($DATA_IN);
    die "DATA_OUT must be set to a valid directory - exiting" unless(CheckENV('DATA_OUT'));
    $DATA_OUT     = $ENV{DATA_OUT};
    $DATA_OUT     = RemoveSlash($DATA_OUT);
}

my $error = 0;

# --- Get the command-line options ---

my $date        = undef;
my $datelist    = undef;
my $failed      = undef;
my $help        = undef;
my $manual      = undef;

GetOptions(
    'date|d=i'       => \$date,
    'list|l=s'       => \$datelist,
    'failed|f=s'     => \$failed,
    'help|h'         => \$help,
    'manual|man'     => \$manual,
);

# --- Actions for -help or -manual options if invoked ---

if($help) {

    pod2usage( {
        -message => ' ',
        -exitval => 0,
        -verbose => 0,
    } );

}

if($manual) {

    pod2usage( {
        -message => ' ',
        -exitval => 0,
        -verbose => 2,
    } );

}

# --- Set output root path ---

my $outputRoot = "$DATA_OUT/observations/land_air/short_range/global/precipitation/cmorph-gauge-merge";
print "\nOutput root directory: $outputRoot\n";

# --- Create list of dates to archive ---

print "Creating list of dates to update...\n";
my @daylist;

# Add date from -date option if supplied!

if($date) {
    my $day;
    eval   { $day = CPC::Day->new($date); };
    if($@) { die "Option --date=$date is invalid! Reason: $@ - exiting"; }
    else   { push(@daylist,$day); }
    print "   Added $day to the update list\n";

    # --- Scan the output archive for the 30 days prior and add days with missing data to the list ---

    for(my $scanDay=$day-30; $scanDay<$day; $scanDay++) {
        my $yyyy     = $scanDay->Year();
        my $yyyymmdd = int($scanDay);
        my $scanFile = "$outputRoot/$yyyy/CMORPH_V0.x_BLD_0.25deg-DLY_EOD_$yyyymmdd";

        unless(-s $scanFile) {
            print "   Added $scanDay to update list - data not found in the archive\n";
            push(@daylist,$scanDay);
        }

    }

}

# Add dates from file if -list option supplied!

if($datelist and -s $datelist) {

    if(open(DATELIST,'<',$datelist)) {
        my @datelist = <DATELIST>; chomp(@datelist);
        close(DATELIST);

        foreach my $row (@datelist) {
            my $day;
            eval   { $day = CPC::Day->new($row); };
            if($@) { warn "   In $datelist, $row is an invalid date! Reason: $@ - not adding to update list\n"; }
            else   { push(@daylist,$day); }
        }

        print "   Added dates from $datelist to update list\n";
    }
    else {
        warn "   Could not open $datelist for reading - $! - no new dates added";
        $error = 1;
    }

}

# --- Cull duplicate dates from dates list and sort into ascending order ---

@daylist = uniq(@daylist);
@daylist = sort {$a <=> $b} @daylist;

# --- Open failed dates file if -failed option supplied ---

if($failed) { open(FAILED,'>',$failed) or die "Could not open $failed for writing - $! - exiting"; }

# --- Update the archive ---

DAY: foreach my $day (@daylist) {
    print "Archiving CPC CMORPH-Gauge-Merge precipitation data for $day...\n";

    # --- Create output directory if needed ---

    my $yyyy       = $day->Year;
    my $mm         = sprintf("%02d",$day->Mnum);
    my $yyyymmdd   = int($day);
    my $outputDir  = join('/',$outputRoot,$yyyy);
    unless(-d $outputDir) { mkpath($outputDir) or die "\nCould not create directory $outputDir - check app permissions on your system - exiting"; }

    # --- Set output filename and delete existing copy if needed ---

    my $destZip    = "$outputDir/CMORPH_V0.x_BLD_0.25deg-DLY_EOD_$yyyymmdd.gz";
    my $destFile   = "$outputDir/CMORPH_V0.x_BLD_0.25deg-DLY_EOD_$yyyymmdd";
    if(-s $destZip)  { unlink($destZip);  }
    if(-s $destFile) { unlink($destFile); }

    # --- Attempt to copy the zipped source file ---

    my $sourceFile = "/cpc/prcp/PRODUCTS/CMORPH_V0.x/BLD/0.25deg-DLY_EOD/GLB/$yyyy/$yyyy$mm/CMORPH_V0.x_BLD_0.25deg-DLY_EOD_$yyyymmdd.gz";

    unless(copy($sourceFile,$destZip)) {
        warn "   ERROR: Unable to download zipped precipitation data file - error caught";
        $error = 1;
        if($failed) { print FAILED "$yyyymmdd\n"; }
        next DAY;
    }
    else { print "   Downloaded a zipped precipitation file for $day\n"; }

    # --- Attempt to unzip the source file ---

    my $unzipFailed = system("gunzip $destZip");

    if($unzipFailed) {
        warn "   ERROR: Unable to unzip precipitation data file - error caught";
        $error = 1;
        if($failed) { print FAILED "$yyyymmdd\n"; }
        next DAY;
    }

    # --- Check that the file actually exists in the output archive ---

    unless(-s $destFile) {
        warn "   ERROR: Archive file not found - check for uncaught errors - error caught";
        $error = 1;
        if($failed) { print FAILED "$yyyymmdd\n"; }
        next DAY;
    }
    else { print "   CMORPH-Gauge-Merge precipitation data for $day has been archived!\n"; }
}  # :DAY

# --- Cleanup and end script ---

if($failed) { close(FAILED); }
if($error)  { die "\nErrors detected - please check the log file for more information\n"; }

exit 0;

