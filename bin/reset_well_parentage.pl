#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use HTGT::DBFactory;

sub usage {
    print "Usage: $0 --plate <plate> --parent <parent> [--commit]\n";
    exit 1;
}

GetOptions(
    'commit'   => \my $commit,
    'plate=s'  => \my $plate,
    'parent=s' => \my $parent,
) or usage();

usage() unless $plate && $parent;

my $htgt = HTGT::DBFactory->connect('eucomm_vector');

$htgt->txn_do(
    sub {
        my $parent_rs =
          $htgt->resultset('Plate')->search_rs( { 'me.name' => $parent } );

        die "Too many rows for parent ($parent)" unless $parent_rs->count == 1;

        my $plate_rs = $htgt->resultset('Plate')->search_rs(
            {
                'me.name' => { 'like' => '%' . $plate . '%' },
                'well_data.data_type' =>
                  [qw/clone_name distribute pass_level qctest_result_id/],
            },
            { 'prefetch' => { 'wells' => 'well_data' } },
        );

        die "No rows found for plate ($plate)" unless $plate_rs->count > 0;

        my $well_data_count = 0;
        my $parent_wells_rs = $parent_rs->first->wells;

        while ( my $plate = $plate_rs->next ) {
            my $wells_rs = $plate->wells;
            while ( my $well = $wells_rs->next ) {
                my $well_data_rs = $well->well_data;
                while ( my $well_data = $well_data_rs->next ) {
                    $well_data->delete;
                    $well_data_count++;
                }

                # find the parent well (i.e. well with the same name)
                my $parent_well_rs = $parent_wells_rs->search_rs(
                    { 'me.well_name' => $well->well_name } );

                die "Too many parent wells for (" . $well->well_name . ")"
                  unless $parent_well_rs->count == 1;

                my $parent_well = $parent_well_rs->first;

                # update parent_well_id and design_instance_id
                $well->update(
                    {
                        parent_well_id     => $parent_well->well_id,
                        design_instance_id => $parent_well->design_instance_id,
                    }
                );
            }
        }

        print "Deleted ($well_data_count) rows from HTGTDB::WellData\n";

        unless ($commit) {
            warn "Rollback\n";
            $htgt->txn_rollback;
        }
    }
);
