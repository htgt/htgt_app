package HTGT::Utils::FloxedExonData;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/lib/HTGT/Utils/FloxedExonData.pm $
# $LastChangedRevision: 1516 $
# $LastChangedDate: 2010-04-21 14:34:58 +0100 (Wed, 21 Apr 2010) $
# $LastChangedBy: rm7 $

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ qw( get_floxed_exon_data get_target_details ) ],
    groups  => {
        default => [ 'get_floxed_exon_data' ],
    }
};

use List::MoreUtils 'firstidx';
use Carp 'confess';
use Readonly;

Readonly my %GET_DESIGN => (
    ''                       => \&get_design_by_id,
    'HASH'                   => \&get_design_by_plate_well,
    'HTGTDB::Well'           => sub { $_[1]->design_instance->design },
    'HTGTDB::DesignInstance' => sub { $_[1]->design },
    'HTGTDB::Design'         => sub { $_[1] },
);

sub get_floxed_exon_data {
    my ( $schema, $target ) = @_;

    my $design = $GET_DESIGN{ ref( $target ) }->( $schema, $target );
    
    my ( $target_start, $target_end, $target_chromosome, $target_strand ) = get_target_details( $design );

    my $order = $target_strand == 1 ? '-asc' : '-desc';
    
    my $floxed_exons = get_exons_in_target_region( $schema, $design, $target_chromosome, $target_start, $target_end, $target_strand, $order );
    confess( "No floxed exons for design " . $design->design_id )
        unless @{ $floxed_exons };

    my $all_exons = get_exons_in_transcript( $schema, $floxed_exons->[0]->ensembl_transcript_stable_id, $order );

    my $first_rank  = rank_of_exon( $floxed_exons->[0], $all_exons );
    my $last_rank   = rank_of_exon( $floxed_exons->[-1], $all_exons );

    my $first_phase = phase_of_exon( $schema, $floxed_exons->[0] );
    
    my $phrase;
    if ( @{ $floxed_exons } == 1 ) {
        $phrase = "Exon $first_rank of " . @{ $all_exons };
    }
    else {
        $phrase = "Exons $first_rank to $last_rank of " . @{ $all_exons };
    }
    
    return {
        design                  => $design,
        target_start            => $target_start,
        target_end              => $target_end,
        target_strand           => $target_strand,
        first_floxed_exon       => $floxed_exons->[0],
        first_floxed_exon_rank  => $first_rank,
        first_floxed_exon_phase => $first_phase,
        last_floxed_exon        => $floxed_exons->[-1],
        last_floxed_exon_rank   => $last_rank,
        exon_rank_phrase        => $phrase,
        num_floxed_exons        => scalar( @{ $floxed_exons } ),
    };
}

sub phase_of_exon {
    my ( $schema, $exon ) = @_;

    my @gnm_exon = $schema->resultset( 'GnmExon' )->search(
        {
            'me.primary_name'    => $exon->ensembl_exon_stable_id,
            'gene_build.source'  => 'Ensembl',
            'gene_build.version' => '52.37e',
        },
        {
            join     => { transcript => { gene_build_gene => 'gene_build' } },
            columns  => [ 'phase' ],
            distinct => 1,
        }
    );

    confess( @gnm_exon . " different phases found in GnmExon for " . $exon->ensembl_exon_stable_id )
        unless @gnm_exon == 1;

    return $gnm_exon[0]->phase;
}

sub rank_of_exon {
    my ( $exon, $all_exons ) = @_;

    my $exon_stable_id = $exon->ensembl_exon_stable_id;
    
    my $index = firstidx { $_->ensembl_exon_stable_id eq $exon_stable_id } @{ $all_exons };

    return $index + 1;
}

sub get_exons_in_transcript {
    my ( $schema, $transcript_id, $order ) = @_;
    
    my @exons_in_transcript = $schema->resultset( 'DisplayExon' )->search(
        {
            ensembl_transcript_stable_id => $transcript_id
        },
        {
            order_by => { $order => 'chr_start' }
        }
    );

    return \@exons_in_transcript;
}

sub get_exons_in_target_region {
    my ( $schema, $design, $target_chromosome, $target_start, $target_end, $target_strand ) = @_;

    my $order = $target_strand == 1 ? '-asc' : '-desc';
    my $start = $target_strand == 1 ? 'chr_start' : 'chr_end';
    
    my @target_exons = $schema->resultset( 'DisplayExon' )->search(
        {
            chr_name   => $target_chromosome,
            chr_strand => $target_strand,
            -and       => [
                $start => { '>', $target_start },
                $start => { '<', $target_end },
            ]
        },
        {
            order_by => { $order => 'chr_start' }
        }
    );

    return \@target_exons;
}

sub get_target_details {
    my ( $design ) = @_;

    my $df = $design->validated_display_features();

    defined $df->{U3} and defined $df->{D5}
        or confess( "failed to retrieve U3 and D5 features for design " . $design->design_id  );

    my $strand = $design->locus->chr_strand || '<undef>';
    
    if ( $strand == 1 ) {
        return ( $df->{U3}->feature_end, $df->{D5}->feature_start, $df->{U3}->chromosome->name, $strand );
    }
    elsif ( $strand == -1 ) {
        return ( $df->{D5}->feature_end, $df->{U3}->feature_start, $df->{U3}->chromosome->name, $strand );
    }
    else {
        confess "Unexpected strand $strand for design " . $design->design_id;
    }
}

sub get_design_by_id {
    my ( $schema, $design_id ) = @_;

    my $design = $schema->resultset( 'Design' )->find(
        {
            design_id => $design_id
        }
    ) or confess( "failed to retrieve design for id: $design_id" );

    return $design;
}

sub get_design_by_plate_well {
    my ( $schema, $data ) = @_;

    my $well = $schema->resultset( 'Well' )->find(
        {
            'plate.name'   => $data->{plate_name},
            'me.well_name' => $data->{well_name},
        },
        {
            join => 'plate'
        }
    ) or confess( "failed to retrieve well: $data->{plate_name}\[$data->{well_name}\]" );

    $well->design_instance->design;
}

1;

__END__

=pod

=head1 NAME

HTGT::Utils::FloxedExonData

=head1 SYNOPSIS

  use HTGT::Utils::FloxedExonData;

  # $design isa HTGTDB::Design
  $data = get_floxed_exon_data( $design );

  # $design_instance isa HTGTDB::DesignInstance
  $data = get_floxed_exon_data( $design_instance );

  # $well isa HTGTDB::Well
  $data = get_floxed_exon_data( $well );

  # $design_id is an integer
  $data = get_floxed_exon_data( $design_id );

  # $plate_name and $well_name are strings
  $data = get_floxed_exon_data( { plate_name => $plate_name, well_name => $well_name } );

=head1 DESCRIPTION

This module exports the single function, B<get_floxed_exon_data()>, that retrieves
data about the exon floxed by one of our knockout designs. It can look up data
based on plate and well name, a design id, or HTGTDB::Well, HTGTDB::DesignInstance,
or HTGTDB::Design object.

This function returns a hash containing:

=over 4

=item design

The HTGTDB::Design object for this design.

=item target_start

=item target_end

=item target_strand

Coordinates and strand of the region between U3 and D5.

=item first_floxed_exon

An HTGTDB::DisplayExon object representing the first floxed exon.

=item first_floxed_exon_rank

Position of the first floxed exon amongst other exons in this transcript.

=item first_floxed_exon_phase

Phase (reading frame) of the first floxed exon.

=item last_floxed_exon

An HTGTDB::DisplayExon object representing the last floxed exon.

=item last_floxed_exon_rank

Position of the last floxed exon amongst other exons in this transcript.

=item exon_rank_phrase

An English phrase describing the floxed exon.

=back

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>.

=cut
