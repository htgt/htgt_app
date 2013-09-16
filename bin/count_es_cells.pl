#!/usr/bin/env perl

# Script to count the number of ES Cells marked for distribution
# associated with each gene, and enter this in the GeneInfo table

use strict;
use warnings;

use HTGT::DBFactory;
use Getopt::Long;

GetOptions( commit => \my $commit ) or die "Usage: $0 [--commit]\n";

my $schema = HTGT::DBFactory->connect('eucomm_vector');

$schema->txn_do(
    sub {

        # Get all of the EPD wells (ES Cells) marked for distribution and
        # count how many cells we have per design_instance_id

        my $epd_rs = $schema->resultset('Well')->search(
            {
                'plate.type'           => 'EPD',
                'well_data.data_type'  => 'distribute',
                'well_data.data_value' => 'yes'
            },
            { join => [ 'plate', 'well_data' ] }
        );

        my %es_count_di;
        while ( my $epd_well = $epd_rs->next ) {
            $es_count_di{ $epd_well->design_instance_id } += 1;
        }

        # Get a list of the genes we need to look at...

        my $gene_info_rs =
          $schema->resultset('GeneInfo')->search_literal('gene_id is not null');

        # Now total up the counts of ES Cells per gene...

        #print "Summary of GeneInfo ES Cell Count updates... \n\n";

        while ( my $gene_info = $gene_info_rs->next ) {

            # Get the design instances for this gene
            my $design_inst_rs = $schema->resultset('DesignInstance')->search(
                { 'gene.id' => $gene_info->gene_id },
                {
                    join => {
                        design => {
                            design_request_links => {
                                design_request => { allele_request => 'gene' }
                            }
                        }
                    },
                    columns  => ['design_instance_id'],
                    distinct => 1
                }
            );

            # Add up the ES Cells for each di...
            my $es_cell_count = 0;
            while ( my $di = $design_inst_rs->next ) {
                $es_cell_count += $es_count_di{ $di->design_instance_id } || 0;
            }

            if ( $es_cell_count > 0 ) {

                #print '[debug] '
                #  . $gene_info->mgi_symbol
                #  . " -- "
                #  . $es_cell_count . "\n";

                if (   ( defined $gene_info->es_cell_count )
                    && ( $gene_info->es_cell_count == $es_cell_count ) )
                {

                    # do nothing - the count is already up to date...
                }
                else {
                    print '[log] '
                      . ( $gene_info->mgi_symbol || '<undef>' )
                      . " - updated from "
                      . ( $gene_info->es_cell_count || '<undef>' ) . " to "
                      . $es_cell_count . "\n";

                    $gene_info->update( { es_cell_count => $es_cell_count } );
                }

            }

        }

        die "Rollback requested\n" unless $commit;
    }
);
