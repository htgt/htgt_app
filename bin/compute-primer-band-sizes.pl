#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Bio::Seq;
use Bio::SeqIO;
use IO::String;
use HTGT::DBFactory;
use Const::Fast;
use Log::Log4perl ':easy';
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use Try::Tiny;

const my %QC_PRIMERS => (

    FRTL => Bio::Seq->new(
        -display_id => 'FRTL',
        -alphabet   => 'dna',
        -seq        => 'TATAGGAACTTCGTCGAGATAACTTCG'
    ),

    FRTL3 => Bio::Seq->new(
        -display_id => 'FRTL3',
        -alphabet   => 'dna',
        -seq        => 'AAGTATAGGAACTTCGTCGAGATAACTTCG'
    ),


    JOEL2 => Bio::Seq->new(
        -display_id => 'JOEL2',
        -alphabet   => 'dna',
        -seq        => 'GCAATAGCATCACAAATTTCACAAATAAAGCA'
    ),

    LAR2 => Bio::Seq->new(
        -display_id => 'LAR2',
        -alphabet   => 'dna',
        -seq => 'CCCCTTCCTCCTACATAGTTGGCAG'
    ),

    LAR3 => Bio::Seq->new(
        -display_id => 'LAR3',
        -alphabet   => 'dna',
        -seq        => 'CACAACGGGTTCTTCTGTTAGTCC',
    ),

    LAR5 => Bio::Seq->new(
        -display_id => 'LAR5',
        -alphabet   => 'dna',
        -seq        => 'CCTTCTACCCCAGACCTTGGGACCACC'
    ),

    LAR7 => Bio::Seq->new(
        -display_id => 'LAR7',
        -alphabet   => 'dna',
        -seq        => 'GGTGTGGGAAAGGGTTCGAAGTTCCTAT'
    ),

    LAVI => Bio::Seq->new(
        -display_id => 'LAVI',
        -alphabet   => 'dna',
        -seq        => 'TAGGAACTTCGGAATAGGAACTTCGG'
    ),

    LF => Bio::Seq->new(
        -display_id => 'LF',
        -alphabet   => 'dna',
        -seq        => 'GAGATGGCGCAACGCAATTAATG'
    ),
    
    PNFLR => Bio::Seq->new(
        -display_id => 'PNFLR',
        -alphabet   => 'dna',
        -seq        => 'CATGTCTGGATCCGGGGGTACCGCGTCGAG'
    ),

    R1RN => Bio::Seq->new(
        -display_id => 'R1RN',
        -alphabet   => 'dna',
        -seq        => 'TGATATCGTGGTATCGTTATGCGCCT',
    ),

    RAF2 => Bio::Seq->new(
        -display_id => 'RAF2',
        -alphabet   => 'dna',
        -seq        => 'GCAATAGCATCACAAATTTCACAAATAAAGCA'
    ),
);

# These should correspond to the columns in the HTGTDB::PrimerBandSize model; if
# you want to store additional band sizes, the model and underlying database table 
# should be updated first.

const my @PRIMER_PAIRS => qw(                                                                
                                GF3_R1RN
                                GF3_LAR2
                                GF3_LAR3
                                GF3_LAR5
                                GF3_LAR7
                                GF3_LAVI
                                GF4_R1RN
                                GF4_LAR2
                                GF4_LAR3
                                GF4_LAR5
                                GF4_LAR7
                                GF4_LAVI
                                PNFLR_GR3
                                PNFLR_GR4
                                RAF2_GR3
                                RAF2_GR4
                                JOEL2_GR3
                                JOEL2_GR4
                                FRTL_GR3
                                FRTL_GR4
                                FRTL3_GR3                                                                
                                FRTL3_GR4
                                LF_GR3
                                LF_GR4
                        );

const my $GET_PRIMERS_QUERY => <<'EOT';
select ftd.description as "primer", to_char(fd2.data_item) as "seq_str"
from design d
join feature f
  on f.design_id = d.design_id
join feature_type_dict ftd
  on ftd.feature_type_id = f.feature_type_id
  and ftd.description in ( 'GF3', 'GF4', 'GR3', 'GR4' )
join feature_data fd1
  on fd1.feature_id = f.feature_id
  and fd1.data_item is not null
join feature_data_type_dict fdtd1
  on fdtd1.feature_data_type_id = fd1.feature_data_type_id
  and fdtd1.description = 'validated'
join feature_data fd2
  on fd2.feature_id = f.feature_id
join feature_data_type_dict fdtd2
  on fdtd2.feature_data_type_id = fd2.feature_data_type_id
  and fdtd2.description = 'sequence'
where d.design_id = ?
EOT

{
    my $log_level = $WARN;
    
    GetOptions(
        help     => sub { pod2usage( -verbose => 1 ) },
        man      => sub { pod2usage( -verbose => 2 ) },
        debug    => sub { $log_level = $DEBUG },
        verbose  => sub { $log_level = $INFO },
        commit   => \my $commit,
        override => \my $override,
    ) or pod2usage(2);    

    Log::Log4perl->easy_init(
        {
            level  => $log_level,
            layout => '%d %p %x %m%n',
        }
    );

    my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

    my %search = (
        'me.cassette'  => { '!=', undef },
        'me.design_id' => { '!=', undef }
    );
    if ( @ARGV ) {
        $search{'me.project_id'} = \@ARGV    
    }

    $htgt->txn_do(
        sub {
            my $project_rs = $htgt->resultset( 'Project' )->search_rs( \%search, { prefetch => 'primer_band_sizes' } );
            while ( my $project = $project_rs->next ) {
                next if $project->primer_band_sizes and not $override;
                Log::Log4perl::NDC->push( $project->project_id );
                try {
                    update_primer_band_sizes( $htgt, $project );
                }
                catch {
                    ERROR( $_ );
                };
                Log::Log4perl::NDC->pop;
            }            
            unless ( $commit ) {
                WARN "Rollback";
                $htgt->txn_rollback;                
            }
        }
    );
}

sub update_primer_band_sizes {
    my ( $htgt, $project ) = @_;

    DEBUG( "update_primer_band_sizes" );
    
    my $seq = $project->design->allele_seq( $project->cassette );
    unless ( $seq ) {
        WARN( "failed to compute allele_seq for project" );
        return;
    }
    
    my $primers = get_primers( $htgt, $project->design_id );

    my $band_sizes = compute_band_sizes( $seq->seq, { %QC_PRIMERS, %$primers } );

    my $num_bands = 0;
    for ( @PRIMER_PAIRS ) {
        if ( $band_sizes->{$_} ) {
            INFO( "$_ => $band_sizes->{$_}" );
            $num_bands++;
        }
        else {
            WARN( "failed to compute $_ band size" );            
        }
    }

    if ( $num_bands > 0 ) {
        $project->search_related_rs( 'primer_band_sizes' )->update_or_create( $band_sizes );
    }
}

sub compute_band_sizes {
    my ( $seq, $primers ) = @_;

    my %band_sizes;
    for my $pair ( @PRIMER_PAIRS ) {
        my $band_size;
        my ( $p1, $p2 ) = map $primers->{$_}, split '_', $pair;
        if ( $p1 and $p2 ) {
            my $i1 = index( $seq, $p1->seq );
            my $i2 = index( $seq, $p2->revcom->seq );
            if ( $i1 > 0 and $i2 > 0 ) {
                $band_size = $i2 + $p2->length - $i1;
            }
        }
        $band_sizes{ $pair } = $band_size;
    }

    DEBUG( sub { "Band sizes: " . Dumper( \%band_sizes ) } );
    
    return \%band_sizes;
}

sub get_primers {
    my ( $htgt, $design_id ) = @_;
    
    my $primers = $htgt->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            $dbh->selectall_hashref( $GET_PRIMERS_QUERY, 'primer', undef, $design_id );
        }
    );

    for my $primer ( qw( GF3 GF4 GR3 GR4 ) ) {
        if ( my $v = $primers->{$primer} ) {
            $primers->{ $primer } = Bio::Seq->new(
                -display_id => $primer,
                -alphabet   => 'dna',
                -seq        => $v->{seq_str}
            );
        }
        else {
            WARN( "desgin $design_id missing primer $primer" );
        }
    }
    
    DEBUG( sub { "Retrieved primers: " . Dumper( $primers ) } );

    return $primers;
}

__END__

=pod

=head1 NAME

compute-primer-band-sizes.pl

=head1 SYNOPSIS

  compute-primer-band-sizes.pl [--commit|--override] [PROJECT_ID ...]

=head1 DESCRIPTION

This program examines the mutant allele sequence for a project and
computes the sizes of various bands used in QC.

=head1 OPTIONS

=over

=item --help

Display a brief help message

=item --man

Display the manual page

=item --debug

Log debug messages

=item --verbose

Log info messages

=item --commit

Commit changes to the database (default is to rollback changes)

=item --override

The default behaviour of this script is to add band sizes for projects
that have no primer band sizes defined.  If the C<--override> flag is
set, existing band sizes will be recomputed and updated.

=back

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Genome Research Ltd

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

    
