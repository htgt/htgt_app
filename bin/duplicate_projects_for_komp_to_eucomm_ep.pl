#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Data::Dumper;
use HTGT::DBFactory;

GetOptions(
    'debug|d'   => \my $debug,
    'verbose|v' => \my $verbose,
    'dryrun'    => \my $dryrun,
    'limit'     => \my $limit
);

my $schema = HTGT::DBFactory->connect('eucomm_vector');

my $allowed_regeneron_statuses = {
   'ES Cell Clone Microinjected' => 1, 
   'ES cell colonies screened / QC one positive' => 1, 
   'ES cell colonies screened / QC positives' => 1, 
   'Germline Transmission Achieved' => 1, 
};

if ($debug) {
    print STDERR "connected\n";
}

my $sql_for_wells = qq[
    select distinct 
    plate.name, well.well_name,
    plate_data.data_type,
    well.design_instance_id,
    (select data_value  from well_data where well_data.well_id = well.well_id and data_type = 'cassette') cassette,
    (select data_value  from well_data where well_data.well_id = well.well_id and data_type = 'backbone') backbone
    from plate, plate_data, well
    where plate.plate_id = well.plate_id
    and plate.plate_id = plate_data.plate_id
    and upper(plate_data.data_type) = 'EUCOMM_EP'
];

if ($verbose) { print STDERR "${sql_for_wells}\n"; }

my $sth = $schema->storage->dbh->prepare($sql_for_wells);

$sth->execute();

my $count = 0;

# Find the wells which NEED duplicated projects
# For each well,look up the matching projects, ensure there are two - one being marked 'vector_only' and the other marked 'ep_only'
# The vector only should have no EP information, the ep only project should have ep information
# (note that  when a project is newly created, this is NOT the case).
# For now - if there are NOT, print out the correct action (insert or update etc)

$schema->txn_do(
    sub {

        $count++;
        while ( my @result = $sth->fetchrow_array() ) {

            $count++;
            if ($verbose) {
                if ( ( $count % 100 ) == 0 ) {
                    print STDERR "$count\n";
                }
            }

            my ( $plate_name, $well_name, $data_type, $di_id, $cassette, $backbone ) = @result;
            if ($debug) {
                print STDERR "$plate_name, $well_name, $data_type, $di_id, $cassette, $backbone\n";
            }

            next unless $di_id;

            if ( $cassette && $backbone ) {

                if ($verbose) {
                    print
                      "getting project with plate $plate_name, well $well_name, $data_type, di: $di_id, $cassette, $backbone\n";
                }
                my $projects = get_projects( $plate_name, $well_name, $data_type, $di_id, $cassette, $backbone );
                my $mgi_gene = $projects->first->mgi_gene;
                my $regeneron_status = $mgi_gene->cached_regeneron_status;
                my $status_name = ' no status ';
                if($regeneron_status){
                    $status_name = $regeneron_status->status;
                }
                if($status_name && $allowed_regeneron_statuses->{$status_name}){
                    print "status for ".$mgi_gene->marker_symbol ." ($well_name) is ".$status_name." - processing\n";
                    correct_projects($projects);
                }else{
                    if($verbose){
                        print "status for ".$mgi_gene->marker_symbol ." ($well_name) is ".$status_name." - skipping\n";
                    }
                }

            } else {
                die
                  "have a komp / eucomm EP switch on plate $plate_name / $well_name without a marked cassette / backbone\n";
            }

            if ( $limit && ( $count > $limit ) ) {
                last;
            }
        }

        if ($dryrun) {
            die "ROLLBACK\n";
        }

    }
);

sub get_projects {
    my ( $plate_name, $well_name, $data_type, $di_id, $cassette, $backbone ) = @_;

    my $projects = $schema->resultset('HTGTDB::Project')->search(
        {   design_instance_id => $di_id,
            cassette           => $cassette,
            backbone           => $backbone
        }
    );

    return $projects;
}

sub correct_projects {
    my $projects = shift;
    my $vector_project;
    my $esc_project;

    if ( $projects->search( { vector_only => 1, is_komp_csd => 1 } )->count == 1 ) {
        $vector_project = $projects->search( { vector_only => 1, is_komp_csd => 1 } )->first;
    }
    if ( $projects->search( { esc_only => 1, is_eucomm => 1 } )->count == 1 ) {
        $esc_project = $projects->search( { esc_only => 1, is_eucomm => 1 } )->first;
    }

    if ( $vector_project && $esc_project ) {
        if ($verbose) {
            print "both projects present ("
              . $vector_project->project_id . ", "
              . $esc_project->project_id
              . "), no need to change\n";
        }
        return 1;
    }

    if ($vector_project) {
        #update the vector-only project so it's status is vector-complete
        add_esc_project_to_vector_project($vector_project);
        if ( $vector_project->status->order_by >= 75 ) {
            $vector_project->update( { project_status_id => 15, vector_only => 1 } );
        }
    } else {
        if ( $projects->search( { is_komp_csd => 1 } )->count == 1 ) {

            if ($verbose) {
                print
                  "found single komp project (not marked vector_only) - altering it, and adding a eucomm esc_only project\n";
            }

            my $single_komp_project = $projects->search( { is_komp_csd => 1 } )->first;

            if ($verbose) { print "NOW adding eucomm project with esc_only\n" }

            my $esc_project = add_esc_project_to_vector_project($single_komp_project);

            if ($verbose) {
                print "added esc_only eucomm project: " . $esc_project->project_id . "\n";
            }

            if ( $single_komp_project->status->order_by >= 75 ) {
                $single_komp_project->update(
                    {   project_status_id => 15,
                        vector_only       => 1,
                        epd_distribute    => undef,
                        targeted_trap     => undef,
                        total_colonies    => undef,
                        colonies_picked   => undef
                    }
                );
                if ($verbose) {
                    print "updated komp project so it has status vector_complete, and vector_only: "
                      . $esc_project->project_id . "\n";
                }
            }
        }else{
            if ($verbose) {
                print
                  "found multiple komp projects (not marked vector_only) - don't know which to alter\n";
            }
        }
    }
}

sub add_esc_project_to_vector_project {
    my $project          = shift;
    my %new_project_data = $project->get_columns;
    my $data             = \%new_project_data;
    my $data_keys        = join " ", keys %new_project_data;
    delete $new_project_data{is_komp_csd};
    delete $new_project_data{project_id};
    $new_project_data{is_eucomm}   = 1;
    $new_project_data{esc_only}    = 1;
    $new_project_data{vector_only} = 0;
    print Data::Dumper->Dump( [$data] );
    my $new_project = $schema->resultset('HTGTDB::Project')->create( \%new_project_data );
    return $new_project;
}
