#!/usr/bin/env perl

use strict;
use Getopt::Long;
use Data::Dumper;
use DateTime;
use DateTime::Format::Builder;
use DateTime::Format::Flexible;
use HTGT::DBFactory;

my $projects_by_code = {};

my $dt        = DateTime->now;
my $edit_date = $dt->day . '-' . $dt->month_name . '-' . $dt->year;
my $edited_by = 'vvi';

my $schema = HTGT::DBFactory->connect('kermits');

my @mi_attempts;

@mi_attempts = $schema->resultset('KermitsDB::EmiAttempt')->search(
  {
    is_active => 1

     #id=>3638
  },
  join     => [ 'status', { 'event' => [ 'centre', { 'clone' => 'pipeline' } ] } ],
  prefetch => [ 'status', { 'event' => [ 'centre', { 'clone' => 'pipeline' } ] } ]
);

my $now = DateTime->now();

print "Retrieved " . scalar(@mi_attempts) . " attempts\n";
print "centre,date,clone,cct_chim,cct_pups,genotyp,hets,is_active,inactivate,oldstatus,robot,inactivate,change_status\n";
$schema->txn_do(
  sub {
    foreach my $mi_attempt (@mi_attempts) {

      #next unless ($mi_attempt->event->clone->clone_name eq 'EPD0064_1_A10');
      my $make_inactive  = $mi_attempt->should_be_made_inactive;
      my $desired_status = $mi_attempt->get_desired_status;
      my $current_status = $mi_attempt->status;
      my $current_status_name;
      if   ($current_status) { $current_status_name = $current_status->name }
      else                   { $current_status_name = 'undefined' }

      my $will_inactivate    = 0;
      my $will_change_status = 0;

      #switch attempt off
      #print "Desired status: ".$desired_status->name."\n";
      #print "Current status: ".$current_status->name."\n";
      if ($make_inactive) {
        $will_inactivate    = 1;
        $will_change_status = 1;
        print "UPDATE: inactivating " . $mi_attempt->event->clone->clone_name . "\n";
        $mi_attempt->update( { is_active => 0, edit_date => $edit_date, edited_by => $edited_by, status_dict_id => 3 } );
      }

      #Make a good-faith attempt to have status capture whether the mi has gone germline, genotyped or neither:
      #  -- this goes in two directions:
      #  -- if the current status is 'below' the 'desired' status, then boost it.
      #  -- if the current status is glt or genotyp, and the desired status is MI, bring it back to MI.
      if ( $desired_status->name eq 'Genotype Confirmed' ) {
        if ( !( $current_status->name eq 'Genotype Confirmed' ) ) {
          $will_change_status = 1;
          print "UPDATE: advancing " . $mi_attempt->event->clone->clone_name . " to genotype confirmed\n";
          $mi_attempt->update( { status_dict_id => 9, edit_date => $edit_date, edited_by => $edited_by } );
        }
      }
      elsif ( $desired_status->name eq 'Germline transmission achieved' ) {
        if ( !( $current_status->name eq 'Germline transmission achieved' ) ) {
          $will_change_status = 1;
          print "UPDATE: advancing " . $mi_attempt->event->clone->clone_name . " to glt\n";
          $mi_attempt->update( { status_dict_id => 6, edit_date => $edit_date, edited_by => $edited_by } );
        }
      }
      elsif ( $desired_status->name eq 'Micro-injected' ) {
        if ( ( $current_status->name eq 'Germline transmission achieved' ) || ( $current_status->name eq 'Genotype Confirmed' ) ) {
          $will_change_status = 1;
          print "UPDATE: reverting " . $mi_attempt->event->clone->clone_name . " to MI\n";
          $mi_attempt->update( { status_dict_id => 3, edit_date => $edit_date, edited_by => $edited_by } );
        }
      }

      if ( $will_inactivate || $will_change_status ) {
        print $mi_attempt->event->centre_id . ","
         . $mi_attempt->actual_mi_date . ","
         . $mi_attempt->event->clone->clone_name . ","
         . $mi_attempt->chimeras_with_glt_from_cct . ","
         . $mi_attempt->number_with_cct . ","
         . $mi_attempt->chimeras_with_glt_from_genotyp . ","
         . $mi_attempt->number_het_offspring . ","
         . $mi_attempt->is_active
         . ",$make_inactive,$current_status_name,"
         . $desired_status->name
         . ",$will_inactivate,$will_change_status\n";
      }

    }

    #die "ROLLBACK\n";
  }
);

1;
