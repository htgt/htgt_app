#!/usr/bin/env perl
#
# $Id: refresh_cache.pl,v 1.1 2009-08-11 11:09:29 rm7 Exp $

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use Log::Log4perl qw( :easy );
use URI;
use URI::QueryParam;
use LWP::UserAgent;
use YAML;

sub init {

    my $logfile  = 'STDERR';
    my $loglevel = $WARN;

    GetOptions(
        help        => sub { pod2usage( -verbose => 1 ) },
        man         => sub { pod2usage( -verbose => 2 ) },
        verbose     => sub { $loglevel = $INFO },
        debug       => sub { $loglevel = $DEBUG },
        'logfile=s' => sub { $logfile  = '>>' . $_[ 1 ] },
    ) and @ARGV == 1 or pod2usage( 2 );

    Log::Log4perl->easy_init(
        {
            level  => $loglevel,
            file   => $logfile,
            layout => '%d %p %m%n',
        }
    );

    my $conffile = shift @ARGV;
    my $conf = eval { YAML::LoadFile( $conffile ) };
    LOGDIE( "Failed to read $conffile: $@" ) if $@;

    return $conf;
}

my $conf = init();

my $base_url = $conf->{ base_url }
    or LOGDIE( "base_url not specified" );

my $ua = LWP::UserAgent->new( requests_redirectable => [] )
    or LOGDIE( "failed to construct LWP::UserAgent" );
$ua->timeout( $conf->{ timeout } )
    if defined $conf->{ timeout };

foreach my $path ( @{ $conf->{ paths } } ) {
    my $uri = URI->new_abs( $path, $base_url );
    $uri->query_param( force_refresh => 1 );
    INFO( "Fetching " . $uri->as_string );
    my $response = $ua->get( $uri );
    ERROR( "Failed to fetch $uri: " . $response->status_line )
        unless $response->is_success;
}

__END__

=pod

=head1 NAME

refresh_cache.pl

=head1 SYNOPSIS

    refresh_cache.pl [OPTIONS] CONFIG

=head1 OPTIONS

=over 4

=item B<--help>

Show brief usage message.

=item B<--man>

Show detailed manual page.

=item B<--verbose>

Show informational messages.

=item B<--debug>

Show debug messages.

=item B<--logfile>

Log to the specified file rather than STDERR.

=back

=head1 DESCRIPTION

This script requests each URI listed in the configuration file, with the additional
parameter force_refresh=1, forcing an update of the underlying cached data.

=head1 CONFIGURATION

The configuration is read from a YAML file containing a hash with the following keys: 

=over 4

=item B<base_url>

The base URL used to construct the requests.

=item B<timeout>

How long to wait for a response from the server.

=item B<paths>

A list of paths (relative to B<base_url>) to be retrieved.

=back

=head2 Example Configuration

    ---
    base_url: http://gtrap1a.internal.sanger.ac.uk:9000/
    timeout: 900
    paths:
      - /htgt/report/recovery_index
      - /htgt/report/recovery_for_targ_vectors_no_ep_no_dna
      - /htgt/report/recovery_for_targ_vectors_ep_fail_no_qc_pos_traps_only
      - /htgt/report/get_all_alleles
      - /htgt/report/get_all_targeting_vectors
      - /htgt/report/get_projects

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>
