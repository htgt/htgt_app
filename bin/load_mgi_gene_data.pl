#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/load_mgi_gene_data.pl $
# $LastChangedRevision: 7931 $
# $LastChangedDate: 2013-01-04 05:47:40 +0000 (Fri, 04 Jan 2013) $
# $LastChangedBy: vvi $
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use Const::Fast;
use Hash::MoreUtils qw( slice );
use HTGT::DBFactory;
use HTGT::Utils::EnsEMBL;
use HTGT::Utils::FileDownloader qw(download_url_to_tmp_file);
use Try::Tiny;
use Log::Log4perl ':easy';
use Data::Dumper;

const my $DEFAULT_MGI_COORDINATE_URL => 'ftp://ftp.informatics.jax.org/pub/reports/MGI_Gene_Model_Coord.rpt';
const my $DEFAULT_MGI_ENSEMBL_URL    => 'ftp://ftp.informatics.jax.org/pub/reports/MRK_ENSEMBL.rpt';

const my @MGI_COORDINATE_COLUMNS => qw(
    mgi_accession_id
    marker_type
    marker_symbol
    marker_name
    genome_build
    entrez_gene_id
    ncbi_gene_chromosome
    ncbi_gene_start
    ncbi_gene_end
    ncbi_gene_strand
    ensembl_gene_id
    ensembl_gene_chromosome
    ensembl_gene_start
    ensembl_gene_end
    ensembl_gene_strand
    vega_gene_id
    vega_gene_chromosome
    vega_gene_start
    vega_gene_end
    vega_gene_strand
);

const my @MGI_GENE_DATA     => grep !/^ensembl_|vega_/, @MGI_COORDINATE_COLUMNS;

const my @ENSEMBL_GENE_DATA => grep /^ensembl_/, @MGI_COORDINATE_COLUMNS;

const my @VEGA_GENE_DATA    => grep /^vega_/, @MGI_COORDINATE_COLUMNS;

const my @STRAND_DATA       => grep /_strand$/, @MGI_COORDINATE_COLUMNS;

const my @MGI_ENSEMBL_COLUMNS => qw (
    mgi_accession_id
    marker_symbol
    marker_name
    cm_position
    chromosome
    ensembl_gene_id
    ensembl_transcript_id
    ensembl_protein_id
);

# Global variable so any subrotine can signal non-zero exit
my $exit_code = 0;

{

    my $log_level = $WARN;

    GetOptions(
        'help'             => sub { pod2usage( -verbose => 1 ) },
        'man'              => sub { pod2usage( -verbose => 2 ) },
        'debug'            => sub { $log_level = $DEBUG },
        'verbose'          => sub { $log_level = $INFO },
        'coordinate-url=s' => \my $mgi_coordinate_url,
        'ensembl-url=s'    => \my $mgi_ensembl_url,
        'commit'           => \my $commit,
    ) or pod2usage(2);

    Log::Log4perl->easy_init( { layout => '%p %m%n', level => $log_level } );

    my $mgi_coordinate_data = download_url_to_tmp_file( $mgi_coordinate_url || $DEFAULT_MGI_COORDINATE_URL );
    my $mgi_ensembl_data    = download_url_to_tmp_file( $mgi_ensembl_url || $DEFAULT_MGI_ENSEMBL_URL );

    my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

    $htgt->txn_do(
        sub {
            delete_gene_data( $htgt );
            load_mgi_coordinate_data( $htgt, $mgi_coordinate_data );
            load_mgi_ensembl_data( $htgt, $mgi_ensembl_data );
            unless ( $commit ) {
                warn "Rollback\n";
                $htgt->txn_rollback;
            }
        }
    );

    exit $exit_code;
}

sub delete_gene_data {
    my $htgt = shift;

    for ( qw( MGIEnsemblGeneMap EnsemblGeneData MGIVegaGeneMap VegaGeneData MGIGeneData ) ) {
        $htgt->resultset( $_ )->delete;
    }
}

sub load_mgi_coordinate_data {
    my ( $htgt, $ifh ) = @_;

    while ( <$ifh> ) {
        chomp;
        my $record = parse_mgi_coordinate_record( $_ ) or next;
        try {
            add_mgi_gene_data( $htgt, $record );
        }
        catch {
            ERROR($_);
            $exit_code = 2;
        };
    }
}

sub load_mgi_ensembl_data {
    my ( $htgt, $ifh ) = @_;

    while ( <$ifh> ) {
        chomp;
        my $record = parse_mgi_ensembl_record( $_ ) or next;

        next if $record->{marker_name} eq 'withdrawn';

        try {
            add_ensembl_gene_data( $htgt, $record );
        }
        catch {
            ERROR($_);
            $exit_code = 2;
        };
    }

}

sub parse_mgi_ensembl_record {
    my $input_line = shift;

    return unless /^MGI:/;

    my %data;
    @data{@MGI_ENSEMBL_COLUMNS} = split "\t", $input_line;

    return \%data;
}

sub parse_mgi_coordinate_record {
    my $input_line = shift;

    return unless /^MGI:/;

    my %data;
    @data{@MGI_COORDINATE_COLUMNS} = split "\t", $_;


    for ( keys %data ) {
        $data{$_} = undef if $data{$_} and lc( $data{$_} ) eq 'null';
    }


    for ( @STRAND_DATA ) {
        next unless $data{$_};
        if ( $data{$_} eq '+' ) {
            $data{$_} = 1;
        }
        elsif ( $data{$_} eq '-' ) {
            $data{$_} = -1;
        }
        else {
            WARN "Invalid $_ '$data{$_}' for $data{mgi_accession_id}";
            delete $data{$_};
        }
    }

    return \%data;
}

sub add_mgi_gene_data {
    my ( $htgt, $data ) = @_;

    my %mgi_gene_data = slice $data, @MGI_GENE_DATA;

    INFO( "Creating MGIGeneData: $data->{mgi_accession_id}" );

    # remove spurious genome build column (not in our model)
    delete $mgi_gene_data{'genome_build'};

    $htgt->resultset( 'MGIGeneData' )->create( \%mgi_gene_data );

    $htgt->resultset( 'MGIGeneIdMap' )->find_or_create( { mgi_accession_id => $data->{mgi_accession_id} } );

    if ( $data->{ensembl_gene_id} ) {
        add_ensembl_gene_data( $htgt, $data );
    }

    if ( $data->{vega_gene_id} ) {
        add_vega_gene_data( $htgt, $data );
    }
}

sub add_ensembl_gene_data {
    my ( $htgt, $data ) = @_;

    for my $ensembl_gene_id ( split /\s*,\s*/, $data->{ensembl_gene_id} ) {
        my $gene_data = $htgt->resultset( 'EnsemblGeneData' )->find(
            {
                ensembl_gene_id => $ensembl_gene_id
            }
        );
        unless ( $gene_data ) {
            $gene_data = create_ensembl_gene_data( $htgt, $ensembl_gene_id );
        }
        next unless $gene_data;
        INFO( "Creating MGIEnsemblGeneMap $data->{mgi_accession_id} => $ensembl_gene_id" );
        $htgt->resultset( 'MGIEnsemblGeneMap' )->find_or_create(
            {
                mgi_accession_id => $data->{mgi_accession_id},
                ensembl_gene_id  => $ensembl_gene_id
            }
        );
    }
}

sub add_vega_gene_data {
    my ( $htgt, $data ) = @_;

    my %vega_gene_data = slice $data, @VEGA_GENE_DATA;

    for my $vega_gene_id ( split /\s*,\s*/, $data->{vega_gene_id} ) {
        INFO( "Creating VegaGeneData for: $vega_gene_id" );
        $htgt->resultset( 'VegaGeneData' )->find_or_create( \%vega_gene_data );
        INFO( "Creating MGIVegaGeneMap $data->{mgi_accession_id} => $vega_gene_id" );
        $htgt->resultset( 'MGIVegaGeneMap' )->create(
            {
                mgi_accession_id => $data->{mgi_accession_id},
                vega_gene_id     => $vega_gene_id
            }
        );
    }
}

{
    my $gene_adaptor;

    sub create_ensembl_gene_data {
        my ( $htgt, $ensembl_gene_id ) = @_;

        $gene_adaptor ||= HTGT::Utils::EnsEMBL->gene_adaptor;

        my $gene = $gene_adaptor->fetch_by_stable_id( $ensembl_gene_id );
        unless ( $gene ) {
            WARN "failed to retrieve Ensembl gene $ensembl_gene_id";
            return;
        }

        my ( $sp, $tm ) = ( 0, 0 );

        for my $transcript ( @{ $gene->get_all_Transcripts } ) {
            my $translation = $transcript->translation
                or next;
            for my $domain ( @{ $translation->get_all_ProteinFeatures }  ) {
                my $logic_name = $domain->analysis->logic_name;
                if ( $logic_name eq 'signalp' ) {
                    $sp = 1;
                }
                elsif ( $logic_name eq 'tmhmm' ) {
                    $tm = 1;
                }
            }
            # No need to consider other transcripts if we found the
            # domains we are looking for
            last if $sp and $tm;
        }

        INFO( "Creating EnsemblGeneData for: $ensembl_gene_id" );
        $htgt->resultset( 'EnsemblGeneData' )->create(
            {
                ensembl_gene_id         => $ensembl_gene_id,
                ensembl_gene_chromosome => $gene->seq_region_name,
                ensembl_gene_start      => $gene->seq_region_start,
                ensembl_gene_end        => $gene->seq_region_end,
                ensembl_gene_strand     => $gene->seq_region_strand,
                sp                      => $sp,
                tm                      => $tm
            }
        );
    }
}

__END__

=head1 NAME

load_mgi_gene_data.pl - Load mgi_gene_data and associated tables

=head1 SYNOPSIS

load_mgi_gene_data.pl [options]

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for load_mgi_gene_data.pl,

=head1 AUTHOR

Ray Miller, E<lt>rm7@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Genome Research Ltd

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
