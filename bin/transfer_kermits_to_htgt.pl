#!/usr/bin/env perl

use strict;
use Getopt::Long;
use Data::Dumper;
use HTGT::DBFactory;
use HTGT::DBFactory::DBConnect;
use DateTime;
use DateTime::Format::Builder;
use DateTime::Format::Flexible;

my $eu_schema = HTGT::DBFactory->connect('eucomm_vector');

# Always read from the live kermits db, even if we are connecting to the test eucomm_vector schema
my $schema = HTGT::DBFactory::DBConnect->connect('external_mi_esmp');

transfer_kermits_to_htgt();

sub transfer_kermits_to_htgt {
  my $projects_by_code = {};
  print "update_project_status - running transfer_kermits\n";

  foreach my $status ( $eu_schema->resultset('HTGTDB::ProjectStatus')->all() ) { $projects_by_code->{ $status->code } = $status; }

  my @project_codes = keys %$projects_by_code;
  print "read in codes: @project_codes\n";

  $schema->txn_do(
    sub {

      my $project_retracting_sql = qq[
           update project
            set project_status_id = 19
            where project_id in (
            select project_id
            from project, project_status
            where (project_status.order_by > 95 and project_status.order_by < 115)
            and project.project_status_id = project_status.project_status_id
            and (is_komp_csd = 1 or is_eucomm = 1)
            )
          ];


      my $sth = $eu_schema->storage->dbh->prepare_cached($project_retracting_sql);
      $sth->execute();

      #Get all MI records and cluster by project_id (implied from EPD_ID)
      my $mi_attempts_by_project = {};

      #my @mi_attempts = $schema->resultset('KermitsDB::EmiAttempt')->search({is_active=>1});

      my @mi_attempts = $schema->resultset('KermitsDB::EmiAttempt')->search(
        {
          is_active => 1
        },
        join     => [ 'status', { 'event' => [ 'centre', { 'clone' => 'pipeline' } ] } ],
        prefetch => [ 'status', { 'event' => [ 'centre', { 'clone' => 'pipeline' } ] } ]
      );

      my $count = 0;
      print "grouping MIs by project\n";
      foreach my $mi_attempt (@mi_attempts) {
        $count++;
        if ( ( $count % 100 ) == 0 ) {
          print "$count\n";
        }
        my $clone_name = $mi_attempt->event->clone->clone_name;
        if ($clone_name) {
          if ( my $project_id = get_project_id_for_clone( $eu_schema, $clone_name ) ) {
            my $status;
            if ( $mi_attempt->status ) {
              $status = $mi_attempt->status->name;
            }
            else {
              $status = 'none';
            }

            #my $project_status = $eu_schema->resultset('HTGTDB::Project')->find({project_id=>$project_id})->status->name;
            #print "$project_status,$project_id,$clone_name,$status,".$mi_attempt->is_active."\n";
            
            #Do not count any MIs from KOMP clones which have been microinjected at EUMODIC partners
            if( project_is_komp_and_mi_is_eumodic($project_id, $mi_attempt) ){
                next;
            }
            
            if ( $mi_attempt->is_active ) {
              push @{ $mi_attempts_by_project->{$project_id} }, $mi_attempt;
            }
          }
          else {
            warn 'no project_id in ${well_summary_by_di} for ' . $clone_name . "\n";
          }
        }
        else {
          warn 'skipping ' . $mi_attempt->event->id . " because theres no clone name??\n";
        }
      }
      print "classifying projects\n";

      # Walk each project: get the 'best' result from all MI records for that project_id.
      # Update the project_id
      foreach my $project_id ( keys %$mi_attempts_by_project ) {
        my @mi_attempts = @{ $mi_attempts_by_project->{$project_id} };
        my $best_status = $projects_by_code->{'M-MIP'};
        foreach my $mi_attempt (@mi_attempts) {
          my $status;
          if ( $mi_attempt->status ) {
            $status = $mi_attempt->status->name;
          }
          else {
            $status = 'none';
          }
          if ( $status eq 'Genotype Confirmed' ) {
            if ( $mi_attempt->emma ) {
                $best_status = $projects_by_code->{'M-GC'};
            }
          }
          elsif ( $status eq 'Germline transmission achieved' && !( $best_status eq 'Genotype Confirmed' ) ) {

            # Dont OVERRIDE G-C with G-L-T
            $best_status = $projects_by_code->{'M-GLT'};
          }
          print "recovered mi: " . $mi_attempt->id . " - status: $status : best at the moment: " . $best_status->name . "\n";
        }

        my $project = $eu_schema->resultset('HTGTDB::Project')->find( { project_id => $project_id } );
        my $current_project_status_order_by = $project->status->order_by;

        if ( $best_status->order_by != $current_project_status_order_by ) {
          print "Changing $current_project_status_order_by to "
           . $best_status->order_by
           . " for project "
           . $project->project_id . ": "
           . $project->mgi_gene->marker_symbol . "\n";
          $project->update( { project_status_id => $best_status->project_status_id, edit_user => 'team87' } );
        }
      }
    }
  );

  #print "update_project_status - finished running transfer_kermits\n";
}

sub get_project_id_for_clone {
  my $schema     = shift;
  my $clone_name = shift;
  my $sth        = $schema->storage->dbh->prepare_cached("select project_id from well_summary_by_di where epd_well_name = ?");
  $sth->execute($clone_name);
  if ( my $row = $sth->fetchrow_arrayref() ) {
    $sth->finish;
    return $row->[0];
  }
  return;
}

sub project_is_komp_and_mi_is_eumodic {
    my $project_id = shift;
    my $mi = shift;
    my $project = $eu_schema->resultset('HTGTDB::Project')->find({project_id=>$project_id});
    if(($project->is_komp_csd or $project->is_komp_regeneron) &&
       (
        $mi->event->centre->name eq 'GSF' ||
        $mi->event->centre->name eq 'ICS' ||
        $mi->event->centre->name eq 'MRC - Harwell' ||
        $mi->event->centre->name eq 'Monterotondo'
       )
    ){
        print "Omitting considering MI for clone ".$mi->event->clone->clone_name." because a KOMP clone has been injected at EUMODIC site (".$mi->event->centre->name.")\n";
        return 1;
    }
    
    return 0;
}

1;
