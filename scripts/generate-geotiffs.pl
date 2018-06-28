#!/usr/bin/perl

=pod

=head1 NAME

generate-geotiffs - Switchboard for getting geotiff generation jobs to the GrADS script for production

=head1 SYNOPSIS

 $JAWF_GEOTIFFS/scripts/generate-geotiffs.pl [-d|-j]
 $JAWF_GEOTIFFS/scripts/generate-geotiffs.pl -h
 $JAWF_GEOTIFFS/scripts/generate-geotiffs.pl -man

 [OPTION]            [DESCRIPTION]                                         [VALUES]

 -date, -d           Ending date of the calendar period to be used         yyyymmdd
 -failed, -f         Print failed job information to this file             filename
 -help, -h           Print usage message and exit
 -jobs, -j           Configuration file with jobs information              filename
 -manual, -man       Display script documentation

=head1 DESCRIPTION

=head2 PURPOSE

Given a date, this script:

=over 3

=item * Reads geotiff generating jobs settings from a configuration file

=item * Determines the date ranges to use for the geotiff data generation

=item * Sets up and executes commands to GrADS to generate the geotiffs

=item * Evaluates the success or failure of the GrADS-based GeoTIFF creation

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

This documentation was last updated on: 28JUN2018

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
use CPC::Month;
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
unless(CPC::Day->new() >= $day - 1) { die "Option --date=$date is too recent - exiting"; }

# --- If option -failed was passed, open the failed jobs file for writing and close it when the script finishes ---

if($failed) {
    open(FAILEDJOBS,'>',$failed) or die "Could not open $failed for writing - $! - exiting";
    print FAILEDJOBS 'gradsScript|ctlObs|ctlClimo|vartype|period|archiveRoot|fileRoot'."\n";
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

# --- Set up a hash of allowed variables to parse from the jobs file ---

my %jobsFileVars = (
    DATA_IN         => $DATA_IN,
    DATA_OUT        => $DATA_OUT,
    APP_PATH        => $APP_PATH,
    PRCP_ARCHIVE    => "$DATA_OUT/observations/land_air/short_range/global/precipitation/cmorph-gauge-merge",
    TEMP_ARCHIVE    => "$DATA_IN/cwlinks/temp/GLOBAL/hi_res",
    TMERGE_OBS      => "$DATA_IN/observations/land_air/short_range/global/merged_tmean/1deg/01d",
    TMERGE_CLIM     => "$DATA_IN/climatologies/land_air/short_range/global/merged_tmean_poe/1deg/01d",
    DEFAULT_ARCHIVE => "$DATA_OUT/observations/land_air/all_ranges/global/jawf_geotiffs",
);

# --- Load the information from the jobs file into a jobs list ---

open(JOBS,'<',$jobsFile) or die "Could not open $jobsFile for reading - $! - exiting";
my @fileContents = <JOBS>; shift(@fileContents); chomp(@fileContents);
my @jobs;
# Strip out comment lines!
foreach my $line (@fileContents) { push(@jobs,$line) unless(substr($line,0,1) eq '#'); }
my $njobs = scalar(@jobs);
close(JOBS);

# --- Change the working directory to where the GrADS script will be invoked ---

chdir("$APP_PATH/scripts") or die "Could not chdir to $APP_PATH/scripts! Reason: $@ - exiting";

# --- Loop jobs ---

my $failedJobs = 0;
my $jobCount   = 0;

JOB: foreach my $job (@jobs) {
    $jobCount++;
    print "Generating geotiffs for job $jobCount out of $njobs\n ";

    # --- Replace allowed variables with the preset values defined above in the job string ---

    $job =~ s/\$(\w+)/exists $jobsFileVars{$1} ? $jobsFileVars{$1} : 'abcdBLORTdcba'/eg;

    if($job =~ /abcdBLORTdcba/) {
        warn "   Variable found in the job settings that was not on list of allowed vars - skipping job...\n";
        $failedJobs++;
        if(openhandle(*FAILEDJOBS)) { warn "   Jobs settings with errors will not be added to failed list...\n"; }
        next JOB;
    }

    # --- Parse jobs settings into GrADS script args ---

    my($gradsScript, $ctlObs, $ctlClimo, $vartype, $period, $archiveRoot, $fileroot) = split(/\|/,$job);
    my($start, $end, $dateDirs);

    if($period =~ /^[+-]?\d+$/) {

        if($period > 0) {
            $start = $day - $period + 1;
            $end   = $day;
            $dateDirs = join('/',$end->Year,sprintf("%02d",$end->Mnum),sprintf("%02d",$end->Mday));
        }
        else            {
            warn "   The setting for period: $period is invalid - skipping job...\n";
            $failedJobs++;
            if(openhandle(*FAILEDJOBS)) { warn "   Jobs settings with errors will not be added to failed list...\n"; }
            next JOB;
        }

    }
    elsif($period =~ /month/) {
        my $month = CPC::Month->new($day->Mnum,$day->Year);
        $start    = CPC::Day->new(int($month).'01');
        $end      = CPC::Day->new(int($month).$month->Length);
	$dateDirs = join('/',$end->Year(),sprintf("%02d",$end->Mnum));
    }
    elsif($period =~ /season/) {
        my $month3 = CPC::Month->new($day->Mnum,$day->Year);
        my $month1 = $month3 - 2;
        $start     = CPC::Day->new(int($month1).'01');
        $end       = CPC::Day->new(int($month3).$month3->Length);
        $dateDirs = join('/',$end->Year(),sprintf("%02d",$end->Mnum));
    }
    elsif($period =~ /year/) {
        my $year  = $day->Year;
        $start    = CPC::Day->new($year.'0101');
        $end      = CPC::Day->new($year.'1231');
        $dateDirs = $end->Year;
    }
    else {
        warn "   The setting for period: $period is invalid - skipping job...\n";
        $failedJobs++;
        if(openhandle(*FAILEDJOBS)) { warn "   Jobs settings with errors will not be added to failed list...\n"; }
        next JOB;
    }

    print "   Period defined as: $start to $end\n";

    my $archiveDir  = "$archiveRoot/$dateDirs";
    my $geotiffRoot = "$archiveDir/$fileroot";

    # --- Create the archive directory if it does not exist yet ---

    unless(-d $archiveDir) { mkpath($archiveDir) or die "Could not create directory $archiveDir - check your permissions - exiting"; }

    # --- Use GrADS to create the image ---

    my $gradsErr = grads("run $gradsScript $ctlObs $ctlClimo $vartype $start $end $geotiffRoot");

    # --- Create a list of the expected output geotiff files that were created in the archive ---

    my @geotiffs;
    if($gradsScript =~ /temperature/ and $vartype =~ /maxmin/) {
        push(@geotiffs,
            $geotiffRoot.'_maximum.tif',
            $geotiffRoot.'_maximum-anomaly.tif',
            $geotiffRoot.'_minimum.tif',
            $geotiffRoot.'_minimum-anomaly.tif',
            $geotiffRoot.'_mean.tif',
            $geotiffRoot.'_mean-anomaly.tif');
    }
    elsif($gradsScript =~ /temperature/ and $vartype =~ /mean/) {
        push(@geotiffs,
            $geotiffRoot.'_mean.tif',
            $geotiffRoot.'_mean-anomaly.tif');
    }
    elsif($gradsScript =~ /precipitation/) {
        push(@geotiffs,
            $geotiffRoot.'_accumulated.tif',
            $geotiffRoot.'_anomaly.tif',
            $geotiffRoot.'_percent-normal.tif');
    }

    # --- Check the output from GrADS for any problems and delete the geotiffs if one found ---

    if($gradsErr) {
        warn  "\n$gradsErr\n";
        if(openhandle(*FAILEDJOBS)) { print FAILEDJOBS "$job\n"; }
        foreach my $geotiff (@geotiffs) { if(-s $geotiff) { unlink($geotiff); } }
        $failedJobs++;
    }
    else {
        my $missingGeoTIFF = 0;

        foreach my $geotiff (@geotiffs) {

            if(-s $geotiff) { print "   $geotiff created!\n"; }
            else            {
                $missingGeoTIFF++;
                warn "   WARNING: No GrADS errors found but $geotiff not created\n";
            }

        }

        if($missingGeoTIFF) {
            if(openhandle(*FAILEDJOBS)) { print FAILEDJOBS "$job\n"; }
            $failedJobs++
        }

    }

}  # :JOB

# --- Exit with nonzero value if failed jobs detected during the run ---

if($failedJobs) {
    warn "\n";
    die "Number of failed geotiff generation jobs: $failedJobs\n";
}

exit 0;

