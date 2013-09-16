#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Getopt::Long;
use HTGT::DBFactory;
use Log::Log4perl ':easy';

local $Data::Dumper::Terse  = 1;
local $Data::Dumper::Indent = 0;

Log::Log4perl->easy_init();
GetOptions( 'commit' => \my $commit );

die "Usage: perl $0 <plate_number> ..."
    unless @ARGV;

my $plate_regex   = qr/^(\D+)(\d+)_(\D)_(\d+)$/;
my $eucomm_vector = HTGT::DBFactory->connect('eucomm_vector');
my $updated_wells = 0;

die "could not connect to database 'eucomm_vector'"
    unless $eucomm_vector;

for my $plate_num (@ARGV) {

    # a simple logger
    my $log = sub { INFO( "[$plate_num] -- ", @_ ) };

    # search for the plate
    my $plate_rs = $eucomm_vector->resultset('Plate')
        ->search( { name => $plate_num } );

    $log->( $plate_rs->count . " matching plate(s) found" );

    next unless $plate_rs->count > 0;

    # is this a 384 well plate in HTGT?
    my $htgt_plate       = $plate_rs->first;
    my $is384_well_plate = $htgt_plate->plate_data_value('is_384');

    if ( defined $is384_well_plate && $is384_well_plate eq 'yes' ) {
        $log->('is a 384 well plate and should be re-jigged');

        # should match our regex
        next unless $htgt_plate->name =~ $plate_regex;

        # find the clone plate and qctest run
        my $clone_plate     = $1 . $2 . '_' . $3;
        my $clone_plates_rs = $eucomm_vector->resultset('Plate')
            ->search( { name => { 'like', $clone_plate . '%' } } );

        $log->( $clone_plates_rs->count . " plate(s) for $clone_plate" );

        next unless $clone_plates_rs->count > 0;

        # propagate the identity changes to the child wells
        $eucomm_vector->txn_do(
            sub {
                while ( my $current_clone_plate = $clone_plates_rs->next ) {
                    my $wells_rs = $current_clone_plate->wells;

                    while ( my $well = $wells_rs->next ) {
                        $updated_wells = fix_child_wells( $well, $updated_wells );
                    }
                }

                INFO("Fixed/Updated $updated_wells wells");

                unless ($commit) {
                    INFO('Rolling back');
                    $eucomm_vector->txn_rollback;
                }
            }
        );
    }
}

exit 0;

sub fix_child_wells {
    my ( $root_well, $count ) = @_;
    my $child_wells_rs = $root_well->child_wells;

    while ( my $child_well = $child_wells_rs->next ) {
        $count = fix_child_wells( $child_well, $count );

        # don't waste time if already correct
        next
            if $child_well->design_instance_id
                == $root_well->design_instance_id;

        # not the best looking message but has all the info we need
        INFO(
            Dumper {
                parent_id          => $root_well->well_id,
                parent_name        => $root_well->plate->name,
                child_id           => $child_well->well_id,
                child_name         => $child_well->plate->name,
                design_instance_id => {
                    $root_well->design_instance_id =>
                        $child_well->design_instance_id
                },
            }
        );

        $child_well->update(
            { design_instance_id => $root_well->design_instance_id } );

        $count++;
    }

    return $count;
}
