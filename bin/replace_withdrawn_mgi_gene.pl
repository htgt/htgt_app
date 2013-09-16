#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use Log::Log4perl ':easy';
use Readonly;
use IO::File;

use HTGT::Utils::FileDownloader;
use HTGT::DBFactory;

my $log_level = $INFO;

Readonly my $WITHDRAWN_MGI_REPORT_URL => "ftp://ftp.informatics.jax.org/pub/reports/MRK_List1.rpt";
Readonly my $MGI_COORDINATE_REPORT_URL => "ftp://ftp.informatics.jax.org/pub/reports/MGI_Coordinate.rpt";

my $withdrawn_mgi_report = download_url_to_tmp_file($WITHDRAWN_MGI_REPORT_URL);
my $mgi_coordinate_report = download_url_to_tmp_file($MGI_COORDINATE_REPORT_URL);

## the following replace the above four lines just for testing purpose
#my $withdrawn_mgi_report = IO::File->new('MRK_List1.rpt', O_RDONLY) or die "open file $! \n";
#my $mgi_coordinate_report= IO::File->new('MGI_Coordinate.rpt', O_RDONLY) or die "open file $!\n";


GetOptions(
    commit => \my $commit,
) or pod2usage(2);

Log::Log4perl->easy_init( { level => $log_level, layout => '%p - %m%n' });

my $schema = HTGT::DBFactory->connect( 'eucomm_vector', { AutoCommit => 0 } );

# read the data
my $symbol_changed_to = read_symbol_change_report($withdrawn_mgi_report);
my %symbol_changed_to = %{$symbol_changed_to};

my $mgi_gene_entries = read_mgi_coordinate_report($mgi_coordinate_report);
my %mgi_gene_entries = %{$mgi_gene_entries};

foreach my $old_symbol ( keys %symbol_changed_to ) {
    my @old_mgi_genes = $schema->resultset('HTGTDB::MGIGene')->search( { marker_symbol => $old_symbol } );

    if ( scalar(@old_mgi_genes) > 0 ) {
	INFO("found old symbol in htgt: ".$old_symbol);
        foreach my $old_gene (@old_mgi_genes) {
            my $old_mgi_gene_id = $old_gene->mgi_gene_id;

            # check if the new mgi_gene is in htgt already, if not, update/replace with new mgi_gene
            my $new_mgi_gene_id;
            my @new_mgi_genes = $schema->resultset('HTGTDB::MGIGene')->search( { marker_symbol => $symbol_changed_to{$old_symbol} } );

            $schema->txn_do(
                sub {
                    if ( scalar(@new_mgi_genes) > 0 ) {
			INFO("Found new symbol in htgt ".$symbol_changed_to{$old_symbol} );
                        foreach my $new_gene (@new_mgi_genes) {
                            $new_mgi_gene_id = $new_gene->mgi_gene_id;
			    INFO("Updating pipeline");
                            update_pipeline( $old_gene, $new_gene );
                        }
                    }
                    else {
                        # look up the mgi coordinate_report, overwrite/update the old mgi gene
                        if ($mgi_gene_entries{ $symbol_changed_to{$old_symbol} }){
                            my $new_entry = $mgi_gene_entries{$symbol_changed_to{$old_symbol}};
			    INFO("updating MGI Gene table");
                            # update the old mgi gene with new mgi gene info, keep the mgi_gene_id, so no need to update related tables.
                            $old_gene->update($new_entry);
                        }
                    }
                }
            );
        }
    }
}

if ($commit) {
    warn "Commiting changes\n";
    $schema->txn_commit;
}
else {
    warn "Rolling back changes\n";
    $schema->txn_rollback;
}

# read the file and store the withdrawn genes
sub read_symbol_change_report {
    my $file = shift;
    my %symbol_changed_to;
    INFO("reading symbol change file");
    while ( my $line = $file->getline ) {

        # find the withdrawn one, store in hash
        next unless ( $line =~ /withdrawn/ );

        my @contents = split /\t/, $line;
        my $symbol   = $contents[3];
        my $name     = $contents[5];
        my $type     = $contents[6];

        if ( $type =~ /Gene/ ) {
            my @lists = split / /, $name;
            if ( $lists[1] && ( $lists[1] =~ /=/ ) && $lists[2] ) {
                $symbol_changed_to{$symbol} = $lists[2];
            }
        }
    }

    return \%symbol_changed_to;
}

# read the coordiante file and store the info
sub read_mgi_coordinate_report {
    my $file = shift;
    my %mgi_gene_entries;
    INFO("reading coordinate file");
    while ( my $line = $file->getline ) {
        chomp $line;
        next unless ( $line =~ /^MGI:/ );

        my (
            $MGI_accession_id,             $marker_type,
            $marker_symbol,                $marker_name,
            $representative_genome_id,     $representative_genome_chromosome,
            $representative_genome_start,  $representative_genome_end,
            $representative_genome_strand, $representative_genome_build,
            $Entrez_gene_id,               $NCBI_gene_chromosome,
            $NCBI_gene_start,              $NCBI_gene_end,
            $NCBI_gene_strand,             $Ensembl_gene_id,
            $Ensembl_gene_chromosome,      $Ensembl_gene_start,
            $Ensembl_gene_end,             $Ensembl_gene_strand,
            $VEGA_gene_id,                 $VEGA_gene_chromosome,
            $VEGA_gene_start,              $VEGA_gene_end,
            $VEGA_gene_strand,             $UniSTS_gene_chromosome,
            $UniSTS_gene_start,            $UniSTS_gene_end,
            $MGI_QTL_gene_chromosome,      $MGI_QTL_gene_start,
            $MGI_QTL_gene_end,             $miRBase_gene_id,
            $miRBase_gene_chromosome,      $miRBase_gene_start,
            $miRBase_gene_end,             $miRBase_gene_strand,
            $Roopenian_STS_gene_start,     $Roopenian_STS_gene_end
        ) = split /\t/, $line;

        $mgi_gene_entries{$marker_symbol} = {
            mgi_accession_id             => $MGI_accession_id,
            marker_type                  => $marker_type,
            marker_symbol                => $marker_symbol,
            marker_name                  => $marker_name,
            representative_genome_id     => $representative_genome_id,
            representative_genome_chr    => $representative_genome_chromosome,
            representative_genome_start  => $representative_genome_start,
            representative_genome_end    => $representative_genome_end,
            representative_genome_strand => $representative_genome_strand,
            representative_genome_build  => $representative_genome_build,
            entrez_gene_id               => $Entrez_gene_id,
            ncbi_gene_chromosome         => $NCBI_gene_chromosome,
            ncbi_gene_start              => $NCBI_gene_start,
            ncbi_gene_end                => $NCBI_gene_end,
            ncbi_gene_strand             => $NCBI_gene_strand,
            ensembl_gene_id              => $Ensembl_gene_id,
            ensembl_gene_chromosome      => $Ensembl_gene_chromosome,
            ensembl_gene_start           => $Ensembl_gene_start,
            ensembl_gene_end             => $Ensembl_gene_end,
            ensembl_gene_strand          => $Ensembl_gene_strand,
            vega_gene_id                 => $VEGA_gene_id,
            vega_gene_chromosome         => $VEGA_gene_chromosome,
            vega_gene_start              => $VEGA_gene_start,
            vega_gene_end                => $VEGA_gene_end,
            vega_gene_strand             => $VEGA_gene_strand,
            unists_gene_start            => $UniSTS_gene_start,
            unists_gene_end              => $UniSTS_gene_end,
            mgi_qtl_gene_start           => $MGI_QTL_gene_start,
            mgi_qtl_gene_end             => $MGI_QTL_gene_end,
            mirbase_gene_start           => $miRBase_gene_start,
            mirbase_gene_end             => $miRBase_gene_end,
            roopenian_sts_gene_start     => $Roopenian_STS_gene_start,
            roopenian_sts_gene_end       => $Roopenian_STS_gene_end
        };

        # convert the '+'/'-' to number 1/-1
        if ( $representative_genome_strand eq '+' ) {
            $mgi_gene_entries{$marker_symbol}{representative_genome_strand} = 1;
        }
        elsif ( $representative_genome_strand eq '-' ) {
            $mgi_gene_entries{$marker_symbol}{representative_genome_strand} =
              -1;
        }

        if ( $Ensembl_gene_strand eq '+' ) {
            $mgi_gene_entries{$marker_symbol}{ensembl_gene_strand} = 1;
        }
        elsif ( $Ensembl_gene_strand eq '-' ) {
            $mgi_gene_entries{$marker_symbol}{ensembl_gene_strand} = -1;
        }

        if ( $NCBI_gene_strand eq '+' ) {
            $mgi_gene_entries{$marker_symbol}{ncbi_gene_strand} = 1;
        }
        elsif ( $NCBI_gene_strand eq '-' ) {
            $mgi_gene_entries{$marker_symbol}{ncbi_gene_strand} = -1;
        }

        if ( $VEGA_gene_strand eq '+' ) {
            $mgi_gene_entries{$marker_symbol}{vega_gene_strand} = 1;
        }
        elsif ( $VEGA_gene_strand eq '-' ) {
            $mgi_gene_entries{$marker_symbol}{vega_gene_strand} = -1;
        }

        for my $property ( keys %{ $mgi_gene_entries{$marker_symbol} } ) {
            if (   $mgi_gene_entries{$marker_symbol}{$property}
                && $mgi_gene_entries{$marker_symbol}{$property} =~ /^null/ )
            {
                $mgi_gene_entries{$marker_symbol}{$property} = undef;
            }
        }
    }
    return \%mgi_gene_entries;
}

sub update_pipeline {
    my ( $old_gene, $new_gene ) = @_;

    # check if there are projects link to the old gene
    my @projects_with_old_gene =
      $schema->resultset('HTGTDB::Project')
      ->search( { mgi_gene_id => $old_gene->mgi_gene_id } );

    if ( scalar(@projects_with_old_gene) > 0 ) {

        #update the project mgi_gene_id
        foreach my $proj (@projects_with_old_gene) {
            $proj->update(
                {
                    mgi_gene_id => $new_gene->mgi_gene_id,
                    edit_user   => $ENV{USER},
                    edit_date   => \'current_timestamp'
                }
            );
        }

        # check if there are projects link to new gene
        my @projects_with_new_gene =
          $schema->resultset('HTGTDB::Project')
          ->search( { mgi_gene_id => $new_gene->mgi_gene_id } );

        if ( scalar(@projects_with_new_gene) == 0 ) {
            if ( $old_gene->gene_recovery ) {
                foreach my $gene_recovery ( $old_gene->gene_recovery ) {
                    $gene_recovery->update(
                        { mgi_gene_id => $new_gene->mgi_gene_id } );
                }
            }
            if ( $old_gene->gene_recovery_history ) {
                foreach
                  my $gene_recovery_history ( $old_gene->gene_recovery_history )
                {
                    $gene_recovery_history->update(
                        { mgi_gene_id => $new_gene->mgi_gene_id } );
                }
            }
        }
    }
}

__END__

=head1 NAME

replace_withdrawn_mgi_gene.pl

=head1 SYNOPSIS

replace_withdrawn_mgi_gene.pl [--commit]

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
