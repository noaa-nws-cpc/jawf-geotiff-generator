#!/usr/bin/perl

=pod

=head1 NAME

update-precipitation-binary-archive - Update CPC global gauge-satellite blend precipitation data in a GrADS template-friendly archive

=head1 SYNOPSIS

 $JAWF_GEOTIFFS/scripts/update-precipitation-binary-archive.pl -d ${date}
 $JAWF_GEOTIFFS/scripts/update-precipitation-binary-archive.pl -h
 $JAWF_GEOTIFFS/scripts/update-precipitation-binary-archive.pl -man

 [OPTION]            [DESCRIPTION]                                         [VALUES]

 -date, -d           Date to update in the precip archive (default -2day)  yyyymmdd
 -help, -h           Print usage message and exit
 -manual, -man       Display script documentation

=head1 DESCRIPTION

=head2 PURPOSE

Given a date, this script:

=over 3

=item * Locates the daily precipitation data for that date

=item * Unpacks and reformats the data as needed

=item * Copies the data into an archive that is GrADS template-friendly

=item * Exits with a nonzero value if unable to update the archive

=back

=head2 REQUIREMENTS

The following software must be installed on the system running this script:

=over 3

=item * GrADS (2.0.2 or above)

=item * Perl CPAN library

=item * CPC Perl5 Library

=back

The following environment variables are required to be set in order to run this script:

=over 3

=item * JAWF_GEOTIFFS - The full path to where jawf-geotiff-generator is installed on your system

=item * DATA_IN - Full path of the input data storage mount (e.g., /cpc/data)

=item * DATA_OUT - Full path of the output data storage mount (e.g., $HOME/data)

=back

=head1 AUTHOR

L<Adam Allgood|mailto:Adam.Allgood@noaa.gov>

L<Climate Prediction Center - NOAA/NWS/NCEP|http://www.cpc.ncep.noaa.gov>

This documentation was last updated on: 09FEB2018

=cut

# --- Standard and CPAN Perl packages ---

use strict;
use warnings;
use Getopt::Long;
use File::Basename qw(fileparse basename);
use File::Copy qw(copy move);
use File::Path qw(mkpath);
use Scalar::Util qw(blessed looks_like_number openhandle);
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
    die "JAWF_GEOTIFFS must be set to a valid directory - please check your environment settings - exiting" unless(CheckENV('JAWF_GEOTIFFS'));
    $APP_PATH   = $ENV{JAWF_GEOTIFFS};
    $APP_PATH   = RemoveSlash($APP_PATH);
    die "DATA_IN must be set to a valid directory - please check your environment settings - exiting" unless(CheckENV('DATA_IN'));
    $DATA_IN    = $ENV{DATA_IN};
    $DATA_IN    = RemoveSlash($DATA_IN);
    die "DATA_OUT must be set to a valid directory - please check your environment settings - exiting" unless(CheckENV('DATA_OUT'));
    $DATA_OUT   = $ENV{DATA_OUT};
    $DATA_OUT   = RemoveSlash($DATA_OUT);
}

# --- Get the command-line options ---

my $date        = int(CPC::Day->new() - 2);
my $help        = undef;
my $manual      = undef;

GetOptions(
    'date|d=i'       => \$date,
    'help|h'         => \$help,
    'manual|man'     => \$manual,
);

# --- Respond to options -help or -manual if they are passed before doing anything else ---

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

# --- If option -date was passed, make sure it was passed with a valid date ---

my $day;
eval   { $day = CPC::Day->new($date); };
if($@) { die "Option --date=$date is invalid! Reason: $@ - exiting"; }
unless(CPC::Day->new() >= $day) { die "Option --date=$date is too recent - exiting"; }

# --- Identify source data ---

my $sourceRoot = "/cpc/prcp/PRODUCTS/CMORPH_V0.x/BLD/0.25deg-DLY_EOD/GLB";
my $yyyy       = $day->Year;
my $mm         = sprintf("%02d",$day->Mnum);
my $dd         = sprintf("%02d",$day->Mday);
my $sourceFile  = "$sourceRoot/$yyyy/$yyyy$mm/CMORPH_V0.x_BLD_0.25deg-DLY_EOD_$yyyy$mm$dd.gz";

# --- Update the archive ---

my $destDir  = "$DATA_OUT/observations/land_air/short_range/global/precip/gauge-satellite-merged/$yyyy/$mm";
unless(mkpath($destDir)) { die "Could not make directory $destDir - check permissions - exiting"; }
my $destFile = "$destDir/CMORPH_v0.x_BLD_0.25deg-DLY_EOD_$yyyy$mm$dd";
unless(copy($sourceFile,"$destFile.gz")) { die "Could not copy $sourceFile to $destFile.gz - exiting"; }
my $failed   = system("gunzip $destFile.gz");
if($failed) { die "Could not unzip $destFile.gz - exiting"; }

# --- Check that archive file is there ---

unless(-s $destFile) { die "Could not find $destFile in archive - exiting"; }
print "$destFile written!\n";

exit 0;

