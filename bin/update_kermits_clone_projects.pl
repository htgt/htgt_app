#! /software/bin/perl

##
## Script to fix the pipeline associations for clones in Kermits
##

use strict;
use warnings FATAL => 'all';
use HTGT::DBFactory;
use DateTime;
use Data::Dumper;

##
## The plan...
##
## foreach emi_clone
##   1. look up the project for that clone in HTGT
##   2. find out if it's komp/eucomm
##   3. assign the emi_clone to that project
##

## Connect to databases

my $htgt_schema    = HTGT::DBFactory->connect( 'eucomm_vector', { AutoCommit => 0 } );
my $kermits_schema = HTGT::DBFactory->connect( 'kermits', { AutoCommit => 0 } );

## Do some work

# Store the project details
my $project_id_lookup   = {};
my $project_name_lookup = {};
my $pln_project_rs = $kermits_schema->resultset('KermitsDB::PlnPipeline')->search({});
while ( my $project = $pln_project_rs->next() ) {
  $project_id_lookup->{$project->name} = $project->id;
  $project_name_lookup->{$project->id} = $project->name
}

# Store the project affilitaion for the HTGT clones
print "Pre-fetching clone details from HTGT...\n\n";
my $htgt_clone_details = {};
my $well_summ_rows_rs  = $htgt_schema->resultset('HTGTDB::WellSummaryByDI')->search(
  { epd_well_name => { '!=', undef } },
  { join => 'project', columns => ['project.is_eucomm','project.is_komp_csd','me.epd_well_name'] }
);
while ( my $ws = $well_summ_rows_rs->next() ) {
  $htgt_clone_details->{$ws->epd_well_name} = {
    is_eucomm => $ws->project->is_eucomm   ? $ws->project->is_eucomm   : 0,
    is_komp   => $ws->project->is_komp_csd ? $ws->project->is_komp_csd : 0
  };
}

$kermits_schema->txn_do(
  sub {

    my $emi_clone_rs = $kermits_schema->resultset('KermitsDB::EmiClone')->search({});
    while ( my $emi_clone = $emi_clone_rs->next() ) {
      
      print " - " . $emi_clone->clone_name . " (currently ".$project_name_lookup->{$emi_clone->pipeline_id}."): ";
      
      if ( defined $htgt_clone_details->{$emi_clone->clone_name} ) {
        my $is_eucomm = $htgt_clone_details->{$emi_clone->clone_name}->{is_eucomm};
        my $is_komp   = $htgt_clone_details->{$emi_clone->clone_name}->{is_komp};
        
        print "is_eucomm: '".$is_eucomm."' ";
        print "is_komp_csd: '".$is_komp."'";
        
        my $pipline_id_to_set = undef;
        
        if    ( $is_eucomm == 1 and $is_komp == 1 ) {}
        elsif ( $is_eucomm == 0 and $is_komp == 0 ) {}
        elsif ( $is_eucomm == 1 and $is_komp == 0 ) { $pipline_id_to_set = $project_id_lookup->{'EUCOMM'}; }
        elsif ( $is_eucomm == 0 and $is_komp == 1 ) { $pipline_id_to_set = $project_id_lookup->{'KOMP'}; }
        
        if ( defined $pipline_id_to_set ) {
          
          unless ( $emi_clone->pipeline_id eq $pipline_id_to_set ) {
            print " - setting pipeline_id to $pipline_id_to_set ...";
            
            my $dt   = DateTime->now;
            my $date = $dt->day . '-' . $dt->month_name . '-' . $dt->year;
            
            $emi_clone->update({ 
              pipeline_id => $pipline_id_to_set,
              edited_by   => 'do2',
              edit_date   => $date
            });
          }
          
        }
        else {
          print " -- can't determine a pipeline! -- ";
        }
        
      }
      else {
        print " -- No well_summary_by_di entry found, help... -- ";
      }
      
      print "\n";

    }

  }
);

exit;
