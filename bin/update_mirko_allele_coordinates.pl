#!/usr/bin/env perl
use warnings FATAL => 'all';
use strict;

# Note
# Allele 25849 was updated manually because the design was on the +ve strand
# and the gene it targeted was on the -ve strand.

use HTGT::Utils::Tarmits;
use HTGT::DBFactory;
use Getopt::Long;
use Log::Log4perl ':easy';
use List::MoreUtils qw( uniq );
use Try::Tiny;
use Const::Fast;
use Data::Dumper::Concise;

my $loglevel = $INFO;
my $commit;

const my $ASSEMBLY_ID => 101;

GetOptions(
    'debug' => sub { $loglevel = $DEBUG },
    commit  => \$commit,
);

Log::Log4perl->easy_init( { level => $loglevel, layout => '%p %x %m%n' } );

my $targrep_schema = HTGT::DBFactory->connect( 'tarmits' );
my $htgt_schema    = HTGT::DBFactory->connect('eucomm_vector', { FetchHashKeyName => 'NAME_lc' });
#idcc_api is used to update tarmits through the api. connection details set in yml file behind ENV variable TARMITS_CLIENT_CONF
my $idcc_api       = HTGT::Utils::Tarmits->new_with_config();

my $mirko = $targrep_schema->resultset('TargRepPipeline')->find( { name => 'mirKO' } );
my @mirko_escells = $mirko->targ_rep_es_cells->search( {}, { columns => [ 'allele_id' ] } );
my @mirko_targ_vecs = $mirko->targ_rep_targeting_vectors->search( {}, { columns => [ 'allele_id' ] } );

my @mirko_allele_ids;
push @mirko_allele_ids, map{ $_->allele_id } @mirko_escells;
push @mirko_allele_ids, map{ $_->allele_id } @mirko_targ_vecs;
my @uniq_mirko_allele_ids = uniq @mirko_allele_ids;

my @alleles = $targrep_schema->resultset('TargRepAllele')->search(
    {
        'me.id' => \@uniq_mirko_allele_ids,
        'targ_rep_mutation_type.name' => 'Deletion',
    },
    {
        join => 'targ_rep_mutation_type',
    }
);

my $allele_id = $ARGV[0];

for my $allele ( @alleles ) {
    if ( $allele_id ) {
        next if $allele_id != $allele->id;
    }
    Log::Log4perl::NDC->remove();
    Log::Log4perl::NDC->push( $allele->id );

    my $design_id = $allele->project_design_id;
    INFO( 'Working on Allele, design_id: ' . $design_id );

    my $design = $htgt_schema->resultset( 'Design' )->find( { design_id => $design_id } );

    unless ( $design ) {
        ERROR( "Unable to find design $design_id" );
        next;
    }

    try{
        update_coordinates( $allele, $design );
    }
    catch {
        ERROR($_ );
    };

}

sub update_coordinates {
    my ( $allele, $design ) = @_;

    unless ( $design->design_type =~  /^Del/ ) {
        ERROR( "Design $design is not of type deletion: " . $design->design_type );
        next;
    }

    my ( $dc, $strand, $chromosome ) = design_coordinates( $design );

    my %update_data = (
        chromosome         => $chromosome,
        strand             => $strand,
        homology_arm_start => $dc->{homology_arm_start},
        homology_arm_end   => $dc->{homology_arm_end},
        cassette_start     => $dc->{cassette_start},
        cassette_end       => $dc->{cassette_end},
    );

    INFO( "Updating allele " . Dumper(\%update_data) );
    return unless $commit;

    $idcc_api->update_allele( $allele->id, \%update_data );

}

sub design_coordinates {
    my $design = shift;

    my $features = design_oligos( $design );

    return unless %{ $features };

    my @strands = uniq map $_->feature_strand, values %{ $features };
    LOGDIE( 'Design ' . $design->design_id . ' features have inconsistent strand' )
        unless @strands == 1;
    my $chr_strand = shift @strands;
    my $strand = $chr_strand == 1 ? '+' : $chr_strand == -1 ? '-' : undef;

    my @chr_names = uniq map $_->chromosome->name, values %{ $features };
    LOGDIE( 'Design ' . $design->design_id . ' features have inconsistent chromosome id')
        unless @chr_names == 1;
    my $chr_name = shift @chr_names;

    my ( $u_oligo, $d_oligo );
    my $num_oligos = scalar( keys %{ $features } );
    # Some of the designs have 6 oligos, if this is the case then the Mirko group
    # picked the U3 and D5 oligos
    if ( $num_oligos > 4 ) {
        $u_oligo = $features->{U3};
        $d_oligo = $features->{D5};
    }
    else {
        $u_oligo = $features->{U5};
        $d_oligo = $features->{D3};
    }

    my %coordinates;
    if ( $chr_strand == 1 ) {
        $coordinates{cassette_start}     = $u_oligo->feature_end;
        $coordinates{cassette_end}       = $d_oligo->feature_start;
        $coordinates{homology_arm_start} = $features->{G5}->feature_start;
        $coordinates{homology_arm_end}   = $features->{G3}->feature_end;
    }
    else {
        $coordinates{cassette_start}     = $u_oligo->feature_start;
        $coordinates{cassette_end}       = $d_oligo->feature_end;
        $coordinates{homology_arm_start} = $features->{G5}->feature_end;
        $coordinates{homology_arm_end}   = $features->{G3}->feature_start;
    }

    return (\%coordinates, $strand, $chr_name );
}

sub design_oligos {
    my ( $design ) = @_;

    my $validated_features = $design->search_related(
        features => {
            'feature_data_type.description' => 'validated'
        },
        {
            join => {
                feature_data => 'feature_data_type'
            }
        }
    );

    my $validated_display_features = $validated_features->search_related(
        display_features => {
            assembly_id => $ASSEMBLY_ID,
            label       => 'construct'
        },
        {
            prefetch => [
                {
                   feature => 'feature_type'
                },
                'chromosome',
            ]
        }
    );

    my %display_feature_for;

    my @types;
    while ( my $df = $validated_display_features->next ) {
        my $type = $df->feature->feature_type->description;
        push @types, $type;
        die "Multiple $type features\n" if exists $display_feature_for{ $type };
        $display_feature_for{ $type } = $df;
    }

    return \%display_feature_for;
}
