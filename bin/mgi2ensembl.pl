#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/mgi2ensembl.pl $
# $LastChangedRevision: 2875 $
# $LastChangedDate: 2010-10-04 13:22:00 +0100 (Mon, 04 Oct 2010) $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Perl6::Slurp;
use Pod::Usage;
use SOAP::Lite;

my $email = $ENV{USER} . '@sanger.ac.uk';

GetOptions(
    'help'    => sub { pod2usage( -verbose => 1 ) },
    'man'     => sub { pod2usage( -verbose => 2 ) },
    'file=s@' => \my @files,
    'email=s' => \$email,
) or pod2usage(2);

pod2usage( "MGI accession ids may be specified in file(s) or on the command line, but not both" )
    if @files and @ARGV;

my @mgi_accession_ids = @ARGV  ? @ARGV
                      : @files ? map slurp( $_, { chomp => 1 } ), @files
                      :          slurp( \*STDIN, { chomp => 1 } );
                      
my %params;
if ( defined $ENV{HTTP_PROXY} ) {
    $params{proxy} = [ http => $ENV{HTTP_PROXY} ];
}

$params{timeout} = 5;

my $soap = SOAP::Lite->proxy( 'http://services.informatics.jax.org/mgiws', %params )
    ->autotype(0);

# Construct an idSet with our MGI accession ids
my @idSetValues =  map { SOAP::Data->name( id => $_ )->prefix( 'bt' ) } @mgi_accession_ids;

my $idSet = SOAP::Data->name( "IDSet" => \SOAP::Data->value( @idSetValues ) )
    ->attr( { "IDType" => 'mgiMarker' } ) 
    ->prefix( 'req' );

# ...and a requestorEmail with our email address
my $requestorEmail = SOAP::Data->name( requestorEmail => $email )
    ->prefix( 'req' );

# ...and a returnSet with just the ensembl and vega attributes
my @returnSetValues = map { SOAP::Data->name( attribute => $_ )->prefix( 'bt') } qw( ensembl vega );

my $returnSet = SOAP::Data->name( "returnSet" => \SOAP::Data->value( @returnSetValues ) )
    ->prefix( 'req' );

# add the requestorEmail, IDSet and resultSet to a batchMarkerRequest element
my $request = SOAP::Data->name( 'batchMarkerRequest' => \SOAP::Data->value( $requestorEmail, $idSet, $returnSet ) )
    ->attr( { 'xmlns:bt' => 'http://ws.mgi.jax.org/xsd/batchType' } )
    ->prefix( 'req' )
    ->uri( 'http://ws.mgi.jax.org/xsd/request' );

# submit the request to the submitDocument method
my $result = $soap->submitDocument($request);

# deal with SOAP errors
if ( $result->fault ) {
    die join( q{, }, $result->faultcode, $result->faultstring ) . "\n";
}

# print out the results
foreach my $r ( $result->paramsout ) {
    print join( "\t", @{$r}{ qw(input ensemblID vegaID) } ) . "\n";
}

__END__

=pod

=head1 NAME

mgi2ensembl.pl

=head1 SYNOPSIS

  mgi2ensembl.pl [OPTIONS] [--file=FILENAME ...]

  mgi2ensembl.pl [MGI_ACCESSION_ID ...]

  Options:

    --help    Display a brief help message
    --man     Display the full manual page
    --email   Specify the requestor email address (default I<$USER>@sanger.ac.uk>)
    --file    Specify path to file containing a list of MGI accession ids; may be given
              more than once to read multiple files.

=head1 DESCRIPTION

This program reads a list of MGI accession ids from the file(s)
specified by B<--file>, or from ARGV if B<--file> is specified, or
from STDIN if ARGV is empty. It then issues a request to the MGI web
service to request the corresponding EnsEMBL and Vega ids and writes
tab-delimited output to STDOUT with the MGI accession id, EnsEMBL
stable id, and Vega id.

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>

=cut
