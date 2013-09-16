#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/floxed_exon_info.pl $
# $LastChangedRevision: 1132 $
# $LastChangedDate: 2010-02-23 16:54:25 +0000 (Tue, 23 Feb 2010) $
# $LastChangedBy: rm7 $

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory;
use HTGT::Utils::FloxedExonData;
use Readonly;

Readonly my $INFO_FORMAT => <<'EOT';
design:                  %d
target_start:            %d
target_end:              %d
target_strand:           %d
first_floxed_exon:       %s
first_floxed_exon_phase: %d
first_floxed_exon_rank:  %d
last_floxed_exon:        %s
last_floxed_exon_rank:   %d
exon_rank_phrase:        %s
EOT

my $design;

GetOptions(
    'help'     => sub { pod2usage( -verbose => 1 ) },
    'man'      => sub { pod2usage( -verbose => 2 ) },
    'design=i' => \$design
) and ( defined $design or @ARGV == 2 )
    or pod2usage(2);

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

my $info;

if ( defined $design ) {
    $info = get_floxed_exon_data( $htgt, $design );
}
else {
    $info = get_floxed_exon_data( $htgt, { plate_name => $ARGV[0], well_name => $ARGV[1] } );
}

printf( $INFO_FORMAT,
        $info->{design}->design_id,
        $info->{target_start},
        $info->{target_end},
        $info->{target_strand},
        $info->{first_floxed_exon}->ensembl_exon_stable_id,
        $info->{first_floxed_exon_phase},
        $info->{first_floxed_exon_rank},
        $info->{last_floxed_exon}->ensembl_exon_stable_id,
        $info->{last_floxed_exon_rank},
        $info->{exon_rank_phrase},
    );

__END__

=pod

=head1 NAME

floxed_exon_info.pl

=head1 SYNOPSIS

  floxed_exon_info.pl --design 47361

  floxed_exon_info.pl 13 B05

=head1 DESCRIPTION

Print information about the exons floxed by a knockout design.

=head1 SEE ALSO

L<HTGT::Utils::FloxedExonData>.

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>.

=cut
