#!/usr/bin/perl

=pod

=head1 NAME

generate-geotiffs - Switchboard for getting geotiff creation jobs to the GrADS script for production

=head1 SYNOPSIS

 $JAWF_GEOTIFFS/scripts/generate-geotiffs.pl [-d|-j]
 $JAWF_GEOTIFFS/scripts/generate-geotiffs.pl -h
 $JAWF_GEOTIFFS/scripts/generate-geotiffs.pl -man

 [OPTION]            [DESCRIPTION]                                         [VALUES]

 -date, -d           Date forecast data are available (default 2 days ago) yyyymmdd
 -failed, -f         Print failed job information to this file             filename
 -help, -h           Print usage message and exit
 -jobs, -j           Configuration file with jobs information              filename
 -manual, -man       Display script documentation

=head1 DESCRIPTION

=head2 PURPOSE

Given a date, this script:

=over 3

=item * Reads GeoTIFF creation jobs information from a configuration file

=item * Sets up each job as a list of commands to pass to the GrADS script

=item * Executes the GrADS script with the required arguments

=item * Evaluates the success or failure of GeoTIFF creation

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

This documentation was last updated on: 31JAN2018

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
my $failed      = undef;
my $help        = undef;
my $jobsFile    = undef;
my $manual      = undef;

GetOptions(
    'date|d=i'       => \$date,
    'failed|f=s'     => \$failed,
    'help|h'         => \$help,
    'jobs|j=s'       => \$jobsFile,
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

# --- If option -failed was passed, open the failed jobs file for writing and close it when the script finishes ---

if($failed) {
    open(FAILEDJOBS,'>',$failed) or die "Could not open $failed for writing - $! - exiting";
    print FAILEDJOBS 'gradsScript|ctlFile|toolParams|vars|issueOffset|validOffset|imageFile'."\n";
}

END {
    if(openhandle(*FAILEDJOBS)) { close(FAILEDJOBS); }
}

# --- Make sure option -jobs was passed with a valid filename ---

unless($jobsFile) {

    pod2usage( {
        -message => "\nOption --jobs must be supplied, please try again or use the -help or -manaul options for more help\n",
        -exitval => 1,
        -verbose => 0,
    } );

}

unless(-s $jobsFile) {

    pod2usage( {
        -message => "\nOption --jobs must be set to a non-empty file, please try again\n",
        -exitval => 1,
        -verbose => 0,
    } );

}

# --- Content to be added below ---



# --- Content to be added above ---

sub date_dirs {
    my $day  = shift;
    my $yyyy = $day->Year();
    my $mm   = sprintf("%02d",$day->Mnum());
    my $dd   = sprintf("%02d",$day->Mday());
    return join('/',$yyyy,$mm,$dd);
}

exit 0;

