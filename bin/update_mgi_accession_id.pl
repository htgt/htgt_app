#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use Log::Log4perl ':easy';
use IO::File;
use Text::CSV_XS;
use HTGT::DBFactory;

Log::Log4perl->easy_init( { level => $INFO } );

GetOptions(
    'help'         => \my $help,
    'file=s'       => \my $file,
    'commit'       => \my $commit,
    'limit_update' => \my $limit_update
) or pod2usage(2);

pod2usage(1) if $help;

my $schema = HTGT::DBFactory->connect('eucomm_vector');

my $fh = IO::File->new( $file, O_RDONLY ) or die "can't open file $!\n";

my $data = parse_file($fh);
my %data = %{$data};

my $mgi_genes;
if ($limit_update) {
    my @old_accession_ids;
    foreach my $old_accession_id ( keys %data ) {
        push @old_accession_ids, $old_accession_id;
    }

    #print @old_accession_ids;
    $mgi_genes
        = $schema->resultset('HTGTDB::MGIGene')->search( { mgi_accession_id => { '-in' => \@old_accession_ids } } );
}
else {
    $mgi_genes = $schema->resultset('HTGTDB::MGIGene')->search( {} );
}

my $number_of_pipeline_changes                         = 0;
my $number_of_no_new_gene_and_old_mgi_gene_overwritten = 0;
my $number_of_mgi_accession_id_changes                 = 0;
my $number_of_symbol_changes_only                      = 0;
my $both_gene_have_projects_transfer_old_gene_project  = 0;
my $have_new_gene_but_no_project_update_old_gene       = 0;
my $number_of_fail                                     = 0;
my $number_of_more_than_one_new_gene                   = 0;
my $old_gene_no_project                                = 0;

while ( my $old_gene = $mgi_genes->next ) {
    my $old_mgi_accession_id = $old_gene->mgi_accession_id;
    my $old_symbol           = $old_gene->marker_symbol;
    my $current_gene         = $data{$old_mgi_accession_id};

    $schema->txn_do(
        sub {
            eval {
                if ($current_gene)
                {
                    my $current_mgi_accession_id = $current_gene->[0];
                    my $current_symbol           = $current_gene->[1];

                    if ( $old_mgi_accession_id ne $current_mgi_accession_id ) {
                        INFO(
                            "MGI Accession ID changed old id: $old_mgi_accession_id new id: $current_mgi_accession_id");
                        $number_of_mgi_accession_id_changes++;

                        # check if the new gene in htgt
                        my @new_genes = $schema->resultset('HTGTDB::MGIGene')
                            ->search( { mgi_accession_id => $current_mgi_accession_id } );

                        if ( scalar(@new_genes) > 0 ) {
                            if ( scalar(@new_genes) > 1 ) {
                                WARN("more than one new gene");
                                $number_of_more_than_one_new_gene++;
                                next;
                            }
                            else {
                                my $new_gene = $new_genes[0];

                   # update the projects point to new mgi_gene_id (if there are projects with the old gene and new gene)
                   # or update old gene with new gene info (if there are projects with old gene
                   #  but there is no project with the new gene)
                                update_pipeline( $old_gene, $new_gene );
                            }
                        }
                        else {

                            # new gene not in htgt, update old gene with new mgi accession & symbol
                            INFO(
                                "updating the mgi gene table: replace $old_mgi_accession_id with $current_mgi_accession_id"
                            );
                            $number_of_no_new_gene_and_old_mgi_gene_overwritten++;
                            $old_gene->update(
                                {   mgi_accession_id => $current_mgi_accession_id,
                                    marker_symbol    => $current_symbol
                                }
                            );
                        }
                    }
                    elsif (( $old_mgi_accession_id eq $current_mgi_accession_id )
                        && ( $old_symbol ne $current_symbol ) )
                    {

                        # mgi accession ids are the same, but symbol different, update old symbol with new symbol
                        INFO(
                            "ID $old_mgi_accession_id the same, Updating marker symbol, replace $old_symbol with $current_symbol"
                        );
                        $number_of_symbol_changes_only++;
                        $old_gene->update( { marker_symbol => $current_symbol } );
                    }
                }
                else {
                    WARN("not found current gene in the file: $old_mgi_accession_id");
                }
            };
            if ($@) {
                INFO("while processing $old_mgi_accession_id, an error occured ($@),rollback changes.");
                $number_of_fail++;
                $schema->txn_rollback;
            }
            elsif ( not $commit ) {
                INFO("no commit specified, rolling back changes");
                $schema->txn_rollback;
            }
        }
    );
}
INFO("Number of MGI Accession changed: $number_of_mgi_accession_id_changes ");
INFO(
    "Number of new gene not in db, update old gene with new gene id & symbol: $number_of_no_new_gene_and_old_mgi_gene_overwritten"
);
INFO("Number of old gene has no project, delete old gene : $old_gene_no_project");
INFO("Number of pileline update: $number_of_pipeline_changes");
INFO(
    "Number of new gene have no project and update old gene with new gene: $have_new_gene_but_no_project_update_old_gene"
);
INFO(
    "Number of new gene has projects and transfer old gene projects to new gene: $both_gene_have_projects_transfer_old_gene_project"
);
INFO("Number of Marker symbol changed only: $number_of_symbol_changes_only");
INFO("Number of fail: $number_of_fail");
INFO("Number of times finding more than one new gene: $number_of_more_than_one_new_gene");

sub update_pipeline {
    my ( $old_gene, $new_gene ) = @_;

    # check if there are projects link to the old gene
    my @projects_with_old_gene = $old_gene->projects;

    if ( scalar(@projects_with_old_gene) > 0 ) {
        $number_of_pipeline_changes++;

        # check if there are projects link to new gene
        my @projects_with_new_gene = $new_gene->projects;

        if ( scalar(@projects_with_new_gene) == 0 ) {

            #update old gene with current id and symbol
            update_old_gene_with_new_gene_info( $old_gene, $new_gene );
        }
        else {

            #update the old gene project with new gene mgi_gene_id
            transfer_projects_from_old_gene_to_new_gene( $old_gene, $new_gene );
        }
    }
    else {
        my $old_gene_id = $old_gene->mgi_accession_id;
        my $new_gene_id = $new_gene->mgi_accession_id;
        INFO("old gene $old_gene_id has no projects. new gene $new_gene_id in htgt. delete old gene.");
        $old_gene_no_project++;
        $old_gene->delete();
    }
}

sub transfer_projects_from_old_gene_to_new_gene {
    my ( $old_gene, $new_gene ) = @_;

    INFO("Updating pipeline project etc.");
    $both_gene_have_projects_transfer_old_gene_project++;
    my @projects_with_old_gene = $old_gene->projects;

    # might not able to update bsc there unique contrant
    foreach my $proj (@projects_with_old_gene) {
        $proj->update(
            {   mgi_gene_id => $new_gene->mgi_gene_id,
                edit_user   => $ENV{USER},
                edit_date   => \'current_timestamp'
            }
        );
    }

    #check if new gene has gene recovery/gene recovery history, if not, update old gene recovery with new gene id
    if ( !$new_gene->gene_recovery ) {
        my $gene_recovery = $old_gene->gene_recovery;
        if ($gene_recovery) {
            INFO("updating old gene recovery with new gene id.");
            $gene_recovery->update( { mgi_gene_id => $new_gene->mgi_gene_id } );
        }
    }
    else {
        INFO("found new gene recovery, cannot update old gene recovery with new gene id.");
    }

    if ( $new_gene->gene_recovery_history_rs->count == 0 ) {
        foreach my $gene_recovery_history ( $old_gene->gene_recovery_history ) {
            INFO("updating old gene recovery history with new gene id.");
            $gene_recovery_history->update( { mgi_gene_id => $new_gene->mgi_gene_id } );
        }
    }
    else {
        INFO("found new gene recovery history, cannot update old gene recovery history with new gene id.");
    }
}

sub update_old_gene_with_new_gene_info {
    my ( $old_gene, $new_gene ) = @_;

    INFO("Updating old gene with new gene info.");
    $have_new_gene_but_no_project_update_old_gene++;

    $old_gene->update(
        {   mgi_accession_id             => $new_gene->mgi_accession_id,
            marker_symbol                => $new_gene->marker_symbol,
            marker_type                  => $new_gene->marker_type,
            marker_name                  => $new_gene->marker_name,
            representative_genome_id     => $new_gene->representative_genome_id,
            representative_genome_chr    => $new_gene->representative_genome_chr,
            representative_genome_start  => $new_gene->representative_genome_start,
            representative_genome_end    => $new_gene->representative_genome_end,
            representative_genome_strand => $new_gene->representative_genome_strand,
            representative_genome_build  => $new_gene->representative_genome_build,
            entrez_gene_id               => $new_gene->entrez_gene_id,
            ncbi_gene_chromosome         => $new_gene->ncbi_gene_chromosome,
            ncbi_gene_start              => $new_gene->ncbi_gene_start,
            ncbi_gene_end                => $new_gene->ncbi_gene_end,
            ncbi_gene_strand             => $new_gene->ncbi_gene_strand,
            ensembl_gene_id              => $new_gene->ensembl_gene_id,
            ensembl_gene_chromosome      => $new_gene->ensembl_gene_chromosome,
            ensembl_gene_start           => $new_gene->ensembl_gene_start,
            ensembl_gene_end             => $new_gene->ensembl_gene_end,
            ensembl_gene_strand          => $new_gene->ensembl_gene_strand,
            vega_gene_id                 => $new_gene->vega_gene_id,
            vega_gene_chromosome         => $new_gene->vega_gene_chromosome,
            vega_gene_start              => $new_gene->vega_gene_start,
            vega_gene_end                => $new_gene->vega_gene_end,
            vega_gene_strand             => $new_gene->vega_gene_strand,
            unists_gene_start            => $new_gene->unists_gene_start,
            unists_gene_end              => $new_gene->unists_gene_end,
            mgi_qtl_gene_start           => $new_gene->mgi_qtl_gene_start,
            mgi_qtl_gene_end             => $new_gene->mgi_qtl_gene_end,
            mirbase_gene_start           => $new_gene->mirbase_gene_start,
            mirbase_gene_end             => $new_gene->mirbase_gene_end,
            roopenian_sts_gene_start     => $new_gene->roopenian_sts_gene_start,
            roopenian_sts_gene_end       => $new_gene->roopenian_sts_gene_end,
            mgi_gt_count                 => $new_gene->mgi_gt_count,
            sp                           => $new_gene->sp,
            tm                           => $new_gene->tm
        }
    );

    # will fail if there are other child records
    $new_gene->delete();
}

sub parse_file {
    my $fh  = shift;
    my $csv = Text::CSV_XS->new();
    my %data;

    while ( my $row = $csv->getline($fh) ) {
        next unless ( $row->[0] =~ /^MGI:/ );

        my $old_id     = $row->[0];
        my $new_id     = $row->[2];
        my $new_symbol = $row->[3];
        $data{$old_id} = [ $new_id, $new_symbol ];
    }
    return \%data;
}

__END__

=head1 NAME

update_mgi_accession_id.pl

=head1 SYNOPSIS

    perl update_mgi_accession_id.pl --file filename [--commit]

=head1 AUTHOR

Wanjuan Yang , E<lt>wy1@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Genome Research Ltd

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
