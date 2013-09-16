#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use HTGT::DBFactory;
use IO::Handle;
use Pod::Usage;
use Text::CSV_XS;

GetOptions(
    'help'         => sub { pod2usage( -verbose => 1 ) },
    'man'          => sub { pod2usage( -verbose => 2 ) },
) or pod2usage(2);


my $ifh = IO::Handle->new_from_fd( *STDIN, 'r' )
    or die "fdopen STDIN: $!\n";

my $ofh = IO::Handle->new_from_fd( *STDOUT, 'w' )
    or die "fdopen STDOUT: $!\n";

my $schema = HTGT::DBFactory->connect( 'eucomm_vector' );

my $csv = Text::CSV_XS->new( { eol => "\n" } );

while ( my $data = $csv->getline( $ifh ) ) {
    my $well_name = $data->[0];
    my $well_summary = $schema->resultset( 'HTGTDB::WellSummaryByDI' )->find(
        {
            epd_well_name => $well_name
        }
    );
    unless ( $well_summary ) {
        push @{ $data }, '', '', '', '', '', "No such well: $well_name";
        $csv->print( $ofh, $data );
        next;
    }
    push @{ $data }, map { $well_summary->$_ } qw( es_cell_line bac epd_distribute targeted_trap );
    push @{ $data }, $well_summary->epd_well->well_data_value( 'allele_name' ) || '';
    
    unless ( $well_summary->es_cell_line ) {
        push @{ $data }, "no es_cell_line in well_summary";
    }
    unless ( $well_summary->bac ) {
        push @{ $data }, "no bac in well_summary";
    }
    unless ( $well_summary->epd_distribute or $well_summary->targeted_trap ) {
        push @{ $data }, "(not (or (distributable? clone) (targeted-trap? clone)))";
    }
    $csv->print( $ofh, $data );   
}

__END__

=pod

=head1 NAME

microinjection_clone_discrepancies

=head1 SYNOPSIS

  microinjection_clone_discrepancies

=cut
