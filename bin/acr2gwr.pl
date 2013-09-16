#!/usr/bin/env perl
# acr2gwr.pl --- extract clones for gateway recovery from alternate clone recovery no-alternates report
# Created: 26 Feb 2010
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/acr2gwr.pl $
# $LastChangedRevision: 1210 $
# $LastChangedDate: 2010-03-03 11:39:01 +0000 (Wed, 03 Mar 2010) $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use IO::File;
use IO::Handle;
use List::MoreUtils 'all';
use Pod::Usage;
use Readonly;
use Text::CSV_XS;

Readonly my %IS_PROMOTORLESS_CASSETTE =>  map { $_ => 1 }
    qw( L1L2_gt0 L1L2_gt1 L1L2_gt2 L1L2_gtk L1L2_st0 L1L2_st1 L1L2_st2 );

Readonly my $MIN_PROMOTORLESS_TRAPS => 4;

GetOptions(
    help  => sub { pod2usage( -verbose => 1 ) },
    man   => sub { pod2usage( -verbose => 2 ) },
) and @ARGV == 1 or pod2usage(2);

my ( $column_headers, $no_alternates ) = parse_no_alternates( shift );

print STDERR @{ $no_alternates } . " genes with no alternate candidate\n";

my @for_gateway = grep wanted_for_gateway( $_ ), @{ $no_alternates };

print STDERR @for_gateway . " genes for gateway recovery\n";

dump_csv( $column_headers, \@for_gateway )
    if @for_gateway;

sub dump_csv {
    my ( $column_headers, $clones ) = @_;

    my $ofh = IO::Handle->new->fdopen( fileno(STDOUT), 'w' )
        or die "dup STDOUT: $!";
    
    my $csv = Text::CSV_XS->new( { eol => $/ } );

    $csv->print( $ofh, $column_headers );

    for ( map @$_, @{ $clones } ) {
        $csv->print( $ofh, [ @{$_}{ @{ $column_headers } } ] );
    }
}

sub wanted_for_gateway {
    my @clones = @{ $_[0] };

    return 1 if all { $IS_PROMOTORLESS_CASSETTE{ $_->{cassette} } } @clones
        and ( $clones[0]->{sp}
                  or $clones[0]->{tm}
                      or ( $clones[0]->{mgi_gt_count} || 0 ) < $MIN_PROMOTORLESS_TRAPS );

    return;
}

sub parse_no_alternates {
    my $acr = shift;

    my $ifh = IO::File->new( $acr, O_RDONLY )
        or die "open $acr: $!";

    my $csv = Text::CSV_XS->new;

    my $header = $csv->getline( $ifh );
    
    $csv->column_names( $header );

    my %by_gene;

    while ( my $record = $csv->getline_hr( $ifh ) ) {
        push @{ $by_gene{ $record->{marker_symbol} } }, $record;
    }

    return ( $header, [ values %by_gene ] );
}

__END__

=head1 NAME

acr2gwr.pl - extract clones for gateway recovery from alternate clone recovery no-alternates report

=head1 SYNOPSIS

  acr2gwr.pl NO_ALTERNATES.CSV

=head1 DESCRIPTION

Stub documentation for acr2gwr.pl, 

=head1 AUTHOR

Ray Miller, E<lt>rm7@hpgen-1-14.internal.sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Genome Research Ltd

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
