#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use HTGT::Utils::SubmitQC 'submit_qc_job';
use Perl6::Slurp;
use Pod::Usage;

GetOptions(
    help          => sub { pod2usage( -verbose => 1 ) },
    man           => sub { pod2usage( -verbose => 2 ) },
    'dry-run'     => \my $dryrun,
    'force-rerun' => \my $force_rerun,
    'from-file=s' => \my $filename,
    'config=s'    => \my $conffile,
) or pod2usage(2);

my @todo;

if ( $filename ) {
    @todo = map [ split ], slurp { chomp => 1 }, $filename eq '-' ? \*STDIN : $filename;
}
elsif ( @ARGV ) {
    while ( @ARGV >= 2 ) {
        push @todo, [ splice @ARGV, 0, 2 ];
    }
    pod2usage( "Expected an even number of arguments" ) if @ARGV;
}
else {
    pod2usage( "Must specify filename or list sequencing projects and plates in arguments" );
}

HTGT::Utils::SubmitQC::set_config( $conffile )
    if $conffile;

for ( @todo ) {
    print "Submitting job @$_ as $ENV{USER}, force re-run: " . ( $force_rerun ? 'yes' : 'no' ) . "\n";
    next if $dryrun;
    submit_qc_job( @$_, $ENV{USER}, { force_rerun => $force_rerun } );    
}

__END__

=pod

=head1 NAME

submit_qc_jobs

=head2 SYNOPSIS

  submit_qc_jobs [OPTIONS] sequencing_project htgt_plate_name [...]

  Options:

    --help        show a brief help message
    --man         show the manual page
    --force-rerun force QC to be re-run on a 384-well plate
 
=cut
