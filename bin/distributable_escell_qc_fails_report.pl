#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use DBI;
use Const::Fast;
use Getopt::Long;
use Log::Log4perl ':easy';
use Path::Class;
use HTGT::DBFactory;

#use Data::Dumper;
#$Data::Dumper::Indent = 1;
#$Data::Dumper::Sortkeys = 1;

const my $CONFIG_FILE => $ENV{ES_DISTRIBUTE_CHECK_CONF};

const my $GET_MARKER_SYMBOL_SQL => <<"EOT";
SELECT mgi_accession_id, marker_symbol FROM mgi_gene_data
EOT

const my $UNIQUE_GENE_SQL => <<"EOT";
SELECT distinct genes.mgi_accession_id, pipelines.name as pipeline FROM targ_rep_alleles
join targ_rep_es_cells on targ_rep_es_cells.allele_id = targ_rep_alleles.id
join pipelines on pipelines.id = targ_rep_es_cells.pipeline_id
join genes on genes.id = targ_rep_alleles.gene_id
WHERE targ_rep_es_cells.report_to_public is true
EOT

const my $UNIQUE_ES_CELL_SQL => <<"EOT";
SELECT distinct targ_rep_es_cells.name as es_cell, pipelines.name as pipeline FROM targ_rep_alleles
join targ_rep_es_cells on targ_rep_es_cells.allele_id = targ_rep_alleles.id
join pipelines on pipelines.id = targ_rep_es_cells.pipeline_id
WHERE targ_rep_es_cells.report_to_public is true
EOT

const my $GENES_WITH_DIST_QC_FAILURE_SQL => <<"EOT";
SELECT distinct genes.mgi_accession_id, pipelines.name as pipeline FROM targ_rep_alleles
join targ_rep_es_cells on targ_rep_es_cells.allele_id = targ_rep_alleles.id
join pipelines on pipelines.id = targ_rep_es_cells.pipeline_id
join genes on genes.id = targ_rep_alleles.gene_id
join targ_rep_distribution_qcs on targ_rep_distribution_qcs.es_cell_id = targ_rep_es_cells.id
WHERE targ_rep_es_cells.report_to_public is true
AND (targ_rep_distribution_qcs.copy_number = 'fail'
OR targ_rep_distribution_qcs.five_prime_lr_pcr = 'fail'
OR targ_rep_distribution_qcs.five_prime_sr_pcr = 'fail'
OR targ_rep_distribution_qcs.three_prime_lr_pcr = 'fail'
OR targ_rep_distribution_qcs.three_prime_sr_pcr = 'fail'
OR targ_rep_distribution_qcs.thawing = 'fail'
OR targ_rep_distribution_qcs.lacz = 'fail'
OR targ_rep_distribution_qcs.loa = 'fail'
OR targ_rep_distribution_qcs.loxp = 'fail'
OR targ_rep_distribution_qcs.chr1 = 'fail'
OR targ_rep_distribution_qcs.chr11a = 'fail'
OR targ_rep_distribution_qcs.chr11b = 'fail'
OR targ_rep_distribution_qcs.chr8a = 'fail'
OR targ_rep_distribution_qcs.chr8b = 'fail'
OR targ_rep_distribution_qcs.chry = 'fail')
EOT

const my $ES_CELLS_WITH_DIST_QC_FAILURE_SQL => <<"EOT";
SELECT distinct targ_rep_es_cells.name, pipelines.name as pipeline FROM targ_rep_es_cells
join pipelines on pipelines.id = targ_rep_es_cells.pipeline_id
join targ_rep_distribution_qcs on targ_rep_distribution_qcs.es_cell_id = targ_rep_es_cells.id
WHERE targ_rep_es_cells.report_to_public is true
AND (targ_rep_distribution_qcs.copy_number = 'fail'
OR targ_rep_distribution_qcs.five_prime_lr_pcr = 'fail'
OR targ_rep_distribution_qcs.five_prime_sr_pcr = 'fail'
OR targ_rep_distribution_qcs.three_prime_lr_pcr = 'fail'
OR targ_rep_distribution_qcs.three_prime_sr_pcr = 'fail'
OR targ_rep_distribution_qcs.thawing = 'fail'
OR targ_rep_distribution_qcs.lacz = 'fail'
OR targ_rep_distribution_qcs.loa = 'fail'
OR targ_rep_distribution_qcs.loxp = 'fail'
OR targ_rep_distribution_qcs.chr1 = 'fail'
OR targ_rep_distribution_qcs.chr11a = 'fail'
OR targ_rep_distribution_qcs.chr11b = 'fail'
OR targ_rep_distribution_qcs.chr8a = 'fail'
OR targ_rep_distribution_qcs.chr8b = 'fail'
OR targ_rep_distribution_qcs.chry = 'fail')
EOT

const my $GENES_WITH_USER_QC_FAILURE_SQL => <<"EOT";
SELECT distinct genes.mgi_accession_id, pipelines.name as pipeline FROM targ_rep_alleles
join targ_rep_es_cells on targ_rep_es_cells.allele_id = targ_rep_alleles.id
join pipelines on pipelines.id = targ_rep_es_cells.pipeline_id
join genes on genes.id = targ_rep_alleles.gene_id
WHERE targ_rep_es_cells.report_to_public is true
AND (targ_rep_es_cells.user_qc_karyotype = 'fail'
OR targ_rep_es_cells.user_qc_southern_blot like 'fail%'
OR targ_rep_es_cells.user_qc_southern_blot = 'double integration'
OR targ_rep_es_cells.user_qc_map_test = 'fail'
OR targ_rep_es_cells.user_qc_tv_backbone_assay = 'fail'
OR targ_rep_es_cells.user_qc_five_prime_cassette_integrity = 'fail'
OR targ_rep_es_cells.user_qc_five_prime_lr_pcr = 'fail'
OR user_qc_lacz_sr_pcr = 'fail'
OR targ_rep_es_cells.user_qc_loss_of_wt_allele = 'fail'
OR targ_rep_es_cells.user_qc_loxp_confirmation = 'fail'
OR targ_rep_es_cells.user_qc_mutant_specific_sr_pcr = 'fail'
OR targ_rep_es_cells.user_qc_neo_count_qpcr = 'fail'
OR targ_rep_es_cells.user_qc_neo_sr_pcr = 'fail'
OR targ_rep_es_cells.user_qc_three_prime_lr_pcr = 'fail')
EOT

const my $ES_CELLS_WITH_USER_QC_FAILURE_SQL => <<"EOT";
SELECT distinct targ_rep_es_cells.name, pipelines.name as pipeline FROM targ_rep_es_cells
join pipelines on pipelines.id = targ_rep_es_cells.pipeline_id
WHERE targ_rep_es_cells.report_to_public is true
AND (targ_rep_es_cells.user_qc_karyotype = 'fail'
OR targ_rep_es_cells.user_qc_southern_blot like 'fail%'
OR targ_rep_es_cells.user_qc_southern_blot = 'double integration'
OR targ_rep_es_cells.user_qc_map_test = 'fail'
OR targ_rep_es_cells.user_qc_tv_backbone_assay = 'fail'
OR targ_rep_es_cells.user_qc_five_prime_cassette_integrity = 'fail'
OR targ_rep_es_cells.user_qc_five_prime_lr_pcr = 'fail'
OR user_qc_lacz_sr_pcr = 'fail'
OR targ_rep_es_cells.user_qc_loss_of_wt_allele = 'fail'
OR targ_rep_es_cells.user_qc_loxp_confirmation = 'fail'
OR targ_rep_es_cells.user_qc_mutant_specific_sr_pcr = 'fail'
OR targ_rep_es_cells.user_qc_neo_count_qpcr = 'fail'
OR targ_rep_es_cells.user_qc_neo_sr_pcr = 'fail'
OR targ_rep_es_cells.user_qc_three_prime_lr_pcr = 'fail')
EOT

const my $FAILURE_DATA_SQL => <<"EOT";
SELECT distinct genes.mgi_accession_id, pipelines.name as pipeline,
targ_rep_es_cells.name as es_cell, targ_rep_distribution_qcs.copy_number,
targ_rep_distribution_qcs.five_prime_lr_pcr, targ_rep_distribution_qcs.five_prime_sr_pcr,
targ_rep_distribution_qcs.three_prime_lr_pcr, targ_rep_distribution_qcs.three_prime_sr_pcr,
targ_rep_distribution_qcs.thawing, targ_rep_distribution_qcs.lacz,
targ_rep_distribution_qcs.loa, targ_rep_distribution_qcs.loxp,
targ_rep_distribution_qcs.chr1, targ_rep_distribution_qcs.chr11a,
targ_rep_distribution_qcs.chr11b, targ_rep_distribution_qcs.chr8a,
targ_rep_distribution_qcs.chr8b, targ_rep_distribution_qcs.chry, targ_rep_es_cells.user_qc_karyotype,
targ_rep_es_cells.user_qc_southern_blot, targ_rep_es_cells.user_qc_map_test,
targ_rep_es_cells.user_qc_tv_backbone_assay, targ_rep_es_cells.user_qc_five_prime_cassette_integrity,
targ_rep_es_cells.user_qc_five_prime_lr_pcr, targ_rep_es_cells.user_qc_lacz_sr_pcr,
targ_rep_es_cells.user_qc_loss_of_wt_allele, targ_rep_es_cells.user_qc_loxp_confirmation,
targ_rep_es_cells.user_qc_mutant_specific_sr_pcr, targ_rep_es_cells.user_qc_neo_count_qpcr,
targ_rep_es_cells.user_qc_neo_sr_pcr, targ_rep_es_cells.user_qc_three_prime_lr_pcr FROM targ_rep_alleles
join targ_rep_es_cells on targ_rep_es_cells.allele_id = targ_rep_alleles.id
join pipelines on pipelines.id = targ_rep_es_cells.pipeline_id
join genes on genes.id = targ_rep_alleles.gene_id
join targ_rep_distribution_qcs on targ_rep_distribution_qcs.es_cell_id = targ_rep_es_cells.id
WHERE targ_rep_es_cells.report_to_public is true
AND (targ_rep_distribution_qcs.copy_number = 'fail'
OR targ_rep_distribution_qcs.five_prime_lr_pcr = 'fail'
OR targ_rep_distribution_qcs.five_prime_sr_pcr = 'fail'
OR targ_rep_distribution_qcs.three_prime_lr_pcr = 'fail'
OR targ_rep_distribution_qcs.three_prime_sr_pcr = 'fail'
OR targ_rep_distribution_qcs.thawing = 'fail'
OR targ_rep_distribution_qcs.lacz = 'fail'
OR targ_rep_distribution_qcs.loa = 'fail'
OR targ_rep_distribution_qcs.loxp = 'fail'
OR targ_rep_distribution_qcs.chr1 = 'fail'
OR targ_rep_distribution_qcs.chr11a = 'fail'
OR targ_rep_distribution_qcs.chr11b = 'fail'
OR targ_rep_distribution_qcs.chr8a = 'fail'
OR targ_rep_distribution_qcs.chr8b = 'fail'
OR targ_rep_distribution_qcs.chry = 'fail'
OR targ_rep_es_cells.user_qc_karyotype = 'fail'
OR targ_rep_es_cells.user_qc_southern_blot like 'fail%'
OR targ_rep_es_cells.user_qc_southern_blot = 'double integration'
OR targ_rep_es_cells.user_qc_map_test = 'fail'
OR targ_rep_es_cells.user_qc_tv_backbone_assay = 'fail'
OR targ_rep_es_cells.user_qc_five_prime_cassette_integrity = 'fail'
OR targ_rep_es_cells.user_qc_five_prime_lr_pcr = 'fail'
OR user_qc_lacz_sr_pcr = 'fail'
OR targ_rep_es_cells.user_qc_loss_of_wt_allele = 'fail'
OR targ_rep_es_cells.user_qc_loxp_confirmation = 'fail'
OR targ_rep_es_cells.user_qc_mutant_specific_sr_pcr = 'fail'
OR targ_rep_es_cells.user_qc_neo_count_qpcr = 'fail'
OR targ_rep_es_cells.user_qc_neo_sr_pcr = 'fail'
OR targ_rep_es_cells.user_qc_three_prime_lr_pcr = 'fail')
order by genes.mgi_accession_id
EOT

#const my $OUTFILE => '/software/team87/brave_new_world/data/misc/distributable-escell-qc-fails.csv';
const my $OUTFILE => '/software/team87/brave_new_world/data/misc/distributable-escell-qc-fails2.csv';
#const my $OUTFILE => './distributable-escell-qc-fails.csv';

my $log_level = $WARN;

GetOptions(
    'debug' => sub { $log_level = $DEBUG },
) or die "Usage: $0 [--debug]\n";

Log::Log4perl->easy_init(
    {
        layout => '%m%n',
        level  => $log_level
    }
);

my $config = parse_config_file( $CONFIG_FILE );

#print Dumper $config;

#print "\n\n" . 'dbi:Pg:'.$config->{imits_db} . "\n";
#print $config->{imits_db_username} . "\n";
#print $config->{imits_db_password} ."\n\n";

#my $dbh = DBI->connect('dbi:Pg:database=imits_test;host=imits-db;port=5434','imits','imits');
#my $dbh = DBI->connect( 'DBI:mysql:' . $config->{imits_db}, $config->{imits_db_username}, $config->{imits_db_password} );
#my $dbh = DBI->connect('dbi:Pg:database='.$config->{imits_db}.';host=imits-db;port=5434','imits',$config->{imits_db_password});
my $dbh = DBI->connect('dbi:Pg:database=imits_combined;host=imits-db.internal.sanger.ac.uk;port=5433',$config->{imits_db_username},$config->{imits_db_password});

my ( $unique_genes, $mgi_acc_ids ) = get_pipeline_counts( $dbh, $UNIQUE_GENE_SQL );
my $unique_es_cells                = get_pipeline_counts( $dbh, $UNIQUE_ES_CELL_SQL );
my $genes_with_dist_qc_failure     = get_pipeline_counts( $dbh, $GENES_WITH_DIST_QC_FAILURE_SQL );
my $es_cells_with_dist_qc_failure  = get_pipeline_counts( $dbh, $ES_CELLS_WITH_DIST_QC_FAILURE_SQL );
my $genes_with_user_qc_failure     = get_pipeline_counts( $dbh, $GENES_WITH_USER_QC_FAILURE_SQL );
my $es_cells_with_user_qc_failure  = get_pipeline_counts( $dbh, $ES_CELLS_WITH_USER_QC_FAILURE_SQL );

write_csv_report( $dbh, $unique_genes, $unique_es_cells, $genes_with_dist_qc_failure, $es_cells_with_dist_qc_failure, $genes_with_user_qc_failure, $es_cells_with_user_qc_failure );

sub get_pipeline_counts{
    my ( $dbh, $sql ) = @_;

    my $sth = $dbh->prepare( $sql );
    DEBUG( "Executing SQL query:\n $sql");
    $sth->execute();

    my %unique_entries;
    my $r = $sth->fetchrow_hashref;
    while ($r) {
        $unique_entries{ $r->{pipeline} }++;
        $r = $sth->fetchrow_hashref;
    }

    return \%unique_entries;
}

sub get_marker_symbols{
    my $schema = HTGT::DBFactory->connect( 'eucomm_vector' );

    my %mgi_acc_id_marker_symbol_map;

    my $sth = $schema->storage->dbh->prepare( $GET_MARKER_SYMBOL_SQL );
    $sth->execute();
    my $r = $sth->fetchrow_hashref;
    while($r){
        $mgi_acc_id_marker_symbol_map{ $r->{MGI_ACCESSION_ID } } = $r->{MARKER_SYMBOL};
        $r = $sth->fetchrow_hashref;
    }

    return \%mgi_acc_id_marker_symbol_map;
}

sub write_csv_report{
    my ( $dbh, $unique_genes, $unique_es_cells, $genes_with_dist_qc_failure, $es_cells_with_dist_qc_failure, $genes_with_user_qc_failure, $es_cells_with_user_qc_failure ) = @_;

    DEBUG( "Writing report to $OUTFILE" );
    my $fh = file( $OUTFILE )->openw()
        or die "Could not create file $OUTFILE\n";

    write_summary_table( $fh, $unique_genes, $unique_es_cells, $genes_with_dist_qc_failure, $es_cells_with_dist_qc_failure, $genes_with_user_qc_failure, $es_cells_with_user_qc_failure );

    my $marker_symbols = get_marker_symbols();

    $fh->print("\nMGI accession ID,Marker symbol,ES cell,Pipeline,QC fails,Distribution QC,,,,,,,,,,,,,,,Mouse clinic QC,,,,,,,,,,,,\n");
    $fh->print(",,,,,Copy number,5' LR PCR,5' SR PCR,3' LR PCR,3' SR PCR,Thawing,lacZ,LOA,loxP,Chr 1,Chr 11a,Chr 11b,Chr 8a,Chr 8b,Chr Y,Karyotype,Southern blot,Map test,TV backbone assay,5' cassette integrity, 5' LR PCR,3' LR PCR,lacZ SR PCR,Loss of WT allele,loxP confirmation,Mutant specific SR PCR,Neo count QPCR,Neo SR PCR\n");

    my $sth = $dbh->prepare( $FAILURE_DATA_SQL );
    DEBUG( "Executing SQL query:\n $FAILURE_DATA_SQL");
    $sth->execute();

    my $r = $sth->fetchrow_hashref;
    while ($r) {
        write_es_cell_detail_row( $fh, $r, $marker_symbols->{ $r->{mgi_accession_id} } );
        $r = $sth->fetchrow_hashref;
    }

    return;
}

sub write_summary_table{
    my ( $fh, $unique_genes, $unique_es_cells, $genes_with_dist_qc_failure, $es_cells_with_dist_qc_failure, $genes_with_user_qc_failure, $es_cells_with_user_qc_failure ) = @_;

    $fh->print( "Pipeline,Unique genes,Unique clones,Genes with clones,Clones that,Genes with clones,Clones that\n" );
    $fh->print( ",,,that have distribution,have distribution,that have mouse,have mouse\n");
    $fh->print( ",,,QC failures,QC failures,clinic QC failures,clinic QC failures\n");
    for my $pipeline( sort keys %{$unique_genes} ){
        $fh->print( $pipeline . ',' . $unique_genes->{$pipeline} . ','
                        . $unique_es_cells->{$pipeline} . ',' );

        defined $genes_with_dist_qc_failure->{$pipeline} ? $fh->print( $genes_with_dist_qc_failure->{$pipeline} . ',' ) : $fh->print( '0,' );

        defined $es_cells_with_dist_qc_failure->{$pipeline} ? $fh->print( $es_cells_with_dist_qc_failure->{$pipeline} . ',' ) : $fh->print( '0,' );

        defined $genes_with_user_qc_failure->{$pipeline} ? $fh->print( $genes_with_user_qc_failure->{$pipeline} . ',' ) : $fh->print( '0,' );

        defined $es_cells_with_user_qc_failure->{$pipeline} ? $fh->print( $es_cells_with_user_qc_failure->{$pipeline} . "\n" ) : $fh->print( "0\n" );

    }

    return;
}

sub write_es_cell_detail_row{
    my ( $fh, $r, $marker_symbol ) = @_;

    my @qc_fails;
    for my $key( sort keys %{$r} ){
        next unless defined $r->{$key};

        if ( $key eq 'user_qc_southern_blot' ){
            push @qc_fails, $key if $r->{$key} =~ /^fail/ or $r->{$key} eq 'double integration';
        }
        else{
            push @qc_fails, $key if $r->{$key} eq 'fail';
        }
    }
    my $qc_fails = join( '; ', @qc_fails );

    my @columns = ( $r->{mgi_accession_id}, $marker_symbol, $r->{es_cell},
                    $r->{pipeline}, $qc_fails, $r->{distribution_qc_copy_number},
                    $r->{distribution_qc_five_prime_lr_pcr},
                    $r->{distribution_qc_five_prime_sr_pcr},
                    $r->{distribution_qc_three_prime_lr_pcr},
                    $r->{distribution_qc_three_prime_sr_pcr},
                    $r->{distribution_qc_thawing}, $r->{distribution_qc_lacz},
                    $r->{distribution_qc_loa}, $r->{distribution_qc_loxp},
                    $r->{distribution_qc_chr1}, $r->{distribution_qc_chr11a},
                    $r->{distribution_qc_chr11b}, $r->{distribution_qc_chr8a},
                    $r->{distribution_qc_chr8b}, $r->{distribution_qc_chry},
                    $r->{user_qc_karyotype}, $r->{user_qc_southern_blot},
                    $r->{user_qc_map_test}, $r->{user_qc_tv_backbone_assay},
                    $r->{user_qc_five_prime_cassette_integrity},
                    $r->{user_qc_five_prime_lr_pcr}, $r->{user_qc_three_prime_lr_pcr},
                    $r->{user_qc_lacz_sr_pcr}, $r->{user_qc_loss_of_wt_allele},
                    $r->{user_qc_loxp_confirmation}, $r->{user_qc_mutant_specific_sr_pcr},
                    $r->{user_qc_neo_count_qpcr}, $r->{user_qc_neo_sr_pcr}
                );
    my @undef_replaced_columns;
    for my $column( @columns ){
        if ( defined $column ){
            push @undef_replaced_columns, $column;
        }
        else{
            push @undef_replaced_columns, '---'
        }
    }
    $fh->print( join( ',', @undef_replaced_columns ) . "\n" );

    return;
}

sub parse_config_file{
    my ( $config_file ) = @_;

    my %config;
    my $fh = file( $config_file)->openr()
        or die "Could not read config file $config_file\n";
    while( my $line = $fh->getline() ){
        chomp( $line );
        $line =~ s/\s//g;
        my ( $key, $value ) = $line =~ /^(.+)=(.+)$/;
        $config{$key} = $value;
    }

    return (\%config);
}
